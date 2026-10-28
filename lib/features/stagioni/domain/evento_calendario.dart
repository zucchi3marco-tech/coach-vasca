import '../../../core/utils/gruppo_visibilita.dart';
import '../../../core/utils/date_italiane.dart';
import '../../impegni/domain/impegno.dart';
import '../../pallanuoto/domain/partita.dart';
import 'stagione.dart';

enum TipoEventoCalendario { partita, impegno }

/// Un evento da mostrare nel calendario di una stagione: una partita o un
/// giorno di un impegno. [gruppoId] nullo = evento di club, visibile a
/// tutti i gruppi. [origine] è l'oggetto di dominio da cui nasce
/// (`Partita`, `Impegno`), per aprirlo al tocco.
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

  /// Un giorno di un impegno (collegiale, riposo…): ogni giorno ha il suo
  /// evento, perché il calendario segna i giorni. [origine] è l'`Impegno`.
  factory EventoCalendario.daImpegno(Impegno i, DateTime giorno) {
    final dettagli = [
      if (i.nome?.trim().isNotEmpty ?? false) i.tipo.etichetta,
      if (i.giorni > 1) periodoImpegno(i, dataCompatta),
      if (i.luogo != null && i.luogo!.isNotEmpty) i.luogo!,
    ];
    return EventoCalendario(
      id: '${i.id}@${soloGiorno(giorno).toIso8601String()}',
      tipo: TipoEventoCalendario.impegno,
      data: soloGiorno(giorno),
      gruppoId: i.gruppoId,
      titolo: i.titolo,
      sottotitolo: dettagli.isEmpty ? null : dettagli.join(' · '),
      origine: i,
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

  bool get impegno => tipo == TipoEventoCalendario.impegno;
}

/// Un evento per ogni giorno di ogni impegno.
List<EventoCalendario> eventiDaImpegni(Iterable<Impegno> impegni) => [
  for (final i in impegni)
    for (final giorno in i.elencoGiorni) EventoCalendario.daImpegno(i, giorno),
];

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

/// I prossimi eventi di un atleta: da oggi in poi, visibili al suo gruppo
/// (gli eventi del suo gruppo e quelli di tutto il club), dal più vicino,
/// al massimo [massimo].
List<EventoCalendario> prossimiEventi(
  Iterable<EventoCalendario> eventi,
  String? gruppoAtleta,
  DateTime oggi, {
  int massimo = 3,
}) {
  final da = soloGiorno(oggi);
  final risultato = [
    for (final e in eventi)
      if (!soloGiorno(e.data).isBefore(da) &&
          visibileNelGruppo(
            gruppoDelRecord: e.gruppoId,
            gruppoSelezionato: gruppoAtleta,
          ))
        e,
  ]..sort((a, b) => soloGiorno(a.data).compareTo(soloGiorno(b.data)));
  return risultato.take(massimo).toList();
}
