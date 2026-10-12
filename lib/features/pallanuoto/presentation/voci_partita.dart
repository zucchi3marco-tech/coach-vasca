import '../domain/statistiche_eventi.dart';

/// "3/7 (43%)", "—" se non c'è niente su cui contare.
String conPercentuale(int fatti, int su) =>
    su == 0 ? '—' : '${rapporto(fatti, su)} (${percentuale(fatti, su)})';

/// Una riga del confronto fra due partite: cosa si confronta e come si
/// scrive il valore. [completa]: si segna solo in modalità completa, la
/// riga c'è solo se una delle due partite ha quei dati.
class VocePartita {
  const VocePartita(this.etichetta, this.valore, {this.completa = false});

  final String etichetta;
  final String Function(NumeriEventi n) valore;
  final bool completa;
}

final vociPartita = <VocePartita>[
  VocePartita('Risultato', (n) => '${n.gol}–${n.golSubiti}'),
  VocePartita('Gol su tiri', (n) => conPercentuale(n.gol, n.tiri)),
  VocePartita(
    'Gol subiti su tiri',
    (n) => conPercentuale(n.golSubiti, n.tiriSubiti),
  ),
  VocePartita(
    'Superiorità',
    (n) => conPercentuale(n.golInSuperiorita, n.superiorita),
  ),
  VocePartita(
    'Inferiorità (gol subiti)',
    (n) => conPercentuale(n.golSubitiInInferiorita, n.inferiorita),
  ),
  VocePartita('Rigori segnati', (n) => rapporto(n.golRigore, n.rigoriTirati)),
  VocePartita('Espulsioni subite', (n) => '${n.espulsioni}'),
  VocePartita('Assist', (n) => '${n.assist}', completa: true),
  VocePartita('Gol in controfuga', (n) => '${n.golControfuga}', completa: true),
  VocePartita(
    'Gol subiti in controfuga',
    (n) => '${n.golSubitiControfuga}',
    completa: true,
  ),
  VocePartita('Palle perse', (n) => '${n.pallePerse}', completa: true),
  VocePartita(
    'Palle recuperate',
    (n) => '${n.palleRecuperate}',
    completa: true,
  ),
  VocePartita(
    'Espulsioni guadagnate',
    (n) => '${n.espulsioniGuadagnate}',
    completa: true,
  ),
  VocePartita(
    'Rigori guadagnati',
    (n) => '${n.rigoriGuadagnati}',
    completa: true,
  ),
];

/// I numeri di un giocatore in una riga: solo quelli che ci sono, così
/// una partita essenziale non si riempie di zeri.
List<String> metricheGiocatore(NumeriEventi n) => [
  'Gol ${rapporto(n.gol, n.tiri)}'
      '${n.tiri > 0 ? ' (${percentuale(n.gol, n.tiri)})' : ''}',
  if (n.espulsioni > 0)
    n.espulsioni == 1 ? '1 espulsione' : '${n.espulsioni} espulsioni',
  if (n.golControfuga > 0) 'controfuga ${n.golControfuga}',
  ...metricheComplete(n),
];

/// I numeri che si segnano solo in modalità completa, quelli che ci sono.
List<String> metricheComplete(NumeriEventi n) => [
  if (n.assist > 0) n.assist == 1 ? '1 assist' : '${n.assist} assist',
  if (n.pallePerse > 0) 'perse ${n.pallePerse}',
  if (n.palleRecuperate > 0) 'recuperate ${n.palleRecuperate}',
  if (n.espulsioniGuadagnate > 0)
    'espulsioni guadagnate ${n.espulsioniGuadagnate}',
  if (n.rigoriGuadagnati > 0) 'rigori guadagnati ${n.rigoriGuadagnati}',
];
