import '../utils/date_italiane.dart';

/// La versione dell'app: il giorno della build e il commit, scritti da
/// Vercel quando la costruisce (`--dart-define` in `vercel-build.sh`). In
/// locale e nei test non ci sono: è la versione "di sviluppo".
class VersioneApp {
  const VersioneApp({required this.commit, required this.data});

  /// Le prime 7 lettere del commit; vuoto in sviluppo.
  final String commit;

  /// Il giorno della build; null in sviluppo.
  final DateTime? data;

  static final corrente = VersioneApp(
    commit: const String.fromEnvironment('VERSIONE_COMMIT'),
    data: DateTime.tryParse(const String.fromEnvironment('VERSIONE_DATA')),
  );

  bool get diSviluppo => data == null;

  /// "Versione del 19 ottobre 2026 (a6ab096)", "Versione di sviluppo".
  String get etichetta {
    final giorno = data;
    if (giorno == null) return 'Versione di sviluppo';
    final codice = commit.isEmpty ? '' : ' ($commit)';
    return 'Versione del ${dataLunga(giorno)}$codice';
  }

  /// Per le segnalazioni: "2026-10-19 a6ab096", "sviluppo".
  String get compatta {
    final giorno = data;
    if (giorno == null) return commit.isEmpty ? 'sviluppo' : commit;
    final g =
        '${giorno.year}-${giorno.month.toString().padLeft(2, '0')}-'
        '${giorno.day.toString().padLeft(2, '0')}';
    return commit.isEmpty ? g : '$g $commit';
  }
}
