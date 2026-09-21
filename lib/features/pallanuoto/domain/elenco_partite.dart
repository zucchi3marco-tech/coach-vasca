import '../../../core/utils/gruppo_visibilita.dart';
import '../../stagioni/domain/evento_calendario.dart';
import '../../stagioni/domain/stagione.dart';
import 'partita.dart';

/// Le partite da mostrare nella tab Partite: quelle comprese nella
/// stagione e visibili al gruppo selezionato (le proprie e quelle di
/// club), dalla più vecchia alla più recente (a parità di giorno, per ora).
List<Partita> partiteDellaStagione(
  Stagione stagione,
  Iterable<Partita> partite,
  String? gruppoSelezionato,
) {
  final inizio = soloGiorno(stagione.dataInizio);
  final fine = soloGiorno(stagione.dataFine);
  final risultato = [
    for (final p in partite)
      if (!soloGiorno(p.data).isBefore(inizio) &&
          !soloGiorno(p.data).isAfter(fine) &&
          visibileNelGruppo(
            gruppoDelRecord: p.gruppoId,
            gruppoSelezionato: gruppoSelezionato,
          ))
        p,
  ];
  risultato.sort((a, b) {
    final perGiorno = soloGiorno(a.data).compareTo(soloGiorno(b.data));
    if (perGiorno != 0) return perGiorno;
    return (a.ora ?? '').compareTo(b.ora ?? '');
  });
  return risultato;
}
