import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/distinta_repository.dart';
import 'package:coach_vasca/features/pallanuoto/data/eventi_partita_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/campo_tiro.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/partita_live_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/cap_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registra le chiamate invece di salvare.
class _RepositoryFinto implements EventiPartitaRepository {
  final chiamate = <String>[];

  EventoPartita _evento(String tipo, {String? atletaId, String? esito}) =>
      EventoPartita(
        id: 'ev${chiamate.length}',
        partitaId: 'p1',
        clubId: 'c1',
        tipo: tipo,
        squadra: atletaId == null && tipo == 'espulsione'
            ? 'avversaria'
            : 'nostra',
        atletaId: atletaId,
        esito: esito,
        creatoIl: DateTime(2026, 10, 12),
      );

  @override
  Future<EventoPartita> registraTiro({
    required String partitaId,
    required String atletaId,
    required String esito,
    int? periodo,
    String contestoTiro = 'azione',
    double? posX,
    double? posY,
  }) async {
    chiamate.add('tiro $atletaId $esito $contestoTiro');
    return _evento('tiro', atletaId: atletaId, esito: esito);
  }

  @override
  Future<EventoPartita> impostaAssist({
    required String id,
    required String? atletaId,
  }) async {
    chiamate.add('assist $atletaId');
    return _evento('tiro');
  }

  @override
  Future<EventoPartita> registraEspulsione({
    required String partitaId,
    String? atletaId,
    int? numeroCalottinaAvversario,
    int? periodo,
    bool espulsioneDaRigore = false,
  }) async {
    chiamate.add('espulsione ${atletaId ?? 'n.$numeroCalottinaAvversario'}');
    return _evento('espulsione', atletaId: atletaId);
  }

  @override
  Future<EventoPartita> impostaGuadagnataDa({
    required String id,
    required String? atletaId,
  }) async {
    chiamate.add('guadagnata $atletaId');
    return _evento('espulsione');
  }

  @override
  Future<EventoPartita> registraPalla({
    required String partitaId,
    required bool recuperata,
    String? atletaId,
    int? periodo,
  }) async {
    chiamate.add('${recuperata ? 'recuperata' : 'persa'} $atletaId');
    return _evento(recuperata ? 'palla_recuperata' : 'palla_persa');
  }

