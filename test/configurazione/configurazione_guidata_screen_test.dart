import 'dart:async';

import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/club/application/membri_club_providers.dart';
import 'package:coach_vasca/features/club/data/membri_club_repository.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/configurazione/application/configurazione_providers.dart';
import 'package:coach_vasca/features/configurazione/data/configurazione_repository.dart';
import 'package:coach_vasca/features/configurazione/domain/stato_configurazione.dart';
import 'package:coach_vasca/features/configurazione/presentation/configurazione_guidata_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/data/gruppi_repository.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/error_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _club = Club(id: 'c1', nome: 'Mako Pallanuoto', sport: 'pallanuoto');

/// Le squadre del telefono: si leggono come flusso e si creano come sul
/// repository vero, annotando cosa gli si chiede.
class _GruppiFinti implements GruppiRepository {
  _GruppiFinti([List<Gruppo> iniziali = const []]) : elenco = [...iniziali];

  final List<Gruppo> elenco;
  final _cambi = StreamController<List<Gruppo>>.broadcast();
  final creati = <({String nome, int ordine})>[];

  /// Cosa dice `configurazioneInCorsoProvider` ogni volta che si crea una
  /// squadra: deve già essere il club, altrimenti HomeScreen cambia schermata.
  final inCorsoAllaCreazione = <String?>[];
  String? Function()? leggiInCorso;

  /// Fa fallire la creazione numero N (0 = la prima) di questo giro.
  int? falliscAllaCreazione;

  Stream<List<Gruppo>> flusso() async* {
    yield [...elenco];
    yield* _cambi.stream;
  }

