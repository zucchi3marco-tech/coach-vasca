import 'package:coach_vasca/core/utils/percentuale_presenze.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/application/personal_best_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/domain/personal_best.dart';
import 'package:coach_vasca/features/atleti/domain/squadre_atleta.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/home/atleta/allenamenti_squadre_screen.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/presenze/application/presenze_providers.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/presenze/domain/presenze_stagione.dart';
import 'package:coach_vasca/features/presenze/presentation/presenze_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Atleta _atleta(
  String id,
  String cognome, {
  String? gruppo = 'u14',
  String? altro,
  List<int> giorni = const [],
}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Mario',
  cognome: cognome,
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  gruppoId: gruppo,
  consensoPrivacyFirmato: true,
  attivo: true,
  altroGruppoId: altro,
  giorniAltroGruppo: giorni,
);

// Lunedì 12 e martedì 13 ottobre 2026.
final _lunedi = DateTime(2026, 10, 12, 18);
final _martedi = DateTime(2026, 10, 13, 20);

/// Rossi: Under 14, il martedì e il giovedì con la prima squadra.
final _rossi = _atleta('r', 'Rossi', altro: 'prima', giorni: const [2, 4]);

Presenza _presenza(String atleta, String allenamento, String stato) => Presenza(
  id: '$atleta-$allenamento',
  allenamentoId: allenamento,
  atletaId: atleta,
  clubId: 'c1',
  stato: stato,
);

