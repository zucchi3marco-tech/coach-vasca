/// Vocabolario condiviso fra la lista eventi partita e le nuove schermate
/// di registrazione (campo disegnato): un solo posto per le etichette,
/// cosi' restano identiche ovunque compaiano.
const esitiTiroSemplice = [('gol', 'Gol'), ('non_gol', 'Non gol')];
const esitiTiroDettagliato = [
  ('gol', 'Gol'),
  ('parato', 'Parato'),
  ('palo_fuori', 'Palo/fuori'),
];
const esitiSuperiorita = [('gol', 'Gol'), ('non_gol', 'Non gol')];
const contestiTiro = [
  ('azione', 'Azione'),
  ('superiorita', 'Superiorità'),
  ('rigore', 'Rigore'),
];

String etichettaContesto(String contesto) {
  switch (contesto) {
    case 'superiorita':
      return 'superiorità';
    case 'rigore':
      return 'rigore';
    default:
      return '';
  }
}

String etichettaEsito(String? esito) {
  switch (esito) {
    case 'gol':
      return 'Gol';
    case 'non_gol':
      return 'Non gol';
    case 'parato':
      return 'Parato';
    case 'palo_fuori':
      return 'Palo/fuori';
    default:
      return 'In corso';
  }
}
