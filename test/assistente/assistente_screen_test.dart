import 'package:coach_vasca/features/assistente/data/assistente_repository.dart';
import 'package:coach_vasca/features/assistente/presentation/assistente_screen.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/distinta_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
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

void main() {
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
            sport: 'pallanuoto',
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
