import 'dart:convert';

import 'package:coach_vasca/features/pallanuoto/domain/clip_video.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/video_partita.dart';
import 'package:flutter_test/flutter_test.dart';

var _n = 0;

/// Un evento registrato dal vivo [minuti] dopo le 15:00.
EventoPartita _e(
  double minuti,
  String tipo, {
  String squadra = 'nostra',
  String? atleta,
  String? esito,
  String contesto = 'azione',
  int? periodo = 1,
  bool rigore = false,
  String? assist,
  String? guadagnata,
}) => EventoPartita(
  id: 'e${_n++}',
  partitaId: 'p1',
  clubId: 'c1',
  tipo: tipo,
  squadra: squadra,
  atletaId: atleta,
  esito: esito,
  contestoTiro: contesto,
  periodo: periodo,
  espulsioneDaRigore: rigore,
  assistDi: assist,
  guadagnataDa: guadagnata,
  creatoIl: _alle(minuti),
);

DateTime _alle(double minuti) => DateTime.utc(
  2026,
  10,
  12,
  15,
).add(Duration(milliseconds: (minuti * 60000).round()));

VideoPartita _video(List<Allineamento> punti) => VideoPartita(
  id: 'v1',
  clubId: 'c1',
  partitaId: 'p1',
  youtubeId: 'dQw4w9WgXcQ',
  allineamenti: punti,
);

NotaVideo _nota(double secondo, {String? atleta}) => NotaVideo(
  id: 'n$secondo',
  videoId: 'v1',
  partitaId: 'p1',
  clubId: 'c1',
  secondo: secondo,
  atletaId: atleta,
  testo: 'Resta sul tuo uomo',
  creataIl: DateTime(2026, 10, 12),
);

