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
