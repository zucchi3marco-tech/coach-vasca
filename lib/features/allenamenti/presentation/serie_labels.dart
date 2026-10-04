import '../../../core/utils/pace_format.dart';
import '../domain/serie.dart';

/// "8×100m" per una serie a distanza, "3×5'" per una a tempo — mai
/// entrambe (vedi [Serie.aTempo]).
String labelVolumeSerie(Serie s) {
  final durata = s.durataS;
  if (durata != null) return '${s.ripetute}×${formatDurataS(durata)}';
  return '${s.ripetute}×${s.distanzaM}m';
}

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
  'pallanuoto tecnico-tattico' => 'Tecnico-tattico',
  'a secco' => 'A secco',
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

/// Etichetta breve per spazi stretti (elenco serie su smartphone).
String labelBloccoBreve(String blocco) => switch (blocco) {
  'riscaldamento' => 'Risc.',
  'principale' => 'Princ.',
  'defaticamento' => 'Defat.',
  'altro' => 'Altro',
  _ => blocco,
};
