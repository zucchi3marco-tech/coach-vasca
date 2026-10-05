import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/training_blocks_repository.dart';
import 'libreria_blocchi_providers.dart';

/// Blocco pronto per essere inviato alla Edge Function: solo i campi che
/// servono all'AI per scegliere e adattare, mai le note interne del
/// coach o i metadati di importazione.
class BloccoDisponibile {
  const BloccoDisponibile({
    required this.id,
    required this.codice,
    required this.titolo,
    required this.fase,
    required this.metriTotali,
    required this.parti,
  });

  final String id;
  final String codice;
  final String titolo;
  final String fase;
  final int metriTotali;
  final List<ParteDisponibile> parti;

  Map<String, dynamic> toMap() => {
    'id': id,
    'codice': codice,
    'titolo': titolo,
    'fase': fase,
    'metriTotali': metriTotali,
    'parti': parti.map((p) => p.toMap()).toList(),
  };
}

class ParteDisponibile {
  const ParteDisponibile({
    required this.ordine,
    required this.giri,
    required this.ripetizioni,
    this.distanzaM,
    this.durataS,
    this.stile,
    required this.zona,
    required this.esecuzione,
    this.recuperoS,
  });

  final int ordine;
  final int giri;
  final int ripetizioni;
  final int? distanzaM;
  final int? durataS;
  final String? stile;
  final String zona;
  final String esecuzione;
  final int? recuperoS;

  Map<String, dynamic> toMap() => {
    'ordine': ordine,
    'giri': giri,
    'ripetizioni': ripetizioni,
    'distanzaM': distanzaM,
    'durataS': durataS,
    'stile': stile,
    'zona': zona,
    'esecuzione': esecuzione,
    'recuperoS': recuperoS,
  };
}

/// Corrispondenza fra il nome del gruppo di allenamento (categoria del
/// club, FASE 11) e il vocabolario "Livelli / categorie" della libreria
/// Excel — dedotta dal coach solo per la pallanuoto ("Under12→Esordienti,
/// Under14→Ragazzi, Under16/18/Senior→Assoluti, Master→Master"); per il
/// nuoto non c'era un elenco esplicito nel piano, qui una corrispondenza
/// ragionevole per analogia (Es.*→Esordienti, Ragazzi/Cadetti→Ragazzi,
/// Juniores/Assoluti→Assoluti, Amatori→Master) — **da rivedere se non
/// corrisponde a come li classifichi davvero**. Il confronto è "contiene"
/// case-insensitive, non un match esatto sul nome del gruppo.
const _mappaLivelli = <String, String>{
  'under 12': 'Esordienti',
  'u12': 'Esordienti',
  'esordienti': 'Esordienti',
  'es.c': 'Esordienti',
  'es.b': 'Esordienti',
  'es.a': 'Esordienti',
  'under 14': 'Ragazzi',
  'u14': 'Ragazzi',
  'ragazzi': 'Ragazzi',
  'cadetti': 'Ragazzi',
  'under 16': 'Assoluti',
  'u16': 'Assoluti',
  'under 18': 'Assoluti',
  'u18': 'Assoluti',
  'under 20': 'Assoluti',
  'u20': 'Assoluti',
  'senior': 'Assoluti',
  'prima squadra': 'Assoluti',
  'juniores': 'Assoluti',
  'assoluti': 'Assoluti',
  'master': 'Master',
  'amatori': 'Master',
};

/// `null` se il nome del gruppo non richiama nessuna categoria nota: in
/// quel caso [blocchiCompatibili] non filtra per livello, solo per sport.
String? livelloExcelPerGruppo(String? nomeGruppo) {
  if (nomeGruppo == null) return null;
  final normalizzato = nomeGruppo.toLowerCase().trim();
  for (final chiave in _mappaLivelli.keys) {
    if (normalizzato.contains(chiave)) return _mappaLivelli[chiave];
  }
  return null;
}

bool _sportCompatibile(String sportBlocco, String? sportRichiesto) =>
    sportRichiesto == null ||
    sportBlocco == 'entrambi' ||
    sportBlocco == sportRichiesto;

bool _livelloCompatibile(String livelliBlocco, String? livelloRichiesto) {
  if (livelloRichiesto == null) return true;
  if (livelliBlocco.isEmpty) return true;
  if (livelliBlocco.contains('Tutti i livelli')) return true;
  return livelliBlocco.contains(livelloRichiesto);
}

/// Fino a [massimo] blocchi approvati del club, compatibili per sport e
/// livello con il gruppo indicato — RIPROGETTAZIONE AI, FASE 3: li scelgli
/// il codice, non l'AI, che può solo adattarli (±25%) o inventarne uno
/// nuovo se davvero nessuno va bene (vedi genera-allenamento/index.ts).
/// Vuoto se il club non ha ancora nessun blocco approvato: la
/// generazione in quel caso resta quella "libera" di prima.
Future<List<BloccoDisponibile>> blocchiCompatibili(
  WidgetRef ref, {
  required String clubId,
  String? sportRichiesto,
  String? nomeGruppo,
  int massimo = 40,
}) async {
  final tutti = await ref.read(trainingBlocksListProvider(clubId).future);
  final livello = livelloExcelPerGruppo(nomeGruppo);

  final compatibili =
      tutti
          .where((b) => b.stato == 'approvato')
          .where((b) => _sportCompatibile(b.sport, sportRichiesto))
          .where((b) => _livelloCompatibile(b.livelli, livello))
          .toList()
        ..sort((a, b) => a.titolo.compareTo(b.titolo));

  final scelti = compatibili.take(massimo).toList();
  final repository = ref.read(trainingBlocksRepositoryProvider);
  // Una richiesta di rete per blocco (fino a 40): una per volta sarebbe
  // lento, qui tutte insieme in parallelo.
  final tutteLeParti = await Future.wait([
    for (final blocco in scelti) repository.fetchParti(blocco.id),
  ]);

  final risultato = <BloccoDisponibile>[];
  for (var i = 0; i < scelti.length; i++) {
    final blocco = scelti[i];
    final parti = tutteLeParti[i];
    if (parti.isEmpty) continue;
    risultato.add(
      BloccoDisponibile(
        id: blocco.id,
        codice: blocco.codice,
        titolo: blocco.titolo,
        fase: blocco.fase,
        metriTotali: blocco.metriTotali,
        parti: [
          for (final p in parti)
            ParteDisponibile(
              ordine: p.ordine,
              giri: p.giri,
              ripetizioni: p.ripetizioni,
              distanzaM: p.distanzaM,
              durataS: p.durataS,
              stile: p.stile,
              zona: p.zona,
              esecuzione: p.esecuzione,
              recuperoS: p.recuperoS,
            ),
        ],
      ),
    );
  }
  return risultato;
}

/// `TrainingBlock.sport` usa 'nuoto'/'pallanuoto'/'entrambi' — lo sport
/// del club (FASE 11) usa 'nuoto'/'pallanuoto'/'nuoto_pallanuoto': questa
/// funzione traduce per [blocchiCompatibili]. Un club "nuoto_pallanuoto"
/// o senza sport impostato non filtra per sport (vede tutto).
String? sportRichiestoDaClub(String? sportClub) => switch (sportClub) {
  'nuoto' => 'nuoto',
  'pallanuoto' => 'pallanuoto',
  _ => null,
};
