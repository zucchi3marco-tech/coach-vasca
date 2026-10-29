import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/profilo_fisico/data/profilo_fisico_repository.dart';
import 'package:coach_vasca/features/profilo_fisico/domain/misura_fisica.dart';
import 'package:coach_vasca/features/profilo_fisico/presentation/profilo_fisico_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime(2026, 10, 29);

Atleta _atleta({required DateTime nascita}) => Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Sofia',
  cognome: 'Rossi',
  dataNascita: nascita,
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  gruppoId: 'u16',
);

MisuraFisica _misura(DateTime data, {double? altezza, double? peso}) =>
    MisuraFisica(
      atletaId: 'a1',
      clubId: 'c1',
      data: data,
      altezzaCm: altezza,
      pesoKg: peso,
    );

class _Profilo implements ProfiloFisicoRepository {
  _Profilo({List<MisuraFisica>? misure, this.consensoIl})
    : elenco = [...?misure];

  final List<MisuraFisica> elenco;
  DateTime? consensoIl;
  final eliminate = <MisuraFisica>[];

  @override
  Future<List<MisuraFisica>> misure(String atletaId) async =>
      [...elenco]..sort((a, b) => b.data.compareTo(a.data));

  @override
  Future<DateTime?> consenso(String atletaId) async => consensoIl;

  @override
  Future<MisuraFisica> salva(MisuraFisica misura) async {
    elenco
      ..removeWhere((m) => DateUtils.isSameDay(m.data, misura.data))
      ..add(misura);
    return misura;
  }

  @override
  Future<void> elimina(MisuraFisica misura) async {
    eliminate.add(misura);
    elenco.removeWhere((m) => DateUtils.isSameDay(m.data, misura.data));
  }

  @override
  Future<DateTime> segnaConsenso({
    required String atletaId,
    required String clubId,
  }) async => consensoIl = _oggi;

  @override
  Future<void> togliConsenso({
    required String atletaId,
    required bool minorenne,
  }) async {
    consensoIl = null;
    if (minorenne) elenco.clear();
  }
}