  @override
  Future<Gruppo> createGruppo({
    required String clubId,
    required String nome,
    required int ordine,
  }) async {
    inCorsoAllaCreazione.add(leggiInCorso?.call());
    if (falliscAllaCreazione == creati.length) {
      falliscAllaCreazione = null;
      throw Exception('non si crea');
    }
    creati.add((nome: nome, ordine: ordine));
    final gruppo = Gruppo(
      id: 'nuovo${elenco.length}',
      clubId: clubId,
      nome: nome,
      ordine: ordine,
    );
    elenco.add(gruppo);
    _cambi.add([...elenco]);
    return gruppo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Il server dei membri del club: crea i codici d'invito.
class _ClubFinto implements MembriClubRepository {
  final inviti = <(String, RuoloClub)>[];

  @override
  Future<String> generaInvito(String clubId, RuoloClub ruolo) async {
    inviti.add((clubId, ruolo));
    return 'ABCDE12345';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ConfigurazioneFinta implements ConfigurazioneRepository {
  int letture = 0;

  @override
  Future<bool> ciSonoInvitiAllenatori(String clubId) async {
    letture++;
    return false;
  }

  @override
  Future<bool> ciSonoCodiciAtleti(String clubId) async {
    letture++;
    return false;
  }
}

Atleta _atleta(String id, {String? userId}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Nome',
  cognome: id,
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  userId: userId,
);

const _u14 = Gruppo(id: 'g1', clubId: 'c1', nome: 'U14', ordine: 3);

class _Prova {
  _Prova({
    List<Gruppo> gruppi = const [],
    this.atleti = const [],
    this.membri = const [],
  }) : gruppiFinti = _GruppiFinti(gruppi) {
    addTearDown(gruppiFinti._cambi.close);
  }

  final _GruppiFinti gruppiFinti;
  final List<Atleta> atleti;
  final List<MembroClub> membri;
  final server = _ClubFinto();
  final configurazione = _ConfigurazioneFinta();
  int fine = 0;

  List<Override> get overrides => [
    gruppiListProvider.overrideWith((ref, _) => gruppiFinti.flusso()),
    gruppiRepositoryProvider.overrideWithValue(gruppiFinti),
    atletiListProvider.overrideWith((ref, _) => Stream.value(atleti)),
    membriClubProvider.overrideWith((ref, _) async => membri),
    membriClubRepositoryProvider.overrideWithValue(server),
    mioRuoloProvider.overrideWith((ref, _) async => RuoloClub.responsabile),
    configurazioneRepositoryProvider.overrideWithValue(configurazione),
  ];

  ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(ConfigurazioneGuidataScreen)),
  );

  String? inCorso(WidgetTester tester) =>
      container(tester).read(configurazioneInCorsoProvider);
}

Future<void> _passa(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Apre la configurazione dentro un Scaffold, come nel corpo di HomeScreen
/// (o come pagina, con [comePagina]).
Future<_Prova> _apri(
  WidgetTester tester, {
  PassoConfigurazione daPasso = PassoConfigurazione.squadre,
  bool comePagina = false,
  List<Gruppo> gruppi = const [],
  List<Atleta> atleti = const [],
  List<MembroClub> membri = const [],
}) async {
  final prova = _Prova(gruppi: gruppi, atleti: atleti, membri: membri);
  // Telefono, alto abbastanza per tutto il passo senza scorrere.
  tester.view.physicalSize = const Size(360, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final schermata = ConfigurazioneGuidataScreen(
    club: _club,
    daPasso: daPasso,
    comePagina: comePagina,
    onFine: () => prova.fine++,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: prova.overrides,
      child: MaterialApp(
        theme: AppTheme.chiaro,
        home: comePagina ? schermata : Scaffold(body: schermata),
      ),
    ),
  );
  prova.gruppiFinti.leggiInCorso = () => prova.inCorso(tester);
  await _passa(tester);
  return prova;
}

void _vediPasso(int numero, String titolo) {
  expect(find.text('Passo $numero di 5'), findsOneWidget);
  expect(find.text(titolo), findsOneWidget);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
  });

  group('le squadre', () {
    testWidgets('senza squadre: categorie e nomi, tutto in ordine', (
      tester,
    ) async {
      final prova = await _apri(tester);

      _vediPasso(2, 'Le squadre');
      expect(find.text('Indietro'), findsNothing);
      expect(find.text('Lo faccio dopo'), findsNothing);
      // Le categorie della pallanuoto, non quelle del nuoto.
      expect(find.text('U14'), findsOneWidget);
      expect(find.text('Es.A'), findsNothing);

      // Toccate in disordine: si creano nell'ordine dell'elenco.
      await tester.tap(find.text('U16'));
      await tester.pump();
      await tester.tap(find.text('U12'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextFormField).first,
        '  Master over 40 ',
      );
      await tester.tap(find.text('Avanti'));
      await _passa(tester);

      expect(prova.gruppiFinti.creati, [
        (nome: 'U12', ordine: 1),
        (nome: 'U16', ordine: 2),
        (nome: 'Master over 40', ordine: 3),
      ]);
      // Il percorso era già "in corso" quando è comparsa la prima squadra.
      expect(prova.gruppiFinti.inCorsoAllaCreazione, ['c1', 'c1', 'c1']);
      expect(prova.inCorso(tester), 'c1');
      _vediPasso(3, 'Gli allenatori');
      expect(find.text('Indietro'), findsOneWidget);
    });

    testWidgets('senza nessuna squadra: errore e nessuna creata', (
      tester,
    ) async {
      final prova = await _apri(tester);

      await tester.tap(find.text('Avanti'));
      await _passa(tester);

      expect(find.text('Aggiungi almeno una squadra'), findsOneWidget);
      expect(prova.gruppiFinti.creati, isEmpty);
      expect(prova.inCorso(tester), isNull);
      _vediPasso(2, 'Le squadre');
    });

    testWidgets(
      'squadre già create: elenco, nessun modulo, Avanti passa oltre',
      (tester) async {
        final prova = await _apri(tester, gruppi: const [_u14]);

        expect(find.text('U14'), findsOneWidget);
        expect(find.text('Aggiungi un\'altra squadra'), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byType(RawChip), findsNothing);

        await tester.tap(find.text('Avanti'));
        await _passa(tester);

        expect(prova.gruppiFinti.creati, isEmpty);
        _vediPasso(3, 'Gli allenatori');
      },
    );

    testWidgets(
      '«Aggiungi un\'altra squadra» continua l\'ordine di quelle che ci sono',
      (tester) async {
        final prova = await _apri(tester, gruppi: const [_u14]);

        await tester.tap(find.text('Aggiungi un\'altra squadra'));
        await _passa(tester);
        // U14 c'è già: non si propone di nuovo.
        expect(find.widgetWithText(RawChip, 'U14'), findsNothing);
        await tester.tap(find.text('U12'));
        await tester.pump();
        await tester.tap(find.text('Avanti'));
        await _passa(tester);

        expect(prova.gruppiFinti.creati, [(nome: 'U12', ordine: 4)]);
        _vediPasso(3, 'Gli allenatori');
      },
    );

    testWidgets('come pagina non segna il percorso "in corso"', (tester) async {
      final prova = await _apri(tester, comePagina: true);

      expect(find.byType(AppBar), findsOneWidget);
      await tester.tap(find.text('U14'));
      await tester.pump();
      await tester.tap(find.text('Avanti'));
      await _passa(tester);

      expect(prova.gruppiFinti.creati, hasLength(1));
      expect(prova.inCorso(tester), isNull);
      expect(prova.gruppiFinti.inCorsoAllaCreazione, [null]);
    });

    testWidgets('se una squadra non si crea, le già create non si ripetono', (
      tester,
    ) async {
      final prova = await _apri(tester);
      prova.gruppiFinti.falliscAllaCreazione = 1;

      await tester.tap(find.text('U12'));
      await tester.pump();
      await tester.tap(find.text('U14'));
      await tester.pump();
      await tester.tap(find.text('Avanti'));
      await _passa(tester);

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(prova.gruppiFinti.creati.map((c) => c.nome), ['U12']);
      _vediPasso(2, 'Le squadre');

      await tester.tap(find.text('Avanti'));
      await _passa(tester);

      expect(prova.gruppiFinti.creati.map((c) => c.nome), ['U12', 'U14']);
      expect(prova.gruppiFinti.creati.last.ordine, 2);
      expect(find.byType(ErrorBanner), findsNothing);
      _vediPasso(3, 'Gli allenatori');
    });
  });

  group('gli allenatori', () {
    testWidgets('«Alleno da solo» si ricorda e porta agli atleti', (
      tester,
    ) async {
      final prova = await _apri(
        tester,
        daPasso: PassoConfigurazione.allenatori,
        gruppi: const [_u14],
      );
      expect(find.textContaining('Tu resti il responsabile'), findsOneWidget);
      expect(find.text('Avanti'), findsNothing);
      final letture = prova.configurazione.letture;

      await tester.tap(find.text('Alleno da solo'));
      await _passa(tester);

      expect(await const PreferenzeConfigurazione().allenaDaSolo('c1'), isTrue);
      _vediPasso(4, 'Gli atleti');
      // Lo stato è stato riletto: il passo conta fatto anche per la scheda
      // "Per cominciare".
      expect(prova.configurazione.letture, greaterThan(letture));
    });

    testWidgets('un invito crea il codice, lo ricorda e fa comparire Avanti', (
      tester,
    ) async {
      final prova = await _apri(
        tester,
        daPasso: PassoConfigurazione.allenatori,
        gruppi: const [_u14],
      );
      final letture = prova.configurazione.letture;

      await tester.tap(find.text('Invita un allenatore o un assistente'));
      await _passa(tester);
      await tester.tap(find.widgetWithText(ListTile, 'Assistente'));
      await _passa(tester);
      expect(find.text('ABCDE12345'), findsOneWidget);
      await tester.tap(find.text('Chiudi'));
      await _passa(tester);

      expect(prova.server.inviti, [('c1', RuoloClub.assistente)]);
      expect(find.text('Codice per un assistente creato'), findsOneWidget);
      expect(prova.configurazione.letture, greaterThan(letture));
      // Ora il passo è fatto: si va avanti, non si lascia per dopo.
      expect(find.text('Avanti'), findsOneWidget);
      expect(find.text('Lo faccio dopo'), findsNothing);
      expect(find.text('Alleno da solo'), findsNothing);

      await tester.tap(find.text('Avanti'));
      await _passa(tester);
      _vediPasso(4, 'Gli atleti');
    });

    testWidgets('nella demo gli inviti sono spenti', (tester) async {
      dotenv.loadFromString(envString: 'MODALITA_DEMO=true');
      await _apri(tester, daPasso: PassoConfigurazione.allenatori);

      expect(find.text('Nella demo gli inviti non si creano'), findsOneWidget);
      final invito = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Invita un allenatore o un assistente'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(invito.onPressed, isNull);
    });
  });

  group('gli atleti e i codici', () {
    testWidgets('gli atleti: quanti ce ne sono e come aggiungerli', (
      tester,
    ) async {
      await _apri(
        tester,
        daPasso: PassoConfigurazione.atleti,
        atleti: [_atleta('a1'), _atleta('a2')],
      );

      _vediPasso(4, 'Gli atleti');
      expect(find.text('Nel club ci sono 2 atleti'), findsOneWidget);
      expect(find.text('Da un foglio Excel'), findsOneWidget);
      expect(find.text('Uno alla volta'), findsOneWidget);
      // Ci sono atleti: si va avanti.
      expect(find.text('Avanti'), findsOneWidget);
      expect(find.text('Lo faccio dopo'), findsNothing);
    });

    testWidgets('senza atleti si può lasciare per dopo', (tester) async {
      await _apri(tester, daPasso: PassoConfigurazione.atleti);

      expect(find.text('Ancora nessun atleta'), findsOneWidget);
      expect(find.text('Avanti'), findsNothing);

      await tester.tap(find.text('Lo faccio dopo'));
      await _passa(tester);

      _vediPasso(5, 'I codici');
    });

    testWidgets('i codici senza atleti: prima gli atleti', (tester) async {
      final prova = await _apri(tester, daPasso: PassoConfigurazione.codici);

      expect(
        find.text(
          'Prima aggiungi gli atleti: poi qui prepari il foglio con il codice '
          'di ognuno.',
        ),
        findsOneWidget,
      );
      expect(find.text('Prepara il foglio dei codici'), findsNothing);

      await tester.tap(find.text('Torna agli atleti'));
      await _passa(tester);
      _vediPasso(4, 'Gli atleti');

      // "Lo faccio dopo" sull'ultimo passo chiude la configurazione.
      await tester.tap(find.text('Lo faccio dopo'));
      await _passa(tester);
      expect(prova.fine, 0);
      await tester.tap(find.text('Lo faccio dopo'));
      await _passa(tester);
      expect(prova.fine, 1);
    });

    testWidgets('i codici con gli atleti: il foglio e chi ha già l\'account', (
      tester,
    ) async {
      await _apri(
        tester,
        daPasso: PassoConfigurazione.codici,
        atleti: [
          _atleta('a1', userId: 'u1'),
          _atleta('a2'),
          _atleta('a3'),
        ],
      );

      expect(
        find.textContaining('I codici valgono 30 giorni.'),
        findsOneWidget,
      );
      expect(find.text('1 atleta ha già l\'account'), findsOneWidget);
      expect(find.text('Prepara il foglio dei codici'), findsOneWidget);
    });

    testWidgets('«Fine» chiude quando i codici sono fatti', (tester) async {
      final prova = await _apri(
        tester,
        daPasso: PassoConfigurazione.codici,
        atleti: [_atleta('a1', userId: 'u1')],
      );

      expect(find.text('Lo faccio dopo'), findsNothing);
      await tester.tap(find.text('Fine'));
      await _passa(tester);

      expect(prova.fine, 1);
    });

    testWidgets('nella demo il foglio dei codici è spento', (tester) async {
      dotenv.loadFromString(envString: 'MODALITA_DEMO=true');
      await _apri(
        tester,
        daPasso: PassoConfigurazione.codici,
        atleti: [_atleta('a1')],
      );

      expect(find.text('Nella demo i codici non si creano'), findsOneWidget);
      final foglio = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Prepara il foglio dei codici'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(foglio.onPressed, isNull);
    });
  });

  group('muoversi fra i passi', () {
    testWidgets('«Indietro» torna al passo prima, mai al club', (tester) async {
      await _apri(
        tester,
        daPasso: PassoConfigurazione.atleti,
        gruppi: const [_u14],
      );

      await tester.tap(find.text('Indietro'));
      await _passa(tester);
      _vediPasso(3, 'Gli allenatori');

      await tester.tap(find.text('Indietro'));
      await _passa(tester);
      _vediPasso(2, 'Le squadre');
      expect(find.text('Indietro'), findsNothing);
    });

    testWidgets('si parte dalle squadre anche se si chiede il club', (
      tester,
    ) async {
      await _apri(tester, daPasso: PassoConfigurazione.club);

      _vediPasso(2, 'Le squadre');
    });
  });
}
