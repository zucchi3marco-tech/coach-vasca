import 'package:coach_vasca/core/utils/pace_format.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/carico/application/carico_providers.dart';
import 'package:coach_vasca/features/carico/data/carico_repository.dart';
import 'package:coach_vasca/features/carico/domain/banister.dart';
import 'package:coach_vasca/features/carico/domain/volumi_atleta.dart';
import 'package:coach_vasca/features/carico/presentation/carico_atleta_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Una riga di `serie_per_carico`.
Map<String, dynamic> _serie(
  String allenamentoId,
  int ripetute, {
  int? distanzaM,
  int? durataS,
  String? zona,
  String esecuzione = 'nuoto',
}) => {
  'allenamento_id': allenamentoId,
  'ripetute': ripetute,
  'distanza_m': distanzaM,
  'durata_s': durataS,
  'zona': zona,
  'esecuzione': esecuzione,
};

void main() {
  test('il lavoro a tempo si conta in minuti, non come 0 m', () {
    final volumi = VolumiAtleta.daSerie(
      [
        _serie('a1', 8, distanzaM: 100, zona: 'B1'),
        _serie('a1', 3, durataS: 600, esecuzione: 'palleggio'),
        _serie('a1', 1, durataS: 300, zona: 'A2'),
        // Un allenamento a cui l'atleta non c'era.
        _serie('a2', 2, durataS: 900, esecuzione: 'palleggio'),
      ],
      {'a1'},
    );
    expect(volumi.volumeTotaleM, 800);
    expect(volumi.tempoTotaleS, 2100);
    expect(volumi.perEsecuzione, {'nuoto': 800});
    expect(volumi.tempoPerEsecuzione, {'palleggio': 1800, 'nuoto': 300});
    expect(volumi.perZona, {'B1': 800});
    expect(volumi.tempoPerZona, {'A2': 300});
  });

  test('una serie a tempo pesa nel carico come i metri al passo medio', () {
    // 8x100 B1: 800 m per il peso della zona (1.6).
    expect(caricoSerie(ripetute: 8, distanzaM: 100, zona: 'B1'), 1280);
    // 10' di palleggio: 600 s al passo medio (110 s ogni 100 m) = 545 m.
    expect(caricoSerie(ripetute: 1, durataS: 600), closeTo(545.5, 0.1));
    // Con una zona, lo stesso peso dei metri.
    expect(
      caricoSerie(ripetute: 2, durataS: 300, zona: 'B2'),
      closeTo(2 * 300 * 100 / 110 * 2.0, 0.001),
    );
    expect(caricoSerie(ripetute: 3), 0);
  });

  test('il tempo di lavoro si legge in minuti e ore', () {
    expect(formattaTempoLavoro(45), '45"');
    expect(formattaTempoLavoro(2700), "45'");
    expect(formattaTempoLavoro(7200), '2h');
    expect(formattaTempoLavoro(9000), "2h30'");
    expect(formattaTempoLavoro(3900), "1h05'");
  });

  testWidgets('nelle statistiche il palleggio mostra i minuti', (tester) async {
    final atleta = Atleta(
      id: 'at1',
      clubId: 'c1',
      nome: 'Marco',
      cognome: 'Rossi',
      dataNascita: DateTime(2010, 3, 4),
      sport: 'pallanuoto',
      consensoPrivacyFirmato: true,
      attivo: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          andamentoCaricoProvider.overrideWith(
            (ref, chiave) async =>
                calcolaBanister({DateTime(2026, 10, 1): 1000}),
          ),
          volumiAtletaProvider.overrideWith(
            (ref, chiave) async => VolumiAtleta.daSerie(
              [
                _serie('a1', 8, distanzaM: 100, zona: 'B1'),
                _serie('a1', 1, durataS: 300),
                _serie('a1', 3, durataS: 600, esecuzione: 'palleggio'),
              ],
              {'a1'},
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: CaricoAtletaScreen(atleta: atleta),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Palleggio'), 300);
    await tester.pumpAndSettle();

    expect(find.text('Lavoro a tempo'), findsOneWidget);
    expect(find.text("35'"), findsOneWidget);
    expect(find.text("30'"), findsOneWidget);
    expect(find.text('0 m'), findsNothing);
    // Nuoto: i metri in grande, il tempo sotto.
    expect(find.text("+ 5' a tempo"), findsOneWidget);
  });
}