void main() {
  group('link di YouTube', () {
    test('si legge l\'id da ogni forma del link', () {
      for (final link in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtube.com/watch?v=dQw4w9WgXcQ&t=125s',
        'https://m.youtube.com/watch?feature=share&v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ?si=abc123',
        'youtu.be/dQw4w9WgXcQ',
        'https://www.youtube.com/live/dQw4w9WgXcQ?feature=shared',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
        '  dQw4w9WgXcQ  ',
      ]) {
        expect(idYoutubeDa(link), 'dQw4w9WgXcQ', reason: link);
      }
    });

    test('un link che non è di un video non vale', () {
      for (final link in [
        '',
        'https://vimeo.com/123456789',
        'https://www.youtube.com/@squadra',
        'https://www.youtube.com/watch?v=corto',
        'https://youtu.be/',
        'una partita',
      ]) {
        expect(idYoutubeDa(link), isNull, reason: link);
      }
    });
  });

  group('dove cade un evento nel video', () {
    final inizio = Allineamento(
      secondo: 300,
      momento: _alle(10),
      periodo: 1,
      eventoId: 'gol1',
    );

    test('senza allineamento non si sa', () {
      expect(secondoNelVideo(const [], momento: _alle(12)), isNull);
    });

    test('con un punto solo vale per tutta la partita', () {
      expect(
        secondoNelVideo([inizio], momento: _alle(12), periodo: 1),
        300 + 120,
      );
      // Anche prima del punto e in un altro tempo (video unico).
      expect(
        secondoNelVideo([inizio], momento: _alle(9), periodo: 1),
        300 - 60,
      );
      expect(
        secondoNelVideo([inizio], momento: _alle(30), periodo: 3),
        300 + 1200,
      );
    });

    test('dopo un taglio conta il punto del suo tempo', () {
      // Fra il primo e il secondo tempo il video è tagliato: 4 minuti
      // di pausa non ci sono.
      final secondoTempo = Allineamento(
        secondo: 1000,
        momento: _alle(25),
        periodo: 2,
      );
      final punti = [inizio, secondoTempo];
      expect(secondoNelVideo(punti, momento: _alle(26), periodo: 2), 1000 + 60);
      // Un evento del secondo tempo prima del punto usa comunque il suo.
      expect(
        secondoNelVideo(punti, momento: _alle(24.5), periodo: 2),
        1000 - 30,
      );
      expect(secondoNelVideo(punti, momento: _alle(15), periodo: 1), 300 + 300);
      // Il terzo tempo, senza un suo punto, segue l'ultimo prima.
      expect(
        secondoNelVideo(punti, momento: _alle(40), periodo: 3),
        1000 + 900,
      );
    });

    test('nello stesso tempo vale l\'ultimo punto prima dell\'evento', () {
      final ritocco = Allineamento(
        secondo: 430,
        momento: _alle(12),
        periodo: 1,
      );
      final punti = [inizio, ritocco];
      expect(secondoNelVideo(punti, momento: _alle(11), periodo: 1), 360);
      expect(secondoNelVideo(punti, momento: _alle(13), periodo: 1), 490);
    });

    test('l\'allineamento si salva e si rilegge', () {
      final testo = jsonEncode([inizio.toJson()]);
      final riletto = allineamentiDa(testo).single;
      expect(riletto.secondo, 300);
      expect(riletto.momento, _alle(10));
      expect(riletto.periodo, 1);
      expect(riletto.eventoId, 'gol1');
      expect(allineamentiDa('[{"secondo": "x"}, 3]'), isEmpty);
      expect(allineamentiDa(null), isEmpty);
    });
  });

  group('le clip', () {
    // Il gol al minuto 10 è al secondo 300 del video.
    final video = _video([Allineamento(secondo: 300, momento: _alle(10))]);
    final gol = _e(10, 'tiro', atleta: 'rossi', esito: 'gol', assist: 'verdi');
    final parato = _e(11, 'tiro', atleta: 'bianchi', esito: 'parato');
    final subito = _e(12, 'tiro', squadra: 'avversaria', esito: 'gol');
    final espulsione = _e(
      13,
      'espulsione',
      squadra: 'avversaria',
      guadagnata: 'bianchi',
    );
    // La superiorità segnata a mano per la stessa espulsione.
    final superiorita = _e(13.3, 'superiorita', esito: 'gol');
    final rigore = _e(14, 'espulsione', squadra: 'avversaria', rigore: true);
    final persa = _e(15, 'palla_persa', atleta: 'rossi');
    final prima = _e(2, 'tiro', atleta: 'rossi', esito: 'non_gol');
    final eventi = [
      gol,
      parato,
      subito,
      espulsione,
      superiorita,
      rigore,
      persa,
      prima,
    ];

    test('ogni evento parte qualche secondo prima e finisce dopo', () {
      final tutte = clipVideo(video: video, eventi: eventi, note: const []);
      // Il tiro al minuto 2 cade prima dell'inizio del video.
      expect(tutte.fuoriDalVideo, 1);
      final diGol = tutte.clip.firstWhere((c) => c.id == gol.id);
      expect(diGol.secondo, 300);
      expect(diGol.inizio, 290);
      expect(diGol.fine, 304);
      final diPersa = tutte.clip.firstWhere((c) => c.id == persa.id);
      expect(diPersa.secondo, 600);
      expect(diPersa.inizio, 592);
      expect(diPersa.fine, 603);
      expect(
        tutte.clip.map((c) => c.secondo),
        orderedEquals([...tutte.clip.map((c) => c.secondo)]..sort()),
      );
    });

    test('i filtri scelgono le situazioni', () {
      List<String> ids(FiltroClip f) => [
        for (final c in clipVideo(
          video: video,
          eventi: eventi,
          note: const [],
          filtro: f,
        ).clip)
          c.id,
      ];
      expect(ids(FiltroClip.golFatti), [gol.id]);
      expect(ids(FiltroClip.golSubiti), [subito.id]);
      expect(ids(FiltroClip.tiri), [gol.id, parato.id]);
      // L'espulsione e la superiorità segnata 18 secondi dopo sono la
      // stessa situazione; quella da rigore no.
      expect(ids(FiltroClip.superiorita), [espulsione.id]);
      expect(ids(FiltroClip.rigori), [rigore.id]);
      expect(ids(FiltroClip.pallePerse), [persa.id]);
      expect(ids(FiltroClip.inferiorita), isEmpty);
    });

    test('una superiorità si guarda tutta, dall\'espulsione', () {
      final c = clipVideo(
        video: video,
        eventi: eventi,
        note: const [],
        filtro: FiltroClip.superiorita,
      ).clip.single;
      expect(c.inizio, 480 - 4);
      expect(c.fine, 480 + 24);
    });

    test('le clip di un giocatore: tiri, assist, espulsioni guadagnate', () {
      List<String> di(String atleta) => [
        for (final c in clipVideo(
          video: video,
          eventi: eventi,
          note: [
            _nota(700, atleta: atleta),
            _nota(800),
          ],
          atletaId: atleta,
        ).clip)
          c.id,
      ];
      expect(di('rossi'), [gol.id, persa.id, 'n700.0']);
      expect(di('verdi'), [gol.id, 'n700.0']);
      expect(di('bianchi'), [parato.id, espulsione.id, 'n700.0']);
    });

    test('senza allineamento restano solo le note', () {
      final r = clipVideo(
        video: _video(const []),
        eventi: eventi,
        note: [_nota(42)],
      );
      expect(r.clip.single.nota?.secondo, 42);
      expect(r.clip.single.inizio, 37);
      expect(r.clip.single.fine, 42);
      expect(r.fuoriDalVideo, 0);
    });

    test('dopo la fine del video un evento non ha clip', () {
      final r = clipVideo(
        video: video,
        eventi: eventi,
        note: const [],
        durata: 500,
      );
      expect(r.clip.map((c) => c.id), [
        gol.id,
        parato.id,
        subito.id,
        espulsione.id,
        superiorita.id,
      ]);
      // Rigore, palla persa e il tiro di prima dell'inizio.
      expect(r.fuoriDalVideo, 3);
      // L'ultima clip si ferma alla fine del video.
      expect(r.clip.last.fine, 500);
    });

    test('i filtri vuoti non si mostrano', () {
      expect(filtriConClip(video: video, eventi: [gol], note: const []), [
        FiltroClip.tutte,
        FiltroClip.golFatti,
        FiltroClip.tiri,
      ]);
    });

    test('il minutaggio', () {
      expect(minutaggio(0), '0:00');
      expect(minutaggio(65.9), '1:05');
      expect(minutaggio(3725), '1:02:05');
    });
  });

  test('il disegno si salva e si rilegge', () {
    const segni = [
      SegnoVideo(
        forma: FormaSegno.freccia,
        colore: 'rosso',
        da: (0.1, 0.2),
        a: (0.5, 0.6),
        controllo: (0.3, 0.1),
      ),
      SegnoVideo(
        forma: FormaSegno.cerchio,
        colore: 'giallo',
        da: (0.4, 0.4),
        a: (0.6, 0.7),
      ),
    ];
    final riletti = segniDa(jsonEncode([for (final s in segni) s.toJson()]));
    expect(riletti, hasLength(2));
    expect(riletti.first.forma, FormaSegno.freccia);
    expect(riletti.first.controllo, (0.3, 0.1));
    expect(riletti.last.forma, FormaSegno.cerchio);
    expect(riletti.last.a, (0.6, 0.7));
    // Un segno illeggibile si salta, gli altri restano.
    expect(
      segniDa([
        {
          'forma': 'stella',
          'da': [0, 0],
          'a': [1, 1],
        },
        segni.last.toJson(),
      ]),
      hasLength(1),
    );
  });
}
