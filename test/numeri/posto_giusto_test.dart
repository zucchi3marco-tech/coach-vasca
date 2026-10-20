import 'package:coach_vasca/features/allenamenti/domain/piano_salvataggio_testo.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:flutter_test/flutter_test.dart';

/// Piano 15, «Prove sui numeri»: una serie non deve finire al posto o nel
/// gruppo sbagliato quando si risalva un allenamento scritto a testo. Ogni
/// serie scritta riusa la riga della stessa serie: con la riga della
/// stessa posizione, una serie aggiunta in cima spostava il "fatta" di
/// bordo vasca sulla serie sotto (e con lui i metri fatti e il carico).

var _contatore = 0;
String _nuovoId() => 'n${_contatore++}';

/// Le serie salvate da [testo], con id s1, s2... e l'esito segnato a
/// bordo vasca per alcune ([esiti], per posizione da 1).
List<Serie> _salvate(String testo, {Map<int, String> esiti = const {}}) {
  final piano = pianoSalvataggio(
    vecchie: const [],
    nuove: interpretaAllenamento(testo).serie,
    nuovoId: _nuovoId,
  );
  return [
    for (final c in piano.crea)
      _riga(
        's${c.ordine}',
        c.nuova,
        ordine: c.ordine,
        piramideId: c.piramideId,
        momentoId: c.momentoId,
        esito: esiti[c.ordine],
      ),
  ];
}

Serie _riga(
  String id,
  SerieScritta nuova, {
  required int ordine,
  String? piramideId,
  String? momentoId,
  String? esito,
}) => Serie(
  id: id,
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: nuova.blocco,
  ripetute: nuova.ripetute,
  distanzaM: nuova.distanzaM,
  durataS: nuova.durataS,
  stile: nuova.stile,
  esecuzione: nuova.esecuzione,
  zona: nuova.zona,
  passoObiettivoS: nuova.passoObiettivoS,
  recuperoS: nuova.recuperoS,
  ripartenzaS: nuova.ripartenzaS,
  attrezzatura: nuova.attrezzatura,
  note: nuova.note,
  piramideId: piramideId,
  esito: esito,
  recuperoDopoS: nuova.recuperoDopoS,
  destinatari: nuova.destinatari,
  momentoId: momentoId,
);

/// Risalva [vecchie] con [testo] come farebbe il database con il piano:
/// le righe aggiornate tengono id ed esito, le nuove non hanno esito.
List<Serie> _risalva(List<Serie> vecchie, String testo) {
  final piano = pianoSalvataggio(
    vecchie: vecchie,
    nuove: interpretaAllenamento(testo).serie,
    nuovoId: _nuovoId,
  );
  final aggiornate = {
    for (final a in piano.aggiorna)
      a.vecchia.id: _riga(
        a.vecchia.id,
        a.nuova,
        ordine: a.ordine,
        piramideId: a.piramideId,
        momentoId: a.momentoId,
        esito: a.vecchia.esito,
      ),
  };
  final tolte = {for (final s in piano.elimina) s.id};
  return [
    for (final s in vecchie)
      if (!tolte.contains(s.id)) aggiornate[s.id] ?? s,
    for (final (i, c) in piano.crea.indexed)
      _riga(
        'nuova$i',
        c.nuova,
        ordine: c.ordine,
        piramideId: c.piramideId,
        momentoId: c.momentoId,
      ),
  ]..sort((a, b) => a.ordine.compareTo(b.ordine));
}

/// Una serie in breve: "8x100 A2" e il suo esito.
String _breve(Serie s) =>
    '${s.ripetute}x${s.distanzaM ?? s.durataS} ${s.zona ?? s.esecuzione}'
    '${s.esito == null ? '' : ' ${s.esito}'}';

/// I metri fatti: le serie segnate fatte, come li conta bordo vasca.
int _metriFatti(List<Serie> serie) =>
    volumeDi(serieDelGruppo(serie).where((s) => s.fatta)).metri;

const _prima =
    'Riscaldamento\n'
    '400 sl A1\n'
    '\n'
    'Principale\n'
    '8x100 sl A2\n'
    '4x50 sl C1\n'
    '\n'
    'Defaticamento\n'
    '200 sl A1';

