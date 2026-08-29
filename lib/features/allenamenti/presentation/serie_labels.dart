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
  _ => esecuzione,
};

String labelBlocco(String blocco) => switch (blocco) {
  'riscaldamento' => 'Riscaldamento',
  'principale' => 'Principale',
  'defaticamento' => 'Defaticamento',
  'altro' => 'Altro',
  _ => blocco,
};
