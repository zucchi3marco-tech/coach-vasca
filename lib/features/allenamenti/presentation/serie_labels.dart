import '../../../core/utils/pace_format.dart';
import '../domain/serie.dart';
import '../domain/testo_allenamento.dart';

/// "8×100m" per una serie a distanza, "3×5'" per una a tempo — mai
/// entrambe (vedi [Serie.aTempo]).
String labelVolumeSerie(DatiSerie s) {
  final durata = s.durataS;
  if (durata != null) return '${s.ripetute}×${formatDurataS(durata)}';
  return '${s.ripetute}×${s.distanzaM}m';
}

/// "8×100m Libero", "4×50m Dorso Gambe", "4×5' Uomo in più".
String titoloSerie(DatiSerie s) => [
  labelVolumeSerie(s),
  ?labelStileSerie(s),
  if (s.esecuzione != 'nuoto') labelEsecuzione(s.esecuzione),
].join(' ');

/// "8×100m Libero Nuoto", "3×5' Uomo in più": il titolo di una serie
/// proposta dal generatore, con l'esecuzione sempre scritta.
String titoloSerieProposta(DatiSerie s) => [
  labelVolumeSerie(s),
  ?labelStileSerie(s),
  labelEsecuzione(s.esecuzione),
].join(' ');

/// Lo stile della serie, se conta: nel lavoro di pallanuoto e a secco
/// "libero" è solo il valore di partenza ([esecuzioniSenzaStile]).
String? labelStileSerie(DatiSerie s) =>
    s.stile == 'libero' && esecuzioniSenzaStile.contains(s.esecuzione)
    ? null
    : labelStile(s.stile);

/// Il titolo di più serie raggruppate: "50-100-200m Libero" o
/// "2×(50-100)m Libero" per una piramide, "2 × (3×200m Libero + 4×75m
/// Dorso)" per un "2x" scritto a testo.
String titoloGruppo(List<DatiSerie> gruppo) {
  final primo = gruppo.first;
  final piramide = strutturaPiramide(gruppo);
  if (piramide != null) {
    final sequenza = gruppo
        .take(piramide.distanze)
        .map((s) => s.distanzaM)
        .join('-');
    return [
      if (piramide.giri > 1)
        '${piramide.giri}×($sequenza)m'
      else
        '${sequenza}m',
      ?labelStileSerie(primo),
      if (primo.esecuzione != 'nuoto') labelEsecuzione(primo.esecuzione),
    ].join(' ');
  }
  final periodo = periodoGruppo(gruppo);
  final volte = gruppo.length ~/ periodo;
  final corpo = gruppo.take(periodo).map(titoloSerie).join(' + ');
  if (volte == 1) return corpo;
  return periodo > 1 ? '$volte × ($corpo)' : '$volte × $corpo';
}

/// Zona, passo, ripartenza, recupero e attrezzi di una serie.
List<String> dettagliSerie(DatiSerie s) => [
  ?s.zona,
  if (s.passoObiettivoS case final p?) '${formatTempoCompatto(p)}/100m',
  if (s.ripartenzaS case final r?) 'rip ${formatTempoCompatto(r)}',
  if (s.recuperoS case final r?) "rec $r''",
  if (s.attrezzatura case final a? when a.trim().isNotEmpty) a,
];

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
  'test' => 'Test',
  'pallanuoto tecnico-tattico' => 'Tecnico-tattico',
  'palleggio' => 'Palleggio',
  'tiri' => 'Tiri',
  'uomo in più' => 'Uomo in più',
  'uomo in meno' => 'Uomo in meno',
  'gioco da schierati' => 'Gioco da schierati',
  'schemi' => 'Schemi',
  'partita' => 'Partita',
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
