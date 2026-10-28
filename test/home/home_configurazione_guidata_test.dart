import 'dart:async';

import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/application/current_atleta_provider.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/application/membri_club_providers.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/configurazione/application/configurazione_providers.dart';
import 'package:coach_vasca/features/configurazione/data/configurazione_repository.dart';
import 'package:coach_vasca/features/configurazione/presentation/configurazione_guidata_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/data/gruppi_repository.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/gruppi/presentation/gruppi_chooser_screen.dart';
import 'package:coach_vasca/features/gruppi/presentation/gruppi_onboarding_screen.dart';
import 'package:coach_vasca/features/home/home_screen.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _club = Club(id: 'c1', nome: 'Mako Pallanuoto', sport: 'pallanuoto');

/// Le squadre del telefono: si leggono come flusso e si creano come sul
/// repository vero, e il flusso cambia subito (HomeScreen lo osserva).
class _GruppiFinti implements GruppiRepository {
  final elenco = <Gruppo>[];
  final _cambi = StreamController<List<Gruppo>>.broadcast();

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
    final gruppo = Gruppo(
      id: 'g${elenco.length}',
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

class _ConfigurazioneFinta implements ConfigurazioneRepository {
  @override
  Future<bool> ciSonoInvitiAllenatori(String clubId) async => false;

  @override
  Future<bool> ciSonoCodiciAtleti(String clubId) async => false;
}

Future<void> _passa(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<_GruppiFinti> _apri(
  WidgetTester tester, {
  RuoloClub ruolo = RuoloClub.responsabile,
  List<Override> altri = const [],
}) async {
  final gruppi = _GruppiFinti();
  addTearDown(gruppi._cambi.close);
  tester.view.physicalSize = const Size(360, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentAtletaProvider.overrideWith((ref) async => null),
        currentClubProvider.overrideWith((ref) async => _club),
        gruppiListProvider.overrideWith((ref, _) => gruppi.flusso()),
        gruppiRepositoryProvider.overrideWithValue(gruppi),
        atletiListProvider.overrideWith((ref, _) => Stream.value(const [])),
        allenamentiListProvider.overrideWith(
          (ref, _) => Stream.value(const []),
        ),
        partiteListProvider.overrideWith((ref, _) => Stream.value(const [])),
        membriClubProvider.overrideWith((ref, _) async => const []),
        mioRuoloProvider.overrideWith((ref, _) async => ruolo),
        configurazioneRepositoryProvider.overrideWithValue(
          _ConfigurazioneFinta(),
        ),
        ...altri,
      ],
      child: MaterialApp(theme: AppTheme.chiaro, home: const HomeScreen()),
    ),
  );
  // Atleta, club, squadre e ruolo arrivano uno dopo l'altro.
  for (var i = 0; i < 5; i++) {
    await _passa(tester);
  }
  return gruppi;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
  });

  testWidgets('il responsabile di un club senza squadre parte dalle squadre', (
    tester,
  ) async {
    await _apri(tester);

    expect(find.byType(ConfigurazioneGuidataScreen), findsOneWidget);
    expect(find.text('Passo 2 di 5'), findsOneWidget);
    expect(find.text('Le squadre'), findsOneWidget);
    expect(find.byType(GruppiOnboardingScreen), findsNothing);
  });

  testWidgets('un allenatore senza squadre vede la schermata di sempre', (
    tester,
  ) async {
    await _apri(tester, ruolo: RuoloClub.allenatore);

    expect(find.byType(GruppiOnboardingScreen), findsOneWidget);
    expect(find.byType(ConfigurazioneGuidataScreen), findsNothing);
  });

  testWidgets('con il percorso in corso resta quello anche con le squadre', (
    tester,
  ) async {
    final gruppi = await _apri(
      tester,
      altri: [
        configurazioneInCorsoProvider.overrideWith(() => _GiaInCorso('c1')),
      ],
    );
    gruppi.elenco.add(
      const Gruppo(id: 'g9', clubId: 'c1', nome: 'U14', ordine: 1),
    );
    gruppi._cambi.add([...gruppi.elenco]);
    await _passa(tester);

    // Non passa alla scelta della squadra: il percorso non è finito.
    expect(find.byType(GruppiChooserScreen), findsNothing);
    expect(find.byType(ConfigurazioneGuidataScreen), findsOneWidget);
  });

  testWidgets('creare le squadre non cambia schermata, finire sì', (
    tester,
  ) async {
    final gruppi = await _apri(tester);

    await tester.tap(find.text('U14'));
    await tester.pump();
    await tester.tap(find.text('Avanti'));
    await _passa(tester);

    // La squadra c'è, ma si è ancora nel percorso: gli allenatori.
    expect(gruppi.elenco.map((g) => g.nome), ['U14']);
    expect(find.byType(GruppiChooserScreen), findsNothing);
    expect(find.text('Passo 3 di 5'), findsOneWidget);
    expect(find.text('Gli allenatori'), findsOneWidget);

    await tester.tap(find.text('Alleno da solo'));
    await _passa(tester);
    expect(find.text('Passo 4 di 5'), findsOneWidget);
    await tester.tap(find.text('Lo faccio dopo'));
    await _passa(tester);
    expect(find.text('Passo 5 di 5'), findsOneWidget);
    expect(find.byType(GruppiChooserScreen), findsNothing);

    await tester.tap(find.text('Lo faccio dopo'));
    await _passa(tester);

    // Fine: ora la home riprende il suo corso, dalla scelta della squadra.
    expect(find.byType(ConfigurazioneGuidataScreen), findsNothing);
    expect(find.byType(GruppiChooserScreen), findsOneWidget);
  });
}

class _GiaInCorso extends ConfigurazioneInCorsoNotifier {
  _GiaInCorso(this.clubId);

  final String clubId;

  @override
  String? build() => clubId;
}
