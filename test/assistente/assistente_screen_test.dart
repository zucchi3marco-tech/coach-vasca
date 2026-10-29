import 'dart:convert';

import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/data/allenamenti_repository.dart';
import 'package:coach_vasca/features/allenamenti/data/seduta_aperta_repository.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/assistente/data/assistente_repository.dart';
import 'package:coach_vasca/features/assistente/presentation/assistente_screen.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/distinta_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/presenze/application/presenze_providers.dart';
import 'package:coach_vasca/features/presenze/data/presenze_repository.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(String id, String nome, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: cognome,
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  gruppoId: 'u14',
);

final _partita = Partita(
  id: 'p1',
  clubId: 'c1',
  gruppoId: 'u14',
  data: DateTime(2026, 10, 17),
  squadraCasa: 'Noi',
  squadraTrasferta: 'Recco',
  numeroMaxConvocati: 15,
);

/// Il "cervello" finto: prima chiede di proporre la convocazione, poi
/// risponde. Annota cosa gli arriva.
class _AssistenteFinto implements AssistenteRepository {
  final arrivati = <List<Map<String, dynamic>>>[];

  @override
  Future<Map<String, dynamic>> prossimoMessaggio({
    required String clubId,
    required Map<String, Object?> contesto,
    required List<Map<String, dynamic>> messaggi,
  }) async {
    arrivati.add(messaggi);
    if (arrivati.length == 1) {
      return {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {
            'id': 't1',
            'type': 'function',
            'function': {
              'name': 'proponi_convocazione',
              'arguments': '{"partita_id": "p1", "atleti": ["G2", "G1"]}',
            },
          },
        ],
      };
    }
    return {
      'role': 'assistant',
      'content': 'Ti ho proposto G2 e G1: controlla e conferma.',
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DistintaFinta implements DistintaRepository {
  final aggiunti = <(String, int)>[];

  @override
  Future<DistintaGiocatore> aggiungiConvocato({
    required String partitaId,
    required String atletaId,
    required int numeroCalottina,
    bool portiere = false,
  }) async {
    aggiunti.add((atletaId, numeroCalottina));
    return DistintaGiocatore(
      id: 'd$numeroCalottina',
      partitaId: partitaId,
      atletaId: atletaId,
      clubId: 'c1',
      numeroCalottina: numeroCalottina,
      capitano: false,
      viceCapitano: false,
      portiere: portiere,
      fuoriquota: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Il "cervello" finto dell'appello: "assenti G1".
class _AssistenteAppello implements AssistenteRepository {
  var chiamate = 0;

  @override
  Future<Map<String, dynamic>> prossimoMessaggio({
    required String clubId,
    required Map<String, Object?> contesto,
    required List<Map<String, dynamic>> messaggi,
  }) async {
    if (chiamate++ == 0) {
      return {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {
            'id': 't1',
            'type': 'function',
            'function': {
              'name': 'proponi_appello',
              'arguments': '{"assenti": ["G1"]}',
            },
          },
        ],
      };
    }
    return {'role': 'assistant', 'content': 'Ecco l\'appello da salvare.'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Il "cervello" finto del messaggio alle famiglie: "G2 porti il
/// documento". Si tiene quello che riceve, per controllare i nomi.
class _AssistenteMessaggio implements AssistenteRepository {
  var chiamate = 0;
  final ricevuti = <List<Map<String, dynamic>>>[];

  @override
  Future<Map<String, dynamic>> prossimoMessaggio({
    required String clubId,
    required Map<String, Object?> contesto,
    required List<Map<String, dynamic>> messaggi,
  }) async {
    ricevuti.add([...messaggi]);
    if (chiamate++ == 0) {
      return {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {
            'id': 't1',
            'type': 'function',
            'function': {
              'name': 'proponi_messaggio_famiglie',
              'arguments': jsonEncode({
                'testo': '*Documento*\nG2 porti il documento sabato.',
              }),
            },
          },
        ],
      };
    }
    return {'role': 'assistant', 'content': 'Ecco il messaggio.'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PresenzeFinte implements PresenzeRepository {
  final segnate = <(String, String)>[];

  @override
  Future<Presenza> segnaPresenza({
    required String allenamentoId,
    required String atletaId,
    required String stato,
  }) async {
    segnate.add((atletaId, stato));
    return Presenza(
      id: 'p-$atletaId',
      allenamentoId: allenamentoId,
      atletaId: atletaId,
      clubId: 'c1',
      stato: stato,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _sedutaA1 = Allenamento(
  id: 'a1',
  clubId: 'c1',
  gruppoId: 'u14',
  data: DateTime(2026, 10, 12),
  titolo: 'Tecnica',
);

const _serieA1 = [
  Serie(
    id: 's1',
    allenamentoId: 'a1',
    clubId: 'c1',
    ordine: 1,
    blocco: 'riscaldamento',
    ripetute: 1,
    distanzaM: 400,
    stile: 'libero',
    esecuzione: 'nuoto',
    zona: 'A1',
    esito: 'fatta',
  ),
];

/// Il "cervello" finto delle modifiche: aggiunge un 4x50 e cambia il
/// titolo. Annota il contesto.
class _AssistenteModifica implements AssistenteRepository {
  final contesti = <Map<String, Object?>>[];

  @override
  Future<Map<String, dynamic>> prossimoMessaggio({
    required String clubId,
    required Map<String, Object?> contesto,
    required List<Map<String, dynamic>> messaggi,
  }) async {
    contesti.add(contesto);
    if (contesti.length == 1) {
      return {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {
            'id': 't1',
            'type': 'function',
            'function': {
              'name': 'proponi_modifica_seduta',
              'arguments':
                  '{"allenamento_id": "a1", "titolo": "Gambe", "testo": '
                  '"Riscaldamento\\n400 sl A1\\n4x50 sl gambe"}',
            },
          },
        ],
      };
    }
    return {'role': 'assistant', 'content': 'Ecco le modifiche da salvare.'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Le serie salvate: annota cosa si crea, si cambia e si toglie.
class _SerieFinte implements SerieRepository {
  final chiamate = <String>[];

  @override
  Future<List<Serie>> fetchPerAllenamento(String allenamentoId) async =>
      _serieA1;

  @override
  dynamic noSuchMethod(Invocation i) {
    final a = i.namedArguments;
    chiamate.add(switch (i.memberName) {
      #createSerie => 'crea ${a[#ordine]}: ${a[#ripetute]}x${a[#distanzaM]}',
      #updateSerie => 'aggiorna ${a[#id]}',
      #deleteSerie => 'togli ${i.positionalArguments.first}',
      _ => '${i.memberName}',
    });
    return Future<Serie>.value(_serieA1.first);
  }
}

class _AllenamentiFinti implements AllenamentiRepository {
  final titoli = <String?>[];

  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #updateAllenamento) {
      titoli.add(i.namedArguments[#titolo] as String?);
    }
    return Future<Allenamento>.value(_sedutaA1);
  }
}

void main() {
  testWidgets('dalla pagina della seduta: prima e dopo, poi si salvano solo i '
      'cambi', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final assistente = _AssistenteModifica();
    final serie = _SerieFinte();
    final allenamenti = _AllenamentiFinti();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistenteRepositoryProvider.overrideWithValue(assistente),
          serieRepositoryProvider.overrideWithValue(serie),
          allenamentiRepositoryProvider.overrideWithValue(allenamenti),
          sedutaApertaRepositoryProvider.overrideWithValue(
            SedutaApertaRepository(null),
          ),
          atletiListProvider.overrideWith(
            (ref, filtro) => Stream.value([_atleta('rossi', 'Marco', 'Rossi')]),
          ),
          gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
          allenamentiListProvider.overrideWith(
            (ref, clubId) => Stream.value([_sedutaA1]),
          ),
          serieListProvider.overrideWith((ref, id) => Stream.value(_serieA1)),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: AssistenteScreen(
            clubId: 'c1',
            gruppoId: 'u14',
            seduta: _sedutaA1,
            oggi: DateTime(2026, 10, 13, 18),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Cambia «Tecnica»'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('domanda-assistente')),
      'Aggiungi 4x50 gambe e chiamala Gambe',
    );
    await tester.tap(find.byTooltip('Chiedi'));
    await tester.pumpAndSettle();

    // Il modello sa da che seduta si parla.
    expect((assistente.contesti.first['seduta_aperta']! as Map)['id'], 'a1');
    expect(find.text('+'), findsOneWidget);
    expect(find.text('4x50 sl gambe'), findsOneWidget);
    expect(
      find.text('Titolo: Tecnica → Gambe', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('400 m → 600 m · 1 serie → 2 serie'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Salva le modifiche'));
    await tester.pumpAndSettle();
    // Il 400 (già fatto) non si tocca: si crea solo il 4x50.
    expect(serie.chiamate, ['crea 2: 4x50']);
    expect(allenamenti.titoli, ['Gambe']);
    expect(find.text('Seduta aggiornata'), findsOneWidget);
    // Aperto dalla seduta: si torna indietro, niente «Apri».
    expect(find.widgetWithText(TextButton, 'Apri'), findsNothing);
  });

  testWidgets("l'appello con una frase: si cambia uno stato, si salvano solo "
      'i cambi', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final presenze = _PresenzeFinte();
    final oggi = DateTime(2026, 10, 13, 18);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistenteRepositoryProvider.overrideWithValue(_AssistenteAppello()),
          presenzeRepositoryProvider.overrideWithValue(presenze),
          atletiListProvider.overrideWith(
            (ref, filtro) => Stream.value([
              _atleta('rossi', 'Marco', 'Rossi'),
              _atleta('bianchi', 'Luca', 'Bianchi'),
              _atleta('verdi', 'Sara', 'Verdi'),
            ]),
          ),
          gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
          allenamentiListProvider.overrideWith(
            (ref, clubId) => Stream.value([
              Allenamento(
                id: 'a1',
                clubId: 'c1',
                gruppoId: 'u14',
                data: DateTime(2026, 10, 13),
              ),
            ]),
          ),
          presenzeClubProvider.overrideWith(
            (ref, clubId) => Stream.value(const [
              Presenza(
                id: 'pv',
                allenamentoId: 'a1',
                atletaId: 'verdi',
                clubId: 'c1',
                stato: 'presente',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: AssistenteScreen(clubId: 'c1', gruppoId: 'u14', oggi: oggi),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('domanda-assistente')),
      'Assenti Bianchi',
    );
    await tester.tap(find.byTooltip('Chiedi'));
    await tester.pumpAndSettle();

    // Bianchi assente, gli altri presenti; Verdi era già segnato.
    expect(find.text('2 presenti · 1 assente'), findsOneWidget);
    expect(find.text('Verdi · già segnato'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appello-rossi')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('In ritardo').last);
    await tester.pumpAndSettle();
    expect(find.text('2 presenti (di cui 1 in ritardo) · 1 assente'), findsOne);

    await tester.tap(find.widgetWithText(FilledButton, 'Salva l\'appello'));
    await tester.pumpAndSettle();
    // Verdi non cambia: non si riscrive.
    expect(
      presenze.segnate,
      unorderedEquals([('bianchi', 'assente'), ('rossi', 'ritardo')]),
    );
    expect(find.text('Appello salvato'), findsOneWidget);
  });

  testWidgets('il messaggio alle famiglie: si corregge e si copia', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final assistente = _AssistenteMessaggio();
    String? copiato;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (chiamata) async {
        if (chiamata.method == 'Clipboard.setData') {
          copiato = (chiamata.arguments as Map)['text'] as String?;
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistenteRepositoryProvider.overrideWithValue(assistente),
          atletiListProvider.overrideWith(
            (ref, filtro) => Stream.value([
              _atleta('rossi', 'Marco', 'Rossi'),
              _atleta('bianchi', 'Luca', 'Bianchi'),
            ]),
          ),
          gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
          allenamentiListProvider.overrideWith(
            (ref, clubId) => Stream.value(const []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: AssistenteScreen(
            clubId: 'c1',
            gruppoId: 'u14',
            oggi: DateTime(2026, 10, 13, 18),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('domanda-assistente')),
      'Scrivi ai genitori che Rossi porti il documento',
    );
    await tester.tap(find.byTooltip('Chiedi'));
    await tester.pumpAndSettle();

    // Al modello il codice, nella scheda cognome e nome.
    expect(jsonEncode(assistente.ricevuti), isNot(contains('Rossi')));
    final campo = find.byKey(const Key('messaggio-famiglie'));
    expect(
      tester.widget<TextField>(campo).controller!.text,
      '*Documento*\nRossi Marco porti il documento sabato.',
    );

    await tester.enterText(
      campo,
      '*Documento*\nRossi Marco porti il documento domenica.',
    );
    await tester.tap(find.widgetWithText(SecondaryButton, 'Copia'));
    await tester.pumpAndSettle();
    expect(copiato, '*Documento*\nRossi Marco porti il documento domenica.');
    expect(
      find.text('Messaggio copiato: incollalo nel gruppo WhatsApp'),
      findsOneWidget,
    );
  });

  testWidgets("l'assistente propone la distinta e l'allenatore la conferma", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final assistente = _AssistenteFinto();
    final distinta = _DistintaFinta();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistenteRepositoryProvider.overrideWithValue(assistente),
          distintaRepositoryProvider.overrideWithValue(distinta),
          atletiListProvider.overrideWith(
            (ref, filtro) => Stream.value([
              _atleta('rossi', 'Marco', 'Rossi'),
              _atleta('bianchi', 'Luca', 'Bianchi'),
            ]),
          ),
          gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
          partiteListProvider.overrideWith(
            (ref, clubId) => Stream.value([_partita]),
          ),
          distintaListProvider.overrideWith((ref, id) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: AssistenteScreen(
            clubId: 'c1',
            gruppoId: 'u14',
            oggi: DateTime(2026, 10, 13, 18),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chiedi all\'assistente'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('domanda-assistente')),
      'Convoca Rossi e Bianchi per sabato',
    );
    await tester.tap(find.byTooltip('Chiedi'));
    await tester.pumpAndSettle();

    // Al modello la domanda con i codici.
    expect(
      assistente.arrivati.first.single['content'],
      'Convoca G2 e G1 per sabato',
    );
    // All'allenatore i nomi: la proposta e la risposta.
    expect(
      find.text('Ti ho proposto Rossi e Bianchi: controlla e conferma.'),
      findsOneWidget,
    );
    expect(find.text('Rossi'), findsOneWidget);
    expect(find.text('Bianchi'), findsOneWidget);
    expect(find.text('Ha letto: distinta'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Convoca'));
    await tester.pumpAndSettle();
    // Come in distinta: l'1 resta al portiere, i giocatori dal 2.
    expect(distinta.aggiunti, [('rossi', 2), ('bianchi', 3)]);
    expect(find.text('Convocati in distinta'), findsOneWidget);
  });
}
