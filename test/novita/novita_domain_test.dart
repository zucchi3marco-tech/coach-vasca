import 'package:coach_vasca/features/novita/domain/novita.dart';
import 'package:flutter_test/flutter_test.dart';

Novita _n(
  String id, {
  bool importante = false,
  PerChi perChi = PerChi.allenatori,
}) => Novita(
  id: id,
  data: DateTime(2026, 10, 19),
  titolo: id,
  testo: 'Testo $id',
  importante: importante,
  perChi: perChi,
);

void main() {
  group('registro', () {
    test('non è vuoto, ha id unici e testi scritti', () {
      expect(registroNovita, isNotEmpty);
      final id = registroNovita.map((n) => n.id).toList();
      expect(id.toSet().length, id.length);
      for (final n in registroNovita) {
        expect(n.titolo.trim(), isNotEmpty);
        expect(n.testo.trim(), isNotEmpty);
        expect(n.id, matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')));
      }
    });

    test('è dalla più recente alla più vecchia', () {
      for (var i = 1; i < registroNovita.length; i++) {
        expect(
          registroNovita[i].data.isAfter(registroNovita[i - 1].data),
          isFalse,
          reason: '${registroNovita[i].id} è più recente della precedente',
        );
      }
    });
  });

  group('perAtleta', () {
    test('allenatori, atleti e tutti', () {
      expect(_n('a').perAtleta(false), isTrue);
      expect(_n('a').perAtleta(true), isFalse);
      expect(_n('a', perChi: PerChi.atleti).perAtleta(true), isTrue);
      expect(_n('a', perChi: PerChi.atleti).perAtleta(false), isFalse);
      expect(_n('a', perChi: PerChi.tutti).perAtleta(true), isTrue);
      expect(_n('a', perChi: PerChi.tutti).perAtleta(false), isTrue);
    });
  });

  group('novitaDaMostrare', () {
    final registro = [
      _n('d', importante: true),
      _n('c', importante: true, perChi: PerChi.atleti),
      _n('b'),
      _n('a', importante: true, perChi: PerChi.tutti),
    ];

    List<String> ids(String? vista, {bool atleta = false}) => [
      for (final n in novitaDaMostrare(
        registro: registro,
        ultimaVista: vista,
        atleta: atleta,
      ))
        n.id,
    ];

    test('telefono nuovo: niente', () {
      expect(ids(null), isEmpty);
    });

    test('id sconosciuto: niente', () {
      expect(ids('zzz'), isEmpty);
    });

    test('già vista la più recente: niente', () {
      expect(ids('d'), isEmpty);
    });

    test('solo le importanti uscite dopo, per l\'allenatore', () {
      expect(ids('a'), ['d']);
      expect(ids('b'), ['d']);
    });

    test('per l\'atleta', () {
      expect(ids('a', atleta: true), ['c']);
    });

    test('non include la novità già vista', () {
      expect(ids('c'), ['d']);
    });

    test('registro vuoto: niente', () {
      expect(
        novitaDaMostrare(registro: const [], ultimaVista: 'a', atleta: false),
        isEmpty,
      );
    });
  });

  group('novitaPer', () {
    final registro = [
      _n('d'),
      _n('c', perChi: PerChi.atleti),
      _n('b', perChi: PerChi.tutti),
      _n('a'),
    ];

    test('allenatore: allenatori e tutti, in ordine', () {
      expect(
        [for (final n in novitaPer(registro: registro, atleta: false)) n.id],
        ['d', 'b', 'a'],
      );
    });

    test('atleta: atleti e tutti, in ordine', () {
      expect(
        [for (final n in novitaPer(registro: registro, atleta: true)) n.id],
        ['c', 'b'],
      );
    });
  });
}
