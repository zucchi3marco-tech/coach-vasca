import 'dart:async';

import 'package:coach_vasca/core/video/lettore_youtube.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/application/video_partita_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/nomi_squadra_repository.dart';
import 'package:coach_vasca/features/pallanuoto/data/video_partite_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/video_partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/disegno_video.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/video_partita_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _partita = Partita(
  id: 'p1',
  clubId: 'c1',
  data: DateTime(2026, 10, 11),
  squadraCasa: 'Noi',
  squadraTrasferta: 'Recco',
  numeroMaxConvocati: 15,
);

final _gol = EventoPartita(
  id: 'gol',
  partitaId: 'p1',
  clubId: 'c1',
  tipo: 'tiro',
  squadra: 'nostra',
  atletaId: 'rossi',
  esito: 'gol',
  periodo: 1,
  creatoIl: DateTime.utc(2026, 10, 11, 15, 10),
);

final _persa = EventoPartita(
  id: 'persa',
  partitaId: 'p1',
  clubId: 'c1',
  tipo: 'palla_persa',
  squadra: 'nostra',
  atletaId: 'bianchi',
  periodo: 1,
  creatoIl: DateTime.utc(2026, 10, 11, 15, 12),
);

VideoPartita _video([List<Allineamento> punti = const []]) => VideoPartita(
  id: 'v1',
  clubId: 'c1',
  partitaId: 'p1',
  youtubeId: 'dQw4w9WgXcQ',
  allineamenti: punti,
);

