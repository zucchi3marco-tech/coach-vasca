import '../../../core/utils/gruppo_visibilita.dart';
import '../../gare/domain/gara.dart';
import '../../pallanuoto/domain/partita.dart';
import 'stagione.dart';

enum TipoEventoCalendario { partita, gara }

/// Un evento da mostrare nel calendario di una stagione: una partita
/// (pallanuoto) o una gara (nuoto). [gruppoId] nullo = evento di club,
/// visibile a tutti i gruppi. [origine] è l'oggetto di dominio da cui
/// nasce (`Partita`, `Gara`), per aprirlo al tocco.
class EventoCalendario {
  const EventoCalendario({
    required this.id,
    required this.tipo,
    required this.data,
    required this.gruppoId,
    required this.titolo,
    required this.origine,
    this.sottotitolo,
  });

  factory EventoCalendario.daPartita(Partita p) {
    final dettagli = [
      if (p.ora != null && p.ora!.isNotEmpty) p.ora!,
      if (p.luogo != null && p.luogo!.isNotEmpty) p.luogo!,
    ];
    return EventoCalendario(
      id: p.id,
      tipo: TipoEventoCalendario.partita,
      data: p.data,
      gruppoId: p.gruppoId,
      titolo: '${p.squadraCasa} - ${p.squadraTrasferta}',
      sottotitolo: dettagli.isEmpty ? null : dettagli.join(' · '),
      origine: p,
    );
  }

  factory EventoCalendario.daGara(Gara g) {
    final dettagli = [
      if (g.ora != null && g.ora!.isNotEmpty) g.ora!,
      if (g.luogo != null && g.luogo!.isNotEmpty) g.luogo!,
    ];
    return EventoCalendario(
      id: g.id,
      tipo: TipoEventoCalendario.gara,
      data: g.data,
      gruppoId: g.gruppoId,
      titolo: g.nome,
      sottotitolo: dettagli.isEmpty ? null : dettagli.join(' · '),
      origine: g,
    );
  }

  final String id;
  final TipoEventoCalendario tipo;
  final DateTime data;
  final String? gruppoId;
  final String titolo;
  final String? sottotitolo;
  final Object origine;

  bool get diClub => gruppoId == null;
}

/// La data senza ora: chiave per raggruppare gli eventi per giorno.
DateTime soloGiorno(DateTime d) => DateTime(d.year, d.month, d.day);

/// Gli eventi da mostrare nel calendario di [stagione]: quelli compresi
/// fra inizio e fine stagione e visibili al suo gruppo (gruppo proprio +
/// eventi di club). Una stagione di club (senza gruppo) mostra tutti gli
/// eventi del club.
List<EventoCalendario> eventiVisibiliInStagione(
  Stagione stagione,
  Iterable<EventoCalendario> eventi,
) {
  final inizio = soloGiorno(stagione.dataInizio);
  final fine = soloGiorno(stagione.dataFine);
  return [
    for (final e in eventi)
      if (!soloGiorno(e.data).isBefore(inizio) &&
          !soloGiorno(e.data).isAfter(fine) &&
          visibileNelGruppo(
            gruppoDelRecord: e.gruppoId,
            gruppoSelezionato: stagione.gruppoId,
          ))
        e,
  ];
}

Map<DateTime, List<EventoCalendario>> raggruppaEventiPerGiorno(
  Iterable<EventoCalendario> eventi,
) {
  final mappa = <DateTime, List<EventoCalendario>>{};
  for (final e in eventi) {
    mappa.putIfAbsent(soloGiorno(e.data), () => []).add(e);
  }
  return mappa;
}
