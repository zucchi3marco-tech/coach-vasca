import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/domain/categoria_fin.dart';
import 'package:coach_vasca/features/atleti/presentation/atleti_list_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(
  String id,
  String cognome,
  int annoNascita, {
  String sport = 'pallanuoto',
  String gruppoId = 'u16',
}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Marco',
  cognome: cognome,
  dataNascita: DateTime(annoNascita, 5, 10),
  sport: sport,
  consensoPrivacyFirmato: true,
  attivo: true,
  gruppoId: gruppoId,
);

void main() {
  group('la stagione sportiva', () {
    test('dal 1° settembre conta l\'anno dopo', () {
      expect(annoStagioneSportiva(DateTime(2026, 8, 31)), 2026);
      expect(annoStagioneSportiva(DateTime(2026, 9, 1)), 2027);
      expect(annoStagioneSportiva(DateTime(2027, 6, 30)), 2027);
      expect(etichettaStagioneSportiva(2027), '2026-27');
      expect(etichettaStagioneSportiva(2100), '2099-00');
    });
  });

  group('le categorie della pallanuoto', () {
    test('con gli anni veri della Canottieri nel 2026-27', () {
      // U14 tutti 2013-14, U16 2011-12, U18 2009-10 (il 2008 è U20).
      final categorie = {
        for (final anno in [
          2001,
          2007,
          2008,
          2009,
          2010,
          2011,
          2012,
          2013,
          2014,
          2015,
          2016,
          2017,
          2020,
        ])
          anno: categoriaPallanuoto(anno, 2027),
      };
      expect(categorie, {
        2001: 'Assoluti',
        2007: 'U20',
        2008: 'U20',
        2009: 'U18',
        2010: 'U18',
        2011: 'U16',
        2012: 'U16',
        2013: 'U14',
        2014: 'U14',
        2015: 'U12',
        2016: 'U12',
        2017: 'U10',
        2020: 'U10',
      });
    });

    test('a settembre tutti salgono di un anno', () {
      // I 2013 sono U14 nel 2026-27 e U16 nel 2027-28.
      expect(categoriaPallanuoto(2013, 2027), 'U14');
      expect(categoriaPallanuoto(2013, 2028), 'U16');
      expect(categoriaPallanuoto(2014, 2028), 'U14');
    });

    test('una data di nascita dopo la stagione non ha categoria', () {
      expect(categoriaPallanuoto(2028, 2027), isNull);
    });

    test('il nuoto non si calcola', () {
      final nuotatore = _atleta('n', 'Rossi', 2012, sport: 'nuoto');
      expect(categoriaAtleta(nuotatore, DateTime(2026, 10, 27)), isNull);
      final giocatore = _atleta('p', 'Rossi', 2012);
      expect(categoriaAtleta(giocatore, DateTime(2026, 10, 27)), 'U16');
    });
  });

  group('la categoria dal nome della squadra', () {
    test('U, Under e i trattini', () {
      expect(categoriaDaNomeSquadra('U16'), 'U16');
      expect(categoriaDaNomeSquadra('u14'), 'U14');
      expect(categoriaDaNomeSquadra('Under 18'), 'U18');
      expect(categoriaDaNomeSquadra('Under18'), 'U18');
      expect(categoriaDaNomeSquadra('U-20'), 'U20');
    });

    test('i nomi che non sono una categoria a due anni', () {
      expect(categoriaDaNomeSquadra('Prima squadra'), isNull);
      expect(categoriaDaNomeSquadra('U15'), isNull);
      expect(categoriaDaNomeSquadra('U16 B'), isNull);
      expect(categoriaDaNomeSquadra('Esordienti A'), isNull);
    });

    test('sotto età e fuori quota', () {
      expect(fuoriCategoria('U14', 'U16'), FuoriCategoria.sottoEta);
      expect(fuoriCategoria('U20', 'U18'), FuoriCategoria.fuoriQuota);
      expect(fuoriCategoria('Assoluti', 'U20'), FuoriCategoria.fuoriQuota);
      expect(fuoriCategoria('U16', 'Under 16'), isNull);
      // In prima squadra gioca chi vuole l'allenatore.
      expect(fuoriCategoria('U18', 'Prima squadra'), isNull);
    });
  });

  testWidgets('nell\'elenco la classe, la categoria e i segni', (tester) async {
    final anno = annoStagioneSportiva(DateTime.now());
    tester.view.physicalSize = const Size(500, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Widget app(String? filtro) => ProviderScope(
      overrides: [
        atletiListProvider.overrideWith(
          (ref, filter) => Stream.value([
            _atleta('a1', 'Rossi', anno - 16),
            _atleta('a2', 'Bianchi', anno - 14),
            _atleta('a3', 'Verdi', anno - 19),
            _atleta('a4', 'Neri', anno - 25, gruppoId: 'prima'),
          ]),
        ),
        gruppiListProvider.overrideWith(
          (ref, clubId) => Stream.value(const [
            Gruppo(id: 'u16', clubId: 'c1', nome: 'U16', ordine: 0),
            Gruppo(id: 'prima', clubId: 'c1', nome: 'Prima squadra', ordine: 1),
          ]),
        ),
        allenamentiListProvider.overrideWith(
          (ref, clubId) => Stream.value(<Allenamento>[]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: AtletiListScreen(clubId: 'c1', filtroGruppoId: filtro),
      ),
    );

    await tester.pumpWidget(app('u16'));
    await tester.pumpAndSettle();
    expect(find.textContaining('classe ${anno - 16} (U16)'), findsOneWidget);
    expect(find.textContaining('classe ${anno - 14} (U14)'), findsOneWidget);
    expect(find.text('Sotto età'), findsOneWidget);
    expect(find.text('Fuori quota'), findsOneWidget);

    // In «Tutti gli atleti» la squadra si vede solo quando non è già la
    // categoria: «U16» per il sotto età, «Prima squadra» per l'assoluto.
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();
    expect(find.textContaining('· classe ${anno - 16} (U16)'), findsOneWidget);
    expect(
      find.textContaining('U16 · classe ${anno - 14} (U14)'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Prima squadra · classe ${anno - 25} (Assoluti)'),
      findsOneWidget,
    );
    expect(find.textContaining('U16 · classe ${anno - 16}'), findsNothing);
  });
}
