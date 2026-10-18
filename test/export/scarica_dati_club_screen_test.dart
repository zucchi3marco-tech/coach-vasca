import 'dart:async';
import 'dart:typed_data';

import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/export/application/excel_dati_club.dart';
import 'package:coach_vasca/features/export/data/dati_club_repository.dart';
import 'package:coach_vasca/features/export/domain/dati_club.dart';
import 'package:coach_vasca/features/export/domain/periodo_dati.dart';
import 'package:coach_vasca/features/export/presentation/scarica_dati_club_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/app_list_row.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Il server finto: annota cosa gli si chiede e restituisce un piccolo club.
class _DatiFinti implements DatiClubRepository {
  final letture = <({String clubId, bool conBenessere})>[];
  var richiesteNascita = 0;

  /// Quando è nato il club; null = il server non lo mostra.
  DateTime? nato;
  Object? erroreNascita;

  /// Se non è null, una lettura aspetta che lo si completi.
  Completer<void>? attesa;

  /// Se non è null, una lettura fallisce così.
  Object? errore;

  @override
  Future<DatiClub> leggi(
    String clubId, {
    required bool conBenessere,
    void Function(String cosa)? avanzamento,
  }) async {
    letture.add((clubId: clubId, conBenessere: conBenessere));
    avanzamento?.call('Leggo le presenze');
    if (attesa != null) await attesa!.future;
    if (errore != null) throw errore!;
    return DatiClub(
      atleti: [
        Atleta(
          id: 'a1',
          clubId: clubId,
          nome: 'Mario',
          cognome: 'Rossi',
          dataNascita: DateTime(2012, 3, 4),
          sport: 'pallanuoto',
          consensoPrivacyFirmato: false,
          attivo: true,
        ),
      ],
      // Come il vero: le schede si leggono solo se sono state chieste.
      schedeBenessere: conBenessere
          ? [
              SchedaBenessere(
                id: 's1',
                atletaId: 'a1',
                clubId: clubId,
                data: DateTime(2026, 10, 9),
                dolori: false,
                oreSonno: 8,
                compilataIl: DateTime(2026, 10, 9, 7, 30),
              ),
            ]
          : null,
    );
  }

  @override
  Future<DateTime?> creatoIl(String clubId) async {
    richiesteNascita++;
    if (erroreNascita != null) throw erroreNascita!;
    return nato;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Il download finto: tiene i file che sarebbero stati scaricati.
class _AzioniFinte extends AzioniDatiClub {
  _AzioniFinte({this.web = true});

  final bool web;
  final scaricati = <({Uint8List bytes, String nome})>[];
  Object? errore;

  @override
  bool get disponibile => web;

  @override
  void scarica(Uint8List bytes, String nomeFile) {
    if (errore != null) throw errore!;
    scaricati.add((bytes: bytes, nome: nomeFile));
  }
}

Widget _app(_DatiFinti server, _AzioniFinte azioni) => ProviderScope(
  overrides: [
    datiClubRepositoryProvider.overrideWithValue(server),
    azioniDatiClubProvider.overrideWithValue(azioni),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    // Come "Riduci movimento": l'acqua della testata è animata senza fine.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: const ScaricaDatiClubScreen(
      clubId: 'c1',
      clubNome: 'Canottieri Milano',
      scaricatoDa: 'Marco Rossi (marco@example.com)',
    ),
  ),
);

Future<void> _apri(
  WidgetTester tester,
  _DatiFinti server,
  _AzioniFinte azioni,
) async {
  // Telefono: 360 px.
  tester.view.physicalSize = const Size(360, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(server, azioni));
  await _passa(tester);
}

/// Lascia finire una lettura finta e la scrittura del file (che aspetta un
/// attimo per far comparire «Scrivo il file»).
Future<void> _passa(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}

Future<void> _tocca(WidgetTester tester, Finder cosa) async {
  await tester.ensureVisible(cosa);
  await tester.pump();
  await tester.tap(cosa);
  await _passa(tester);
}

const _scarica = 'Scarica il file Excel';

Switch _interruttore(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch));

