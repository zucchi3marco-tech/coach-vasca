import 'package:coach_vasca/features/profilo_fisico/data/specialisti_repository.dart';
import 'package:coach_vasca/features/profilo_fisico/domain/specialista.dart';
import 'package:coach_vasca/features/profilo_fisico/presentation/specialisti_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/app_text_field.dart';
import 'package:coach_vasca/widgets/danger_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Il campo del modulo sotto l'etichetta [etichetta].
Finder _campo(String etichetta) => find.descendant(
  of: find.widgetWithText(AppTextField, etichetta),
  matching: find.byType(TextFormField),
);

class _Specialisti implements SpecialistiRepository {
  _Specialisti([List<Specialista>? iniziali]) : elenco_ = [...?iniziali];

  final List<Specialista> elenco_;

  @override
  Future<List<Specialista>> elenco(String clubId) async =>
      ordinaSpecialisti(elenco_.where((s) => s.clubId == clubId));

  @override
  Future<Specialista> salva(Specialista specialista) async {
    final salvato = Specialista.fromMap({
      ...specialista.toMap(),
      'id': specialista.id ?? 's${elenco_.length + 1}',
    })!;
    elenco_
      ..removeWhere((s) => s.id == salvato.id)
      ..add(salvato);
    return salvato;
  }

  @override
  Future<void> elimina(Specialista specialista) async =>
      elenco_.removeWhere((s) => s.id == specialista.id);
}

const _rossi = Specialista(
  id: 's1',
  clubId: 'c1',
  tipo: TipoSpecialista.fisioterapista,
  nome: 'Studio Rossi',
  descrizione: 'A Monza, sconto per gli atleti',
  whatsapp: '+393331234567',
);

void main() {
  group('i contatti', () {
    test('il numero WhatsApp scritto in tanti modi', () {
      expect(leggiWhatsapp('333 123 4567'), '+393331234567');
      expect(leggiWhatsapp('+39 333-123.4567'), '+393331234567');
      expect(leggiWhatsapp('0039 333 1234567'), '+393331234567');
      expect(leggiWhatsapp('+41 79 123 45 67'), '+41791234567');
      expect(leggiWhatsapp('  '), isNull);
      expect(() => leggiWhatsapp('chiama Mario'), throwsFormatException);
      expect(() => leggiWhatsapp('123'), throwsFormatException);
      expect(() => leggiWhatsapp('333+1234567'), throwsFormatException);
      expect(mostraWhatsapp('+393331234567'), '+39 333 123 4567');
      expect(mostraWhatsapp('+41791234567'), '+41791234567');
    });

    test('il sito con o senza https', () {
      expect(leggiSito('studiorossi.it'), 'https://studiorossi.it');
      expect(
        leggiSito('HTTP://www.studio.it/sport'),
        'http://www.studio.it/sport',
      );
      expect(leggiSito(''), isNull);
      expect(() => leggiSito('studio rossi'), throwsFormatException);
      expect(() => leggiSito('localhost'), throwsFormatException);
      expect(mostraSito('https://www.studiorossi.it/'), 'studiorossi.it');
    });

    test('un tipo che l\'app non conosce si salta', () {
      expect(
        Specialista.fromMap({'club_id': 'c1', 'tipo': 'dietista', 'nome': 'X'}),
        isNull,
      );
      expect(_rossi.contatti, 'WhatsApp +39 333 123 4567');
    });
  });

  group('la pagina', () {
    Future<void> apri(
      WidgetTester tester,
      _Specialisti repo, {
      bool responsabile = true,
    }) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [specialistiRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: SpecialistiScreen(clubId: 'c1', modificabile: responsabile),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('il responsabile aggiunge uno specialista', (tester) async {
      final repo = _Specialisti();
      await apri(tester, repo);
      await tester.tap(find.text('Aggiungi il primo specialista'));
      await tester.pumpAndSettle();

      // Senza tipo e senza contatto non si salva.
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(find.text('Scegli che specialista è'), findsWidgets);

      await tester.tap(find.text('Scegli'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nutrizionista sportivo').last);
      await tester.pumpAndSettle();
      await tester.enterText(_campo('Nome'), 'Dott.ssa Bianchi');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(
        find.text('Scrivi il numero WhatsApp, il sito o tutti e due.'),
        findsOneWidget,
      );
      expect(repo.elenco_, isEmpty);

      await tester.enterText(_campo('Sito'), 'bianchinutrizione.it');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      expect(repo.elenco_.single.sito, 'https://bianchinutrizione.it');
      expect(repo.elenco_.single.tipo, TipoSpecialista.nutrizionista);
      expect(find.text('Nutrizionisti sportivi'), findsOneWidget);
      expect(find.text('Dott.ssa Bianchi'), findsOneWidget);
      expect(find.text('bianchinutrizione.it'), findsOneWidget);
    });

    testWidgets('il responsabile toglie uno specialista', (tester) async {
      final repo = _Specialisti([_rossi]);
      await apri(tester, repo);
      expect(find.text('Fisioterapisti'), findsOneWidget);
      await tester.tap(find.text('Studio Rossi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Togli lo specialista'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DangerButton, 'Togli'));
      await tester.pumpAndSettle();
      expect(repo.elenco_, isEmpty);
      expect(find.text('Studio Rossi'), findsNothing);
    });

    testWidgets('gli altri dello staff leggono soltanto', (tester) async {
      await apri(tester, _Specialisti([_rossi]), responsabile: false);
      expect(find.text('Studio Rossi'), findsOneWidget);
      expect(
        find.text('A Monza, sconto per gli atleti\nWhatsApp +39 333 123 4567'),
        findsOneWidget,
      );
      expect(find.text('Aggiungi uno specialista'), findsNothing);
      await tester.tap(find.text('Studio Rossi'));
      await tester.pumpAndSettle();
      expect(find.text('Specialista'), findsNothing);
    });

    testWidgets('senza specialisti, per lo staff', (tester) async {
      await apri(tester, _Specialisti(), responsabile: false);
      expect(
        find.text(
          'Non ce ne sono ancora: li aggiunge il responsabile del club.',
        ),
        findsOneWidget,
      );
    });
  });
}
