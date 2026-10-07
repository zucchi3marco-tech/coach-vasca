import 'package:coach_vasca/features/ai_genera/application/tempo_stimato_service.dart';
import 'package:coach_vasca/features/ai_genera/domain/scheda_generata.dart';
import 'package:flutter_test/flutter_test.dart';

SerieGenerata _serie({
  int ripetute = 1,
  int distanzaM = 100,
  int? recuperoS,
  List<RipartenzaCorsia> ripartenze = const [],
}) => SerieGenerata(
  ordine: 1,
  blocco: 'principale',
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: 'libero',
  esecuzione: 'nuoto',
  recuperoS: recuperoS,
  ripartenzePerCorsia: ripartenze,
);

void main() {
  group('stimaMinutiSessione', () {
    test('nessuna serie: zero minuti', () {
      expect(stimaMinutiSessione(const []), 0);
    });

    test('una serie con una sola corsia: la ripartenza comprende già il '
        'recupero', () {
      final serie = [
        _serie(
          ripetute: 8,
          distanzaM: 100,
          recuperoS: 20,
          ripartenze: const [RipartenzaCorsia(nome: 'Gruppo', ripartenzaS: 90)],
        ),
      ];
      // 8 * 90 = 720s = 12 min (il recupero è già dentro la ripartenza)
      expect(stimaMinutiSessione(serie), 12);
    });

    test('più corsie: usa la ripartenza più lenta (quella che finisce per '
        'ultima)', () {
      final serie = [
        _serie(
          ripetute: 4,
          distanzaM: 100,
          ripartenze: const [
            RipartenzaCorsia(nome: 'Veloci', ripartenzaS: 70),
            RipartenzaCorsia(nome: 'Lenti', ripartenzaS: 100),
          ],
        ),
      ];
      // 4 * 100 = 400s = 6.67 -> 7 min (non la corsia veloce, 4*70=280s)
      expect(stimaMinutiSessione(serie), 7);
    });

    test('una serie senza ripartenze conta il nuoto al passo medio della '
        'libreria (110 s/100m) più il recupero', () {
      final serie = [_serie(ripetute: 10, distanzaM: 50, recuperoS: 30)];
      // 10 * (55 + 30) = 850s = 14.17 -> 14 min
      expect(stimaMinutiSessione(serie), 14);
    });

    test('un riscaldamento senza ripartenze non vale più zero minuti', () {
      final serie = [_serie(ripetute: 1, distanzaM: 400)];
      expect(stimaMinutiSessione(serie), 7); // 4 * 110 = 440s = 7.33 -> 7
    });

    test('somma su più serie', () {
      final serie = [
        _serie(
          ripetute: 1,
          distanzaM: 400,
          ripartenze: const [
            RipartenzaCorsia(nome: 'Gruppo', ripartenzaS: 400),
          ],
        ),
        _serie(
          ripetute: 8,
          distanzaM: 100,
          recuperoS: 20,
          ripartenze: const [RipartenzaCorsia(nome: 'Gruppo', ripartenzaS: 85)],
        ),
      ];
      // riscaldamento: 400s; principale: 8*85 = 680s; totale 1080s = 18 min
      expect(stimaMinutiSessione(serie), 18);
    });
  });

  group('SchedaGenerata.minutiStimati', () {
    Map<String, dynamic> risposta({Object? minuti}) => {
      'titolo': 'Seduta',
      'note': null,
      'serie': [_serie(ripetute: 4, distanzaM: 100).toMap()],
      'minutiStimati': ?minuti,
    };

    test('legge la stima della Edge Function e la conserva in toMap', () {
      final scheda = SchedaGenerata.fromMap(risposta(minuti: 58));
      expect(scheda.minutiStimati, 58);
      expect(SchedaGenerata.fromMap(scheda.toMap()).minutiStimati, 58);
    });

    test('senza stima (es. dettatura) resta null', () {
      expect(SchedaGenerata.fromMap(risposta()).minutiStimati, isNull);
    });
  });
}
