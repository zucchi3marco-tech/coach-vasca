import 'parametri_generazione.dart';

/// Campi del form "Genera settimana con AI" che l'AI ha ricavato dal
/// testo libero del coach. Come [ModuloCompilato]: tutto opzionale, si
/// applica solo ciò che il testo diceva davvero.
class ModuloSettimanaCompilato {
  const ModuloSettimanaCompilato({
    this.volumeSettimanaleMetri,
    this.volumeLavoroCentraleSettimanaleMetri,
    this.minutiMax,
    this.vascaM,
    this.tipoSettimana,
    this.giorni = const [],
    this.focusPerGiorno = const {},
    this.focusComune = const [],
    this.braccia,
    this.gambe,
    this.stileTecnica,
    this.attrezzaturaLavoroCentrale = const [],
    this.vincoli,
  });

  final int? volumeSettimanaleMetri;
  final int? volumeLavoroCentraleSettimanaleMetri;
  final int? minutiMax;
  final int? vascaM;
  final String? tipoSettimana;

  /// Giorni della settimana nominati, 1 = lunedì ... 7 = domenica.
  final List<int> giorni;

  /// Focus di giorni specifici (chiave 1-7).
  final Map<int, List<String>> focusPerGiorno;

  /// Focus valido per tutte le sedute senza uno specifico.
  final List<String> focusComune;

  final DettaglioFocus? braccia;
  final DettaglioFocus? gambe;
  final String? stileTecnica;
  final List<String> attrezzaturaLavoroCentrale;
  final String? vincoli;

  bool get vuoto =>
      volumeSettimanaleMetri == null &&
      volumeLavoroCentraleSettimanaleMetri == null &&
      minutiMax == null &&
      vascaM == null &&
      tipoSettimana == null &&
      giorni.isEmpty &&
      focusPerGiorno.isEmpty &&
      focusComune.isEmpty &&
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

  factory ModuloSettimanaCompilato.fromMap(Map<String, dynamic> m) {
    final giorni = <int>{
      for (final g in (m['giorni'] is List ? m['giorni'] as List : const []))
        if (g is num && g >= 1 && g <= 7) g.round(),
    }.toList()..sort();
    final focusPerGiorno = <int, List<String>>{};
    final voci = m['focusPerGiorno'];
    if (voci is List) {
      for (final v in voci) {
        if (v is! Map) continue;
        final giorno = _intero(v['giorno']);
        final focus = _lista(v['focus']);
        if (giorno != null && giorno >= 1 && giorno <= 7 && focus.isNotEmpty) {
          focusPerGiorno[giorno] = focus;
        }
      }
    }
    return ModuloSettimanaCompilato(
      volumeSettimanaleMetri: _intero(m['volumeSettimanaleMetri']),
      volumeLavoroCentraleSettimanaleMetri: _intero(
        m['volumeLavoroCentraleSettimanaleMetri'],
      ),
      minutiMax: _intero(m['minutiMax']),
      vascaM: _intero(m['vascaM']),
      tipoSettimana: _testo(m['tipoSettimana']),
      giorni: giorni,
      focusPerGiorno: focusPerGiorno,
      focusComune: _lista(m['focusComune']),
      braccia: _dettaglio(m, 'Braccia'),
      gambe: _dettaglio(m, 'Gambe'),
      stileTecnica: _testo(m['stileTecnica']),
      attrezzaturaLavoroCentrale: _lista(m['attrezziLavoroCentrale']),
      vincoli: _testo(m['vincoli']),
    );
  }
}
