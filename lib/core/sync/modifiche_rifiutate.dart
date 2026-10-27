import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Una modifica in coda che il server ha rifiutato (un permesso, un
/// vincolo, dati non validi): ritentarla non servirebbe, e la sincronizzazione
/// la scarta. Prima spariva senza avviso; ora la spia nella barra la mostra
/// (scelta del coach, proposta 28).
///
/// Si tiene solo che tipo di modifica era e la risposta del server, mai i
/// dati: la riga poteva avere nomi e dati degli atleti.
class ModificaRifiutata {
  const ModificaRifiutata({
    required this.tabella,
    required this.operazione,
    required this.quando,
    this.codice,
    this.messaggio,
  });

  factory ModificaRifiutata.daErrore({
    required String tabella,
    required String operazione,
    required Object errore,
    DateTime? quando,
  }) {
    final (codice, messaggio) = switch (errore) {
      // Il messaggio di Postgres dice quale regola, senza i valori; i
      // dettagli ("Failing row contains ...") possono avere i dati e non si
      // tengono.
      PostgrestException(:final code, :final message) => (code, message),
      _ => (null, errore.runtimeType.toString()),
    };
    return ModificaRifiutata(
      tabella: tabella,
      operazione: operazione,
      quando: quando ?? DateTime.now(),
      codice: codice,
      messaggio: messaggio,
    );
  }

  /// Una modifica fatta senza rete che, quando la rete è tornata, ha
  /// trovato la riga già cambiata da qualcun altro ([tolta]: già tolta):
  /// non si manda, resta la versione del collega (scelta del coach).
  factory ModificaRifiutata.conflitto({
    required String tabella,
    required String operazione,
    bool tolta = false,
    DateTime? quando,
  }) => ModificaRifiutata(
    tabella: tabella,
    operazione: operazione,
    quando: quando ?? DateTime.now(),
    codice: tolta ? codiceTolta : codiceConflitto,
  );

  static const codiceConflitto = 'conflitto';
  static const codiceTolta = 'tolta';

  factory ModificaRifiutata.daMappa(Map<String, dynamic> m) =>
      ModificaRifiutata(
        tabella: m['tabella'] as String,
        operazione: m['operazione'] as String,
        quando: DateTime.parse(m['quando'] as String),
        codice: m['codice'] as String?,
        messaggio: m['messaggio'] as String?,
      );

  /// La tabella del database (es. "presenze").
  final String tabella;

  /// "insert", "update", "upsert" o "delete".
  final String operazione;
  final DateTime quando;

  /// Il codice dell'errore di Postgres (es. "42501").
  final String? codice;
  final String? messaggio;

  Map<String, dynamic> aMappa() => {
    'tabella': tabella,
    'operazione': operazione,
    'quando': quando.toIso8601String(),
    'codice': ?codice,
    'messaggio': ?messaggio,
  };

  /// "Presenze", "Benessere"...: cosa si stava salvando.
  String get cosa => _nomiTabelle[tabella] ?? _nomeDaTabella(tabella);

  /// "nuova", "modifica", "eliminazione".
  String get tipo => switch (operazione) {
    'insert' => 'nuova',
    'delete' => 'eliminazione',
    _ => 'modifica',
  };

  /// Perché il server l'ha rifiutata, a parole.
  String get perche => switch (codice) {
    codiceConflitto =>
      'Mentre eri senza rete un collega (o un altro telefono) l\'ha '
          'cambiata: è rimasta la sua versione. Guardala e, se serve, '
          'rifai la tua modifica.',
    codiceTolta =>
      'Mentre eri senza rete un collega (o un altro telefono) l\'ha tolta.',
    '42501' => 'Permesso negato: questo account non può farlo.',
    '23505' => 'C\'era già: un\'altra modifica è arrivata prima.',
    '23503' => 'Era collegata a qualcosa che non c\'è più.',
    '23502' ||
    '23514' ||
    '22P02' ||
    '22007' ||
    '22008' => 'Il server ha trovato dati non validi.',
    'PGRST204' ||
    'PGRST205' ||
    '42703' ||
    '42P01' => 'L\'app sul telefono è più vecchia del server: aggiornala.',
    _ => 'Il server non l\'ha accettata.',
  };
}

const _nomiTabelle = {
  'allenamenti': 'Allenamento',
  'atleti': 'Atleta',
  'distinta_giocatori': 'Distinta della partita',
  'esercizi_seduta': 'Esercizio della seduta',
  'esercizi_secco': 'Esercizio del secco',
  'eventi_partita': 'Evento della partita',
  'gara_iscritti': 'Iscritti alla gara',
  'gare': 'Gara',
  'generazioni_ai': 'Allenamento generato',
  'gruppi': 'Squadra',
  'impegni': 'Impegno',
  'note_video': 'Nota sul video',
  'partite': 'Partita',
  'personal_best': 'Tempo migliore',
  'presenze': 'Presenze',
  'programmi_secco': 'Programma del secco',
  'referti_partita': 'Referto della partita',
  'rinumera_distinta': 'Numeri della distinta',
  'rpe_sedute': 'Fatica della seduta',
  'scegli_capitani': 'Capitano e vice',
  'schede_benessere': 'Benessere',
  'schemi_tattici': 'Schema tattico',
  'serie': 'Serie dell\'allenamento',
  'serie_secco_fatte': 'Serie del secco',
  'stagioni': 'Stagione',
  'tabelle_passi': 'Tabella dei passi',
  'tempi_gara': 'Tempo di gara',
  'test_club': 'Test',
  'test_ingresso': 'Test d\'ingresso',
  'test_risultati': 'Risultato di un test',
  'training_block_parti': 'Parte di un blocco',
  'training_blocks': 'Blocco di allenamento',
  'video_partite': 'Video della partita',
};

/// "righe_programma" → "Righe programma".
String _nomeDaTabella(String tabella) {
  final parole = tabella.replaceAll('_', ' ');
  if (parole.isEmpty) return tabella;
  return parole[0].toUpperCase() + parole.substring(1);
}

const _chiave = 'modifiche_rifiutate';
const _massimo = 20;

/// Le modifiche rifiutate dal server, dalla più recente, salvate sul
/// telefono finché chi usa l'app non tocca «Ho capito».
final modificheRifiutateProvider =
    NotifierProvider<ModificheRifiutate, List<ModificaRifiutata>>(
      ModificheRifiutate.new,
    );

class ModificheRifiutate extends Notifier<List<ModificaRifiutata>> {
  late Future<void> _lettura;

  @override
  List<ModificaRifiutata> build() {
    _lettura = _leggi();
    return const [];
  }

  Future<void> _leggi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvate = prefs.getString(_chiave);
      if (salvate == null) return;
      state = [
        for (final m in jsonDecode(salvate) as List)
          ModificaRifiutata.daMappa((m as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      // Una copia illeggibile non deve fermare l'app.
    }
  }

  Future<void> _salva() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chiave,
        jsonEncode([for (final m in state) m.aMappa()]),
      );
    } catch (_) {}
  }

  Future<void> aggiungi(ModificaRifiutata modifica) async {
    // Prima la copia salvata, così non si perde e non si raddoppia.
    await _lettura;
    state = [modifica, ...state].take(_massimo).toList();
    await _salva();
  }

  /// «Ho capito»: l'elenco si svuota.
  Future<void> svuota() async {
    await _lettura;
    state = const [];
    await _salva();
  }
}