void main() {
  late List<Serie> vecchie;

  setUp(() {
    vecchie = _salvate(_prima, esiti: {1: 'fatta', 2: 'fatta', 3: 'saltata'});
  });

  void ordineSenzaBuchi(List<Serie> serie) => expect(
    serie.map((s) => s.ordine),
    [for (var i = 1; i <= serie.length; i++) i],
  );

  test('un testo uguale non tocca nessuna riga', () {
    final piano = pianoSalvataggio(
      vecchie: vecchie,
      nuove: interpretaAllenamento(_prima).serie,
      nuovoId: _nuovoId,
    );
    expect(piano.vuoto, isTrue);
  });

  test('una serie aggiunta in cima: ogni segno resta sulla sua serie', () {
    final dopo = _risalva(
      vecchie,
      _prima.replaceFirst('Principale\n', 'Principale\n200 gambe A1\n'),
    );
    expect(dopo.map(_breve), [
      '1x400 A1 fatta',
      '1x200 A1',
      '8x100 A2 fatta',
      '4x50 C1 saltata',
      '1x200 A1',
    ]);
    // Le serie di prima tengono la loro riga: cambia solo il posto.
    expect(dopo.where((s) => s.id.startsWith('s')).map((s) => s.id), [
      's1',
      's2',
      's3',
      's4',
    ]);
    expect(_metriFatti(dopo), _metriFatti(vecchie));
    ordineSenzaBuchi(dopo);
  });

  test('una serie tolta in mezzo: si elimina quella, non l\'ultima', () {
    final piano = pianoSalvataggio(
      vecchie: vecchie,
      nuove: interpretaAllenamento(_prima.replaceFirst('8x100 sl A2\n', ''))
          .serie,
      nuovoId: _nuovoId,
    );
    expect(piano.elimina.map((s) => s.id), ['s2']);
    expect(piano.crea, isEmpty);
    final dopo = _risalva(vecchie, _prima.replaceFirst('8x100 sl A2\n', ''));
    expect(dopo.map(_breve), ['1x400 A1 fatta', '4x50 C1 saltata', '1x200 A1']);
    ordineSenzaBuchi(dopo);
  });

  test('una serie corretta resta la stessa riga, con il suo "fatta"', () {
    final piano = pianoSalvataggio(
      vecchie: vecchie,
      nuove: interpretaAllenamento(_prima.replaceFirst('8x100', '6x100')).serie,
      nuovoId: _nuovoId,
    );
    expect(piano.aggiorna.map((a) => a.vecchia.id), ['s2']);
    expect(piano.crea, isEmpty);
    expect(piano.elimina, isEmpty);
    expect(
      _risalva(vecchie, _prima.replaceFirst('8x100', '6x100')).map(_breve),
      ['1x400 A1 fatta', '6x100 A2 fatta', '4x50 C1 saltata', '1x200 A1'],
    );
  });

  test('due serie scambiate tengono ognuna la sua riga', () {
    final scambiate = _prima.replaceFirst(
      '8x100 sl A2\n4x50 sl C1',
      '4x50 sl C1\n8x100 sl A2',
    );
    final piano = pianoSalvataggio(
      vecchie: vecchie,
      nuove: interpretaAllenamento(scambiate).serie,
      nuovoId: _nuovoId,
    );
    expect(piano.crea, isEmpty);
    expect(piano.elimina, isEmpty);
    expect(_risalva(vecchie, scambiate).map(_breve), [
      '1x400 A1 fatta',
      '4x50 C1 saltata',
      '8x100 A2 fatta',
      '1x200 A1',
    ]);
  });

  test('una serie scritta due volte: la copia è nuova, senza segno', () {
    final dopo = _risalva(
      vecchie,
      _prima.replaceFirst('8x100 sl A2\n', '8x100 sl A2\n8x100 sl A2\n'),
    );
    expect(dopo.map(_breve), [
      '1x400 A1 fatta',
      '8x100 A2 fatta',
      '8x100 A2',
      '4x50 C1 saltata',
      '1x200 A1',
    ]);
    expect(_metriFatti(dopo), 1200);
  });

  group('i gruppi restano interi', () {
    const conGruppi =
        'Principale\n'
        '2x\n'
        '4x50 sl A2\n'
        '100 do\n'
        '\n'
        '8x100 sl B1\n'
        'Portieri\n'
        "3x6' tiri\n"
        '\n'
        '200 sl A1';

    test('con una serie aggiunta sopra, il "2x" e il lavoro in parallelo '
        'tengono le loro righe e i loro gruppi', () {
      final prima = _salvate(conGruppi, esiti: {1: 'fatta', 5: 'fatta'});
      final testo = conGruppi.replaceFirst(
        'Principale\n',
        'Principale\n400 sl A1\n\n',
      );
      final dopo = _risalva(prima, testo);
      ordineSenzaBuchi(dopo);

      // Le righe di prima sono le stesse, scivolate di uno.
      expect(dopo.skip(1).map((s) => s.id), [for (final s in prima) s.id]);
      expect(dopo.first.id, startsWith('nuova'));
      expect(dopo.first.piramideId, isNull);
      expect(dopo.first.momentoId, isNull);
      // Il "2x" ha ancora le sue quattro righe, con lo stesso gruppo.
      final dueX = dopo.sublist(1, 5);
      expect(dueX.map((s) => s.piramideId).toSet(), {prima.first.piramideId});
      expect(dopo[5].piramideId, isNull);
      // Il lavoro in parallelo: lo stesso momento, i portieri per i
      // portieri, la serie dopo fuori.
      expect(dopo[5].momentoId, prima[4].momentoId);
      expect(dopo[6].momentoId, prima[4].momentoId);
      expect(dopo[6].destinatari, Destinatari.portieri);
      expect(dopo[7].momentoId, isNull);
      // I segni sulle loro serie.
      expect(dopo[1].esito, 'fatta');
      expect(dopo[5].esito, 'fatta');
      expect(dopo.where((s) => s.esito != null), hasLength(2));
      // I metri del gruppo: 400 in più, i portieri non contano.
      expect(
        volumeDi(serieDelGruppo(dopo)).metri,
        volumeDi(serieDelGruppo(prima)).metri + 400,
      );
    });

    test('un "2x" diventato "3x" si allunga senza prendere la serie sotto', () {
      final prima = _salvate(conGruppi);
      final dopo = _risalva(prima, conGruppi.replaceFirst('2x\n', '3x\n'));
      ordineSenzaBuchi(dopo);
      final gruppo = prima.first.piramideId;
      expect(dopo.where((s) => s.piramideId == gruppo), hasLength(6));
      expect(dopo.take(6).every((s) => s.piramideId == gruppo), isTrue);
      expect(dopo[6].piramideId, isNull);
      expect(dopo[6].momentoId, prima[4].momentoId);
      expect(
        volumeDi(serieDelGruppo(dopo)).metri,
        volumeDi(serieDelGruppo(prima)).metri + 300,
      );
    });
  });
}
