import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/statistiche_eventi.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/eventi_labels.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/voci_partita.dart';
import 'package:flutter_test/flutter_test.dart';

var _n = 0;

EventoPartita _e(
  String tipo, {
  String partita = 'p1',
  String squadra = 'nostra',
  String? atleta,
  String? esito,
  String contesto = 'azione',
  bool daRigore = false,
  int? numero,
  String? assist,
  String? guadagnata,
}) => EventoPartita(
  id: 'e${_n++}',
  partitaId: partita,
  clubId: 'c1',
  tipo: tipo,
  squadra: squadra,
  atletaId: atleta,
  esito: esito,
  contestoTiro: contesto,
  espulsioneDaRigore: daRigore,
  numeroCalottinaAvversario: numero,
  assistDi: assist,
  guadagnataDa: guadagnata,
  creatoIl: DateTime(2026, 10, 12),
);

void main() {
  test('superiorità e inferiorità dalle espulsioni, rigori a parte', () {
    final s = StatisticheEventi.da([
      // Tre espulsioni avversarie (una guadagnata da Rossi), un rigore.
      _e('espulsione', squadra: 'avversaria', numero: 4, guadagnata: 'rossi'),
      _e('espulsione', squadra: 'avversaria', numero: 7),
      _e('espulsione', squadra: 'avversaria', numero: 9),
      _e(
        'espulsione',
        squadra: 'avversaria',
        numero: 2,
        daRigore: true,
        guadagnata: 'bianchi',
      ),
      // Un gol in superiorità su tre, un rigore segnato.
      _e('tiro', atleta: 'rossi', esito: 'gol', contesto: 'superiorita'),
      _e('tiro', atleta: 'verdi', esito: 'non_gol', contesto: 'superiorita'),
      _e('tiro', atleta: 'bianchi', esito: 'gol', contesto: 'rigore'),
      // Due nostre espulsioni, un gol subito in inferiorità.
      _e('espulsione', atleta: 'verdi'),
      _e('espulsione', atleta: 'verdi', daRigore: true),
      _e('espulsione', atleta: 'neri'),
      _e('tiro', squadra: 'avversaria', esito: 'gol', contesto: 'superiorita'),
    ]);
    final n = s.squadra;
    expect(n.superiorita, 3);
    expect(n.golInSuperiorita, 1);
    expect(n.rigoriAvuti, 1);
    expect(rapporto(n.golRigore, n.rigoriTirati), '1/1');
    expect(n.inferiorita, 2);
    expect(n.golSubitiInInferiorita, 1);
    expect(n.rigoriConcessi, 1);
    expect(n.espulsioni, 3);
    expect(n.espulsioniGuadagnate, 1);
    expect(n.rigoriGuadagnati, 1);
    expect(s.di('rossi').espulsioniGuadagnate, 1);
    expect(s.di('bianchi').rigoriGuadagnati, 1);
    expect(s.di('verdi').espulsioni, 2);
    expect(conPercentuale(n.golInSuperiorita, n.superiorita), '1/3 (33%)');
    expect(conPercentuale(0, 0), '—');
  });

  test('le superiorità segnate in cronologia contano se sono di più', () {
    final soloCronologia = StatisticheEventi.da([
      _e('superiorita', esito: 'gol'),
      _e('superiorita', esito: 'non_gol'),
      _e('superiorita', squadra: 'avversaria', esito: 'gol'),
    ]).squadra;
    expect(soloCronologia.superiorita, 2);
    expect(soloCronologia.golInSuperiorita, 1);
    expect(soloCronologia.inferiorita, 1);
    expect(soloCronologia.golSubitiInInferiorita, 1);

    // Segnate in tutti e due i modi: la stessa situazione non si conta
    // due volte.
    final entrambe = StatisticheEventi.da([
      _e('espulsione', squadra: 'avversaria', numero: 4),
      _e('superiorita', esito: 'gol'),
      _e('tiro', atleta: 'rossi', esito: 'gol', contesto: 'superiorita'),
    ]).squadra;
    expect(entrambe.superiorita, 1);
    expect(entrambe.golInSuperiorita, 1);
  });

  test('si conta partita per partita, poi si somma', () {
    final s = StatisticheEventi.da([
      _e('superiorita', partita: 'p1', esito: 'gol'),
      _e('espulsione', partita: 'p2', squadra: 'avversaria', numero: 3),
      _e('espulsione', partita: 'p2', squadra: 'avversaria', numero: 5),
    ]);
    expect(s.partite, 2);
    expect(s.squadra.superiorita, 3);
    expect(s.squadra.golInSuperiorita, 1);
  });

  test('assist solo sui gol, palle perse e recuperate anche della squadra', () {
    final s = StatisticheEventi.da([
      _e('tiro', atleta: 'rossi', esito: 'gol', assist: 'bianchi'),
      _e('tiro', atleta: 'rossi', esito: 'non_gol', assist: 'bianchi'),
      _e('tiro', atleta: 'verdi', esito: 'gol', contesto: 'controfuga'),
      _e('tiro', squadra: 'avversaria', esito: 'gol', contesto: 'controfuga'),
      _e('palla_persa', atleta: 'rossi'),
      _e('palla_persa'),
      _e('palla_recuperata', atleta: 'bianchi'),
    ]);
    final n = s.squadra;
    expect(n.assist, 1);
    expect(s.di('bianchi').assist, 1);
    expect(n.golControfuga, 1);
    expect(n.golSubitiControfuga, 1);
    expect(n.golAzione, 1);
    expect(n.pallePerse, 2);
    expect(s.di('rossi').pallePerse, 1);
    expect(n.palleRecuperate, 1);
    expect(n.haEventiCompleti, isTrue);
    expect(metricheGiocatore(s.di('rossi')), ['Gol 1/2 (50%)', 'perse 1']);
    expect(metricheGiocatore(s.di('bianchi')), [
      'Gol 0/0',
      '1 assist',
      'recuperate 1',
    ]);
  });

  test('una partita essenziale non ha dati della modalità completa', () {
    final n = StatisticheEventi.da([
      _e('tiro', atleta: 'rossi', esito: 'gol'),
      _e('espulsione', squadra: 'avversaria', numero: 4),
    ]).squadra;
    expect(n.haEventiCompleti, isFalse);
    expect(StatisticheEventi.vuote.squadra.gol, 0);
  });

  test('in modalità completa il gol in controfuga sta accanto al gol', () {
    expect(conControfuga(esitiTiroSemplice).map((e) => e.$2), [
      'Gol',
      'Gol in controfuga',
      'Non gol',
    ]);
    expect(conControfuga(esitiTiroDettagliato).map((e) => e.$1), [
      'gol',
      golInControfuga,
      'parato',
      'palo_fuori',
    ]);
  });
}
