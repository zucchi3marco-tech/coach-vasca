import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/distinta_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/numeri_distinta.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/scegli_convocati_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/cap_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Partita _partita({int massimo = 15}) => Partita(
  id: 'p1',
  clubId: 'c1',
  gruppoId: 'g1',
  data: DateTime(2026, 10, 24),
  coloreCalottina: 'bianca',
  squadraCasa: 'Pallanuoto Riviera',
  squadraTrasferta: 'Bologna',
  numeroMaxConvocati: massimo,
);

Atleta _atleta(
  String id,
  String nome,
  String cognome, {
  String? gruppoId = 'g1',
  String? ruolo,
  String sport = 'pallanuoto',
}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: cognome,
  dataNascita: DateTime(2012),
  sport: sport,
  gruppoId: gruppoId,
  ruolo: ruolo,
  consensoPrivacyFirmato: true,
  attivo: true,
);

/// La squadra di prova: tre di movimento e un portiere della squadra
/// della partita, uno di un'altra squadra, un nuotatore (non conta).
final _atleti = [
  _atleta('rossi', 'Marco', 'Rossi'),
  _atleta('bianchi', 'Luca', 'Bianchi'),
  _atleta('verdi', 'Anna', 'Verdi'),
  _atleta('neri', 'Paolo', 'Neri', ruolo: 'portiere'),
  _atleta('gialli', 'Sara', 'Gialli', gruppoId: 'g2'),
  _atleta('nuoto', 'Elia', 'Azzurri', sport: 'nuoto'),
];

DistintaGiocatore _riga(
  String atletaId,
  int numero, {
  bool portiere = false,
  bool capitano = false,
}) => DistintaGiocatore(
  id: 'riga-$atletaId',
  partitaId: 'p1',
  atletaId: atletaId,
  clubId: 'c1',
  numeroCalottina: numero,
  capitano: capitano,
  viceCapitano: false,
  portiere: portiere,
  fuoriquota: false,
);

typedef _Salvataggio = ({
  String partitaId,
  List<NuovoConvocato> aggiungi,
  List<String> togli,
});

/// Il server finto: annota cosa gli si salva.
class _DistintaFinta implements DistintaRepository {
  _DistintaFinta({this.errore});

  Object? errore;
  final salvataggi = <_Salvataggio>[];

  @override
  Future<void> salvaConvocati({
    required String partitaId,
    List<NuovoConvocato> aggiungi = const [],
    List<String> togli = const [],
  }) async {
    if (errore != null) throw errore!;
    salvataggi.add((partitaId: partitaId, aggiungi: aggiungi, togli: togli));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UltimaDistinta _ultima(Map<String, NellUltimaPartita> perAtleta) =>
    UltimaDistinta(
      partitaId: 'p0',
      data: DateTime(2026, 10, 12),
      avversario: 'Rari Nantes',
      perAtleta: perAtleta,
    );

/// La pagina aperta da un pulsante: [risultato] raccoglie cosa ritorna.
Widget _app(
  _DistintaFinta finta, {
  Partita? partita,
  List<DistintaGiocatore> distinta = const [],
  UltimaDistinta? ultima,
  double testo = 1,
  List<bool?>? risultato,
}) => ProviderScope(
  overrides: [
    distintaRepositoryProvider.overrideWithValue(finta),
    distintaListProvider.overrideWith((ref, id) => Stream.value(distinta)),
    atletiListProvider.overrideWith((ref, filtro) => Stream.value(_atleti)),
    gruppiListProvider.overrideWith(
      (ref, clubId) => Stream.value(const [
        Gruppo(id: 'g1', clubId: 'c1', nome: 'Under 14', ordine: 0),
        Gruppo(id: 'g2', clubId: 'c1', nome: 'Under 16', ordine: 1),
      ]),
    ),
    ultimaDistintaProvider.overrideWith((ref, chiave) async => ultima),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(testo)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            final esito = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) =>
                    ScegliConvocatiScreen(partita: partita ?? _partita()),
              ),
            );
            risultato?.add(esito);
          },
          child: const Text('Apri'),
        ),
      ),
    ),
  ),
);

Future<void> _apri(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.tap(find.text('Apri'));
  await tester.pumpAndSettle();
}

