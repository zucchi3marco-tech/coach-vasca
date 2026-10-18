import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/club/application/membri_club_providers.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/configurazione/application/configurazione_providers.dart';
import 'package:coach_vasca/features/configurazione/domain/stato_configurazione.dart';
import 'package:coach_vasca/features/configurazione/presentation/card_per_cominciare.dart';
import 'package:coach_vasca/features/configurazione/presentation/configurazione_guidata_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La configurazione su un telefono stretto (360 px) con il testo di
/// sistema ingrandito, nei due temi: niente deve uscire dallo schermo (un
/// overflow fa fallire il test).

const _club = Club(id: 'c1', nome: 'Mako Pallanuoto', sport: 'pallanuoto');

const _niente = StatoConfigurazione(
  squadre: 0,
  altriAllenatori: 0,
  invitiAllenatori: false,
  allenaDaSolo: false,
  atleti: 0,
  atletiConAccount: 0,
  codiciAtleti: false,
);

Atleta _atleta(String id) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Nome',
  cognome: id,
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

Future<void> _monta(
  WidgetTester tester,
  Widget figlio, {
  required ThemeData tema,
  List<Gruppo> gruppi = const [],
  List<Atleta> atleti = const [],
  StatoConfigurazione stato = _niente,
}) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gruppiListProvider.overrideWith((ref, _) => Stream.value(gruppi)),
        atletiListProvider.overrideWith((ref, _) => Stream.value(atleti)),
        mioRuoloProvider.overrideWith((ref, _) async => RuoloClub.responsabile),
        statoConfigurazioneProvider.overrideWith((ref, _) async => stato),
      ],
      child: MaterialApp(
        theme: tema,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(body: figlio),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (nomeTema, tema) in [
    ('chiaro', AppTheme.chiaro),
    ('scuro', AppTheme.scuro),
  ]) {
    group('tema $nomeTema', () {
      for (final passo in PassoConfigurazione.values.skip(1)) {
        testWidgets('${passo.titolo}, club nuovo', (tester) async {
          await _monta(
            tester,
            ConfigurazioneGuidataScreen(
              club: _club,
              daPasso: passo,
              onFine: () {},
            ),
            tema: tema,
          );
          expect(find.text(passo.titolo), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('${passo.titolo}, come pagina e con i dati', (
          tester,
        ) async {
          await _monta(
            tester,
            ConfigurazioneGuidataScreen(
              club: _club,
              daPasso: passo,
              comePagina: true,
              onFine: () {},
            ),
            tema: tema,
            gruppi: const [
              Gruppo(id: 'g1', clubId: 'c1', nome: 'Under 14', ordine: 1),
              Gruppo(
                id: 'g2',
                clubId: 'c1',
                nome: 'Prima squadra Serie B',
                ordine: 2,
              ),
            ],
            atleti: [for (var i = 0; i < 12; i++) _atleta('a$i')],
            stato: const StatoConfigurazione(
              squadre: 2,
              altriAllenatori: 0,
              invitiAllenatori: true,
              allenaDaSolo: false,
              atleti: 12,
              atletiConAccount: 0,
              codiciAtleti: true,
            ),
          );
          expect(find.text(passo.titolo), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('la scheda "Per cominciare"', (tester) async {
        await _monta(
          tester,
          ListView(
            padding: const EdgeInsets.all(16),
            children: [CardPerCominciare(clubId: 'c1', onApriPasso: (_) {})],
          ),
          tema: tema,
          stato: const StatoConfigurazione(
            squadre: 2,
            altriAllenatori: 0,
            invitiAllenatori: false,
            allenaDaSolo: false,
            atleti: 12,
            atletiConAccount: 0,
            codiciAtleti: false,
          ),
        );
        // Le preferenze del dispositivo arrivano un attimo dopo.
        await tester.pumpAndSettle();
        expect(find.text('Per cominciare'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
