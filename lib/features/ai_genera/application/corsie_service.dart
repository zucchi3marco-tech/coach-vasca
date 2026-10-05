import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pace_format.dart';
import '../../ripartenze/domain/calcolo_ripartenze.dart' as calcolo;
import '../../atleti/application/personal_best_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/personal_best.dart';
import '../../tabelle_passi/application/tabelle_passi_providers.dart';
import '../../test/application/test_providers.dart';
import '../../test/domain/test_ingresso.dart';
import '../domain/parametri_generazione.dart';
import '../domain/scheda_generata.dart';

/// Come il gruppo si divide in corsie di ripartenza, e chi sta in quale.
///
/// RIPROGETTAZIONE AI, FASE 3: porta anche i dati grezzi per atleta (PB
/// di ogni stile, passi dal test di soglia) così le ripartenze finali si
/// possono calcolare per OGNI serie con lo stile e la zona giuste
/// (vedi [ripartenzaPerSerie]), invece di usare una sola coppia
/// passo100S/differenzialeS sempre in stile libero per l'intera scheda.
class AssegnazioneCorsie {
  const AssegnazioneCorsie({
    required this.corsie,
    this.senzaTempo = const [],
    this.pbPerAtleta = const {},
    this.passiSogliaPerAtleta = const {},
    this.senzaTestSoglia = const [],
  });

  /// Vuota se nessun atleta ha il PB sui 100 stile libero.
  final List<CorsiaGenerazione> corsie;

  /// Atleti del gruppo senza PB sui 100 sl: non si sa in che corsia
  /// metterli, li decide l'allenatore.
  final List<String> senzaTempo;

  /// Tutti i personal best (tutti gli stili) di ogni atleta del gruppo.
  final Map<String, List<PersonalBest>> pbPerAtleta;

  /// Passo (s/100) per zona (A1/A2/B1) dal test di soglia più recente di
  /// ogni atleta, se esiste e ha le tabelle passi generate.
  final Map<String, Map<String, double>> passiSogliaPerAtleta;

  /// Atleti del gruppo senza un test di soglia valido: per A1/A2/B1 si
  /// ricade sul modello dai primati, segnalato in UI.
  final List<String> senzaTestSoglia;

  bool get divisoInDue => corsie.length > 1;

  /// 1 = corsia più veloce, 2 = più lenta; `null` se il gruppo non è
  /// diviso o l'atleta non ha un tempo di riferimento.
  int? numeroCorsia(String atletaId) {
    if (!divisoInDue) return null;
    for (var i = 0; i < corsie.length; i++) {
      if (corsie[i].atletiIds.contains(atletaId)) return i + 1;
    }
    return null;
  }
}

/// Media dei personal best sui 100 stile libero (e il differenziale di
/// gara T200-T100, dove disponibile) degli atleti indicati — vedi FASE 10
/// punto 4. Ignora chi non ha almeno il PB sui 100. Se lo scarto di passo
/// nel gruppo supera il 10% della media, divide in due corsie (1 = veloci,
/// 2 = lente) invece di restituirne una sola, ricordando chi sta dove.
AssegnazioneCorsie assegnaCorsie(
  List<Atleta> atleti,
  Map<String, List<PersonalBest>> pbPerAtleta,
) {
  final dati = <({String id, double passo100S, double? differenzialeS})>[];
  final senzaTempo = <String>[];
  for (final atleta in atleti) {
    double? tempo100;
    double? tempo200;
    for (final p in pbPerAtleta[atleta.id] ?? const <PersonalBest>[]) {
      if (p.stile != 'libero') continue;
      if (p.distanzaM == 100) tempo100 = p.tempoS;
      if (p.distanzaM == 200) tempo200 = p.tempoS;
    }
    if (tempo100 != null) {
      dati.add((
        id: atleta.id,
        passo100S: tempo100,
        differenzialeS: tempo200 != null ? tempo200 - tempo100 : null,
      ));
    } else {
      senzaTempo.add(atleta.id);
    }
  }
  if (dati.isEmpty) {
    return AssegnazioneCorsie(corsie: const [], senzaTempo: senzaTempo);
  }

  double media(Iterable<double> valori) =>
      valori.reduce((a, b) => a + b) / valori.length;
  double? mediaDifferenziali(
    Iterable<({String id, double passo100S, double? differenzialeS})> voci,
  ) {
    final valori = voci
        .map((v) => v.differenzialeS)
        .whereType<double>()
        .toList();
    return valori.isEmpty ? null : media(valori);
  }

  final passi = dati.map((d) => d.passo100S).toList();
  final passoMedio = media(passi);
  final scarto =
      passi.reduce((a, b) => a > b ? a : b) -
      passi.reduce((a, b) => a < b ? a : b);

  // Scarto oltre il 10% del passo medio: PB troppo eterogenei per un'unica
  // ripartenza, si dividono gli atleti in due corsie per passo.
  if (dati.length > 1 && scarto / passoMedio > 0.10) {
    final ordinati = [...dati]
      ..sort((a, b) => a.passo100S.compareTo(b.passo100S));
    final meta = (ordinati.length / 2).ceil();
    final veloci = ordinati.sublist(0, meta);
    final lenti = ordinati.sublist(meta);
    return AssegnazioneCorsie(
      corsie: [
        CorsiaGenerazione(
          nome: 'Corsia 1 (veloci)',
          passo100S: media(veloci.map((v) => v.passo100S)),
          differenzialeS: mediaDifferenziali(veloci),
          atletiIds: veloci.map((v) => v.id).toList(),
        ),
        CorsiaGenerazione(
          nome: 'Corsia 2 (lenti)',
          passo100S: media(lenti.map((v) => v.passo100S)),
          differenzialeS: mediaDifferenziali(lenti),
          atletiIds: lenti.map((v) => v.id).toList(),
        ),
      ],
      senzaTempo: senzaTempo,
    );
  }

  return AssegnazioneCorsie(
    corsie: [
      CorsiaGenerazione(
        nome: 'Gruppo',
        passo100S: passoMedio,
        differenzialeS: mediaDifferenziali(dati),
        atletiIds: dati.map((d) => d.id).toList(),
      ),
    ],
    senzaTempo: senzaTempo,
  );
}

