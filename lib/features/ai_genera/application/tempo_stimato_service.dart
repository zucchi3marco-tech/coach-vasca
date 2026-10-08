import '../domain/scheda_generata.dart';

/// Passo medio della libreria di blocchi (s/100m, foglio Legenda
/// dell'Excel): lo stesso che usa la Edge Function senza corsie.
const _passoMedioS = 110.0;

/// Stima di riserva dei minuti di lavoro di una scheda, per quelle senza
/// la stima della Edge Function ([SchedaGenerata.minutiStimati], es. una
/// dettatura): la generazione calcola la sua, più precisa, con il passo
/// della corsia più lenta zona per zona (`stimaMinutiSessione` in
/// `supabase/functions/genera-allenamento/index.ts`).
///
/// Per ogni serie: se ha ripartenze, ripetute × la ripartenza più lenta
/// fra le corsie (è l'atleta che finisce per ultimo, e la ripartenza
/// comprende già il recupero); a tempo, ripetute × (durata + recupero);
/// altrimenti ripetute × (nuoto al passo medio + recupero).
int stimaMinutiSessione(List<SerieGenerata> serie) {
  var secondiTotali = 0.0;
  for (final s in serie) {
    final durata = s.durataS;
    if (durata != null) {
      secondiTotali += s.ripetute * (durata + (s.recuperoS ?? 0));
    } else if (s.ripartenzePerCorsia.isNotEmpty) {
      final ripartenzaPiuLenta = s.ripartenzePerCorsia
          .map((r) => r.ripartenzaS)
          .reduce((a, b) => a > b ? a : b);
      secondiTotali += s.ripetute * ripartenzaPiuLenta;
    } else {
      secondiTotali +=
          s.ripetute *
          ((s.distanzaM ?? 0) / 100 * _passoMedioS + (s.recuperoS ?? 0));
    }
  }
  return (secondiTotali / 60).round();
}
