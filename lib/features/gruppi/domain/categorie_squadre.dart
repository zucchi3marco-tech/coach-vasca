/// Le categorie che un club propone come squadre già pronte, per sport.
const categorieNuoto = [
  'Es.C',
  'Es.B',
  'Es.A',
  'Ragazzi',
  'Juniores',
  'Cadetti',
  'Assoluti',
  'Amatori',
];

const categoriePallanuoto = [
  'U10',
  'U11',
  'U12',
  'U13',
  'U14',
  'U15',
  'U16',
  'U17',
  'U18',
  'U20',
  'Prima squadra',
];

/// Le categorie dello sport del club ('nuoto' | 'pallanuoto'); nessuna se lo
/// sport non c'è (o se il club fa entrambi).
List<String> categoriePerSport(String? sport) => switch (sport) {
  'nuoto' => categorieNuoto,
  'pallanuoto' => categoriePallanuoto,
  _ => const [],
};