void main() {
  group('la regola', () {
    test('quei giorni con l\'altra squadra, gli altri con la sua', () {
      expect(_rossi.attesoA('u14', _lunedi), isTrue);
      expect(_rossi.attesoA('prima', _lunedi), isFalse);
      expect(_rossi.attesoA('u14', _martedi), isFalse);
      expect(_rossi.attesoA('prima', _martedi), isTrue);
      // Un allenamento di tutto il club è per tutti.
      expect(_rossi.attesoA(null, _martedi), isTrue);
      // Senza squadra, atteso dappertutto, come prima.
      expect(
        _atleta('x', 'Neri', gruppo: null).attesoA('prima', _lunedi),
        true,
      );
    });

    test('vede allenamenti e partite di tutte e due, ogni giorno', () {
      expect(_rossi.vedeGruppo('u14'), isTrue);
      expect(_rossi.vedeGruppo('prima'), isTrue);
      expect(_rossi.vedeGruppo(null), isTrue);
      expect(_rossi.vedeGruppo('u16'), isFalse);
      expect(_atleta('b', 'Bianchi').vedeGruppo('prima'), isFalse);
    });

    test('i giorni dal database e dalla copia locale', () {
      expect(Atleta.leggiGiorni(const [4, 2, 2, 9]), [2, 4]);
      expect(Atleta.leggiGiorni('4,2'), [2, 4]);
      expect(Atleta.leggiGiorni(null), isEmpty);
      expect(Atleta.scriviGiorni(const [2, 4]), '2,4');
      expect(Atleta.scriviGiorni(const []), isNull);
      expect(etichettaGiorni(const [2, 4]), 'mar, gio');
      final daMappa = Atleta.fromMap({
        'id': 'r',
        'club_id': 'c1',
        'nome': 'Mario',
        'cognome': 'Rossi',
        'data_nascita': '2012-01-01',
        'sport': 'pallanuoto',
        'consenso_privacy_firmato': true,
        'attivo': true,
        'gruppo_id': 'u14',
        'altro_gruppo_id': 'prima',
        'giorni_altro_gruppo': [2, 4],
      });
      expect(daMappa.altroGruppoId, 'prima');
      expect(daMappa.giorniAltroGruppo, [2, 4]);
    });
  });

  group('le presenze', () {
    final allenamenti = [
      Allenamento(id: 'u14-lun', clubId: 'c1', data: _lunedi, gruppoId: 'u14'),
      Allenamento(id: 'u14-mar', clubId: 'c1', data: _martedi, gruppoId: 'u14'),
      Allenamento(
        id: 'prima-mar',
        clubId: 'c1',
        data: _martedi,
        gruppoId: 'prima',
      ),
    ];

    test('la percentuale conta solo dove era atteso', () {
      final percentuale = percentualePresenze(
        allenamenti: allenamenti,
        presenze: [
          _presenza('r', 'u14-lun', 'presente'),
          _presenza('r', 'prima-mar', 'presente'),
        ],
        atletaId: 'r',
        gruppoAtleta: 'u14',
        atteso: (a) => _rossi.attesoA(a.gruppoId, a.data),
        adesso: DateTime(2026, 10, 20),
      );
      // Due su due: il martedì dell'Under 14 non era suo.
      expect(percentuale, 100);
    });

    test(
      'nella griglia della stagione il martedì dell\'Under 14 non è suo',
      () {
        final stagione = presenzeStagione(
          allenamenti: allenamenti,
          presenze: [_presenza('r', 'u14-lun', 'presente')],
          atleti: [_rossi],
          gruppoId: 'u14',
          dal: DateTime(2026, 10, 1),
          adesso: DateTime(2026, 10, 20),
        );
        expect(stagione.allenamenti.map((a) => a.id), ['u14-lun', 'u14-mar']);
        expect(stagione.righe.single.stati, [
          StatoPresenza.presente,
          StatoPresenza.nonSuo,
        ]);
        expect(stagione.righe.single.percentuale, 100);
      },
    );

    // Sempre lo stesso ProviderScope: la barra del club nascosta dalla
    // schermata si rimette a posto prima che i provider spariscano.
    Widget app(Widget figlio) => ProviderScope(
      overrides: [
        atletiListProvider.overrideWith(
          (ref, filtro) => Stream.value([
            _rossi,
            _atleta('b', 'Bianchi'),
            _atleta('v', 'Verdi', gruppo: 'prima'),
          ]),
        ),
        presenzeListProvider.overrideWith(
          (ref, id) => Stream.value(const <Presenza>[]),
        ),
        gruppiListProvider.overrideWith(
          (ref, clubId) => Stream.value([
            const Gruppo(id: 'u14', clubId: 'c1', nome: 'Under 14', ordine: 1),
            const Gruppo(id: 'prima', clubId: 'c1', nome: 'Prima', ordine: 2),
          ]),
        ),
        personalBestClubProvider.overrideWith(
          (ref, clubId) => Stream.value(const <PersonalBest>[]),
        ),
      ],
      child: MaterialApp(theme: AppTheme.chiaro, home: figlio),
    );

    Future<void> apri(WidgetTester tester, Allenamento allenamento) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(PresenzeScreen(allenamento: allenamento)));
      await tester.pumpAndSettle();
    }

    Future<void> chiudi(WidgetTester tester) =>
        tester.pumpWidget(app(const SizedBox()));

    testWidgets('il martedì Rossi è con la prima squadra, "da Under 14"', (
      tester,
    ) async {
      await apri(tester, allenamenti[2]);
      expect(find.text('Rossi Mario'), findsOneWidget);
      expect(find.text('da Under 14'), findsOneWidget);
      expect(find.text('Verdi Mario'), findsOneWidget);
      expect(find.text('Bianchi Mario'), findsNothing);
      // Un cambio di un giorno: Bianchi si aggiunge da qui.
      expect(find.text('Aggiungi un atleta'), findsOneWidget);
      await chiudi(tester);
    });

    testWidgets('e non è nelle presenze dell\'Under 14 di quel giorno', (
      tester,
    ) async {
      await apri(tester, allenamenti[1]);
      expect(find.text('Bianchi Mario'), findsOneWidget);
      expect(find.text('Rossi Mario'), findsNothing);
      await chiudi(tester);
    });

    testWidgets('l\'atleta vede gli allenamenti delle due squadre', (
      tester,
    ) async {
      final oggi = DateTime.now();
      final domani = DateTime(oggi.year, oggi.month, oggi.day + 1, 18);
      final dopodomani = DateTime(oggi.year, oggi.month, oggi.day + 2, 18);
      // Domani con la prima squadra, dopodomani con la sua.
      final atleta = _atleta(
        'r',
        'Rossi',
        altro: 'prima',
        giorni: [domani.weekday],
      );
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allenamentiAtletaProvider.overrideWith(
              (ref, clubId) async => [
                Allenamento(
                  id: 'u14-domani',
                  clubId: 'c1',
                  data: domani,
                  titolo: 'Under 14 domani',
                  gruppoId: 'u14',
                ),
                Allenamento(
                  id: 'prima-domani',
                  clubId: 'c1',
                  data: domani,
                  titolo: 'Prima domani',
                  gruppoId: 'prima',
                ),
                Allenamento(
                  id: 'u14-dopo',
                  clubId: 'c1',
                  data: dopodomani,
                  titolo: 'Under 14 dopodomani',
                  gruppoId: 'u14',
                ),
                Allenamento(
                  id: 'u16',
                  clubId: 'c1',
                  data: domani,
                  titolo: 'Under 16',
                  gruppoId: 'u16',
                ),
              ],
            ),
            gruppiListProvider.overrideWith(
              (ref, clubId) => Stream.value([
                const Gruppo(
                  id: 'u14',
                  clubId: 'c1',
                  nome: 'Under 14',
                  ordine: 1,
                ),
                const Gruppo(
                  id: 'prima',
                  clubId: 'c1',
                  nome: 'Prima',
                  ordine: 2,
                ),
              ]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            home: AllenamentiSquadreScreen(atleta: atleta),
          ),
        ),
      );
      // Le schede entrano a cascata: un secondo basta.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Under 14 e Prima'), findsOneWidget);
      expect(find.text('Under 14 domani'), findsOneWidget);
      expect(find.text('Prima domani'), findsOneWidget);
      expect(find.text('Under 14 dopodomani'), findsOneWidget);
      // Non è sua: non la vede.
      expect(find.text('Under 16'), findsNothing);
      // I suoi: domani la prima squadra, dopodomani l'Under 14.
      expect(find.text('Il tuo'), findsNWidgets(2));
    });

    testWidgets('il lunedì è nelle presenze dell\'Under 14', (tester) async {
      await apri(tester, allenamenti[0]);
      expect(find.text('Rossi Mario'), findsOneWidget);
      expect(find.text('da Under 14'), findsNothing);
      await chiudi(tester);
    });
  });
}
