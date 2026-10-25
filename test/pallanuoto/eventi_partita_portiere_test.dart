import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/eventi_partita_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/eventi_partita_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registra le correzioni di portiere e di esito.
class _RepositoryFinto implements EventiPartitaRepository {
  final chiamate = <String>[];

  @override
  Future<EventoPartita> impostaPortiere({
    required String id,
    required String? atletaId,
  }) async {
    chiamate.add('portiere $id $atletaId');
    return _tiro(portiereId: atletaId);
  }

  @override
  Future<EventoPartita> modificaEsito({
    required String id,
    required String esito,
  }) async {
    chiamate.add('esito $id $esito');
    return _tiro();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EventoPartita _tiro({String? portiereId, String esito = 'non_gol'}) =>
    EventoPartita(
      id: 'e1',
      partitaId: 'p1',
      clubId: 'c1',
      tipo: 'tiro',
      squadra: 'avversaria',
      esito: esito,
      portiereId: portiereId,
      creatoIl: DateTime(2026, 10, 12),
    );

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

DistintaGiocatore _convocato(String atletaId, int numero, bool portiere) =>
    DistintaGiocatore(
      id: 'd$numero',
      partitaId: 'p1',
      atletaId: atletaId,
      clubId: 'c1',
      numeroCalottina: numero,
      capitano: false,
      viceCapitano: false,
      portiere: portiere,
      fuoriquota: false,
    );

final _partita = Partita(
  id: 'p1',
  clubId: 'c1',
  data: DateTime(2026, 10, 12),
  squadraCasa: 'Noi',
  squadraTrasferta: 'Loro',
  numeroMaxConvocati: 15,
  tracciaTempo: false,
  eventiLive: 'essenziale',
);

Widget _app(_RepositoryFinto repository, EventoPartita evento, Widget figlio) =>
    ProviderScope(
      overrides: [
        eventiPartitaRepositoryProvider.overrideWithValue(repository),
        eventiPartitaListProvider.overrideWith(
          (ref, id) => Stream.value([evento]),
        ),
        distintaListProvider.overrideWith(
          (ref, id) => Stream.value([
            _convocato('a', 1, true),
            _convocato('b', 2, false),
            _convocato('c', 13, true),
          ]),
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

Future<_RepositoryFinto> _apri(
  WidgetTester tester,
  EventoPartita evento,
) async {
  final repository = _RepositoryFinto();
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(repository, evento, EventiPartitaScreen(partita: _partita)),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// Chiude la schermata dentro lo stesso ProviderScope (la barra del club
/// si rimette a posto prima che i provider spariscano).
Future<void> _chiudi(WidgetTester tester, _RepositoryFinto repository) async {
  await tester.pumpWidget(_app(repository, _tiro(), const SizedBox()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un tiro avversario mostra chi era in porta', (tester) async {
    final repository = await _apri(tester, _tiro(portiereId: 'a'));
    expect(find.text('In porta: Rossi'), findsOneWidget);
    // Un vecchio "non gol" si legge ancora.
    expect(find.textContaining('Non gol'), findsOneWidget);
    await _chiudi(tester, repository);
  });

  testWidgets('si corregge il portiere fra quelli della partita', (
    tester,
  ) async {
    final repository = await _apri(tester, _tiro(portiereId: 'a'));
    await tester.tap(find.textContaining('Tiro avversario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambia il portiere'));
    await tester.pumpAndSettle();
    expect(find.text('Chi era in porta?'), findsOneWidget);
    // Solo i portieri: Bianchi non è fra le scelte.
    expect(find.text('Bianchi X'), findsNothing);
    await tester.tap(find.text('Verdi X'));
    await tester.pumpAndSettle();
    expect(repository.chiamate, ['portiere e1 c']);
    await _chiudi(tester, repository);
  });

  testWidgets('l\'esito di un tiro avversario si corregge con parato e '
      'palo/fuori', (tester) async {
    final repository = await _apri(tester, _tiro());
    await tester.tap(find.textContaining('Tiro avversario'));
    await tester.pumpAndSettle();
    expect(find.text('Parato'), findsOneWidget);
    expect(find.text('Palo/fuori'), findsOneWidget);
    await tester.tap(find.text('Parato'));
    await tester.pumpAndSettle();
    expect(repository.chiamate, ['esito e1 parato']);
    await _chiudi(tester, repository);
  });
}
