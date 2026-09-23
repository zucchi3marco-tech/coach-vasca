import 'parametri_generazione.dart';

/// Campi del form "Genera con AI" che l'AI ha ricavato dal testo libero
/// del coach ("Scrivi il tuo allenamento"). Tutto è opzionale: si
/// applicano al form solo i campi che il testo menzionava davvero, il
/// resto resta com'era.
class ModuloCompilato {
  const ModuloCompilato({
    this.vascaM,
    this.minutiMax,
    this.volumeMetri,
    this.volumeLavoroCentraleMetri,
    this.tipiLavoro = const [],
    this.focus = const [],
    this.braccia,
    this.gambe,
    this.stileTecnica,
    this.attrezzaturaLavoroCentrale = const [],
    this.vincoli,
  });

  final int? vascaM;
  final int? minutiMax;
  final int? volumeMetri;
  final int? volumeLavoroCentraleMetri;
  final List<String> tipiLavoro;
  final List<String> focus;
  final DettaglioFocus? braccia;
  final DettaglioFocus? gambe;
  final String? stileTecnica;
  final List<String> attrezzaturaLavoroCentrale;
  final String? vincoli;

  /// `true` se dal testo non è uscito nessun campo utile.
  bool get vuoto =>
      vascaM == null &&
      minutiMax == null &&
      volumeMetri == null &&
      volumeLavoroCentraleMetri == null &&
      tipiLavoro.isEmpty &&
      focus.isEmpty &&
      braccia == null &&
      gambe == null &&
      stileTecnica == null &&
      attrezzaturaLavoroCentrale.isEmpty &&
      (vincoli == null || vincoli!.isEmpty);

  static List<String> _lista(Object? v) =>
      v is List ? v.whereType<String>().toList() : const [];

  static int? _intero(Object? v) => v is num ? v.round() : null;

  static String? _testo(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static DettaglioFocus? _dettaglio(Map<String, dynamic> m, String suffisso) {
    final metri = _intero(m['metri$suffisso']);
    final attrezzi = _lista(m['attrezzi$suffisso']);
    final stile = _testo(m['stile$suffisso']);
    if (metri == null && attrezzi.isEmpty && stile == null) return null;
    return DettaglioFocus(metri: metri, attrezzatura: attrezzi, stile: stile);
  }

  factory ModuloCompilato.fromMap(Map<String, dynamic> m) {
    return ModuloCompilato(
      vascaM: _intero(m['vascaM']),
      minutiMax: _intero(m['minutiMax']),
      volumeMetri: _intero(m['volumeMetri']),
      volumeLavoroCentraleMetri: _intero(m['volumeLavoroCentraleMetri']),
      tipiLavoro: _lista(m['tipiLavoro']),
      focus: _lista(m['focus']),
      braccia: _dettaglio(m, 'Braccia'),
      gambe: _dettaglio(m, 'Gambe'),
      stileTecnica: _testo(m['stileTecnica']),
      attrezzaturaLavoroCentrale: _lista(m['attrezziLavoroCentrale']),
      vincoli: _testo(m['vincoli']),
    );
  }
}
