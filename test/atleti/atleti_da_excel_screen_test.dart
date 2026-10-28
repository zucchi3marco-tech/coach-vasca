import 'dart:convert';
import 'dart:typed_data';

import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/data/atleti_repository.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/presentation/atleti_da_excel_screen.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un archivio finto: ricorda cosa gli viene chiesto di scrivere.
class _ArchivioFinto implements AtletiRepository {
  _ArchivioFinto({this.falliscoAllaCreazioneNumero});

  /// Alla creazione numero N (da 1) lancia un errore.
  final int? falliscoAllaCreazioneNumero;

  final creati = <Map<String, Object?>>[];
  final aggiornati = <Map<String, Object?>>[];

  @override
  Future<Atleta> createAtleta({
    required String clubId,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    String? gruppoId,
    String? emailGenitore,
    String? telefonoGenitore,
    bool consensoPrivacyFirmato = false,
    String? note,
    String? numeroTesseraFin,
    DateTime? visitaMedicaScadenza,
    String? ruolo,
    String? altroGruppoId,
    List<int> giorniAltroGruppo = const [],
  }) async {
    if (falliscoAllaCreazioneNumero == creati.length + 1) {
      throw Exception('prova');
    }
    creati.add({
      'cognome': cognome,
      'nome': nome,
      'gruppoId': gruppoId,
      'ruolo': ruolo,
      'consenso': consensoPrivacyFirmato,
    });
    return Atleta(
      id: 'nuovo-${creati.length}',
      clubId: clubId,
      nome: nome,
      cognome: cognome,
      dataNascita: dataNascita,
      sport: 'pallanuoto',
      consensoPrivacyFirmato: consensoPrivacyFirmato,
      attivo: true,
      gruppoId: gruppoId,
      ruolo: ruolo,
    );
  }