/// Oltre questa attesa, un singolo atleta senza risposta (rete lenta o
/// bloccata) non deve far restare l'intera generazione "in caricamento"
/// all'infinito: si procede senza i suoi dati, come se non li avesse.
const _timeoutDatiAtleta = Duration(seconds: 8);

/// PB (tutti gli stili) e passi dal test di soglia più recente di un
/// atleta — letti in parallelo fra loro (non uno in attesa dell'altro),
/// con un timeout: una rete lenta rallenta, non blocca indefinitamente.
Future<({List<PersonalBest> pb, Map<String, double>? passiSoglia})> _datiAtleta(
  WidgetRef ref,
  String atletaId,
) async {
  try {
    final risultati = await Future.wait([
      ref.read(personalBestListProvider(atletaId).future),
      ref.read(testListProvider(atletaId).future),
    ]).timeout(_timeoutDatiAtleta);
    final pb = risultati[0] as List<PersonalBest>;
    final test = risultati[1] as List<TestIngresso>;
    final ultimo = test.isEmpty ? null : test.first;
    if (ultimo == null) return (pb: pb, passiSoglia: null);

    final tabelle = await ref
        .read(tabellePassiProvider(ultimo.id).future)
        .timeout(_timeoutDatiAtleta);
    if (tabelle.isEmpty) return (pb: pb, passiSoglia: null);
    return (
      pb: pb,
      passiSoglia: {for (final t in tabelle) t.zona: t.passo100S},
    );
  } on TimeoutException {
    return (pb: const <PersonalBest>[], passiSoglia: null);
  }
}

/// Come [assegnaCorsie], leggendo i PB di ogni atleta dal provider — più
/// i passi dal test di soglia più recente di ognuno, quando esiste e ha
/// le tabelle passi generate (FASE 3): servono a [ripartenzaPerSerie]
/// per le zone A1/A2/B1. Un atleta per volta sarebbe lento con gruppi
/// numerosi (due richieste di rete ciascuno): letti tutti in parallelo.
Future<AssegnazioneCorsie> calcolaAssegnazioneCorsie(
  WidgetRef ref,
  List<Atleta> atleti,
) async {
  final datiPerAtleta = await Future.wait([
    for (final atleta in atleti) _datiAtleta(ref, atleta.id),
  ]);

  final pb = <String, List<PersonalBest>>{};
  final passiSoglia = <String, Map<String, double>>{};
  final senzaTestSoglia = <String>[];
  for (var i = 0; i < atleti.length; i++) {
    final id = atleti[i].id;
    pb[id] = datiPerAtleta[i].pb;
    final passi = datiPerAtleta[i].passiSoglia;
    if (passi == null) {
      senzaTestSoglia.add(id);
    } else {
      passiSoglia[id] = passi;
    }
  }

  final base = assegnaCorsie(atleti, pb);
  return AssegnazioneCorsie(
    corsie: base.corsie,
    senzaTempo: base.senzaTempo,
    pbPerAtleta: pb,
    passiSogliaPerAtleta: passiSoglia,
    senzaTestSoglia: senzaTestSoglia,
  );
}

/// Media di [passiSogliaPerAtleta] per [zona] sugli atleti indicati che
/// hanno un test valido — `null` se nessuno di loro ne ha uno (si ricade
/// sul modello dai primati in [ripartenzaPerSerie]).
double? _passoSogliaMedioGruppo(
  String zona,
  List<String> atletiIds,
  Map<String, Map<String, double>> passiSogliaPerAtleta,
) {
  final valori = [
    for (final id in atletiIds)
      if (passiSogliaPerAtleta[id]?[zona] != null)
        passiSogliaPerAtleta[id]![zona]!,
  ];
  if (valori.isEmpty) return null;
  return valori.reduce((a, b) => a + b) / valori.length;
}

