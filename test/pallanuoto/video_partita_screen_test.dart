import 'dart:async';
import 'dart:typed_data';

import 'package:coach_vasca/core/video/lettore_youtube.dart';
import 'package:coach_vasca/core/voce/voce.dart';
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

  /// Dove sta la voce di ogni nota salvata (per id) e quanto dura.
  final voci = <String?, ({String? path, double? secondi})>{};
  final caricate = <String>[];
  final tolti = <String>[];
  final risposte = <RispostaNota>[];

  @override
  Future<void> salvaNota({
    String? id,
    String? idNuova,
    String? audioPath,
    double? audioSecondi,
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
    voci[id ?? idNuova] = (path: audioPath, secondi: audioSecondi);
  }

  @override
  String nuovoIdNota() => 'nuova';

  @override
  Future<String> caricaVoce({
    required String clubId,
    required String notaId,
    required VoceRegistrata voce,
  }) async {
    final path = '$clubId/$notaId.${voce.estensione}';
    caricate.add(path);
    return path;
  }

  @override
  Future<String> indirizzoVoce(String path) async => 'url:$path';

  @override
  Future<void> eliminaFileVoce(String path) async => tolti.add(path);

  @override
  Future<List<RispostaNota>> risposteNote(String partitaId) async => [
    ...risposte,
  ];

  @override
  Future<void> rispondiNota({
    required NotaVideo nota,
    required String atletaId,
    required String testo,
  }) async {
    risposte
      ..removeWhere((r) => r.notaId == nota.id && r.atletaId == atletaId)
      ..add(
        RispostaNota(
          id: 'r${risposte.length}',
          notaId: nota.id,
          atletaId: atletaId,
          testo: testo.trim(),
          aggiornataIl: DateTime(2026, 10, 26),
        ),
      );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Il microfono finto: registra sempre 42 secondi.
class _RegistratoreFinto implements RegistratoreVoce {
  var _attivo = false;

  @override
  bool get disponibile => true;

  @override
  bool get inRegistrazione => _attivo;

  @override
  Future<void> avvia() async => _attivo = true;

  @override
  Future<VoceRegistrata?> ferma() async {
    _attivo = false;
    return VoceRegistrata(
      byte: Uint8List.fromList(const [1, 2, 3]),
      tipo: 'audio/webm',
      secondi: 42,
    );
  }

  @override
  void annulla() => _attivo = false;
}

/// L'altoparlante finto: annota cosa apre e quando suona.
class _LettoreFinto implements LettoreVoce {
  final aperti = <String>[];
  var suonato = 0;
  var _suona = false;

  @override
  void Function()? allaFine;

  @override
  Future<void> apri(String indirizzo) async => aperti.add(indirizzo);

  @override
  Future<void> apriRegistrata(VoceRegistrata voce) async =>
      aperti.add('registrata');

  @override
  Future<void> suona({double secondo = 0}) async {
    suonato++;
    _suona = true;
  }

  @override
  void pausa() => _suona = false;

  @override
  double get secondo => 0;

  @override
  bool get inRiproduzione => _suona;

  @override
  void chiudi() => _suona = false;
}

Widget _app(
  _RepositoryFinto finto,
  Widget figlio, {
  List<NotaVideo> note = const [],
  RegistratoreVoce? registratore,
  LettoreVoce? lettore,
}) => ProviderScope(
  overrides: [
    if (registratore != null)
      creaRegistratoreVoceProvider.overrideWithValue(() => registratore),
    if (lettore != null)
      creaLettoreVoceProvider.overrideWithValue(() => lettore),
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

  testWidgets('PC 1500x920: «È qui» sta subito sotto il video', (tester) async {
    tester.view.physicalSize = const Size(1500, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final finto = _RepositoryFinto(_video());
    await tester.pumpWidget(_app(finto, VideoPartitaScreen(partita: _partita)));
    await tester.pumpAndSettle();

    tocchiRichiesti.clear();
    await tester.tap(find.text('Allinea il video'));
    await tester.pumpAndSettle();
    // Sul web, con l'elenco aperto il video non deve prendersi i clic
    // delle righe che gli stanno sopra.
    expect(tocchiRichiesti, [false]);
    await tester.tap(find.text('Tiro — Rossi Marco — Gol (T1)'));
    await tester.pumpAndSettle();
    expect(tocchiRichiesti, [false, true]);

    // Fuori dall'elenco che scorre: subito sotto il video, anche con la
    // barra del club in cima allo schermo vero.
    final eQui = find.text('È qui');
    expect(eQui, findsOneWidget);
    final video = tester.getRect(find.byType(AspectRatio).first);
    expect(tester.getRect(eQui).top - video.bottom, lessThan(80));
    await tester.tap(eQui);
    await tester.pumpAndSettle();
    expect(finto.allineamenti, hasLength(1));
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

    // La clip parte 15 secondi prima del gol.
    expect(find.text('Nota a 0:25'), findsOneWidget);
    final tavola = find.byType(TavolaDisegnoVideo);
    await tester.dragFrom(tester.getCenter(tavola), const Offset(120, -40));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Qui resta largo');
    await tester.tap(find.text('Salva nota'));
    await tester.pumpAndSettle();

    final nota = finto.note.single;
    expect(nota.secondo, 25);
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

  testWidgets('il commento a voce si registra mentre la clip scorre e si '
      'salva con la nota', (tester) async {
    _schermoGrande(tester);
    final finto = _RepositoryFinto(
      _video([Allineamento(secondo: 40, momento: _gol.creatoIl, periodo: 1)]),
    );
    final lettore = _LettoreFinto();
    await tester.pumpWidget(
      _app(
        finto,
        VideoPartitaScreen(partita: _partita),
        registratore: _RegistratoreFinto(),
        lettore: lettore,
      ),
    );
    await tester.pumpAndSettle();
    final video = tester
        .widget<LettoreYoutube>(find.byType(LettoreYoutube))
        .controllore;

    await tester.tap(find.text('Tiro — Rossi Marco — Gol (T1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disegna'));
    await tester.pumpAndSettle();

    // Si registra: la clip riparte dal punto della nota.
    await tester.ensureVisible(find.text('Registra il commento'));
    await tester.tap(find.text('Registra il commento'));
    await tester.pump();
    expect(find.textContaining('Registro mentre la clip scorre'), findsOne);
    expect(video.secondo, 25);
    expect(video.inRiproduzione, isTrue);
    // Mentre registra la nota non si salva.
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Salva nota'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Ferma'));
    await tester.pumpAndSettle();
    expect(video.inRiproduzione, isFalse);
    expect(find.text('Registrato · 0:42 · si salva con la nota'), findsOne);

    // Si riascolta prima di salvare.
    await tester.tap(find.text('Riascolta'));
    await tester.pump();
    expect(lettore.aperti, ['registrata']);
    expect(video.inRiproduzione, isTrue);
    lettore.allaFine!();
    await tester.pump();
    expect(video.inRiproduzione, isFalse);

    // Solo la voce basta per una nota.
    await tester.tap(find.text('Salva nota'));
    await tester.pumpAndSettle();
    expect(finto.caricate, ['c1/nuova.webm']);
    expect(finto.voci['nuova'], (path: 'c1/nuova.webm', secondi: 42.0));
  });

  testWidgets('dove il browser non registra il tasto non c\'è', (tester) async {
    _schermoGrande(tester);
    final finto = _RepositoryFinto(_video());
    await tester.pumpWidget(_app(finto, VideoPartitaScreen(partita: _partita)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disegna'));
    await tester.pumpAndSettle();
    expect(find.text('Registra il commento'), findsNothing);
    await tester.tap(find.text('Salva nota'));
    await tester.pump();
    expect(
      find.text(
        'Disegna qualcosa sul fotogramma, scrivi la nota o registra un '
        'commento a voce.',
      ),
      findsOneWidget,
    );
  });

  NotaVideo notaConVoce() => NotaVideo(
    id: 'nv',
    videoId: 'v1',
    partitaId: 'p1',
    clubId: 'c1',
    secondo: 162,
    atletaId: 'rossi',
    creataIl: DateTime(2026, 10, 11),
    audioPath: 'c1/nv.webm',
    audioSecondi: 42,
  );

  /// Porta il video sulla nota a 162": la si tocca nell'elenco e il
  /// lettore va avanti fino a lei.
  Future<ControlloreVideo> apriLaNota(WidgetTester tester) async {
    final video = tester
        .widget<LettoreYoutube>(find.byType(LettoreYoutube))
        .controllore;
    await tester.tap(find.text('Nota per Rossi Marco').last);
    await tester.pump();
    for (var t = video.secondo + 0.25; t <= 162 + 1e-9; t += 0.25) {
      video.aggiorna(secondo: t, inRiproduzione: true);
      await tester.pump();
    }
    return video;
  }

  testWidgets('il giocatore ascolta il commento con il video e risponde', (
    tester,
  ) async {
    _schermoGrande(tester);
    final finto = _RepositoryFinto(
      _video([Allineamento(secondo: 40, momento: _gol.creatoIl, periodo: 1)]),
    );
    final lettore = _LettoreFinto();
    await tester.pumpWidget(
      _app(
        finto,
        VideoPartitaScreen(
          partita: _partita,
          modifica: false,
          atletaId: 'rossi',
        ),
        note: [notaConVoce()],
        lettore: lettore,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('commento a voce'), findsWidgets);

    final video = await apriLaNota(tester);
    expect(video.inRiproduzione, isFalse);
    await tester.tap(find.text('Ascolta il commento · 0:42'));
    await tester.pump();
    expect(lettore.aperti, ['url:c1/nv.webm']);
    expect(lettore.suonato, 1);
    expect(video.secondo, 162);
    expect(video.inRiproduzione, isTrue);
    expect(find.text('Ferma il commento'), findsOneWidget);

    // Finito il commento il video si ferma.
    lettore.allaFine!();
    await tester.pump();
    expect(video.inRiproduzione, isFalse);
    expect(find.text('Ascolta il commento · 0:42'), findsOneWidget);

    await tester.tap(find.text('Rispondi all\'allenatore'));
    await tester.pumpAndSettle();
    expect(find.text('La leggono solo i tuoi allenatori.'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Ho capito, dovevo passarla',
    );
    await tester.pump();
    await tester.tap(find.text('Manda'));
    await tester.pumpAndSettle();
    expect(finto.risposte.single.testo, 'Ho capito, dovevo passarla');
    expect(finto.risposte.single.atletaId, 'rossi');
    expect(find.text('La tua risposta'), findsOneWidget);
    expect(find.text('Correggi la risposta'), findsOneWidget);
  });

  testWidgets('l\'allenatore legge la risposta sotto la nota', (tester) async {
    _schermoGrande(tester);
    final finto = _RepositoryFinto(
      _video([Allineamento(secondo: 40, momento: _gol.creatoIl, periodo: 1)]),
    );
    finto.risposte.add(
      RispostaNota(
        id: 'r1',
        notaId: 'nv',
        atletaId: 'rossi',
        testo: 'Ho capito, dovevo passarla',
        aggiornataIl: DateTime(2026, 10, 26),
      ),
    );
    await tester.pumpWidget(
      _app(
        finto,
        VideoPartitaScreen(partita: _partita),
        note: [notaConVoce()],
        lettore: _LettoreFinto(),
      ),
    );
    await tester.pumpAndSettle();
    await apriLaNota(tester);
    // Le risposte arrivano dal server appena la nota si apre.
    await tester.pump();
    expect(find.text('La risposta'), findsOneWidget);
    expect(find.text('Ho capito, dovevo passarla'), findsOneWidget);
    expect(find.text('Rispondi all\'allenatore'), findsNothing);
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
    // Gol a 40", palla persa a 160" (clip 147-168); una nota dentro la
    // clip della palla persa e una subito dopo.
    final finto = _RepositoryFinto(
      _video([Allineamento(secondo: 40, momento: _gol.creatoIl, periodo: 1)]),
    );
    await tester.pumpWidget(
      _app(
        finto,
        VideoPartitaScreen(partita: _partita),
        note: [nota('n1', 162), nota('n2', 170)],
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
    expect(video.secondo, 25);
    expect(find.text('In onda · 1 di 4'), findsOneWidget);

    await scorri(25.25, 49);
    expect(find.text('In onda · 2 di 4'), findsOneWidget);
    expect(video.secondo, 147);

    // Dentro la clip della palla persa la prima nota ferma il video.
    await scorri(147.25, 162);
    expect(video.inRiproduzione, isFalse);
    expect(find.text('Nota n1'), findsOneWidget);
    await tester.tap(find.text('Continua'));
    await tester.pump();

    // Finita la palla persa la nota già vista non si ripete, e la clip
    // della seconda comincia prima del punto in cui siamo: niente salto
    // indietro.
    await scorri(162.25, 168);
    expect(video.secondo, 168);
    expect(find.text('In onda'), findsOneWidget);
    await scorri(168.25, 170);
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
