class Stagione {
  const Stagione({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.dataInizio,
    required this.dataFine,
    this.obiettivo,
    this.gruppoId,
    this.campionato,
  });

  final String id;
  final String clubId;
  final String nome;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String? obiettivo;
  final String? gruppoId;

  /// Campionato disputato in questa stagione: le partite create con una
  /// data compresa fra [dataInizio] e [dataFine] lo ereditano
  /// automaticamente, non si sceglie più partita per partita.
  final String? campionato;
}

/// Etichetta della "categoria" di una stagione di club (senza gruppo).
const etichettaTuttiGliAtleti = 'Tutti gli atleti';

String _giornoMeseAnno(DateTime d) =>
    '${d.day}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Titolo automatico di una stagione, es. "Campionato U14 -
/// 1/09/2026-30/06/2027": parola fissa "Campionato", la categoria (il
/// nome del gruppo, oppure [etichettaTuttiGliAtleti]) e le date.
String titoloStagione({
  required String? categoria,
  required DateTime dataInizio,
  required DateTime dataFine,
}) {
  final cat = (categoria == null || categoria.trim().isEmpty)
      ? ''
      : ' ${categoria.trim()}';
  return 'Campionato$cat - ${_giornoMeseAnno(dataInizio)}-'
      '${_giornoMeseAnno(dataFine)}';
}

/// La stagione che contiene la data odierna: preferisce quelle del gruppo
/// indicato, altrimenti quelle di club (senza gruppo) — mai quelle di un
/// altro gruppo. [gruppoId] null = nessun gruppo: solo le stagioni di
/// club. Usata per la "stagione in corso" (home dell'atleta, tab Partite).
/// Torna null se nessuna stagione visibile contiene oggi.
Stagione? stagioneCorrenteDiGruppo(
  List<Stagione> stagioni,
  String? gruppoId, {
  DateTime? oggi,
}) {
  final data = oggi ?? DateTime.now();
  bool inCorso(Stagione s) =>
      !data.isBefore(s.dataInizio) && !data.isAfter(s.dataFine);
  final delGruppo = gruppoId == null
      ? const <Stagione>[]
      : stagioni.where((s) => s.gruppoId == gruppoId && inCorso(s));
  if (delGruppo.isNotEmpty) return delGruppo.first;
  for (final s in stagioni) {
    if (s.gruppoId == null && inCorso(s)) return s;
  }
  return null;
}
