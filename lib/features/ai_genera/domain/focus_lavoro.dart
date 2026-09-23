import 'parametri_generazione.dart';

/// Quale parte del corpo/nuotata enfatizzare in una seduta generata
/// (non l'energia: quella vive in "tipo di lavoro" — vedi
/// `tipo_lavoro.dart`). Stesso vocabolario nel generatore singolo e in
/// quello della settimana.
const focusLavoro = ['completo', 'braccia', 'gambe', 'tecnica'];

String etichettaFocusLavoro(String f) => switch (f) {
  'completo' => 'Completo',
  'braccia' => 'Braccia',
  'gambe' => 'Gambe',
  'tecnica' => 'Tecnica',
  _ => f.isEmpty ? f : f[0].toUpperCase() + f.substring(1),
};

/// I dettagli di braccia/gambe della settimana (metri per seduta,
/// attrezzi, stile) adattati a UNA seduta: presenti solo se il focus di
/// quella seduta li include, con i metri limitati al volume della seduta
/// e, se braccia e gambe insieme lo superano, ridotti in proporzione.
({DettaglioFocus? braccia, DettaglioFocus? gambe}) dettagliFocusPerSeduta({
  required List<String> focus,
  required int volumeSeduta,
  DettaglioFocus? braccia,
  DettaglioFocus? gambe,
}) {
  var b = focus.contains('braccia') ? braccia : null;
  var g = focus.contains('gambe') ? gambe : null;
  final mb = b?.metri ?? 0;
  final mg = g?.metri ?? 0;
  final somma = mb + mg;
  final fattore = somma > volumeSeduta ? volumeSeduta / somma : 1.0;
  DettaglioFocus? scala(DettaglioFocus? d) => d == null || d.metri == null
      ? d
      : DettaglioFocus(
          metri: (d.metri! * fattore).round(),
          attrezzatura: d.attrezzatura,
          stile: d.stile,
        );
  b = scala(b);
  g = scala(g);
  return (braccia: b, gambe: g);
}
