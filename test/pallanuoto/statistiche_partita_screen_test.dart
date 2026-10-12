import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/nomi_squadra_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/confronto_partite_screen.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/statistiche_partita_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

var _n = 0;

EventoPartita _e(
  String partita,
  String tipo, {
  String squadra = 'nostra',
  String? atleta,
  String? esito,
  String contesto = 'azione',
  int? numero,
  String? assist,
}) => EventoPartita(
  id: 'e${_n++}',
  partitaId: partita,
  clubId: 'c1',
  tipo: tipo,
  squadra: squadra,
  atletaId: atleta,
  esito: esito,
  contestoTiro: contesto,
  numeroCalottinaAvversario: numero,
  assistDi: assist,
  creatoIl: DateTime(2026, 10, 12),
);

Partita _partita(String id, String avversario, {String eventi = 'completa'}) =>
    Partita(
      id: id,
      clubId: 'c1',
      data: DateTime(2026, 10, id == 'p1' ? 3 : 10),
      squadraCasa: 'Noi',
      squadraTrasferta: avversario,
      numeroMaxConvocati: 15,
      eventiLive: eventi,
    );

final _eventi = {
  'p1': [
    _e('p1', 'espulsione', squadra: 'avversaria', numero: 4),
    _e('p1', 'espulsione', squadra: 'avversaria', numero: 6),
    _e(
      'p1',
      'tiro',
      atleta: 'a',
      esito: 'gol',
      contesto: 'superiorita',
      assist: 'b',
    ),
    _e('p1', 'palla_persa', atleta: 'b'),
  ],
  'p2': [
    _e('p2', 'tiro', atleta: 'a', esito: 'non_gol'),
    _e('p2', 'tiro', squadra: 'avversaria', esito: 'gol'),
  ],
};

Widget _app(Widget figlio) => ProviderScope(
  overrides: [
    eventiPartitaListProvider.overrideWith(
      (ref, id) => Stream.value(_eventi[id] ?? const []),
    ),
    distintaListProvider.overrideWith(
      (ref, id) => Stream.value([
        for (final (i, atleta) in ['a', 'b'].indexed)
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
    nomiSquadraProvider.overrideWith(
      (ref, clubId) async => {'a': 'Rossi Marco', 'b': 'Bianchi Luca'},
    ),
    partiteListProvider.overrideWith(
      (ref, clubId) => Stream.value([
        _partita('p1', 'Posillipo'),
        _partita('p2', 'Recco', eventi: 'essenziale'),
      ]),
    ),
  ],
  child: MaterialApp(theme: AppTheme.chiaro, home: figlio),
);

void main() {
  testWidgets('le statistiche della partita con i numeri completi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(StatistichePartitaScreen(partita: _partita('p1', 'Posillipo'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Superiorità'), findsOneWidget);
    // Un gol su due superiorità.
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('50%'), findsWidgets);
    expect(find.text('Assist'), findsOneWidget);
    expect(find.text('Palle perse'), findsOneWidget);
    expect(find.text('1 assist'), findsOneWidget);
    expect(find.text('perse 1'), findsOneWidget);

    // Il confronto si apre scegliendo l'altra partita.
    await tester.tap(find.byTooltip('Confronta con un\'altra partita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('vs Recco'));
    await tester.pumpAndSettle();
    expect(find.byType(ConfrontoPartiteScreen), findsOneWidget);
    expect(find.text('1–0'), findsOneWidget);
    expect(find.text('0–1'), findsOneWidget);
    expect(find.text('1/2 (50%)'), findsOneWidget);
    // Una delle due è completa: ci sono anche assist e palle perse.
    expect(find.text('Palle perse'), findsOneWidget);
  });
}
