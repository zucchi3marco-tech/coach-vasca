import 'package:coach_vasca/features/allenamenti/data/allenamenti_repository.dart';
import 'package:coach_vasca/features/allenamenti/data/duplicazione_settimana_service.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Allenamenti implements AllenamentiRepository {
  final creati =
      <
        ({
          DateTime data,
          String? gruppoId,
          String? titolo,
          String tipo,
          int? durataMin,
        })
      >[];

  @override
  Future<Allenamento> createAllenamento({
    required String clubId,
    required DateTime data,
    String? titolo,
    String? gruppoId,
    String? note,
    String tipo = 'acqua',
    int? durataMin,
  }) async {
    creati.add((
      data: data,
      gruppoId: gruppoId,
      titolo: titolo,
      tipo: tipo,
      durataMin: durataMin,
    ));
    return Allenamento(
      id: 'copia',
      clubId: clubId,
      data: data,
      titolo: titolo,
      gruppoId: gruppoId,
      tipo: tipo,
      durataMin: durataMin,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Gli esercizi a secco: annota le sedute copiate.
class _Secco implements SeccoRepository {
  final copie = <({String da, String a})>[];

  @override
  Future<void> copiaSeduta({
    required String daAllenamentoId,
    required String aAllenamentoId,
    required String clubId,
  }) async => copie.add((da: daAllenamentoId, a: aAllenamentoId));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Serie implements SerieRepository {
  _Serie(this.originali);

  final List<Serie> originali;
  final create =
      <
        ({
          String allenamentoId,
          int ordine,
          int? durataS,
          String? gruppo,
          Destinatari destinatari,
        })
      >[];
  final momenti = <String?>[];

  @override
  Future<List<Serie>> fetchPerAllenamento(String allenamentoId) async =>
      originali;

  @override
  Future<Serie> createSerie({
    required String allenamentoId,
    required int ordine,
    required String blocco,
    required int ripetute,
    int? distanzaM,
    int? durataS,
    required String stile,
    required String esecuzione,
    String? zona,
    double? passoObiettivoS,
    int? recuperoS,
    double? ripartenzaS,
    String? attrezzatura,
    String? note,
    String? piramideId,
    int? recuperoDopoS,
    Destinatari destinatari = Destinatari.tutti,
    String? momentoId,
  }) async {
    create.add((
      allenamentoId: allenamentoId,
      ordine: ordine,
      durataS: durataS,
      gruppo: piramideId,
      destinatari: destinatari,
    ));
    momenti.add(momentoId);
    return originali.first;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Serie _serie(
  int ordine, {
  String? piramideId,
  int? durataS,
  Destinatari destinatari = Destinatari.tutti,
  String? momentoId,
}) => Serie(
  momentoId: momentoId,
  id: 's$ordine',
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: 'principale',
  ripetute: 2,
  distanzaM: durataS == null ? 100 : null,
  durataS: durataS,
  stile: 'libero',
  esecuzione: 'nuoto',
  piramideId: piramideId,
  esito: 'fatta',
  destinatari: destinatari,
);

void main() {
  test('duplica per un\'altra squadra: serie e gruppi copiati', () async {
    final allenamenti = _Allenamenti();
    final serie = _Serie([
      _serie(1),
      _serie(2, piramideId: 'g-vecchio'),
      _serie(3, piramideId: 'g-vecchio'),
      _serie(4, durataS: 300),
    ]);
    final copia =
        await DuplicazioneSettimanaService(
          allenamenti,
          serie,
          _Secco(),
        ).copiaAllenamento(
          Allenamento(
            id: 'a1',
            clubId: 'c1',
            data: DateTime(2026, 10, 8, 18),
            titolo: 'Aerobico',
            gruppoId: 'u14',
          ),
          data: DateTime(2026, 10, 9, 18),
          gruppoId: 'u16',
        );

    expect(copia.gruppoId, 'u16');
    expect(allenamenti.creati.single.titolo, 'Aerobico');
    expect(allenamenti.creati.single.data, DateTime(2026, 10, 9, 18));
    expect(serie.create, hasLength(4));
    expect(serie.create.every((c) => c.allenamentoId == 'copia'), isTrue);
    // Il gruppo resta un gruppo, con un id nuovo.
    expect(serie.create[0].gruppo, isNull);
    expect(serie.create[1].gruppo, isNotNull);
    expect(serie.create[1].gruppo, serie.create[2].gruppo);
    expect(serie.create[1].gruppo, isNot('g-vecchio'));
    expect(serie.create[3].durataS, 300);
  });

  test('un lavoro in parallelo resta insieme, con un momento nuovo', () async {
    final serie = _Serie([
      _serie(1, momentoId: 'm-vecchio'),
      _serie(2, momentoId: 'm-vecchio', destinatari: Destinatari.portieri),
      _serie(3),
    ]);
    await DuplicazioneSettimanaService(
      _Allenamenti(),
      serie,
      _Secco(),
    ).copiaAllenamento(
      Allenamento(
        id: 'a1',
        clubId: 'c1',
        data: DateTime(2026, 10, 8, 18),
        gruppoId: 'u14',
      ),
      data: DateTime(2026, 10, 9, 18),
      gruppoId: 'u16',
    );
    expect(serie.momenti[0], isNotNull);
    expect(serie.momenti[0], isNot('m-vecchio'));
    expect(serie.momenti[1], serie.momenti[0]);
    expect(serie.momenti[2], isNull);
  });

  test(
    "per chi: per la stessa squadra resta, per un'altra solo il ruolo",
    () async {
      Allenamento sorgente() => Allenamento(
        id: 'a1',
        clubId: 'c1',
        data: DateTime(2026, 10, 8, 18),
        gruppoId: 'u14',
      );
      List<Serie> originali() => [
        _serie(1, destinatari: Destinatari.portieri),
        _serie(2, destinatari: const Destinatari(soloAtleti: ['rossi'])),
        _serie(
          3,
          destinatari: const Destinatari(
            ruolo: 'movimento',
            tranneAtleti: ['rossi'],
          ),
        ),
      ];

      final stessa = _Serie(originali());
      await DuplicazioneSettimanaService(
        _Allenamenti(),
        stessa,
        _Secco(),
      ).copiaAllenamento(
        sorgente(),
        data: DateTime(2026, 10, 15, 18),
        gruppoId: 'u14',
      );
      expect(stessa.create.map((c) => c.destinatari), [
        for (final s in originali()) s.destinatari,
      ]);

      final altra = _Serie(originali());
      await DuplicazioneSettimanaService(
        _Allenamenti(),
        altra,
        _Secco(),
      ).copiaAllenamento(
        sorgente(),
        data: DateTime(2026, 10, 9, 18),
        gruppoId: 'u16',
      );
      // La variante di Rossi non va all'altra squadra; l'ordine si ricompatta.
      expect(altra.create.map((c) => c.ordine), [1, 2]);
      expect(altra.create.map((c) => c.destinatari), [
        Destinatari.portieri,
        Destinatari.movimento,
      ]);
    },
  );

  test(
    'una seduta a secco si copia con durata ed esercizi, senza serie',
    () async {
      final allenamenti = _Allenamenti();
      final serie = _Serie(const []);
      final secco = _Secco();
      await DuplicazioneSettimanaService(
        allenamenti,
        serie,
        secco,
      ).copiaAllenamento(
        Allenamento(
          id: 's1',
          clubId: 'c1',
          data: DateTime(2026, 10, 14),
          titolo: 'Prevenzione spalla',
          gruppoId: 'u14',
          tipo: 'secco',
          durataMin: 40,
        ),
        data: DateTime(2026, 10, 21),
        gruppoId: 'u14',
      );

      expect(allenamenti.creati.single.tipo, 'secco');
      expect(allenamenti.creati.single.durataMin, 40);
      expect(secco.copie.single, (da: 's1', a: 'copia'));
      expect(serie.create, isEmpty);
    },
  );
}