  @override
  Future<EventoPartita> registraTiroAvversario({
    required String partitaId,
    required String esito,
    int? periodo,
    String contestoTiro = 'azione',
    String? portiereId,
  }) async {
    chiamate.add('avversario $esito $contestoTiro $portiereId');
    return _evento('tiro', esito: esito);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Registra i tempi in porta scritti, come "riga:tempi".
class _DistintaRepositoryFinto implements DistintaRepository {
  final scritture = <String>[];

  @override
  Future<void> impostaTempiInPorta(String id, List<int> tempi) async {
    scritture.add('$id:$tempi');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Atleta _atleta(String id, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'X',
  cognome: cognome,
  dataNascita: DateTime(2011),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

DistintaGiocatore _convocato(
  String atletaId,
  int numero, {
  bool portiere = false,
  List<int> tempiInPorta = const [],
}) => DistintaGiocatore(
  id: 'd$numero',
  partitaId: 'p1',
  atletaId: atletaId,
  clubId: 'c1',
  numeroCalottina: numero,
  capitano: false,
  viceCapitano: false,
  portiere: portiere,
  fuoriquota: false,
  tempiInPorta: tempiInPorta,
);

/// Due portieri (1 Rossi e 13 Verdi) più un giocatore di movimento.
List<DistintaGiocatore> _conDuePortieri() => [
  _convocato('a', 1, portiere: true),
  _convocato('b', 2),
  _convocato('c', 13, portiere: true),
];

Partita _partita(String eventiLive, {bool tracciaTempo = false}) => Partita(
  id: 'p1',
  clubId: 'c1',
  data: DateTime(2026, 10, 12),
  squadraCasa: 'Noi',
  squadraTrasferta: 'Loro',
  numeroMaxConvocati: 15,
  tracciaTempo: tracciaTempo,
  eventiLive: eventiLive,
);

Widget _app(
  _RepositoryFinto repository,
  Widget figlio, {
  List<DistintaGiocatore>? distinta,
  List<EventoPartita> eventi = const [],
  _DistintaRepositoryFinto? distintaRepository,
}) => ProviderScope(
  overrides: [
    eventiPartitaRepositoryProvider.overrideWithValue(repository),
    distintaRepositoryProvider.overrideWithValue(
      distintaRepository ?? _DistintaRepositoryFinto(),
    ),
    eventiPartitaListProvider.overrideWith((ref, id) => Stream.value(eventi)),
    distintaListProvider.overrideWith(
      (ref, id) =>
          Stream.value(distinta ?? [_convocato('a', 2), _convocato('b', 3)]),
    ),
    atletiListProvider.overrideWith(
      (ref, filtro) => Stream.value([
        _atleta('a', 'Rossi'),
        _atleta('b', 'Bianchi'),
        _atleta('c', 'Verdi'),
      ]),
    ),
  ],
  child: MaterialApp(theme: AppTheme.chiaro, home: figlio),
);

Future<void> _apri(
  WidgetTester tester,
  _RepositoryFinto repository,
  String eventiLive, {
  bool tracciaTempo = false,
  List<DistintaGiocatore>? distinta,
  List<EventoPartita> eventi = const [],
  _DistintaRepositoryFinto? distintaRepository,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      repository,
      PartitaLiveScreen(
        partita: _partita(eventiLive, tracciaTempo: tracciaTempo),
      ),
      distinta: distinta,
      eventi: eventi,
      distintaRepository: distintaRepository,
    ),
  );
  await tester.pumpAndSettle();
}

/// Chiude la schermata dentro lo stesso ProviderScope: la barra del club
/// si rimette a posto prima che i provider spariscano.
Future<void> _chiudi(WidgetTester tester, _RepositoryFinto repository) async {
  await tester.pumpWidget(_app(repository, const SizedBox()));
  await tester.pumpAndSettle();
}

/// L'avviso "Evento registrato" copre i bottoni in basso finché non sparisce
/// (4" dopo essere comparso).
Future<void> _senzaAvviso(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

/// La calottina [numero] della nostra squadra (in casa: bianca).
Finder _calottina(int numero) => find.byWidgetPredicate(
  (w) => w is CapBadge && w.numero == numero && w.colore == CapColore.bianca,
);

Finder _calottinaAvversaria(int numero) => find.byWidgetPredicate(
  (w) => w is CapBadge && w.numero == numero && w.colore == CapColore.blu,
);

void main() {
  testWidgets('telefono in orizzontale: tutte le calottine si toccano '
      'senza scorrere', (tester) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository, 'essenziale');
    // Un telefono in orizzontale (812 x 375), come a bordo vasca.
    tester.view.physicalSize = const Size(812, 375);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CampoTiro));
    await tester.pumpAndSettle();
    final altezza = tester.view.physicalSize.height;
    for (var n = 1; n <= 15; n++) {
      for (final calottina in [_calottina(n), _calottinaAvversaria(n)]) {
        expect(calottina, findsOneWidget, reason: 'calottina $n');
        final r = tester.getRect(calottina);
        expect(r.top, greaterThanOrEqualTo(0), reason: 'calottina $n');
        expect(r.bottom, lessThanOrEqualTo(altezza), reason: 'calottina $n');
      }
    }
    expect(tester.takeException(), isNull);
    await _chiudi(tester, repository);
  });

  testWidgets('modalità completa: gol in controfuga, poi l\'assist', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository, 'completa');

    await tester.tap(find.byType(CampoTiro));
    await tester.pumpAndSettle();
    expect(find.text('Chi ha tirato?'), findsOneWidget);
    await tester.tap(_calottina(2));
    await tester.pumpAndSettle();

    expect(find.text('Tiro di Rossi'), findsOneWidget);
    await tester.tap(find.text('Gol in controfuga'));
    await tester.pumpAndSettle();
    expect(repository.chiamate, ['tiro a gol controfuga']);

    // Il gol è già salvato; ora l'assist (non di chi ha segnato).
    expect(find.text('Chi ha fatto l\'assist?'), findsOneWidget);
    await tester.tap(_calottina(2));
    await tester.pumpAndSettle();
    expect(repository.chiamate, hasLength(1));
    await tester.tap(_calottina(3));
    await tester.pumpAndSettle();
    expect(repository.chiamate.last, 'assist b');
    expect(find.text('Chi ha fatto l\'assist?'), findsNothing);
    await _chiudi(tester, repository);
  });

  testWidgets('modalità completa: espulsione guadagnata e palla persa', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository, 'completa');

    await tester.tap(find.text('Espulsione'));
    await tester.pumpAndSettle();
    await tester.tap(_calottinaAvversaria(7));
    await tester.pumpAndSettle();
    expect(find.text('Chi ha guadagnato l\'espulsione?'), findsOneWidget);
    await tester.tap(_calottina(3));
    await tester.pumpAndSettle();
    expect(repository.chiamate, ['espulsione n.7', 'guadagnata b']);
    await _senzaAvviso(tester);

    await tester.tap(find.text('Palla persa'));
    await tester.pumpAndSettle();
    expect(find.text('Chi ha perso palla?'), findsOneWidget);
    await tester.tap(find.text('Senza giocatore'));
    await tester.pumpAndSettle();
    expect(repository.chiamate.last, 'persa null');
    await _chiudi(tester, repository);
  });

  testWidgets('tiro avversario: si distingue il parato e si salva il portiere '
      'in porta', (tester) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository, 'essenziale', distinta: _conDuePortieri());
    // Il primo portiere (numero più basso) è in porta.
    expect(find.text('In porta'), findsOneWidget);
    expect(find.text('Rossi'), findsOneWidget);

    await tester.tap(find.text('Tiro avversario'));
    await tester.pumpAndSettle();
    expect(find.text('Gol'), findsOneWidget);
    expect(find.text('Parato'), findsOneWidget);
    expect(find.text('Palo/fuori'), findsOneWidget);
    expect(find.text('Non gol'), findsNothing);
    await tester.tap(find.text('Parato'));
    await tester.pumpAndSettle();
    expect(repository.chiamate, ['avversario parato azione a']);
    await _chiudi(tester, repository);
  });

  testWidgets('tiro avversario in modalità completa: parato e controfuga', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository, 'completa');
    // Nessun portiere nella distinta: niente chip, portiere nullo.
    expect(find.text('In porta'), findsNothing);

    await tester.tap(find.text('Tiro avversario'));
    await tester.pumpAndSettle();
    expect(find.text('Parato'), findsOneWidget);
    expect(find.text('Gol in controfuga'), findsOneWidget);
    await tester.tap(find.text('Parato'));
    await tester.pumpAndSettle();
    expect(repository.chiamate, ['avversario parato azione null']);
    await _chiudi(tester, repository);
  });

  testWidgets('il chip cambia il portiere dei tiri avversari successivi', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository, 'essenziale', distinta: _conDuePortieri());
    await tester.tap(find.text('In porta'));
    await tester.pumpAndSettle();
    expect(find.text('Chi è in porta?'), findsOneWidget);
    await tester.tap(find.text('Verdi'));
    await tester.pumpAndSettle();
    expect(find.text('Chi è in porta?'), findsNothing);
    expect(find.text('Verdi'), findsOneWidget);

    await tester.tap(find.text('Tiro avversario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gol'));
    await tester.pumpAndSettle();
    expect(repository.chiamate, ['avversario gol azione c']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('portiere_in_acqua_p1'), 'c');
    await _chiudi(tester, repository);
  });

  testWidgets('il portiere salvato sul telefono ha la precedenza', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(
      tester,
      repository,
      'essenziale',
      distinta: _conDuePortieri(),
      prefs: {'portiere_in_acqua_p1': 'c'},
    );
    expect(find.text('Verdi'), findsOneWidget);
    expect(find.text('Rossi'), findsNothing);
    await _chiudi(tester, repository);
  });

  testWidgets('senza salvataggio si riparte dall\'ultimo tiro avversario', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(
      tester,
      repository,
      'essenziale',
      distinta: _conDuePortieri(),
      eventi: [
        EventoPartita(
          id: 'e1',
          partitaId: 'p1',
          clubId: 'c1',
          tipo: 'tiro',
          squadra: 'avversaria',
          esito: 'parato',
          portiereId: 'c',
          creatoIl: DateTime(2026, 10, 12),
        ),
      ],
    );
    expect(find.text('Verdi'), findsOneWidget);
    await _chiudi(tester, repository);
  });

  testWidgets('con due portieri il cambio di tempo chiede chi è in porta', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    final distintaRepository = _DistintaRepositoryFinto();
    await _apri(
      tester,
      repository,
      'essenziale',
      tracciaTempo: true,
      distinta: _conDuePortieri(),
      distintaRepository: distintaRepository,
    );
    // Aperta senza tempo scelto: parte dal primo, con Rossi in porta.
    expect(distintaRepository.scritture, ['d1:[1]']);

    await tester.tap(find.text('T2'));
    await tester.pumpAndSettle();
    expect(find.text('Chi è in porta nel 2° tempo?'), findsOneWidget);
    await tester.tap(find.text('Verdi'));
    await tester.pumpAndSettle();
    expect(find.text('Chi è in porta nel 2° tempo?'), findsNothing);
    expect(distintaRepository.scritture, ['d1:[1]', 'd13:[2]']);

    // Chiudere la domanda senza scegliere lascia Verdi in porta.
    await tester.tap(find.text('T3'));
    await tester.pumpAndSettle();
    expect(find.text('Chi è in porta nel 3° tempo?'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Chi è in porta nel 3° tempo?'), findsNothing);
    expect(distintaRepository.scritture.last, 'd13:[2, 3]');
    await _chiudi(tester, repository);
  });

  testWidgets('con un solo portiere il cambio di tempo non chiede nulla e '
      'il tempo si scrive una volta', (tester) async {
    final repository = _RepositoryFinto();
    final distintaRepository = _DistintaRepositoryFinto();
    await _apri(
      tester,
      repository,
      'essenziale',
      tracciaTempo: true,
      distinta: [_convocato('a', 1, portiere: true), _convocato('b', 2)],
      distintaRepository: distintaRepository,
    );
    expect(distintaRepository.scritture, ['d1:[1]']);

    await tester.tap(find.text('T2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chi è in porta'), findsNothing);
    expect(distintaRepository.scritture, ['d1:[1]', 'd1:[1, 2]']);

    // Tornare a un tempo già scritto non riscrive niente.
    await tester.tap(find.text('T1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('T2'));
    await tester.pumpAndSettle();
    expect(distintaRepository.scritture, hasLength(2));
    await _chiudi(tester, repository);
  });

  testWidgets('il tempo di default è il più alto fra gli eventi', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    final distintaRepository = _DistintaRepositoryFinto();
    await _apri(
      tester,
      repository,
      'essenziale',
      tracciaTempo: true,
      distinta: [_convocato('a', 1, portiere: true)],
      distintaRepository: distintaRepository,
      eventi: [
        for (final periodo in [2, 3, null])
          EventoPartita(
            id: 'e$periodo',
            partitaId: 'p1',
            clubId: 'c1',
            tipo: 'tiro',
            squadra: 'nostra',
            esito: 'gol',
            periodo: periodo,
            creatoIl: DateTime(2026, 10, 12),
          ),
      ],
    );
    expect(distintaRepository.scritture, ['d1:[3]']);
    await _chiudi(tester, repository);
  });

  testWidgets('telefono in orizzontale con portieri e tempi: tutto entra', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(
      tester,
      repository,
      'essenziale',
      tracciaTempo: true,
      distinta: _conDuePortieri(),
      distintaRepository: _DistintaRepositoryFinto(),
    );
    tester.view.physicalSize = const Size(812, 375);
    await tester.pumpAndSettle();
    expect(find.text('In porta'), findsOneWidget);
    await tester.tap(find.byType(CampoTiro));
    await tester.pumpAndSettle();
    final altezza = tester.view.physicalSize.height;
    for (var n = 1; n <= 15; n++) {
      // .last: le calottine 1 e 13 sono anche nel chip del portiere.
      final r = tester.getRect(_calottina(n).last);
      expect(r.top, greaterThanOrEqualTo(0), reason: 'calottina $n');
      expect(r.bottom, lessThanOrEqualTo(altezza), reason: 'calottina $n');
    }
    expect(tester.takeException(), isNull);
    await _chiudi(tester, repository);
  });

  testWidgets('modalità essenziale: com\'era, senza passi in più', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository, 'essenziale');
    expect(find.text('Palla persa'), findsNothing);

    await tester.tap(find.byType(CampoTiro));
    await tester.pumpAndSettle();
    await tester.tap(_calottina(2));
    await tester.pumpAndSettle();
    expect(find.text('Gol in controfuga'), findsNothing);
    await tester.tap(find.text('Gol'));
    await tester.pumpAndSettle();
    expect(repository.chiamate, ['tiro a gol azione']);
    expect(find.text('Chi ha fatto l\'assist?'), findsNothing);
    await _senzaAvviso(tester);

    await tester.tap(find.text('Espulsione'));
    await tester.pumpAndSettle();
    await tester.tap(_calottinaAvversaria(7));
    await tester.pumpAndSettle();
    expect(repository.chiamate.last, 'espulsione n.7');
    expect(find.text('Chi ha guadagnato l\'espulsione?'), findsNothing);
    await _chiudi(tester, repository);
  });
}