  @override
  Future<Atleta> updateAtleta({
    required Atleta originale,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    String? gruppoId,
    String? emailGenitore,
    String? telefonoGenitore,
    required bool consensoPrivacyFirmato,
    DateTime? consensoPrivacyData,
    String? note,
    String? numeroTesseraFin,
    DateTime? visitaMedicaScadenza,
    String? ruolo,
    String? altroGruppoId,
    List<int> giorniAltroGruppo = const [],
  }) async {
    aggiornati.add({
      'id': originale.id,
      'gruppoId': gruppoId,
      'tessera': numeroTesseraFin,
      'ruolo': ruolo,
      'altroGruppoId': altroGruppoId,
    });
    return Atleta(
      id: originale.id,
      clubId: originale.clubId,
      nome: nome,
      cognome: cognome,
      dataNascita: dataNascita,
      sport: originale.sport,
      consensoPrivacyFirmato: consensoPrivacyFirmato,
      attivo: originale.attivo,
      gruppoId: gruppoId,
      numeroTesseraFin: numeroTesseraFin,
      ruolo: ruolo,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _esistente = Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Mario',
  cognome: 'Rossi',
  dataNascita: DateTime(2012, 3, 12),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: false,
  attivo: true,
  ruolo: 'portiere',
);

Uint8List _csv(String testo) => Uint8List.fromList(utf8.encode(testo));

const _csvBase =
    'Cognome;Nome;Data di nascita;Squadra;Tessera\n'
    'Rossi;Mario;12/03/2012;Esordienti A;4455\n'
    'Verdi;Anna;01/05/2011;Esordienti A;\n'
    'Bianchi;Luca;15/06/2010;Master;\n'
    'Neri;Sara;31/02/2010;;\n';

Widget _app(
  _ArchivioFinto archivio, {
  String sport = 'pallanuoto',
  Future<FileScelto?> Function()? scegliFile,
}) => ProviderScope(
  overrides: [
    currentClubProvider.overrideWith(
      (ref) async => Club(id: 'c1', nome: 'Mako', sport: sport),
    ),
    gruppiListProvider.overrideWith(
      (ref, clubId) => Stream.value(const [
        Gruppo(id: 'g1', clubId: 'c1', nome: 'Esordienti A', ordine: 0),
        Gruppo(id: 'g2', clubId: 'c1', nome: 'Under 14', ordine: 1),
      ]),
    ),
    atletiListProvider.overrideWith(
      (ref, filter) => Stream.value([_esistente]),
    ),
    atletiRepositoryProvider.overrideWithValue(archivio),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    // Come "Riduci movimento": l'acqua della testata e' animata senza fine.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: AtletiDaExcelScreen(clubId: 'c1', scegliFile: scegliFile),
  ),
);

void _grande(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void _ignoraOverflowDiTesto() {
  final originale = FlutterError.onError;
  FlutterError.onError = (dettagli) {
    if (dettagli.exceptionAsString().contains('overflowed')) return;
    originale?.call(dettagli);
  };
  addTearDown(() => FlutterError.onError = originale);
}

void main() {
  testWidgets('primo passo: spiegazione e i due pulsanti', (tester) async {
    _grande(tester);
    _ignoraOverflowDiTesto();
    await tester.pumpWidget(_app(_ArchivioFinto()));
    await tester.pumpAndSettle();

    expect(find.text('Atleti da un foglio Excel'), findsOneWidget);
    expect(
      find.textContaining('Cognome, Nome e Data di nascita'),
      findsOneWidget,
    );
    expect(find.textContaining('Ruolo,'), findsOneWidget);
    expect(
      find.text('Il file lo legge l\'app qui, non viene mandato a nessuno.'),
      findsOneWidget,
    );
    expect(find.text('Scegli il file'), findsOneWidget);
    expect(find.text('Scarica il modello'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('anche in un club segnato «nuoto» nel database il foglio ha il '
      'ruolo: l\'app è solo pallanuoto', (tester) async {
    _grande(tester);
    _ignoraOverflowDiTesto();
    await tester.pumpWidget(_app(_ArchivioFinto(), sport: 'nuoto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ruolo,'), findsOneWidget);
  });

  testWidgets('il modello, fuori dal browser, avvisa con un messaggio', (
    tester,
  ) async {
    _grande(tester);
    _ignoraOverflowDiTesto();
    await tester.pumpWidget(_app(_ArchivioFinto()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scarica il modello'));
    await tester.pump();
    expect(find.textContaining('solo dalla versione web'), findsOneWidget);
  });

  testWidgets('un file .xls da il messaggio del formato vecchio', (
    tester,
  ) async {
    _grande(tester);
    _ignoraOverflowDiTesto();
    await tester.pumpWidget(
      _app(
        _ArchivioFinto(),
        scegliFile: () async => (nome: 'atleti.xls', bytes: Uint8List(8)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scegli il file'));
    await tester.pumpAndSettle();
    expect(find.textContaining('formato vecchio di Excel'), findsOneWidget);
    expect(find.text('Scegli il file'), findsOneWidget);
  });

  testWidgets('anteprima, salvataggio e fine', (tester) async {
    _grande(tester);
    _ignoraOverflowDiTesto();
    final archivio = _ArchivioFinto();
    await tester.pumpWidget(
      _app(
        archivio,
        scegliFile: () async => (nome: 'atleti.csv', bytes: _csv(_csvBase)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scegli il file'));
    await tester.pumpAndSettle();

    // Anteprima: Verdi e Bianchi nuovi, Rossi gia nell'app (tessera e
    // squadra da aggiungere), Neri fuori per la data impossibile.
    expect(find.text('Da aggiungere'), findsOneWidget);
    expect(find.text('Verdi Anna'), findsOneWidget);
    expect(find.text('Bianchi Luca'), findsOneWidget);
    expect(find.text('Già nell\'app'), findsWidgets);
    expect(find.text('Rossi Mario'), findsOneWidget);
    expect(find.text('Aggiungo squadra e tessera'), findsOneWidget);
    expect(find.text('Restano fuori'), findsWidgets);
    expect(find.text('Riga 5'), findsOneWidget);
    expect(find.textContaining('non leggibile'), findsOneWidget);
    expect(find.text('Squadre che non conosco'), findsOneWidget);
    expect(find.text('«Master» nel foglio'), findsOneWidget);
    expect(find.text('Aggiungi 2 atleti e completane 1'), findsOneWidget);
    expect(find.text('Scegli un altro file'), findsOneWidget);

    await tester.tap(find.text('Aggiungi 2 atleti e completane 1'));
    await tester.pumpAndSettle();

    expect(archivio.creati.map((c) => c['cognome']), ['Verdi', 'Bianchi']);
    expect(archivio.creati.first['gruppoId'], 'g1');
    // «Master» non e stato abbinato: senza squadra.
    expect(archivio.creati.last['gruppoId'], isNull);
    expect(archivio.aggiornati, hasLength(1));
    // Si completa solo cio che manca: il ruolo c'era e resta.
    expect(archivio.aggiornati.single['id'], 'a1');
    expect(archivio.aggiornati.single['gruppoId'], 'g1');
    expect(archivio.aggiornati.single['tessera'], '4455');
    expect(archivio.aggiornati.single['ruolo'], 'portiere');

    expect(find.text('Aggiunti 2 atleti, completato 1.'), findsOneWidget);
    expect(find.text('Foglio dei codici per i nuovi'), findsOneWidget);
    expect(find.text('Fatto'), findsWidgets);
  });

  testWidgets('l\'abbinamento di una squadra sconosciuta si sceglie in '
      'anteprima', (tester) async {
    _grande(tester);
    _ignoraOverflowDiTesto();
    final archivio = _ArchivioFinto();
    await tester.pumpWidget(
      _app(
        archivio,
        scegliFile: () async => (nome: 'atleti.csv', bytes: _csv(_csvBase)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scegli il file'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Senza squadra').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Under 14').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aggiungi 2 atleti e completane 1'));
    await tester.pumpAndSettle();

    expect(archivio.creati.last['cognome'], 'Bianchi');
    expect(archivio.creati.last['gruppoId'], 'g2');
  });

  testWidgets('un errore a meta dice quanti ne sono stati aggiunti', (
    tester,
  ) async {
    _grande(tester);
    _ignoraOverflowDiTesto();
    final archivio = _ArchivioFinto(falliscoAllaCreazioneNumero: 2);
    await tester.pumpWidget(
      _app(
        archivio,
        scegliFile: () async => (nome: 'atleti.csv', bytes: _csv(_csvBase)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scegli il file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aggiungi 2 atleti e completane 1'));
    await tester.pumpAndSettle();

    expect(archivio.creati, hasLength(1));
    expect(find.textContaining('Aggiunti 1 di 3. Poi: '), findsOneWidget);
    expect(
      find.textContaining('Puoi riprovare con lo stesso file'),
      findsOneWidget,
    );
    // Chi e gia stato aggiunto si riconosce: ora Verdi e nell'app.
    expect(find.text('Aggiungi 1 atleta e completane 1'), findsOneWidget);
  });

  testWidgets('su telefono niente va fuori dallo schermo', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        _ArchivioFinto(),
        scegliFile: () async => (nome: 'atleti.csv', bytes: _csv(_csvBase)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scegli il file'));
    await tester.pumpAndSettle();
    expect(find.text('Aggiungi 2 atleti e completane 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un file senza le colonne giuste mostra l\'errore e basta', (
    tester,
  ) async {
    _grande(tester);
    _ignoraOverflowDiTesto();
    await tester.pumpWidget(
      _app(
        _ArchivioFinto(),
        scegliFile: () async =>
            (nome: 'a.csv', bytes: _csv('Squadra;Note\nEsordienti A;boh\n')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scegli il file'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Non trovo le colonne Cognome e Nome'),
      findsOneWidget,
    );
    expect(find.text('Niente da aggiungere'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Niente da aggiungere'),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Scegli un altro file'), findsOneWidget);
  });
}
