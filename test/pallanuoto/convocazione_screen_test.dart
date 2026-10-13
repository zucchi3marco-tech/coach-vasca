import 'dart:async';

import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/home/atleta/home_atleta_widgets.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/partite_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/convocazione.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/convocazione_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Partita _partita({DateTime? inviataIl, String? ritrovoLuogo}) => Partita(
  id: 'p1',
  clubId: 'c1',
  gruppoId: 'g1',
  data: DateTime(2026, 10, 17),
  ora: '16:00',
  luogo: 'Piscina Comunale',
  coloreCalottina: 'bianca',
  squadraCasa: 'Pallanuoto Riviera',
  squadraTrasferta: 'Rari Nantes Bologna',
  numeroMaxConvocati: 15,
  ritrovoOra: inviataIl == null ? null : '15:00',
  ritrovoLuogo: ritrovoLuogo,
  daPortare: inviataIl == null ? null : 'Accappatoio, ciabatte',
  convocazioneInviataIl: inviataIl,
);

typedef _Salvataggio = ({
  String? ritrovoOra,
  String? ritrovoLuogo,
  String? daPortare,
  bool invia,
});

/// Il server finto: tiene la partita e annota cosa gli si salva.
class _PartiteFinte implements PartiteRepository {
  _PartiteFinte(this.partita);

  Partita partita;
  final salvataggi = <_Salvataggio>[];
  final _cambi = StreamController<List<Partita>>.broadcast();

  Stream<List<Partita>> flusso() async* {
    yield [partita];
    yield* _cambi.stream;
  }

  @override
  Future<String?> ultimoDaPortare(String clubId) async =>
      'Accappatoio, ciabatte';

  @override
  Future<Partita> salvaConvocazione({
    required String id,
    String? ora,
    String? luogo,
    String? ritrovoOra,
    String? ritrovoLuogo,
    String? rientroOra,
    String? daPortare,
    String? note,
    bool invia = false,
  }) async {
    salvataggi.add((
      ritrovoOra: ritrovoOra,
      ritrovoLuogo: ritrovoLuogo,
      daPortare: daPortare,
      invia: invia,
    ));
    if (invia) {
      partita = _partita(
        inviataIl: DateTime(2026, 10, 15, 18, 32),
        ritrovoLuogo: ritrovoLuogo,
      );
      _cambi.add([partita]);
    }
    return partita;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Atleta _atleta(String id, String nome, String cognome, {String? userId}) =>
    Atleta(
      id: id,
      clubId: 'c1',
      nome: nome,
      cognome: cognome,
      dataNascita: DateTime(2012),
      sport: 'pallanuoto',
      consensoPrivacyFirmato: true,
      attivo: true,
      userId: userId,
    );

DistintaGiocatore _convocato(
  String atletaId,
  int numero, {
  bool portiere = false,
}) => DistintaGiocatore(
  id: 'd$numero',
  partitaId: 'p1',
  atletaId: atletaId,
  clubId: 'c1',
  numeroCalottina: numero,
  capitano: false,
  viceCapitano: false,
  portiere: portiere,
  fuoriquota: false,
);

Widget _app(_PartiteFinte finte) => ProviderScope(
  overrides: [
    partiteRepositoryProvider.overrideWithValue(finte),
    partiteListProvider.overrideWith((ref, clubId) => finte.flusso()),
    distintaListProvider.overrideWith(
      (ref, id) => Stream.value([
        _convocato('bianchi', 2),
        _convocato('rossi', 1, portiere: true),
      ]),
    ),
    atletiListProvider.overrideWith(
      (ref, filtro) => Stream.value([
        _atleta('rossi', 'Marco', 'Rossi', userId: 'u1'),
        _atleta('bianchi', 'Luca', 'Bianchi'),
      ]),
    ),
    gruppiListProvider.overrideWith(
      (ref, clubId) => Stream.value([
        const Gruppo(id: 'g1', clubId: 'c1', nome: 'Under 14', ordine: 0),
      ]),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ConvocazioneScreen(partita: finte.partita),
            ),
          ),
          child: const Text('Apri'),
        ),
      ),
    ),
  ),
);

void _schermoGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Il campo sotto l'etichetta (l'etichetta sta sopra, fuori dal campo).
Finder _campo(String etichetta) => find.descendant(
  of: find.widgetWithText(AppTextField, etichetta),
  matching: find.byType(TextField),
);

/// Il testo del messaggio nell'anteprima.
String _messaggio(WidgetTester tester) =>
    tester.widget<SelectableText>(find.byType(SelectableText)).data!;