/// Primato (e differenziale T200-T100, se c'è) di un atleta nello
/// [stile] indicato — ricade sul libero se non ce l'ha in quello stile
/// (FASE 3, richiesta del coach: "il primato nello stesso stile della
/// serie se l'atleta ce l'ha, altrimenti sul libero").
({double? passo100S, double? differenzialeS, double? tempo200S}) _pbPerStile(
  List<PersonalBest> pb,
  String stile,
) {
  double? cerca(String s, int distanza) => pbDelloSlot(pb, s, distanza)?.tempoS;
  final passo100 = cerca(stile, 100) ?? cerca('libero', 100);
  final stileUsato = cerca(stile, 100) != null ? stile : 'libero';
  final passo200 = cerca(stileUsato, 200);
  return (
    passo100S: passo100,
    differenzialeS: (passo200 != null && passo100 != null)
        ? passo200 - passo100
        : null,
    tempo200S: passo200,
  );
}

/// Ripartenza (e passo) per una serie generata, nella sua zona e stile
/// reali, per il gruppo di atleti [atletiIds] — FASE 3: le zone A1/A2/B1
/// usano il passo del test di soglia quando disponibile (media del
/// gruppo), le altre il modello dai primati **nello stile della serie**
/// invece che sempre in stile libero. Se non c'è nulla (né test né PB
/// nello stile o nel libero), torna `(null, null)`: si ricade su quanto
/// proposto dall'AI, mai un buco silenzioso.
({double? passoS, double? ripartenzaS}) ripartenzaPerSerie({
  required String zona,
  required String stile,
  required int distanzaM,
  required List<String> atletiIds,
  required AssegnazioneCorsie assegnazione,
}) {
  if (zona == 'A1' || zona == 'A2' || zona == 'B1') {
    final passoSoglia = _passoSogliaMedioGruppo(
      zona,
      atletiIds,
      assegnazione.passiSogliaPerAtleta,
    );
    if (passoSoglia != null) {
      return calcolo.ripartenzaEPasso(
        zona: zona,
        passo100S: null,
        differenzialeS: null,
        distanzaM: distanzaM,
        passoBaseOverride: passoSoglia,
      );
    }
  }

  // Nessun test di soglia (o zona B2+): modello dai primati, nello
  // stile della serie quando disponibile.
  final datiPerAtleta = [
    for (final id in atletiIds)
      _pbPerStile(assegnazione.pbPerAtleta[id] ?? const [], stile),
  ].where((d) => d.passo100S != null).toList();
  if (datiPerAtleta.isEmpty) {
    // Nessun PB nello stile né nel libero per questo gruppo: userà il
    // valore (eventualmente libero) già in CorsiaGenerazione, se c'è.
    return (passoS: null, ripartenzaS: null);
  }
  double media(Iterable<double> v) => v.reduce((a, b) => a + b) / v.length;
  final passo100S = media(datiPerAtleta.map((d) => d.passo100S!));
  final differenziali = datiPerAtleta
      .map((d) => d.differenzialeS)
      .whereType<double>()
      .toList();
  final tempi200 = datiPerAtleta
      .map((d) => d.tempo200S)
      .whereType<double>()
      .toList();
  return calcolo.ripartenzaEPasso(
    zona: zona,
    passo100S: passo100S,
    differenzialeS: differenziali.isEmpty ? null : media(differenziali),
    tempo200S: tempi200.isEmpty ? null : media(tempi200),
    distanzaM: distanzaM,
  );
}

Future<List<CorsiaGenerazione>> calcolaCorsie(
  WidgetRef ref,
  List<Atleta> atleti,
) async => (await calcolaAssegnazioneCorsie(ref, atleti)).corsie;

/// Es. "Veloci: rip 1:25 · Lenti: rip 1:40" — stringa vuota se non ci
/// sono ripartenze per corsia (niente passi di riferimento, o zona a
/// bassa intensità che non ne prevede una).
String formattaRipartenzeCorsia(List<RipartenzaCorsia> ripartenzePerCorsia) {
  if (ripartenzePerCorsia.isEmpty) return '';
  return ripartenzePerCorsia
      .map((r) => '${r.nome}: rip ${formatPaceSeconds(r.ripartenzaS)}')
      .join(' · ');
}

/// Ripartenza e nota da salvare su una `Serie` a partire da una
/// `SerieGenerata`: con più corsie si tiene come riferimento la più
/// veloce (ripartenza più stretta), il dettaglio di tutte resta in nota
/// perché il campo ripartenza della serie ne ammette una sola.
({double? ripartenzaS, String? note}) risolviRipartenza(
  List<RipartenzaCorsia> ripartenzePerCorsia,
  String? notaBase,
) {
  if (ripartenzePerCorsia.isEmpty) {
    return (ripartenzaS: null, note: notaBase);
  }
  final ripartenzaS = ripartenzePerCorsia
      .map((r) => r.ripartenzaS)
      .reduce((a, b) => a < b ? a : b);
  final dettaglio = formattaRipartenzeCorsia(ripartenzePerCorsia);
  final note = notaBase == null || notaBase.isEmpty
      ? dettaglio
      : '$notaBase — $dettaglio';
  return (ripartenzaS: ripartenzaS, note: note);
}
