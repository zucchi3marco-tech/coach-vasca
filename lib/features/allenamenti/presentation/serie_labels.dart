String labelStile(String stile) => switch (stile) {
  'libero' => 'Libero',
  'dorso' => 'Dorso',
  'rana' => 'Rana',
  'delfino' => 'Delfino',
  'misti' => 'Misti',
  _ => stile,
};

String labelEsecuzione(String esecuzione) => switch (esecuzione) {
  'nuoto' => 'Nuoto',
  'gambe' => 'Gambe',
  'braccia' => 'Braccia',
  'pull' => 'Pull',
  'tecnica' => 'Tecnica',
  'remate' => 'Remate',
  _ => esecuzione,
};

/// Ordine canonico dei blocchi, per riepiloghi/totali per blocco (le serie
/// stesse restano ordinate per `ordine`, non raggruppate per blocco).
const ordineBlocchi = ['riscaldamento', 'principale', 'defaticamento', 'altro'];

String labelBlocco(String blocco) => switch (blocco) {
  'riscaldamento' => 'Riscaldamento',
  'principale' => 'Principale',
  'defaticamento' => 'Defaticamento',
  'altro' => 'Altro',
  _ => blocco,
};