void main() {
  testWidgets('la convocazione si prepara con il messaggio per le famiglie '
      'e si invia ai convocati', (tester) async {
    _schermoGrande(tester);
    final finte = _PartiteFinte(_partita());
    await tester.pumpWidget(_app(finte));
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    // Il ritrovo proposto un'ora prima, il "da portare" dell'ultima volta.
    expect(
      _messaggio(tester),
      contains(
        '*Convocazione Under 14*\n'
        'Pallanuoto Riviera – Rari Nantes Bologna\n'
        'Sabato 17 ottobre, in casa',
      ),
    );
    expect(_messaggio(tester), contains('Ritrovo: ore 15:00\n'));
    expect(_messaggio(tester), contains('Da portare: Accappatoio, ciabatte'));
    expect(
      _messaggio(tester),
      endsWith('*Convocati (2)*\n1 Rossi Marco (portiere)\n2 Bianchi Luca'),
    );
    expect(
      find.text(
        'L\'avviso arriva nell\'app e sul telefono a 1 convocato con '
        'l\'account. L\'altro non ha l\'account: raggiungilo con il '
        'messaggio su WhatsApp.',
      ),
      findsOneWidget,
    );

    // Il messaggio cambia mentre si scrive.
    await tester.enterText(
      _campo('Dove ci si trova (facoltativo)'),
      'in piscina',
    );
    await tester.pump();
    expect(_messaggio(tester), contains('Ritrovo: ore 15:00, in piscina\n'));

    await tester.tap(find.text('Invia ai convocati'));
    await tester.pumpAndSettle();
    expect(find.text('Inviare la convocazione a 1 convocato?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Invia'));
    await tester.pumpAndSettle();

    expect(finte.salvataggi.single, (
      ritrovoOra: '15:00',
      ritrovoLuogo: 'in piscina',
      daPortare: 'Accappatoio, ciabatte',
      invia: true,
    ));
    expect(find.text('Convocazione inviata'), findsOneWidget);
    expect(find.text('Invia di nuovo ai convocati'), findsOneWidget);
    expect(
      find.textContaining('Inviata giovedì 15 ott alle 18:32.'),
      findsOneWidget,
    );
  });

  testWidgets('il messaggio si copia, e quello che si scrive resta anche '
      'uscendo senza inviare', (tester) async {
    _schermoGrande(tester);
    String? copiato;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (chiamata) async {
        if (chiamata.method == 'Clipboard.setData') {
          copiato = (chiamata.arguments as Map)['text'] as String;
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
    final finte = _PartiteFinte(_partita());
    await tester.pumpWidget(_app(finte));
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copia il messaggio'));
    await tester.pumpAndSettle();
    expect(copiato, _messaggio(tester));
    expect(
      find.text('Messaggio copiato: incollalo nel gruppo WhatsApp'),
      findsOneWidget,
    );
    // Aprire e copiare senza toccare niente non salva niente.
    expect(finte.salvataggi, isEmpty);

    await tester.enterText(
      _campo('Note (facoltativo)'),
      'Quota pullman 10 euro.',
    );
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Apri'), findsOneWidget);
    expect(finte.salvataggi.single.invia, isFalse);
  });

  testWidgets('senza convocati non si invia', (tester) async {
    _schermoGrande(tester);
    final finte = _PartiteFinte(_partita());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partiteRepositoryProvider.overrideWithValue(finte),
          partiteListProvider.overrideWith((ref, clubId) => finte.flusso()),
          distintaListProvider.overrideWith((ref, id) => Stream.value([])),
          atletiListProvider.overrideWith((ref, filtro) => Stream.value([])),
          gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: ConvocazioneScreen(partita: finte.partita),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aggiungi i convocati nella distinta: la convocazione si invia a '
        'loro.',
      ),
      findsOneWidget,
    );
    final invia = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Invia ai convocati'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(invia.onPressed, isNull);
    expect(_messaggio(tester), startsWith('*Convocazione*\n'));
  });

  testWidgets('se nessun convocato ha l\'account la conferma lo dice', (
    tester,
  ) async {
    _schermoGrande(tester);
    final finte = _PartiteFinte(_partita());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partiteRepositoryProvider.overrideWithValue(finte),
          partiteListProvider.overrideWith((ref, clubId) => finte.flusso()),
          distintaListProvider.overrideWith(
            (ref, id) => Stream.value([_convocato('bianchi', 2)]),
          ),
          atletiListProvider.overrideWith(
            (ref, filtro) =>
                Stream.value([_atleta('bianchi', 'Luca', 'Bianchi')]),
          ),
          gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: ConvocazioneScreen(partita: finte.partita),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Invia ai convocati'));
    await tester.pumpAndSettle();
    expect(find.text('Inviare la convocazione?'), findsOneWidget);
    expect(find.textContaining('a 0 convocati'), findsNothing);
    // "Invia" largo quanto la scritta, accanto ad "Annulla".
    final invia = tester.getRect(find.widgetWithText(FilledButton, 'Invia'));
    final annulla = tester.getRect(find.widgetWithText(TextButton, 'Annulla'));
    expect(invia.center.dy, closeTo(annulla.center.dy, 1));
  });

  testWidgets("nella home l'atleta convocato trova ritrovo e cosa portare", (
    tester,
  ) async {
    _schermoGrande(tester);
    final partita = _partita(
      inviataIl: DateTime(2026, 10, 15, 18, 32),
      ritrovoLuogo: 'in piscina',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.chiaro,
        home: Scaffold(
          body: CardProssimaPartita(
            partita: partita,
            convocazione: (
              titolo: 'Sei convocato con il numero 7',
              voci: vociConvocazioneAtleta(partita),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sei convocato con il numero 7'), findsOneWidget);
    expect(find.text('Ritrovo'), findsOneWidget);
    expect(find.text('ore 15:00, in piscina'), findsOneWidget);
    expect(find.text('Accappatoio, ciabatte'), findsOneWidget);
  });
}
