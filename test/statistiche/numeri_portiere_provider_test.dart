import 'package:coach_vasca/features/pallanuoto/data/distinta_repository.dart';
import 'package:coach_vasca/features/pallanuoto/data/eventi_partita_repository.dart';
import 'package:coach_vasca/features/pallanuoto/data/partite_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/referti/data/referti_repository.dart';
import 'package:coach_vasca/features/referti/domain/referto_letto.dart';
import 'package:coach_vasca/features/referti/domain/referto_partita.dart';
import 'package:coach_vasca/features/statistiche/application/statistiche_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DistintaFinta implements DistintaRepository {
  @override
  Future<Map<String, List<int>>> tempiInPortaDellAtleta(
    String atletaId,
  ) async => {
    'p1': [1, 2, 3, 4],
    'p2': [1, 2],
    'fuori': [1, 2, 3, 4],
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EventoPartita _tiro(String partita, String esito) => EventoPartita(
  id: '$partita-$esito-${esito.hashCode}',
  partitaId: partita,
  clubId: 'c1',
  tipo: 'tiro',
  squadra: 'avversaria',
  esito: esito,
  portiereId: 'g1',
  creatoIl: DateTime(2026, 10, 24, 18),
);

class _EventiFinti implements EventiPartitaRepository {
  final tiri = [
    _tiro('p1', 'parato'),
    _tiro('p1', 'parato'),
    _tiro('p1', 'gol'),
  ];

  @override
  Future<List<EventoPartita>> perPortiere(String atletaId) async => tiri;

  @override
  Future<List<EventoPartita>> perPartite(List<String> partitaIds) async => [
    for (final e in tiri)
      if (partitaIds.contains(e.partitaId)) e,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Partita _partita(String id, DateTime data) => Partita(
  id: id,
  clubId: 'c1',
  data: data,
  squadraCasa: 'Noi',
  squadraTrasferta: 'Loro',
  numeroMaxConvocati: 15,
  tracciaTempo: false,
  nostraSquadra: 'casa',
);

class _PartiteFinte implements PartiteRepository {
  final tutte = [
    _partita('p1', DateTime(2026, 10, 10)),
    _partita('p2', DateTime(2026, 10, 17)),
    _partita('fuori', DateTime(2025, 3, 1)),
  ];

  @override
  Future<List<Partita>> perIds(List<String> ids) async => [
    for (final p in tutte)
      if (ids.contains(p.id)) p,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RefertiFinti implements RefertiRepository {
  RefertoPartita _referto(String partita, List<(int, int)> parziali) =>
      RefertoPartita(
        id: 'r$partita',
        partitaId: partita,
        clubId: 'c1',
        squadraCasa: 'Noi',
        squadraTrasferta: 'Loro',
        risultatoCasa: 0,
        risultatoTrasferta: 0,
        parziali: [
          for (final (c, t) in parziali) ParzialeReferto(casa: c, trasferta: t),
        ],
        giocatoriCasa: const [],
        giocatoriTrasferta: const [],
      );

  @override
  Future<List<RefertoPartita>> perPartite(List<String> partitaIds) async => [
    for (final id in partitaIds) _referto(id, [(2, 1), (1, 3), (0, 5), (0, 5)]),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _contenitore() {
  final c = ProviderContainer(
    overrides: [
      distintaRepositoryProvider.overrideWithValue(_DistintaFinta()),
      eventiPartitaRepositoryProvider.overrideWithValue(_EventiFinti()),
      partiteRepositoryProvider.overrideWithValue(_PartiteFinte()),
      refertiRepositoryProvider.overrideWithValue(_RefertiFinti()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test(
    'da sempre: dal vivo dove c\'è, dal referto negli altri tempi',
    () async {
      final c = _contenitore();
      final n = await c.read(
        numeriPortiereProvider((
          atletaId: 'g1',
          dataInizio: null,
          dataFine: null,
        )).future,
      );
      // p1 dal vivo (2 parate, 1 gol); p2 dal referto, tempi 1-2 (1 + 3);
      // 'fuori' dal referto, tutti i tempi (1 + 3 + 5 + 5).
      expect(n.partite, 3);
      expect(n.parate, 2);
      expect(n.golSubiti, 1 + 4 + 14);
      expect(n.golSubitiDalVivo, 1);
    },
  );

  test('con una stagione: solo le partite di quel periodo', () async {
    final c = _contenitore();
    final n = await c.read(
      numeriPortiereProvider((
        atletaId: 'g1',
        dataInizio: DateTime(2026, 9, 1),
        dataFine: DateTime(2027, 6, 30),
      )).future,
    );
    expect(n.partite, 2);
    expect(n.parate, 2);
    expect(n.golSubiti, 1 + 4);
    expect(n.percentualeParate, 67);
  });
}
