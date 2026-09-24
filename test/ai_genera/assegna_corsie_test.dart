import 'package:coach_vasca/features/ai_genera/application/corsie_service.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/domain/personal_best.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(String id) => Atleta(
  id: id,
  clubId: 'c',
  nome: id,
  cognome: 'X',
  dataNascita: DateTime(2012),
  sport: 'nuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

PersonalBest _pb100(String atletaId, double tempoS, {int dist = 100}) =>
    PersonalBest(
      id: '$atletaId-$dist',
      atletaId: atletaId,
      clubId: 'c',
      stile: 'libero',
      distanzaM: dist,
      tempoS: tempoS,
    );

void main() {
  group('assegnaCorsie', () {
    test('tempi vicini: una sola corsia con tutti, nessun numero', () {
      final r = assegnaCorsie(
        [_atleta('a'), _atleta('b'), _atleta('c')],
        {
          'a': [_pb100('a', 60)],
          'b': [_pb100('b', 62)],
          'c': [_pb100('c', 64)],
        },
      );
      expect(r.divisoInDue, isFalse);
      expect(r.corsie.single.nome, 'Gruppo');
      expect(r.corsie.single.atletiIds, hasLength(3));
      expect(r.numeroCorsia('a'), isNull);
    });

    test('scarto oltre il 10%: due corsie, 1 = veloci e 2 = lenti', () {
      final r = assegnaCorsie(
        [_atleta('a'), _atleta('b'), _atleta('c'), _atleta('d')],
        {
          'a': [_pb100('a', 55)],
          'b': [_pb100('b', 58)],
          'c': [_pb100('c', 70)],
          'd': [_pb100('d', 75)],
        },
      );
      expect(r.divisoInDue, isTrue);
      expect(r.corsie.map((c) => c.nome), [
        'Corsia 1 (veloci)',
        'Corsia 2 (lenti)',
      ]);
      expect(r.numeroCorsia('a'), 1);
      expect(r.numeroCorsia('b'), 1);
      expect(r.numeroCorsia('c'), 2);
      expect(r.numeroCorsia('d'), 2);
    });

    test('chi non ha il PB sui 100 sl resta senza corsia e segnalato', () {
      final r = assegnaCorsie(
        [_atleta('a'), _atleta('b'), _atleta('z')],
        {
          'a': [_pb100('a', 55)],
          'b': [_pb100('b', 75)],
          'z': [_pb100('z', 90, dist: 50)],
        },
      );
      expect(r.senzaTempo, ['z']);
      expect(r.numeroCorsia('z'), isNull);
      expect(r.numeroCorsia('a'), 1);
      expect(r.numeroCorsia('b'), 2);
    });

    test('nessun atleta con tempi: nessuna corsia', () {
      final r = assegnaCorsie([_atleta('a')], {});
      expect(r.corsie, isEmpty);
      expect(r.senzaTempo, ['a']);
    });
  });
}
