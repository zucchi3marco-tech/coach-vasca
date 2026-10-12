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

/// Il valore dell'esito "gol in controfuga" nei bottoni dell'esito (in
/// modalità completa): si salva come esito gol con contesto controfuga.
const golInControfuga = 'gol_controfuga';

/// Gli esiti di un tiro in modalità completa: lo stesso elenco con, dopo
/// il gol, il gol in controfuga — un tocco solo, senza un passo in più.
List<(String, String)> conControfuga(List<(String, String)> esiti) => [
  for (final esito in esiti) ...[
    esito,
    if (esito.$1 == 'gol') (golInControfuga, 'Gol in controfuga'),
  ],
];

String etichettaContesto(String contesto) {
  switch (contesto) {
    case 'superiorita':
      return 'superiorità';
    case 'rigore':
      return 'rigore';
    case 'controfuga':
      return 'controfuga';
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