void _telefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Il numero sulla calottina di un atleta (null se non è spuntato).
CapBadge? _calottina(WidgetTester tester, String nomeCompleto) {
  final riga = find
      .ancestor(of: find.text(nomeCompleto), matching: find.byType(InkWell))
      .first;
  final badge = find.descendant(of: riga, matching: find.byType(CapBadge));
  return badge.evaluate().isEmpty ? null : tester.widget<CapBadge>(badge);
}

Finder _salva(String etichetta) => find.widgetWithText(FilledButton, etichetta);

void main() {
  testWidgets('spuntando più atleti si salva una volta sola, con i numeri '
      'giusti (il portiere toccato per ultimo ha l\'1)', (tester) async {
    _telefono(tester);
    final finta = _DistintaFinta();
    final risultato = <bool?>[];
    await _apri(tester, _app(finta, risultato: risultato));

    // La squadra della partita e le altre, dal nome della squadra.
    expect(find.text('Under 14'), findsOneWidget);
    expect(find.text('Dalle altre squadre'), findsOneWidget);
    expect(find.text('Under 16'), findsOneWidget);
    expect(find.text('Azzurri Elia'), findsNothing);
    expect(find.text('0 / 15 convocati'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(_salva('Salva')).onPressed,
      isNull,
      reason: 'senza modifiche non si salva',
    );

    await tester.tap(find.text('Bianchi Luca'));
    await tester.tap(find.text('Rossi Marco'));
    await tester.tap(find.text('Neri Paolo'));
    await tester.pump();

    expect(find.text('3 / 15 convocati'), findsOneWidget);
    expect(_calottina(tester, 'Bianchi Luca')!.numero, 2);
    expect(_calottina(tester, 'Rossi Marco')!.numero, 3);
    expect(_calottina(tester, 'Neri Paolo')!.numero, 1);
    expect(_calottina(tester, 'Neri Paolo')!.colore, CapColore.rossaPortiere);
    expect(_calottina(tester, 'Bianchi Luca')!.colore, CapColore.bianca);
    expect(_calottina(tester, 'Verdi Anna'), isNull);

    await tester.tap(_salva('Salva · 3 convocati'));
    await tester.pumpAndSettle();

    expect(finta.salvataggi, hasLength(1));
    final salvataggio = finta.salvataggi.single;
    expect(salvataggio.partitaId, 'p1');
    expect(salvataggio.togli, isEmpty);
    expect(salvataggio.aggiungi, [
      (
        atletaId: 'bianchi',
        numero: 2,
        portiere: false,
        capitano: false,
        viceCapitano: false,
      ),
      (
        atletaId: 'rossi',
        numero: 3,
        portiere: false,
        capitano: false,
        viceCapitano: false,
      ),
      (
        atletaId: 'neri',
        numero: 1,
        portiere: true,
        capitano: false,
        viceCapitano: false,
      ),
    ]);
    expect(find.byType(ScegliConvocatiScreen), findsNothing);
    expect(risultato, [true]);
  });

  testWidgets('"Come l\'ultima partita" riprende chi c\'era, con i suoi '
      'numeri, il capitano e il vice', (tester) async {
    _telefono(tester);
    final finta = _DistintaFinta();
    final ultima = _ultima({
      'bianchi': (numero: 7, capitano: true, viceCapitano: false),
      'rossi': (numero: 5, capitano: false, viceCapitano: true),
      'neri': (numero: 13, capitano: false, viceCapitano: false),
      // Non è più fra gli atleti: si salta.
      'sparito': (numero: 9, capitano: false, viceCapitano: false),
    });
    await _apri(tester, _app(finta, ultima: ultima));

    // Chi c'era nell'ultima partita lo dice sotto il nome.
    expect(find.text('Nell\'ultima partita il 7'), findsOneWidget);
    expect(
      find.text('Ultima partita: contro Rari Nantes (12 ott).'),
      findsOneWidget,
    );

    await tester.tap(find.text('Come l\'ultima partita'));
    await tester.pump();

    expect(find.text('3 / 15 convocati'), findsOneWidget);
    expect(_calottina(tester, 'Bianchi Luca')!.numero, 7);
    expect(_calottina(tester, 'Rossi Marco')!.numero, 5);
    expect(_calottina(tester, 'Neri Paolo')!.numero, 13);
    expect(find.text('Nell\'ultima partita il 7'), findsNothing);
    expect(find.text('Capitano'), findsOneWidget);
    expect(find.text('Vice capitano'), findsOneWidget);

    await tester.tap(_salva('Salva · 3 convocati'));
    await tester.pumpAndSettle();

    // In ordine di numero.
    expect(finta.salvataggi.single.aggiungi, [
      (
        atletaId: 'rossi',
        numero: 5,
        portiere: false,
        capitano: false,
        viceCapitano: true,
      ),
      (
        atletaId: 'bianchi',
        numero: 7,
        portiere: false,
        capitano: true,
        viceCapitano: false,
      ),
      (
        atletaId: 'neri',
        numero: 13,
        portiere: true,
        capitano: false,
        viceCapitano: false,
      ),
    ]);
  });

  testWidgets('togliere uno già in distinta ne manda via la riga, chi resta '
      'tiene il numero e il nuovo prende quello libero', (tester) async {
    _telefono(tester);
    final finta = _DistintaFinta();
    await _apri(
      tester,
      _app(
        finta,
        distinta: [
          _riga('neri', 1, portiere: true),
          _riga('bianchi', 2),
          _riga('rossi', 3, capitano: true),
        ],
      ),
    );

    // Parte da chi è già in distinta, ognuno col suo numero.
    expect(find.text('3 / 15 convocati'), findsOneWidget);
    expect(_calottina(tester, 'Bianchi Luca')!.numero, 2);
    expect(_calottina(tester, 'Rossi Marco')!.numero, 3);
    expect(_calottina(tester, 'Neri Paolo')!.numero, 1);
    expect(find.text('Capitano'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(_salva('Salva · 3 convocati')).onPressed,
      isNull,
    );

    await tester.tap(find.text('Bianchi Luca'));
    await tester.pump();
    expect(find.text('2 / 15 convocati'), findsOneWidget);
    expect(_calottina(tester, 'Bianchi Luca'), isNull);
    // Gli altri non cambiano numero.
    expect(_calottina(tester, 'Rossi Marco')!.numero, 3);
    expect(_calottina(tester, 'Neri Paolo')!.numero, 1);

    // Il nuovo prende il 2, che si è liberato.
    await tester.tap(find.text('Verdi Anna'));
    await tester.pump();
    expect(_calottina(tester, 'Verdi Anna')!.numero, 2);

    await tester.tap(_salva('Salva · 3 convocati'));
    await tester.pumpAndSettle();

    final salvataggio = finta.salvataggi.single;
    expect(salvataggio.togli, ['riga-bianchi']);
    expect(salvataggio.aggiungi, [
      (
        atletaId: 'verdi',
        numero: 2,
        portiere: false,
        capitano: false,
        viceCapitano: false,
      ),
    ]);
  });

  testWidgets('al massimo non se ne aggiungono altri, ma si può togliere', (
    tester,
  ) async {
    _telefono(tester);
    final finta = _DistintaFinta();
    await _apri(tester, _app(finta, partita: _partita(massimo: 3)));

    await tester.tap(find.text('Bianchi Luca'));
    await tester.tap(find.text('Rossi Marco'));
    await tester.tap(find.text('Verdi Anna'));
    await tester.pump();
    expect(find.text('3 / 3 convocati'), findsOneWidget);

    await tester.tap(find.text('Neri Paolo'));
    await tester.pump();
    expect(find.text('3 / 3 convocati'), findsOneWidget);
    expect(_calottina(tester, 'Neri Paolo'), isNull);
    expect(
      find.text('Sei a 3: togline uno per aggiungerne un altro.'),
      findsOneWidget,
    );

    // Chi è spuntato si toglie sempre, e poi c'è di nuovo posto.
    await tester.tap(find.text('Verdi Anna'));
    await tester.pump();
    expect(find.text('2 / 3 convocati'), findsOneWidget);
    await tester.tap(find.text('Neri Paolo'));
    await tester.pump();
    expect(find.text('3 / 3 convocati'), findsOneWidget);
    expect(_calottina(tester, 'Neri Paolo')!.numero, 1);
  });

  testWidgets('"Tutta la squadra" spunta in ordine alfabetico fino al massimo '
      'e "Togli tutti" svuota', (tester) async {
    _telefono(tester);
    final finta = _DistintaFinta();
    await _apri(tester, _app(finta, partita: _partita(massimo: 3)));

    await tester.tap(find.text('Tutta la squadra'));
    await tester.pump();

    // Bianchi, Neri e Rossi, in ordine di cognome: per Verdi non c'è più
    // posto; Gialli è di un'altra squadra.
    expect(find.text('3 / 3 convocati'), findsOneWidget);
    expect(_calottina(tester, 'Bianchi Luca')!.numero, 2);
    expect(_calottina(tester, 'Neri Paolo')!.numero, 1);
    expect(_calottina(tester, 'Rossi Marco')!.numero, 3);
    expect(_calottina(tester, 'Verdi Anna'), isNull);
    await tester.scrollUntilVisible(find.text('Gialli Sara'), 200);
    expect(_calottina(tester, 'Gialli Sara'), isNull);
    await tester.scrollUntilVisible(
      find.text('Togli tutti'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Togli tutti'));
    await tester.pump();
    expect(find.text('0 / 3 convocati'), findsOneWidget);
    expect(find.text('Togli tutti'), findsNothing);
    expect(_calottina(tester, 'Bianchi Luca'), isNull);
    expect(tester.widget<FilledButton>(_salva('Salva')).onPressed, isNull);
  });

  testWidgets('uscendo con delle modifiche chiede conferma', (tester) async {
    _telefono(tester);
    final finta = _DistintaFinta();
    final risultato = <bool?>[];
    await _apri(tester, _app(finta, risultato: risultato));

    // Senza modifiche si esce subito.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ScegliConvocatiScreen), findsNothing);

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rossi Marco'));
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Uscire senza salvare?'), findsOneWidget);
    await tester.tap(find.text('Resta'));
    await tester.pumpAndSettle();
    expect(find.byType(ScegliConvocatiScreen), findsOneWidget);
    expect(find.text('1 / 15 convocati'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esci senza salvare'));
    await tester.pumpAndSettle();
    expect(find.byType(ScegliConvocatiScreen), findsNothing);
    expect(finta.salvataggi, isEmpty);
    expect(risultato, [null, null]);
  });

  testWidgets('se il salvataggio fallisce la pagina resta e dice l\'errore', (
    tester,
  ) async {
    _telefono(tester);
    final finta = _DistintaFinta(errore: Exception('Numero già usato.'));
    await _apri(tester, _app(finta));

    await tester.tap(find.text('Rossi Marco'));
    await tester.pump();
    await tester.tap(_salva('Salva · 1 convocato'));
    await tester.pumpAndSettle();

    expect(find.byType(ScegliConvocatiScreen), findsOneWidget);
    expect(find.text('Numero già usato.'), findsOneWidget);
    // Si può riprovare.
    expect(
      tester.widget<FilledButton>(_salva('Salva · 1 convocato')).onPressed,
      isNotNull,
    );
  });

  testWidgets('su 360 px con testo ingrandito niente va fuori misura', (
    tester,
  ) async {
    _telefono(tester);
    final finta = _DistintaFinta(errore: Exception('Numero già usato.'));
    final ultima = _ultima({
      'bianchi': (numero: 7, capitano: true, viceCapitano: false),
      'neri': (numero: 13, capitano: false, viceCapitano: false),
    });
    await _apri(
      tester,
      _app(
        finta,
        testo: 1.3,
        ultima: ultima,
        distinta: [_riga('rossi', 3), _riga('verdi', 4, capitano: true)],
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Come l\'ultima partita'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Gialli Sara'), 200);
    await tester.tap(find.text('Gialli Sara'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Fino in fondo: l'altra squadra e il pulsante di salvataggio con
    // l'errore sopra.
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Numero già usato.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('su schermo largo i due pulsanti veloci stanno affiancati', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ultima = _ultima({
      'bianchi': (numero: 7, capitano: false, viceCapitano: false),
    });
    await _apri(tester, _app(_DistintaFinta(), ultima: ultima));

    // I pulsanti, non i testi: nei test il carattere è largo e può andare
    // a capo.
    final tutta = tester.getCenter(
      find.widgetWithText(OutlinedButton, 'Tutta la squadra'),
    );
    final comeUltima = tester.getCenter(
      find.widgetWithText(OutlinedButton, 'Come l\'ultima partita'),
    );
    expect(comeUltima.dy, tutta.dy);
    expect(comeUltima.dx, greaterThan(tutta.dx));
    expect(tester.takeException(), isNull);
  });
}
