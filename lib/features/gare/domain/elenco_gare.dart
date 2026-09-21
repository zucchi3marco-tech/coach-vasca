import '../../../core/utils/gruppo_visibilita.dart';
import '../../stagioni/domain/evento_calendario.dart';
import '../../stagioni/domain/stagione.dart';
import 'gara.dart';

/// Le gare da mostrare nella tab Gare: quelle comprese nella stagione e
/// visibili al gruppo selezionato (le proprie e quelle di club), dalla
/// più vecchia alla più recente (a parità di giorno, per ora).
List<Gara> gareDellaStagione(
  Stagione stagione,
  Iterable<Gara> gare,
  String? gruppoSelezionato,
) {
  final inizio = soloGiorno(stagione.dataInizio);
  final fine = soloGiorno(stagione.dataFine);
  final risultato = [
    for (final g in gare)
      if (!soloGiorno(g.data).isBefore(inizio) &&
          !soloGiorno(g.data).isAfter(fine) &&
          visibileNelGruppo(
            gruppoDelRecord: g.gruppoId,
            gruppoSelezionato: gruppoSelezionato,
          ))
        g,
  ];
  risultato.sort((a, b) {
    final perGiorno = soloGiorno(a.data).compareTo(soloGiorno(b.data));
    if (perGiorno != 0) return perGiorno;
    return (a.ora ?? '').compareTo(b.ora ?? '');
  });
  return risultato;
}
