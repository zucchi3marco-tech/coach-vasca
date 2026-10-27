import 'package:coach_vasca/features/pallanuoto/data/eventi_partita_repository.dart';
import 'package:coach_vasca/features/pallanuoto/data/partite_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/referti/data/referti_repository.dart';
import 'package:coach_vasca/features/referti/domain/referto_partita.dart';
import 'package:coach_vasca/features/statistiche/application/statistiche_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// La segnalazione del 27 ottobre 2026: le stagioni U16 e U14 hanno le
// stesse date, e nelle statistiche U16 c'era anche la partita U14.

Partita _partita(String id, DateTime data, String? gruppoId) => Partita(
  id: id,
  clubId: 'c1',
  gruppoId: gruppoId,
  data: data,
  squadraCasa: 'Noi',
  squadraTrasferta: 'Loro',
  numeroMaxConvocati: 15,
  tracciaTempo: false,
  nostraSquadra: 'casa',
);

class _PartiteFinte implements PartiteRepository {
  final tutte = [
    _partita('u16', DateTime(2026, 10, 24), 'gU16'),
    _partita('u14', DateTime(2026, 10, 25), 'gU14'),
    _partita('club', DateTime(2026, 10, 26), null),
  ];

  @override
  Future<List<Partita>> perClubEPeriodo({
    required String clubId,
    required DateTime dataInizio,
    required DateTime dataFine,
  }) async => tutte;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RefertiFinti implements RefertiRepository {
  @override
  Future<List<RefertoPartita>> perPartite(List<String> partitaIds) async => [
    for (final id in partitaIds)
      RefertoPartita(
        id: 'r$id',
        partitaId: id,
        clubId: 'c1',
        squadraCasa: 'Noi',
        squadraTrasferta: 'Loro',
        // U16 perde 14-21, U14 vince 11-3, quella di club pari 5-5.
        risultatoCasa: switch (id) {
          'u16' => 14,
          'u14' => 11,
          _ => 5,
        },
        risultatoTrasferta: switch (id) {
          'u16' => 21,
          'u14' => 3,
          _ => 5,
        },
        parziali: const [],
        giocatoriCasa: const [],
        giocatoriTrasferta: const [],
      ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EventiFinti implements EventiPartitaRepository {
  @override
  Future<List<EventoPartita>> perPartite(List<String> partitaIds) async => [
    for (final id in partitaIds)
      EventoPartita(
        id: 'e$id',
        partitaId: id,
        clubId: 'c1',
        tipo: 'tiro',
        squadra: 'nostra',
        esito: 'gol',
        posX: 0.5,
        posY: 0.5,
        creatoIl: DateTime(2026, 10, 24, 18),
      ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _contenitore() {
  final c = ProviderContainer(
    overrides: [
      partiteRepositoryProvider.overrideWithValue(_PartiteFinte()),
      refertiRepositoryProvider.overrideWithValue(_RefertiFinti()),
      eventiPartitaRepositoryProvider.overrideWithValue(_EventiFinti()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

ChiaveStagioneStatistiche _chiave(String? gruppoId) => (
  clubId: 'c1',
  dataInizio: DateTime(2026, 9, 1),
  dataFine: DateTime(2027, 6, 30),
  gruppoId: gruppoId,
);

void main() {
  test('la stagione U16 conta solo le partite U16 e quelle di club', () async {
    final r = await _contenitore().read(
      riepilogoRefertiProvider(_chiave('gU16')).future,
    );
    expect(r.partite, 2);
    expect(r.golFatti, 14 + 5);
    expect(r.golSubiti, 21 + 5);
    expect(r.vittorie, 0);
  });

  test('la stagione U14 conta la sua, non quella U16', () async {
    final r = await _contenitore().read(
      riepilogoRefertiProvider(_chiave('gU14')).future,
    );
    expect(r.partite, 2);
    expect(r.vittorie, 1);
    expect(r.golFatti, 11 + 5);
  });

  test('dal vivo e mappa dei tiri: la stessa regola', () async {
    final c = _contenitore();
    final eventi = await c.read(
      riepilogoEventiProvider(_chiave('gU16')).future,
    );
    expect(eventi.partite, 2);
    final tiri = await c.read(
      tiriStagionePerMappaProvider(_chiave('gU16')).future,
    );
    expect({for (final t in tiri) t.partitaId}, {'u16', 'club'});
  });

  test('senza squadra (un atleta): tutte le partite del club', () async {
    final r = await _contenitore().read(
      riepilogoRefertiProvider(_chiave(null)).future,
    );
    expect(r.partite, 3);
  });
}
