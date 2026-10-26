import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/obiettivi/data/obiettivi_repository.dart';
import 'package:coach_vasca/features/obiettivi/domain/scheda_obiettivi.dart';
import 'package:coach_vasca/features/obiettivi/presentation/nuova_scheda_screen.dart';
import 'package:coach_vasca/features/obiettivi/presentation/obiettivi_atleta_screen.dart';
import 'package:coach_vasca/features/obiettivi/presentation/risposta_obiettivi_screen.dart';
import 'package:coach_vasca/features/obiettivi/presentation/scheda_obiettivi_screen.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registra cosa si salva.
class _ObiettiviFinti implements ObiettiviRepository {
  final fatti = <String>[];

  @override
  Future<void> crea({
    required String clubId,
    required String? stagioneId,
    required String? gruppoId,
    required String titolo,
    required List<String> domande,
  }) async => fatti.add('crea $stagioneId $gruppoId $titolo $domande');

  @override
  Future<void> rispondi({
    required SchedaObiettivi scheda,
    required String atletaId,
    required List<String> risposte,
  }) async => fatti.add('rispondi ${scheda.id} $atletaId $risposte');

  @override
  Future<void> scriviRitorno(String rispostaId, String testo) async =>
      fatti.add('ritorno $rispostaId $testo');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Atleta _atleta(String id, String nome, {String? gruppo = 'g16'}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: 'Rossi',
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  gruppoId: gruppo,
);

final _luca = _atleta('a1', 'Luca');
final _marco = _atleta('a2', 'Marco');
final _piccolo = _atleta('a3', 'Piero', gruppo: 'g14');

SchedaObiettivi _scheda(
  String id, {
  bool chiusa = false,
  String? gruppo = 'g16',
}) => SchedaObiettivi(
  id: id,
  clubId: 'c1',
  stagioneId: 's1',
  gruppoId: gruppo,
  titolo: 'Scheda $id',
  domande: const ['Cosa vuoi migliorare?', 'Un obiettivo per il derby'],
  chiusa: chiusa,
  createdAt: DateTime(2026, 10, 1),
);

RispostaObiettivi _risposta(String scheda, String atleta, {String? ritorno}) =>
    RispostaObiettivi(
      id: 'r-$scheda-$atleta',
      schedaId: scheda,
      atletaId: atleta,
      clubId: 'c1',
      risposte: const ['Il tiro', 'Segnare'],
      ritorno: ritorno,
      inviataAt: DateTime(2026, 10, 3),
    );

final _stagione = Stagione(
  id: 's1',
  clubId: 'c1',
  nome: 'U16',
  dataInizio: DateTime(2026, 9, 1),
  dataFine: DateTime(2027, 6, 30),
  gruppoId: 'g16',
);

Future<_ObiettiviFinti> _apri(
  WidgetTester tester,
  Widget pagina, {
  List<SchedaObiettivi> schede = const [],
  List<RispostaObiettivi> risposte = const [],
}) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = _ObiettiviFinti();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        obiettiviRepositoryProvider.overrideWithValue(repository),
        schedeObiettiviProvider.overrideWith((ref, _) async => schede),
        risposteSchedaProvider.overrideWith(
          (ref, id) async => [
            for (final r in risposte)
              if (r.schedaId == id) r,
          ],
        ),
        risposteAtletaObiettiviProvider.overrideWith(
          (ref, id) async => [
            for (final r in risposte)
              if (r.atletaId == id) r,
          ],
        ),
        atletiListProvider.overrideWith(
          (ref, _) => Stream.value([_luca, _marco, _piccolo]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        home: Navigator(
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => Scaffold(body: pagina)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  test('la scheda arriva al gruppo, all\'altra squadra o a tutto il club', () {
    expect(_scheda('x').perAtleta(_luca), isTrue);
    expect(_scheda('x').perAtleta(_piccolo), isFalse);
    expect(_scheda('x', gruppo: null).perAtleta(_piccolo), isTrue);
    final conAltra = Atleta(
      id: 'a4',
      clubId: 'c1',
      nome: 'Ugo',
      cognome: 'Neri',
      dataNascita: DateTime(2010),
      sport: 'pallanuoto',
      consensoPrivacyFirmato: true,
      attivo: true,
      gruppoId: 'g14',
      altroGruppoId: 'g16',
    );
    expect(_scheda('x').perAtleta(conAltra), isTrue);
  });

  test('le domande pronte non chiedono della salute; le altre si notano', () {
    expect(domandeObiettiviPronte.where(sembraSullaSalute), isEmpty);
    expect(sembraSullaSalute('Hai avuto infortuni l\'anno scorso?'), isTrue);
    expect(sembraSullaSalute('Quanto pesi?'), isFalse);
    expect(sembraSullaSalute('Il tuo peso è cambiato?'), isTrue);
    expect(sembraSullaSalute('Cosa vuoi migliorare nel tiro?'), isFalse);
  });

  test('scheda e risposta si leggono dal database', () {
    final s = SchedaObiettivi.fromMap({
      'id': 's9',
      'club_id': 'c1',
      'stagione_id': 's1',
      'gruppo_id': null,
      'titolo': 'Obiettivi',
      'domande': ['Uno', 'Due'],
      'chiusa': true,
      'created_at': '2026-10-26T10:00:00Z',
    });
    expect(s.domande, ['Uno', 'Due']);
    expect(s.chiusa, isTrue);
    final r = RispostaObiettivi.fromMap({
      'id': 'r1',
      'scheda_id': 's9',
      'atleta_id': 'a1',
      'club_id': 'c1',
      'risposte': ['a', 'b'],
      'ritorno': 'Bene',
      'ritorno_at': '2026-10-27T10:00:00Z',
      'inviata_at': '2026-10-26T12:00:00Z',
    });
    expect(r.risposte, ['a', 'b']);
    expect(r.ritorno, 'Bene');
    expect(r.ritornoAt, isNotNull);
  });

  testWidgets('l\'allenatore sceglie le domande e manda la scheda', (
    tester,
  ) async {
    final repository = await _apri(
      tester,
      NuovaSchedaScreen(stagione: _stagione),
    );
    expect(find.text('Obiettivi di inizio stagione'), findsOneWidget);

    // Toglie la seconda pronta, ne aggiunge una sua.
    await tester.tap(find.text(domandeObiettiviPronte[1]).first);
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Hai avuto infortuni?',
    );
    await tester.pump();
    expect(find.textContaining('Sembra una domanda sulla salute'), findsOne);
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Chi è il tuo modello in acqua?',
    );
    await tester.pump();
    expect(
      find.textContaining('Sembra una domanda sulla salute'),
      findsNothing,
    );
    await tester.tap(find.text('Aggiungi la domanda'));
    await tester.pump();

    await tester.ensureVisible(find.text('Manda agli atleti'));
    await tester.tap(find.text('Manda agli atleti'));
    await tester.pumpAndSettle();
    expect(repository.fatti, [
      'crea s1 g16 Obiettivi di inizio stagione '
          '[${domandeObiettiviPronte[0]}, ${domandeObiettiviPronte[2]}, '
          'Chi è il tuo modello in acqua?]',
    ]);
  });

  testWidgets('l\'atleta risponde e manda', (tester) async {
    final repository = await _apri(
      tester,
      RispostaObiettiviScreen(scheda: _scheda('s1'), atleta: _luca),
    );
    await tester.enterText(find.byType(TextFormField).at(0), ' Il tiro ');
    await tester.enterText(find.byType(TextFormField).at(1), 'Segnare');
    await tester.tap(find.text('Manda all\'allenatore'));
    await tester.pumpAndSettle();
    expect(repository.fatti, ['rispondi s1 a1 [ Il tiro , Segnare]']);
  });

  testWidgets('a scheda chiusa l\'atleta legge risposte e ritorno', (
    tester,
  ) async {
    await _apri(
      tester,
      RispostaObiettiviScreen(
        scheda: _scheda('s1', chiusa: true),
        atleta: _luca,
        risposta: _risposta('s1', 'a1', ritorno: 'Bene, lavoriamo sulla gamba'),
      ),
    );
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Il tiro'), findsOneWidget);
    expect(find.text('Bene, lavoriamo sulla gamba'), findsOneWidget);
    expect(find.text('Salva le correzioni'), findsNothing);
  });

  testWidgets('l\'allenatore scrive le sue due righe', (tester) async {
    final repository = await _apri(
      tester,
      RispostaObiettiviScreen(
        scheda: _scheda('s1'),
        atleta: _luca,
        risposta: _risposta('s1', 'a1'),
        perAllenatore: true,
      ),
    );
    // Le risposte si leggono, non si cambiano.
    expect(find.text('Il tiro'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Bene il tiro');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(repository.fatti, ['ritorno r-s1-a1 Bene il tiro']);
  });

  testWidgets('nella scheda: chi ha risposto e chi no, solo del gruppo', (
    tester,
  ) async {
    await _apri(
      tester,
      SchedaObiettiviScreen(scheda: _scheda('s1')),
      risposte: [_risposta('s1', 'a2')],
    );
    expect(find.text('Risposte (1 di 2)'), findsOneWidget);
    expect(find.textContaining('scrivi le tue due righe'), findsOneWidget);
    expect(find.text('Non ha ancora risposto'), findsOneWidget);
    expect(find.text('Piero Rossi'), findsNothing);
  });

  testWidgets('nella home: solo le schede aperte senza risposta', (
    tester,
  ) async {
    await _apri(
      tester,
      CardSchedeObiettivi(atleta: _luca),
      schede: [
        _scheda('aperta'),
        _scheda('fatta'),
        _scheda('chiusa', chiusa: true),
        _scheda('altro', gruppo: 'g14'),
      ],
      risposte: [_risposta('fatta', 'a1')],
    );
    expect(find.text('Scheda da compilare'), findsOneWidget);
    expect(find.text('Scheda aperta'), findsOneWidget);

    await tester.tap(find.text('Scheda aperta'));
    await tester.pumpAndSettle();
    expect(find.byType(RispostaObiettiviScreen), findsOneWidget);
  });

  testWidgets('«I miei obiettivi»: tutte le sue, con lo stato', (tester) async {
    await _apri(
      tester,
      ObiettiviAtletaScreen(atleta: _luca),
      schede: [_scheda('aperta'), _scheda('fatta')],
      risposte: [_risposta('fatta', 'a1', ritorno: 'Bene')],
    );
    expect(find.text('Da compilare'), findsOneWidget);
    expect(find.text('C\'è il ritorno dell\'allenatore'), findsOneWidget);
  });
}
