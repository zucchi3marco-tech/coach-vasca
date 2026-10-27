import 'dart:convert';
import 'dart:typed_data';

import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/biglietti_codici_pdf.dart';
import 'package:coach_vasca/features/club/data/logo_club_repository.dart';
import 'package:coach_vasca/features/club/presentation/logo_club.dart';
import 'package:coach_vasca/features/export/marchio_pdf.dart';
import 'package:coach_vasca/features/export/pdf_export.dart';
import 'package:coach_vasca/features/pallanuoto/pdf/schema_tattico_pdf.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un PNG vero di 1×1 pixel.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

/// L'inizio di un PNG senza il resto: un file rovinato.
final _pngRovinato = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, //
]);

/// Il server finto dei loghi: uno per club, in memoria.
class _Loghi implements LogoClubRepository {
  final loghi = <String, Uint8List>{};
  Object? errore;

  @override
  Future<Uint8List?> logo(String clubId, {Duration? attesa}) async =>
      loghi[clubId];

  @override
  Future<void> carica(String clubId, Uint8List bytes) async {
    if (errore != null) throw errore!;
    loghi[clubId] = bytes;
  }

  @override
  Future<void> togli(String clubId) async {
    if (errore != null) throw errore!;
    loghi.remove(clubId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Conta le immagini dentro un PDF (non compresso nei test).
int _immagini(Uint8List pdf) =>
    RegExp(r'/Subtype\s*/Image').allMatches(latin1.decode(pdf)).length;

Future<void> _apri(
  WidgetTester tester,
  _Loghi loghi, {
  required bool modificabile,
  Uint8List? scelto,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        logoClubRepositoryProvider.overrideWithValue(loghi),
        sceltaLogoProvider.overrideWithValue(() async => scelto),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        home: Scaffold(
          body: SezioneLogoClub(clubId: 'c1', modificabile: modificabile),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('tipoLogo', () {
    test('riconosce PNG e JPG dai primi byte', () {
      expect(tipoLogo(_png), 'image/png');
      expect(
        tipoLogo(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10])),
        'image/jpeg',
      );
      expect(tipoLogo(Uint8List.fromList(utf8.encode('GIF89a...'))), isNull);
      expect(tipoLogo(Uint8List(0)), isNull);
    });

    test('un PNG rovinato non diventa un\'immagine del PDF', () {
      expect(immagineLogoPdf(_pngRovinato), isNull);
      expect(immagineLogoPdf(null), isNull);
      expect(immagineLogoPdf(_png), isNotNull);
    });
  });

  group('il logo nei PDF', () {
    final allenamento = Allenamento(
      id: 'a1',
      clubId: 'c1',
      data: DateTime(2026, 10, 27, 18),
      titolo: 'Tecnica',
    );

    test('la seduta ha il logo in testa, senza logo solo il nome', () async {
      final con = await generaPdf([
        (allenamento, const []),
      ], marchio: MarchioPdf(nomeClub: 'Canottieri Milano', logo: _png));
      final senza = await generaPdf([
        (allenamento, const []),
      ], marchio: const MarchioPdf(nomeClub: 'Canottieri Milano'));
      final niente = await generaPdf([(allenamento, const [])]);
      expect(_immagini(con), isPositive);
      expect(_immagini(senza), 0);
      expect(_immagini(niente), 0);
    });

    test('un logo rovinato non ferma il PDF', () async {
      final bytes = await generaPdf([
        (allenamento, const []),
      ], marchio: MarchioPdf(nomeClub: 'Canottieri', logo: _pngRovinato));
      expect(bytes, isNotEmpty);
      expect(_immagini(bytes), 0);
    });

    test('lo schema tattico ha il logo in testa', () async {
      final bytes = await generaSchemaPdf(
        titolo: 'Superiorità',
        categoria: 'U14',
        campo: 'metà campo',
        immaginiPassi: const [],
        marchio: MarchioPdf(nomeClub: 'Canottieri', logo: _png),
      );
      expect(_immagini(bytes), isPositive);
    });

    test('i biglietti dei codici hanno il logo accanto al club', () async {
      final bytes = await generaBigliettiCodici(
        nomeClub: 'Canottieri',
        logo: _png,
        biglietti: [
          for (final nome in ['Luca', 'Anna', 'Marco'])
            BigliettoCodice(
              cognome: 'Rossi',
              nome: nome,
              codice: 'A1B2C3D4E5',
              scade: DateTime(2026, 11, 30),
            ),
        ],
      );
      final senza = await generaBigliettiCodici(
        nomeClub: 'Canottieri',
        biglietti: [
          BigliettoCodice(
            cognome: 'Rossi',
            nome: 'Luca',
            codice: 'A1B2C3D4E5',
            scade: DateTime(2026, 11, 30),
          ),
        ],
      );
      // La stessa immagine, usata da ogni biglietto, sta nel PDF una volta
      // sola: quante ne ha una seduta con il logo.
      final seduta = await generaPdf([
        (Allenamento(id: 'a', clubId: 'c', data: DateTime(2026)), const []),
      ], marchio: MarchioPdf(nomeClub: 'Canottieri', logo: _png));
      expect(_immagini(bytes), _immagini(seduta));
      expect(_immagini(senza), 0);
    });
  });

  group('«Il logo del club» in «Il mio club»', () {
    testWidgets('il responsabile carica il logo, poi lo cambia o lo toglie', (
      tester,
    ) async {
      final loghi = _Loghi();
      await _apri(tester, loghi, modificabile: true, scelto: _png);

      expect(find.text('Il logo del club'), findsOneWidget);
      expect(find.textContaining('PNG o JPG, fino a 1 MB'), findsOneWidget);
      expect(find.text('Togli'), findsNothing);

      await tester.tap(find.text('Carica il logo'));
      await tester.pump();
      await tester.pump();

      expect(loghi.loghi['c1'], _png);
      expect(
        find.text('Logo salvato: da ora è in testa ai PDF.'),
        findsOneWidget,
      );
      expect(find.text('Cambia il logo'), findsOneWidget);
      expect(find.bySemanticsLabel('Logo del club'), findsOneWidget);

      await tester.tap(find.text('Togli'));
      await tester.pumpAndSettle();
      expect(find.text('Togliere il logo?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Togli').last);
      await tester.pump();
      await tester.pump();

      expect(loghi.loghi, isEmpty);
      expect(find.text('Carica il logo'), findsOneWidget);
    });

    testWidgets('se il file non va, un avviso con il motivo', (tester) async {
      final loghi = _Loghi()
        ..errore = Exception("Il logo dev'essere un'immagine PNG o JPG.");
      await _apri(tester, loghi, modificabile: true, scelto: _png);

      await tester.tap(find.text('Carica il logo'));
      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining("Il logo dev'essere un'immagine PNG o JPG."),
        findsOneWidget,
      );
      expect(find.text('Carica il logo'), findsOneWidget);
    });

    testWidgets('chi non è il responsabile lo vede ma non lo cambia', (
      tester,
    ) async {
      final loghi = _Loghi();
      await _apri(tester, loghi, modificabile: false);
      expect(
        find.text("Non c'è ancora: lo mette il responsabile del club."),
        findsOneWidget,
      );
      expect(find.text('Carica il logo'), findsNothing);
    });

    testWidgets('chi non è il responsabile vede il logo messo', (tester) async {
      final loghi = _Loghi()..loghi['c1'] = _png;
      await _apri(tester, loghi, modificabile: false);
      expect(
        find.text('È in alto nei PDF: sedute, report, schemi e codici.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Logo del club'), findsOneWidget);
      expect(find.text('Cambia il logo'), findsNothing);
      expect(find.text('Togli'), findsNothing);
    });
  });
}
