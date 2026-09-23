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

    test('una serie con una sola corsia: nuoto + recupero', () {
      final serie = [
        _serie(
          ripetute: 8,
          distanzaM: 100,
          recuperoS: 20,
          ripartenze: const [RipartenzaCorsia(nome: 'Gruppo', ripartenzaS: 90)],
        ),
      ];
      // 8 * (100/100) * 90 = 720s nuoto; 8 * 20 = 160s recupero; 880s = 14.67 -> 15 min
      expect(stimaMinutiSessione(serie), 15);
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
      // 4 * 1 * 100 = 400s = 6.67 -> 7 min (non la corsia veloce, 4*70=280s)
      expect(stimaMinutiSessione(serie), 7);
    });

    test('una serie senza ripartenze non aggiunge tempo di nuoto (solo il '
        'recupero, se presente): stima per difetto, non un rifiuto', () {
      final serie = [_serie(ripetute: 10, distanzaM: 50, recuperoS: 30)];
      expect(stimaMinutiSessione(serie), 5); // 10*30 = 300s = 5 min
    });

    test('somma su più serie', () {
      final serie = [
        _serie(
          ripetute: 1,
          distanzaM: 400,
          ripartenze: const [RipartenzaCorsia(nome: 'Gruppo', ripartenzaS: 90)],
        ),
        _serie(
          ripetute: 8,
          distanzaM: 100,
          recuperoS: 20,
          ripartenze: const [RipartenzaCorsia(nome: 'Gruppo', ripartenzaS: 85)],
        ),
      ];
      // riscaldamento: 4*90=360s; principale: 8*85 + 8*20 = 680+160=840s
      // totale 1200s = 20 min
      expect(stimaMinutiSessione(serie), 20);
    });
  });
}
