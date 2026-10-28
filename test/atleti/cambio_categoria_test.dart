import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/data/atleti_repository.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/domain/categoria_fin.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/gruppi/presentation/cambio_categoria_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(
  String id,
  String cognome,
  int annoNascita, {
  String? gruppoId = 'u14',
  bool attivo = true,
  String? altroGruppoId,
}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Luca',
  cognome: cognome,
  dataNascita: DateTime(annoNascita, 3, 1),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: attivo,
  gruppoId: gruppoId,
  altroGruppoId: altroGruppoId,
  giorniAltroGruppo: altroGruppoId == null ? const [] : const [2, 4],
  note: 'Mancino',
);

const _squadre = [
  Gruppo(id: 'u14', clubId: 'c1', nome: 'U14', ordine: 1),
  Gruppo(id: 'u16', clubId: 'c1', nome: 'Under 16', ordine: 2),
  Gruppo(id: 'prima', clubId: 'c1', nome: 'Prima squadra', ordine: 3),
];

// Nel 2027-28 (anno 2028) i 2013 passano da U14 a U16, i 2011 da U16 a U18.
final _atleti = [
  _atleta('a1', 'Rossi', 2013),
  _atleta('a2', 'Bianchi', 2013, altroGruppoId: 'u16'),
  // Resta U14.
  _atleta('a3', 'Verdi', 2014),
  // Già negli U16 sotto età: l'allenatore l'ha messo lì.
  _atleta('a4', 'Neri', 2013, gruppoId: 'u16'),
  // Il club non ha una squadra U18.
  _atleta('a5', 'Gialli', 2011, gruppoId: 'u16'),
  _atleta('a7', 'Arancio', 2013, gruppoId: null),
  _atleta('a8', 'Viola', 2013, attivo: false),
  // In prima squadra gioca chi decide l'allenatore.
  _atleta('a9', 'Grigi', 2011, gruppoId: 'prima'),
];

class _AtletiFinti implements AtletiRepository {
  final spostati = <String, Atleta>{};

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
    final nuovo = Atleta(
      id: originale.id,
      clubId: originale.clubId,
      nome: nome,
      cognome: cognome,
      dataNascita: dataNascita,
      sport: originale.sport,
      consensoPrivacyFirmato: consensoPrivacyFirmato,
      attivo: originale.attivo,
      gruppoId: gruppoId,
      note: note,
      altroGruppoId: altroGruppoId,
      giorniAltroGruppo: giorniAltroGruppo,
    );
    spostati[originale.id] = nuovo;
    return nuovo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(_AtletiFinti repository, Widget pagina) => ProviderScope(
  overrides: [
    atletiRepositoryProvider.overrideWithValue(repository),
    atletiListProvider.overrideWith((ref, filtro) => Stream.value(_atleti)),
    gruppiListProvider.overrideWith((ref, clubId) => Stream.value(_squadre)),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => Scaffold(body: pagina)),
    ),
  ),
);

void main() {
  test('chi cambia categoria e la squadra proposta', () {
    final cambi = cambiDiCategoria(
      atleti: _atleti,
      squadre: _squadre,
      annoStagione: 2028,
    );
    expect(
      [
        for (final c in cambi)
          '${c.atleta.cognome} ${c.da}→${c.a} ${c.squadraProposta?.id}',
      ],
      [
        'Arancio U14→U16 u16',
        'Bianchi U14→U16 u16',
        'Rossi U14→U16 u16',
        'Gialli U16→U18 null',
      ],
    );
  });

  test('a metà stagione, dopo gli spostamenti, non resta nessuno', () {
    // Oggi (2026-27) i 2012 sono già negli U16, come nella Canottieri vera.
    final cambi = cambiDiCategoria(
      atleti: [
        _atleta('x', 'Rossi', 2012, gruppoId: 'u16'),
        _atleta('y', 'Verdi', 2013),
      ],
      squadre: _squadre,
      annoStagione: 2027,
    );
    expect(cambi, isEmpty);
  });

  test('il riquadro solo a settembre e ottobre', () {
    expect(inizioStagioneSportiva(DateTime(2027, 8, 31)), isFalse);
    expect(inizioStagioneSportiva(DateTime(2027, 9, 1)), isTrue);
    expect(inizioStagioneSportiva(DateTime(2027, 10, 31)), isTrue);
    expect(inizioStagioneSportiva(DateTime(2027, 11, 1)), isFalse);
  });

  testWidgets('si toglie la spunta a chi resta, poi «Sposta»', (tester) async {
    tester.view.physicalSize = const Size(480, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _AtletiFinti();
    // Dalla pagina di prima, dove si torna dopo «Sposta».
    await tester.pumpWidget(
      _app(
        repository,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CambioCategoriaScreen(
                  clubId: 'c1',
                  annoStagione: 2028,
                ),
              ),
            ),
            child: const Text('Apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Nel 2027-28 salgono di categoria 4 atleti'),
      findsOneWidget,
    );
    expect(find.text('Negli U16'), findsOneWidget);
    expect(find.text('Negli U18'), findsOneWidget);
    expect(find.text('classe 2013 · senza squadra'), findsOneWidget);
    // Tre proposti negli U16; Gialli aspetta che si scelga la squadra.
    expect(find.text('Sposta 3 atleti'), findsOneWidget);

    // Arancio resta dov'è.
    final riga = find.ancestor(
      of: find.text('Arancio Luca'),
      matching: find.byType(InkWell),
    );
    await tester.tap(
      find.descendant(of: riga, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sposta 2 atleti'), findsOneWidget);

    await tester.tap(find.text('Sposta 2 atleti'));
    await tester.pumpAndSettle();

    expect(repository.spostati.keys.toSet(), {'a1', 'a2'});
    expect(repository.spostati['a1']!.gruppoId, 'u16');
    expect(repository.spostati['a1']!.note, 'Mancino');
    // Bianchi si allenava già con gli U16 in giorni fissi: non servono più.
    expect(repository.spostati['a2']!.gruppoId, 'u16');
    expect(repository.spostati['a2']!.altroGruppoId, isNull);
    expect(repository.spostati['a2']!.giorniAltroGruppo, isEmpty);
    expect(find.text('Spostati 2 atleti.'), findsOneWidget);
  });

  testWidgets('il riquadro in «Squadre» a ottobre, non a novembre', (
    tester,
  ) async {
    final repository = _AtletiFinti();
    await tester.pumpWidget(
      _app(
        repository,
        RiquadroCambioCategoria(clubId: 'c1', oggi: DateTime(2027, 10, 3)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chi cambia categoria'), findsOneWidget);
    expect(
      find.text('Nel 2027-28 salgono di categoria 4 atleti'),
      findsOneWidget,
    );

    // Un albero nuovo: il Navigator della prova non ricostruisce la pagina.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _app(
        repository,
        RiquadroCambioCategoria(clubId: 'c1', oggi: DateTime(2027, 11, 3)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chi cambia categoria'), findsNothing);
  });
}