/// Il valore accanto a un'etichetta del foglio «Leggimi».
String _leggimi(Uint8List bytes, String etichetta) {
  final righe = Excel.decodeBytes(bytes).tables['Leggimi']!.rows;
  final riga = righe.firstWhere(
    (r) => r.isNotEmpty && r.first?.value.toString() == etichetta,
  );
  return riga[1]!.value.toString();
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
  });

  testWidgets('all\'apertura: Tutto scelto, benessere spento, il pulsante', (
    tester,
  ) async {
    await _apri(tester, _DatiFinti(), _AzioniFinte());

    expect(find.text('Canottieri Milano'), findsOneWidget);
    expect(find.text('Scarica i dati del club'), findsOneWidget);
    expect(
      find.text('Un file Excel con un foglio per tipo di dato.'),
      findsOneWidget,
    );

    // Tutto è la scelta fatta; con due stagioni di base ci sono tre righe.
    final tutto = find.ancestor(
      of: find.text('Tutto'),
      matching: find.byType(AppListRow),
    );
    expect(
      find.descendant(
        of: tutto,
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.text('Tutti i dati'), findsOneWidget);
    expect(find.byType(AppListRow), findsNWidgets(3));
    final periodi = periodiDisponibili(DateTime.now());
    for (final p in periodi.skip(1)) {
      expect(find.text(p.etichetta), findsOneWidget);
      expect(find.text(p.descrizione), findsOneWidget);
    }

    // Il benessere è spento e dice perché è un dato delicato.
    expect(find.text('Anche benessere e dolori'), findsOneWidget);
    expect(
      find.text(
        'Sonno, energia, dolori e sintomi delle schede degli atleti: sono '
        'dati sulla salute, aggiungili solo se ti servono.',
      ),
      findsOneWidget,
    );
    expect(_interruttore(tester).value, isFalse);

    // L'avviso sui dati personali sta prima del pulsante.
    expect(
      find.text(
        'Il file contiene dati personali di atleti, anche minorenni: '
        'conservalo con cura e non mandarlo in giro. Si prepara su questo '
        'dispositivo e non passa da nessun altro servizio.',
      ),
      findsOneWidget,
    );
    expect(find.text(_scarica), findsOneWidget);
    expect(find.text('Scaricalo di nuovo'), findsNothing);
  });

  testWidgets('scarica il file: una lettura, il nome, la conferma', (
    tester,
  ) async {
    final server = _DatiFinti();
    final azioni = _AzioniFinte();
    await _apri(tester, server, azioni);

    await _tocca(tester, find.text(_scarica));

    expect(server.letture, [(clubId: 'c1', conBenessere: false)]);
    final nome = nomeFileDatiClub('Canottieri Milano', DateTime.now());
    expect(azioni.scaricati, hasLength(1));
    expect(azioni.scaricati.single.nome, nome);
    expect(find.text('File scaricato: $nome'), findsOneWidget);
    expect(find.text('Lo trovi fra i download del browser.'), findsOneWidget);
    // Fatto: resta solo «Scaricalo di nuovo», niente secondo pulsante pieno.
    expect(find.text(_scarica), findsNothing);
    expect(find.text('Scaricalo di nuovo'), findsOneWidget);

    // Il file è quello giusto: tutto il periodo, senza benessere.
    final bytes = azioni.scaricati.single.bytes;
    final excel = Excel.decodeBytes(bytes);
    expect(excel.tables.keys, contains('Atleti'));
    expect(excel.tables.keys, isNot(contains('Benessere')));
    expect(_leggimi(bytes, 'Club'), 'Canottieri Milano');
    expect(_leggimi(bytes, 'Da'), 'Marco Rossi (marco@example.com)');
    expect(_leggimi(bytes, 'Periodo'), 'Tutto (Tutti i dati)');
    expect(_leggimi(bytes, 'Benessere e dolori'), 'non inclusi');
  });

  testWidgets('«Scaricalo di nuovo» riusa lo stesso file, senza rileggere', (
    tester,
  ) async {
    final server = _DatiFinti();
    final azioni = _AzioniFinte();
    await _apri(tester, server, azioni);
    await _tocca(tester, find.text(_scarica));

    await _tocca(tester, find.text('Scaricalo di nuovo'));

    expect(server.letture, hasLength(1));
    expect(azioni.scaricati, hasLength(2));
    expect(azioni.scaricati[1].nome, azioni.scaricati[0].nome);
    expect(azioni.scaricati[1].bytes, azioni.scaricati[0].bytes);
    expect(find.textContaining('File scaricato: '), findsOneWidget);
  });

  testWidgets('cambiare periodo o benessere dopo il file torna all\'inizio', (
    tester,
  ) async {
    final azioni = _AzioniFinte();
    await _apri(tester, _DatiFinti(), azioni);
    final stagione = periodiDisponibili(DateTime.now())[1];

    await _tocca(tester, find.text(_scarica));
    expect(find.text('Scaricalo di nuovo'), findsOneWidget);
    await _tocca(tester, find.text(stagione.etichetta));
    expect(find.text('Scaricalo di nuovo'), findsNothing);
    expect(find.textContaining('File scaricato: '), findsNothing);
    expect(find.text(_scarica), findsOneWidget);

    await _tocca(tester, find.text(_scarica));
    expect(find.text('Scaricalo di nuovo'), findsOneWidget);
    await _tocca(tester, find.text('Anche benessere e dolori'));
    expect(find.text('Scaricalo di nuovo'), findsNothing);
    expect(find.text(_scarica), findsOneWidget);
    expect(_interruttore(tester).value, isTrue);
    // Niente è stato scaricato per il solo cambio di scelta.
    expect(azioni.scaricati, hasLength(2));
  });

  testWidgets('con benessere e dolori: si chiede al server e c\'è il foglio', (
    tester,
  ) async {
    final server = _DatiFinti();
    final azioni = _AzioniFinte();
    await _apri(tester, server, azioni);

    await _tocca(tester, find.text('Anche benessere e dolori'));
    expect(_interruttore(tester).value, isTrue);
    await _tocca(tester, find.text(_scarica));

    expect(server.letture, [(clubId: 'c1', conBenessere: true)]);
    final bytes = azioni.scaricati.single.bytes;
    final excel = Excel.decodeBytes(bytes);
    expect(excel.tables.keys, contains('Benessere'));
    expect(_leggimi(bytes, 'Benessere e dolori'), 'inclusi');
  });

  testWidgets('scegliendo una stagione, il file porta quel periodo', (
    tester,
  ) async {
    final server = _DatiFinti();
    final azioni = _AzioniFinte();
    await _apri(tester, server, azioni);
    final stagione = periodiDisponibili(DateTime.now())[1];

    await _tocca(tester, find.text(stagione.etichetta));
    // Ora la scelta è lei e non più «Tutto».
    final scelta = find.ancestor(
      of: find.text(stagione.etichetta),
      matching: find.byType(AppListRow),
    );
    expect(
      find.descendant(
        of: scelta,
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    await _tocca(tester, find.text(_scarica));

    final bytes = azioni.scaricati.single.bytes;
    expect(
      _leggimi(bytes, 'Periodo'),
      '${stagione.etichetta} (${stagione.descrizione})',
    );
  });

  testWidgets('le stagioni offerte arrivano fin dove è nato il club', (
    tester,
  ) async {
    final oggi = DateTime.now();
    final server = _DatiFinti()..nato = DateTime(oggi.year - 3, oggi.month, 1);
    await _apri(tester, server, _AzioniFinte());

    final attese = periodiDisponibili(oggi, daQuando: server.nato);
    expect(attese.length, greaterThan(3));
    expect(find.byType(AppListRow), findsNWidgets(attese.length));
    expect(find.text(attese.last.etichetta), findsOneWidget);
    expect(server.richiesteNascita, 1);
  });

  testWidgets('se la data di nascita del club non si legge, quelle di base', (
    tester,
  ) async {
    final server = _DatiFinti()..erroreNascita = Exception('rete');
    final azioni = _AzioniFinte();
    await _apri(tester, server, azioni);

    expect(find.byType(AppListRow), findsNWidgets(3));
    // Nessun errore in vista: si può scaricare lo stesso.
    expect(find.text('Non è stato possibile preparare il file.'), findsNothing);
    await _tocca(tester, find.text(_scarica));
    expect(azioni.scaricati, hasLength(1));
  });

  testWidgets('durante il lavoro: controlli spenti, i passi, il pulsante', (
    tester,
  ) async {
    final server = _DatiFinti()..attesa = Completer<void>();
    final azioni = _AzioniFinte();
    await _apri(tester, server, azioni);

    await tester.ensureVisible(find.text(_scarica));
    await tester.pump();
    await tester.tap(find.text(_scarica));
    await tester.pump();
    await tester.pump();

    // Legge: il passo dice cosa, il pulsante gira, niente si può cambiare.
    expect(find.text('Leggo le presenze…'), findsOneWidget);
    expect(find.text(_scarica), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_interruttore(tester).onChanged, isNull);
    final righe = tester.widgetList<AppListRow>(find.byType(AppListRow));
    expect(righe.every((r) => r.onTap == null), isTrue);
    expect(server.letture, hasLength(1));
    expect(azioni.scaricati, isEmpty);

    // Finita la lettura, il file si scrive.
    server.attesa!.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('Scrivo il file…'), findsOneWidget);
    expect(find.text('Leggo le presenze…'), findsNothing);
    expect(azioni.scaricati, isEmpty);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(azioni.scaricati, hasLength(1));
    expect(find.text('Scrivo il file…'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_interruttore(tester).onChanged, isNotNull);
    expect(find.text('Scaricalo di nuovo'), findsOneWidget);
  });

  testWidgets('se il server non risponde: fascia d\'errore e «Riprova»', (
    tester,
  ) async {
    final server = _DatiFinti()..errore = Exception('rete');
    final azioni = _AzioniFinte();
    await _apri(tester, server, azioni);

    await _tocca(tester, find.text(_scarica));

    expect(find.text('Non è stato possibile preparare il file.'), findsOne);
    expect(find.text('Controlla la connessione e riprova.'), findsOneWidget);
    expect(find.text('Riprova'), findsOneWidget);
    expect(azioni.scaricati, isEmpty);
    // I controlli sono di nuovo liberi e il pulsante c'è ancora.
    expect(_interruttore(tester).onChanged, isNotNull);
    expect(find.text(_scarica), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('File scaricato: '), findsNothing);

    server.errore = null;
    await _tocca(tester, find.text('Riprova'));

    expect(server.letture, hasLength(2));
    expect(azioni.scaricati, hasLength(1));
    expect(find.text('Non è stato possibile preparare il file.'), findsNothing);
    expect(find.textContaining('File scaricato: '), findsOneWidget);
  });

  testWidgets('se il download non parte, è lo stesso errore e si riprova', (
    tester,
  ) async {
    final azioni = _AzioniFinte()..errore = Exception('bloccato');
    await _apri(tester, _DatiFinti(), azioni);

    await _tocca(tester, find.text(_scarica));

    expect(find.text('Non è stato possibile preparare il file.'), findsOne);
    expect(find.textContaining('File scaricato: '), findsNothing);
    expect(find.text('Riprova'), findsOneWidget);
  });

  testWidgets('nella demo non legge niente e non scarica', (tester) async {
    dotenv.loadFromString(envString: 'MODALITA_DEMO=true');
    final server = _DatiFinti();
    final azioni = _AzioniFinte();
    await _apri(tester, server, azioni);

    expect(find.text('Nella demo i dati non si scaricano'), findsOneWidget);
    expect(find.text('Torna indietro'), findsOneWidget);
    expect(find.text(_scarica), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(server.letture, isEmpty);
    expect(server.richiesteNascita, 0);
    expect(azioni.scaricati, isEmpty);
  });

  testWidgets('fuori dal browser: niente pulsante, si dice dove scaricare', (
    tester,
  ) async {
    final server = _DatiFinti();
    await _apri(tester, server, _AzioniFinte(web: false));

    expect(find.text('Scarica i dati del club'), findsOneWidget);
    expect(
      find.text(
        'Il file Excel si scarica aprendo l\'app nel browser, per esempio da '
        'un computer.',
      ),
      findsOneWidget,
    );
    expect(find.text(_scarica), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(AppListRow), findsNothing);
    expect(server.letture, isEmpty);
  });
}