void main() {
  group('i conti', () {
    test('maggiorenne dal giorno dei 18 anni', () {
      final nascita = DateTime(2008, 10, 29);
      expect(maggiorenne(nascita, DateTime(2026, 10, 28)), isFalse);
      expect(maggiorenne(nascita, DateTime(2026, 10, 29)), isTrue);
      expect(
        profiloFisicoAperto(
          dataNascita: DateTime(2012),
          conConsenso: true,
          oggi: _oggi,
        ),
        isTrue,
      );
      expect(
        profiloFisicoAperto(
          dataNascita: DateTime(2012),
          conConsenso: false,
          oggi: _oggi,
        ),
        isFalse,
      );
    });

    test('l\'altezza anche in metri, il peso con la virgola', () {
      expect(leggiAltezza('172'), 172);
      expect(leggiAltezza('1,72'), 172);
      expect(leggiAltezza(' 172,5 cm'), 172.5);
      expect(leggiAltezza(''), isNull);
      expect(() => leggiAltezza('300'), throwsFormatException);
      expect(leggiPeso('61,5'), 61.5);
      expect(leggiPeso('61.54'), 61.5);
      expect(() => leggiPeso('5'), throwsFormatException);
      expect(numeroMisura(172), '172');
      expect(numeroMisura(61.5), '61,5');
    });

    test('la crescita dalla prima all\'ultima misura', () {
      final misure = [
        _misura(DateTime(2026, 10, 20), altezza: 175, peso: 62),
        _misura(DateTime(2026, 9, 12), altezza: 172),
        _misura(DateTime(2026, 9, 1), peso: 63.5),
      ];
      expect(
        crescita(misure, (m) => m.altezzaCm, 'cm', oggi: _oggi),
        '+3 cm dal 12 settembre',
      );
      expect(
        crescita(misure, (m) => m.pesoKg, 'kg', oggi: _oggi),
        '−1,5 kg dall\'1 settembre',
      );
      expect(
        crescita(misure.take(1).toList(), (m) => m.altezzaCm, 'cm'),
        isNull,
      );
      expect(ultimoValore(misure, (m) => m.altezzaCm), 175);
    });
  });

  group('la pagina', () {
    Future<void> apri(
      WidgetTester tester,
      Atleta atleta,
      _Profilo profilo, {
      bool staff = false,
    }) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profiloFisicoRepositoryProvider.overrideWithValue(profilo),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: ProfiloFisicoScreen(
              atleta: atleta,
              vistaAllenatore: staff,
              oggi: _oggi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('chi ha meno di 18 anni senza consenso non scrive', (
      tester,
    ) async {
      await apri(tester, _atleta(nascita: DateTime(2011, 3, 4)), _Profilo());
      expect(find.textContaining('serve il'), findsOneWidget);
      expect(find.text('Aggiungi le misure'), findsNothing);
      expect(find.text('Aggiungi le prime misure'), findsNothing);
    });

    testWidgets('l\'atleta aggiunge le misure e vede la crescita', (
      tester,
    ) async {
      final profilo = _Profilo(
        misure: [_misura(DateTime(2026, 9, 12), altezza: 172, peso: 60)],
        consensoIl: DateTime(2026, 9, 1),
      );
      await apri(tester, _atleta(nascita: DateTime(2011, 3, 4)), profilo);
      expect(find.text('172 cm'), findsOneWidget);

      await tester.tap(find.text('Aggiungi le misure'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('misura-altezza')), '1,75');
      await tester.enterText(find.byKey(const Key('misura-peso')), '61,5');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      expect(profilo.elenco, hasLength(2));
      expect(find.text('175 cm'), findsOneWidget);
      expect(find.text('61,5 kg'), findsOneWidget);
      expect(find.text('+3 cm dal 12 settembre'), findsOneWidget);
      expect(find.text('+1,5 kg dal 12 settembre'), findsOneWidget);
    });

    testWidgets('un numero fuori misura non si salva', (tester) async {
      final profilo = _Profilo();
      await apri(tester, _atleta(nascita: DateTime(2000)), profilo);
      await tester.tap(find.text('Aggiungi le misure'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('misura-altezza')), '17');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(find.text('L\'altezza va da 80 a 230 cm'), findsOneWidget);
      expect(profilo.elenco, isEmpty);
    });

    testWidgets('lo staff legge e segna il consenso, ma non scrive', (
      tester,
    ) async {
      final profilo = _Profilo();
      await apri(
        tester,
        _atleta(nascita: DateTime(2011, 3, 4)),
        profilo,
        staff: true,
      );
      expect(find.text('Aggiungi le misure'), findsNothing);
      await tester.tap(find.text('Segna il consenso ricevuto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sì, l\'ho ricevuto'));
      await tester.pumpAndSettle();
      expect(profilo.consensoIl, _oggi);
      expect(find.text('Ricevuto il 29 ottobre 2026.'), findsOneWidget);
      expect(
        find.text('Non ha ancora scritto altezza e peso.'),
        findsOneWidget,
      );
      expect(find.text('Aggiungi le misure'), findsNothing);
    });

    testWidgets('togliere il consenso cancella le misure del minorenne', (
      tester,
    ) async {
      final profilo = _Profilo(
        misure: [_misura(DateTime(2026, 9, 12), altezza: 172)],
        consensoIl: DateTime(2026, 9, 1),
      );
      await apri(
        tester,
        _atleta(nascita: DateTime(2011, 3, 4)),
        profilo,
        staff: true,
      );
      expect(find.text('172 cm'), findsWidgets);
      await tester.tap(find.text('Togli il consenso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Togli il consenso').last);
      await tester.pumpAndSettle();
      expect(profilo.consensoIl, isNull);
      expect(profilo.elenco, isEmpty);
      expect(find.text('172 cm'), findsNothing);
    });

    testWidgets('il maggiorenne non ha la parte del consenso', (tester) async {
      await apri(
        tester,
        _atleta(nascita: DateTime(2000)),
        _Profilo(),
        staff: true,
      );
      expect(find.text('Consenso del genitore'), findsNothing);
    });
  });
}
