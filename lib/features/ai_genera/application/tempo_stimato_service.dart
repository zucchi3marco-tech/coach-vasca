import '../domain/scheda_generata.dart';

/// Stima i minuti di lavoro di una scheda: tempo di nuoto (dalla
/// ripartenza più lenta fra le corsie di ogni serie — è l'atleta che
/// finisce per ultimo) più i recuperi, sommati su tutte le serie.
///
/// Stessa formula, tenuta manualmente sincronizzata, della funzione
/// `stimaMinutiSessione` dentro `supabase/functions/genera-allenamento/
/// index.ts` (che è la fonte di verità per il vincolo bloccante: qui
/// serve solo a mostrare una stima informativa in `SchedaGenerataScreen`).
///
/// Una serie senza `ripartenzePerCorsia` (niente corsie calcolate, es.
/// nessun atleta del gruppo con i PB necessari) non ha un passo noto: la
/// sua parte di nuoto non entra nella stima, che diventa quindi
/// un'approssimazione **per difetto** in quel caso — mai un rifiuto
/// ingiustificato per mancanza di dati.
int stimaMinutiSessione(List<SerieGenerata> serie) {
  var secondiTotali = 0.0;
  for (final s in serie) {
    if (s.ripartenzePerCorsia.isNotEmpty) {
      final ripartenzaPiuLenta = s.ripartenzePerCorsia
          .map((r) => r.ripartenzaS)
          .reduce((a, b) => a > b ? a : b);
      secondiTotali += s.ripetute * (s.distanzaM / 100) * ripartenzaPiuLenta;
    }
    secondiTotali += s.ripetute * (s.recuperoS ?? 0);
  }
  return (secondiTotali / 60).round();
}
