import 'package:coach_vasca/features/allenamenti/data/allenamenti_repository.dart';
import 'package:coach_vasca/features/allenamenti/data/duplicazione_settimana_service.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:flutter_test/flutter_test.dart';

class _Allenamenti implements AllenamentiRepository {
  final creati = <({DateTime data, String? gruppoId, String? titolo})>[];

  @override
  Future<Allenamento> createAllenamento({
    required String clubId,
    required DateTime data,
    String? titolo,
    String? gruppoId,
    String? note,
  }) async {
    creati.add((data: data, gruppoId: gruppoId, titolo: titolo));
    return Allenamento(
      id: 'copia',
      clubId: clubId,
      data: data,
      titolo: titolo,
      gruppoId: gruppoId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Serie implements SerieRepository {
  _Serie(this.originali);

  final List<Serie> originali;
  final create = <({String allenamentoId, int? durataS, String? gruppo})>[];

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
  }) async {
    create.add((
      allenamentoId: allenamentoId,
      durataS: durataS,
      gruppo: piramideId,
    ));
    return originali.first;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Serie _serie(int ordine, {String? piramideId, int? durataS}) => Serie(
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
    final copia = await DuplicazioneSettimanaService(allenamenti, serie)
        .copiaAllenamento(
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
}
