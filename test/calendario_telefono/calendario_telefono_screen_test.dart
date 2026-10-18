import 'package:coach_vasca/features/atleti/application/current_atleta_provider.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/calendario_telefono/data/calendario_telefono_repository.dart';
import 'package:coach_vasca/features/calendario_telefono/presentation/calendario_telefono_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _codiceVecchio = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _codiceNuovo = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

String _indirizzo(String codice) =>
    'https://abc.supabase.co/functions/v1/calendario?c=$codice';

/// Il server finto: tiene il codice e annota come lo si chiede.
class _CalendarioFinto implements CalendarioTelefonoRepository {
  var _codice = _codiceVecchio;
  final richieste = <bool>[];
  Object? errore;

  @override
  Future<String> codice({bool nuovo = false}) async {
    richieste.add(nuovo);
    if (errore != null) throw errore!;
    if (nuovo) _codice = _codiceNuovo;
    return _codice;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _atleta = Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Marco',
  cognome: 'Rossi',
  dataNascita: DateTime(2012, 3, 4),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: false,
  attivo: true,
);

Widget _app(_CalendarioFinto server, {Atleta? atleta}) => ProviderScope(
  overrides: [
    calendarioTelefonoRepositoryProvider.overrideWithValue(server),
    currentAtletaProvider.overrideWith((ref) async => atleta),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    // Come "Riduci movimento": l'acqua della testata è animata senza fine.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: const CalendarioTelefonoScreen(),
  ),
);

Future<void> _apri(
  WidgetTester tester,
  _CalendarioFinto server, {
  Atleta? atleta,
}) async {
  // Telefono: 360 px.
  tester.view.physicalSize = const Size(360, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(server, atleta: atleta));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
  });

  testWidgets('mostra l\'indirizzo, i passi e i tre pulsanti', (tester) async {
    await _apri(tester, _CalendarioFinto());

    expect(find.text('Partite nel calendario'), findsOneWidget);
    expect(find.text('Collegalo una volta'), findsOneWidget);
    expect(find.textContaining('Tocca «Aggiungi al calendario»'), findsOne);
    expect(find.text(_indirizzo(_codiceVecchio)), findsOneWidget);
    expect(find.text('Aggiungi al calendario'), findsOneWidget);
    expect(find.text('Google Calendar'), findsOneWidget);
    expect(find.text('Copia l\'indirizzo'), findsOneWidget);
    expect(find.text('Cambia indirizzo'), findsOneWidget);
    expect(find.textContaining('L\'indirizzo è personale'), findsOneWidget);
  });

  testWidgets('«Copia l\'indirizzo» mette l\'indirizzo https negli appunti', (
    tester,
  ) async {
    String? copiato;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiato = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _apri(tester, _CalendarioFinto());

    await tester.ensureVisible(find.text('Copia l\'indirizzo'));
    await tester.tap(find.text('Copia l\'indirizzo'));
    await tester.pump();

    expect(copiato, _indirizzo(_codiceVecchio));
    expect(find.text('Indirizzo copiato'), findsOneWidget);
  });

  testWidgets('«Cambia indirizzo» chiede conferma e mostra il nuovo', (
    tester,
  ) async {
    final server = _CalendarioFinto();
    await _apri(tester, server);

    await tester.ensureVisible(find.text('Cambia indirizzo'));
    await tester.tap(find.text('Cambia indirizzo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cambiare indirizzo?'), findsOneWidget);
    // Annulla: niente cambia.
    await tester.tap(find.text('Annulla'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(server.richieste, [false]);
    expect(find.text(_indirizzo(_codiceVecchio)), findsOneWidget);

    await tester.tap(find.text('Cambia indirizzo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cambia'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(server.richieste, [false, true]);
    expect(find.text(_indirizzo(_codiceNuovo)), findsOneWidget);
    expect(find.text(_indirizzo(_codiceVecchio)), findsNothing);
    expect(
      find.text('Indirizzo cambiato: collega di nuovo il calendario'),
      findsOneWidget,
    );
  });

  testWidgets('se il server non risponde mostra la fascia d\'errore', (
    tester,
  ) async {
    final server = _CalendarioFinto()..errore = Exception('rete');
    await _apri(tester, server);

    expect(
      find.text('Non è stato possibile preparare l\'indirizzo del calendario.'),
      findsOneWidget,
    );
    expect(find.text('Controlla la connessione e riprova.'), findsOneWidget);
    expect(find.text('Riprova'), findsOneWidget);
    expect(find.text('Aggiungi al calendario'), findsNothing);

    // Riprova: ora il server risponde.
    server.errore = null;
    await tester.tap(find.text('Riprova'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(_indirizzo(_codiceVecchio)), findsOneWidget);
  });

  testWidgets('la riga su «Convocato» non c\'è per l\'allenatore', (
    tester,
  ) async {
    await _apri(tester, _CalendarioFinto());
    expect(find.textContaining('«Convocato»'), findsNothing);
  });

  testWidgets('la riga su «Convocato» c\'è per un atleta', (tester) async {
    await _apri(tester, _CalendarioFinto(), atleta: _atleta);
    expect(
      find.text('Sulle partite in cui sei convocato c\'è «Convocato».'),
      findsOneWidget,
    );
  });

  testWidgets('nella demo non chiama il server e dice che non si collega', (
    tester,
  ) async {
    dotenv.loadFromString(envString: 'MODALITA_DEMO=true');
    final server = _CalendarioFinto();
    await _apri(tester, server);

    expect(find.text('Nella demo il calendario non si collega'), findsOne);
    expect(find.text('Torna indietro'), findsOneWidget);
    expect(server.richieste, isEmpty);
  });
}
