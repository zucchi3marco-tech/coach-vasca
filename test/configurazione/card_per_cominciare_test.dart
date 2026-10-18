import 'package:coach_vasca/features/club/application/membri_club_providers.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/configurazione/application/configurazione_providers.dart';
import 'package:coach_vasca/features/configurazione/data/configurazione_repository.dart';
import 'package:coach_vasca/features/configurazione/domain/stato_configurazione.dart';
import 'package:coach_vasca/features/configurazione/presentation/card_per_cominciare.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _aMeta = StatoConfigurazione(
  squadre: 2,
  altriAllenatori: 0,
  invitiAllenatori: false,
  allenaDaSolo: false,
  atleti: 12,
  atletiConAccount: 0,
  codiciAtleti: false,
);

const _tuttoFatto = StatoConfigurazione(
  squadre: 2,
  altriAllenatori: 1,
  invitiAllenatori: true,
  allenaDaSolo: false,
  atleti: 12,
  atletiConAccount: 3,
  codiciAtleti: true,
);

Future<void> _monta(
  WidgetTester tester, {
  RuoloClub ruolo = RuoloClub.responsabile,
  StatoConfigurazione stato = _aMeta,
  void Function(PassoConfigurazione)? onApriPasso,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mioRuoloProvider.overrideWith((ref, _) async => ruolo),
        statoConfigurazioneProvider.overrideWith((ref, _) async => stato),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        home: Scaffold(
          body: ListView(
            children: [
              CardPerCominciare(
                clubId: 'c1',
                onApriPasso: onApriPasso ?? (_) {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('il responsabile vede i passi con le spunte', (tester) async {
    await _monta(tester);

    expect(find.text('Per cominciare'), findsOneWidget);
    expect(find.textContaining('3 di 5 fatti'), findsOneWidget);
    // Fatti: il titolo del passo; da fare: cosa fare.
    expect(find.text('Il club'), findsOneWidget);
    expect(find.text('Le squadre'), findsOneWidget);
    expect(find.text('Gli atleti'), findsOneWidget);
    expect(find.text('Invita chi allena con te'), findsOneWidget);
    expect(find.text('Dai ai ragazzi i loro codici'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
  });

  testWidgets('un passo da fare si apre, uno fatto no', (tester) async {
    final aperti = <PassoConfigurazione>[];
    await _monta(tester, onApriPasso: aperti.add);

    await tester.tap(find.text('Invita chi allena con te'));
    await tester.tap(find.text('Gli atleti'));
    await tester.tap(find.text('Dai ai ragazzi i loro codici'));
    await tester.pump();

    expect(aperti, [
      PassoConfigurazione.allenatori,
      PassoConfigurazione.codici,
    ]);
  });

  testWidgets('non c\'è per un allenatore o un assistente', (tester) async {
    await _monta(tester, ruolo: RuoloClub.allenatore);
    expect(find.text('Per cominciare'), findsNothing);

    await _monta(tester, ruolo: RuoloClub.assistente);
    expect(find.text('Per cominciare'), findsNothing);
  });

  testWidgets('non c\'è quando è tutto fatto', (tester) async {
    await _monta(tester, stato: _tuttoFatto);
    expect(find.text('Per cominciare'), findsNothing);
  });

  testWidgets('non c\'è se lo stato non si legge', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mioRuoloProvider.overrideWith(
            (ref, _) async => RuoloClub.responsabile,
          ),
          statoConfigurazioneProvider.overrideWith(
            (ref, _) async => throw StateError('senza rete'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: Scaffold(
            body: CardPerCominciare(clubId: 'c1', onApriPasso: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Per cominciare'), findsNothing);
  });

  testWidgets('"Nascondi" la toglie e la ricorda sul dispositivo', (
    tester,
  ) async {
    await _monta(tester);

    await tester.tap(find.text('Nascondi'));
    await tester.pumpAndSettle();

    expect(find.text('Per cominciare'), findsNothing);
    expect(find.textContaining('Il mio club'), findsOneWidget);
    expect(await const PreferenzeConfigurazione().nascosta('c1'), isTrue);
  });

  testWidgets('già nascosta non c\'è', (tester) async {
    SharedPreferences.setMockInitialValues({
      'configurazione_nascosta_c1': true,
    });
    await _monta(tester);

    expect(find.text('Per cominciare'), findsNothing);
  });
}