Atleta _atleta(String id, String nome, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: cognome,
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

/// Il server finto: tiene il video e annota cosa gli si chiede.
class _RepositoryFinto implements VideoPartiteRepository {
  _RepositoryFinto(this.video);

  VideoPartita video;
  final _cambi = StreamController<VideoPartita?>.broadcast();
  final allineamenti = <List<Allineamento>>[];
  final note =
      <
        ({
          double secondo,
          String? eventoId,
          String? atletaId,
          String? testo,
          List<SegnoVideo> disegno,
        })
      >[];

  Stream<VideoPartita?> flusso() async* {
    yield video;
    yield* _cambi.stream;
  }

  @override
  Future<VideoPartita> salvaAllineamenti(
    String videoId,
    List<Allineamento> punti,
  ) async {
    allineamenti.add(punti);
    video = _video(punti);
    _cambi.add(video);
    return video;
  }

  @override
  Future<void> salvaNota({
    String? id,
    required VideoPartita video,
    required double secondo,
    String? eventoId,
    String? atletaId,
    String? testo,
    required List<SegnoVideo> disegno,
  }) async {
    note.add((
      secondo: secondo,
      eventoId: eventoId,
      atletaId: atletaId,
      testo: testo,
      disegno: [...disegno],
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(
  _RepositoryFinto finto,
  Widget figlio, {
  List<NotaVideo> note = const [],
}) => ProviderScope(
  overrides: [
    videoPartiteRepositoryProvider.overrideWithValue(finto),
    videoPartitaProvider.overrideWith((ref, id) => finto.flusso()),
    noteVideoProvider.overrideWith((ref, id) => Stream.value(note)),
    eventiPartitaListProvider.overrideWith(
      (ref, id) => Stream.value([_gol, _persa]),
    ),
    distintaListProvider.overrideWith(
      (ref, id) => Stream.value([
        for (final (i, atleta) in ['rossi', 'bianchi'].indexed)
          DistintaGiocatore(
            id: 'd$i',
            partitaId: id,
            atletaId: atleta,
            clubId: 'c1',
            numeroCalottina: i + 2,
            capitano: false,
            viceCapitano: false,
            portiere: false,
            fuoriquota: false,
          ),
      ]),
    ),
    atletiListProvider.overrideWith(
      (ref, filtro) => Stream.value([
        _atleta('rossi', 'Marco', 'Rossi'),
        _atleta('bianchi', 'Luca', 'Bianchi'),
      ]),
    ),
    nomiSquadraProvider.overrideWith(
      (ref, clubId) async => {
        'rossi': 'Rossi Marco',
        'bianchi': 'Bianchi Luca',
      },
    ),
  ],
  child: MaterialApp(theme: AppTheme.chiaro, home: figlio),
);

void _schermoGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('l\'allenatore allinea il video su un gol e ne nascono le '
      'clip', (tester) async {
    _schermoGrande(tester);
    final finto = _RepositoryFinto(_video());
    await tester.pumpWidget(_app(finto, VideoPartitaScreen(partita: _partita)));
    await tester.pumpAndSettle();

    expect(find.text('Allinea il video agli eventi'), findsOneWidget);
    await tester.tap(find.text('Allinea il video'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiro — Rossi Marco — Gol (T1)'));
    await tester.pumpAndSettle();

    // Il gol è al secondo 2 del video.
    expect(find.text('Dov\'è nel video?'), findsOneWidget);
    await tester.tap(find.text('+1 s'));
    await tester.tap(find.text('+1 s'));
    await tester.pump();
    await tester.tap(find.text('È qui'));
    await tester.pumpAndSettle();

    final punto = finto.allineamenti.single.single;
    expect(punto.secondo, 2);
    expect(punto.eventoId, 'gol');
    expect(punto.periodo, 1);
    expect(punto.momento, _gol.creatoIl);

    // Ogni evento è una clip: la palla persa due minuti dopo è a 2:02.
    expect(find.text('Tiro — Rossi Marco — Gol (T1)'), findsOneWidget);
    expect(find.text('Palla persa — Bianchi Luca (T1)'), findsOneWidget);
    expect(find.text('2:02'), findsOneWidget);
    expect(find.text('Palle perse'), findsOneWidget);

    await tester.tap(find.text('Palla persa — Bianchi Luca (T1)'));
    await tester.pumpAndSettle();
    expect(find.text('In onda'), findsWidgets);
    expect(find.text('La clip è spostata? Allinea qui'), findsOneWidget);
  });

  testWidgets('telefono in orizzontale: il video non copre «È qui»', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final finto = _RepositoryFinto(_video());
    await tester.pumpWidget(_app(finto, VideoPartitaScreen(partita: _partita)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Allinea il video'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allinea il video'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiro — Rossi Marco — Gol (T1)'));
    await tester.pumpAndSettle();

    final eQui = find.text('È qui');
    await tester.ensureVisible(eQui);
    await tester.pumpAndSettle();
    expect(tester.getRect(eQui).bottom, lessThanOrEqualTo(390));
    await tester.tap(eQui);
    await tester.pumpAndSettle();
    expect(finto.allineamenti, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sul fotogramma della clip si disegna una nota per il '
      'giocatore', (tester) async {
    _schermoGrande(tester);
    final finto = _RepositoryFinto(
      _video([Allineamento(secondo: 40, momento: _gol.creatoIl, periodo: 1)]),
    );
    await tester.pumpWidget(_app(finto, VideoPartitaScreen(partita: _partita)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiro — Rossi Marco — Gol (T1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disegna'));
    await tester.pumpAndSettle();

    // La clip parte 10 secondi prima del gol.
    expect(find.text('Nota a 0:30'), findsOneWidget);
    final tavola = find.byType(TavolaDisegnoVideo);
    await tester.dragFrom(tester.getCenter(tavola), const Offset(120, -40));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Qui resta largo');
    await tester.tap(find.text('Salva nota'));
    await tester.pumpAndSettle();

    final nota = finto.note.single;
    expect(nota.secondo, 30);
    expect(nota.eventoId, 'gol');
    // Commentando la clip di Rossi la nota è per lui.
    expect(nota.atletaId, 'rossi');
    expect(nota.testo, 'Qui resta largo');
    expect(nota.disegno.single.forma, FormaSegno.freccia);
    expect(
      find.text('Nota salvata: la vede solo Rossi Marco.'),
      findsOneWidget,
    );
  });

  testWidgets('l\'atleta convocato vede in cima le sue azioni, senza '
      'modificare', (tester) async {
    _schermoGrande(tester);
    final finto = _RepositoryFinto(
      _video([Allineamento(secondo: 40, momento: _gol.creatoIl, periodo: 1)]),
    );
    await tester.pumpWidget(
      _app(
        finto,
        VideoPartitaScreen(
          partita: _partita,
          modifica: false,
          atletaId: 'rossi',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Le tue azioni'), findsOneWidget);
    expect(find.text('Tutta la partita'), findsOneWidget);
    // Il gol una volta fra le sue, una fra tutte.
    expect(find.text('Tiro — Rossi Marco — Gol (T1)'), findsNWidgets(2));
    expect(find.text('Palla persa — Bianchi Luca (T1)'), findsOneWidget);
    expect(find.text('Disegna'), findsNothing);
    expect(find.text('Tutti i giocatori'), findsNothing);
    expect(find.byTooltip('Altro'), findsNothing);
  });

  testWidgets('guardate di fila, le clip si seguono senza tornare indietro '
      'e il video si ferma sulle note', (tester) async {
    _schermoGrande(tester);
    NotaVideo nota(String id, double secondo) => NotaVideo(
      id: id,
      videoId: 'v1',
      partitaId: 'p1',
      clubId: 'c1',
      secondo: secondo,
      testo: 'Nota $id',
      creataIl: DateTime(2026, 10, 11),
    );
    // Gol a 40", palla persa a 160" (clip 152-163); una nota dentro la
    // clip della palla persa e una subito dopo.
    final finto = _RepositoryFinto(
      _video([Allineamento(secondo: 40, momento: _gol.creatoIl, periodo: 1)]),
    );
    await tester.pumpWidget(
      _app(
        finto,
        VideoPartitaScreen(partita: _partita),
        note: [nota('n1', 162), nota('n2', 165)],
      ),
    );
    await tester.pumpAndSettle();
    final video = tester
        .widget<LettoreYoutube>(find.byType(LettoreYoutube))
        .controllore;
    // Il lettore va avanti da solo, un quarto di secondo alla volta.
    Future<void> scorri(double da, double a) async {
      for (var t = da; t <= a + 1e-9; t += 0.25) {
        video.aggiorna(secondo: t, inRiproduzione: true);
        await tester.pump();
      }
    }

    await tester.tap(find.text('Guarda di fila'));
    await tester.pump();
    expect(video.secondo, 30);
    expect(find.text('In onda · 1 di 4'), findsOneWidget);

    await scorri(30.25, 44);
    expect(find.text('In onda · 2 di 4'), findsOneWidget);
    expect(video.secondo, 152);

    // Dentro la clip della palla persa la prima nota ferma il video.
    await scorri(152.25, 162);
    expect(video.inRiproduzione, isFalse);
    expect(find.text('Nota n1'), findsOneWidget);
    await tester.tap(find.text('Continua'));
    await tester.pump();

    // Finita la palla persa la nota già vista non si ripete, e la clip
    // della seconda comincia prima del punto in cui siamo: niente salto
    // indietro.
    await scorri(162.25, 163);
    expect(video.secondo, 163);
    expect(find.text('In onda'), findsOneWidget);
    await scorri(163.25, 165);
    expect(find.text('Nota n2'), findsOneWidget);
    expect(find.text('Continua'), findsOneWidget);

    // Era l'ultima: il video riparte libero.
    await tester.tap(find.text('Continua'));
    await tester.pump();
    expect(video.inRiproduzione, isTrue);
    expect(find.text('In onda'), findsNothing);
  });

  testWidgets('su telefono il video resta in alto e sotto scorrono '
      'comandi e clip', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final finto = _RepositoryFinto(
      _video([Allineamento(secondo: 40, momento: _gol.creatoIl, periodo: 1)]),
    );
    await tester.pumpWidget(_app(finto, VideoPartitaScreen(partita: _partita)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiro — Rossi Marco — Gol (T1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disegna'));
    await tester.pumpAndSettle();
    expect(find.text('Salva nota'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('senza video l\'allenatore incolla il link', (tester) async {
    _schermoGrande(tester);
    final finto = _RepositoryFinto(_video());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoPartitaProvider.overrideWith((ref, id) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: VideoPartitaScreen(partita: _partita),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Collega il video della partita'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'https://vimeo.com/1');
    await tester.tap(find.text('Collega video'));
    await tester.pumpAndSettle();
    expect(find.text('Non è un link di un video di YouTube.'), findsOneWidget);
    expect(finto.allineamenti, isEmpty);
  });
}
