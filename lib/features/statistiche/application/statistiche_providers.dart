import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pallanuoto/data/distinta_repository.dart';
import '../../pallanuoto/data/eventi_partita_repository.dart';
import '../../pallanuoto/data/partite_repository.dart';
import '../../pallanuoto/domain/evento_partita.dart';
import '../../pallanuoto/domain/numeri_portiere.dart';
import '../../pallanuoto/domain/statistiche_eventi.dart';
import '../../referti/data/referti_repository.dart';
import '../domain/statistiche_stagionali.dart';

typedef ChiaveStagioneStatistiche = ({
  String clubId,
  DateTime dataInizio,
  DateTime dataFine,
});

/// Statistiche di squadra "da referti", per tutte le partite del club con
/// data nel periodo indicato (tipicamente una Stagione).
///
/// `autoDispose`: senza, il risultato resta in cache per l'intera sessione
/// una volta calcolato — se la schermata viene aperta prima che una
/// partita/referto esista ancora, mostrerebbe per sempre lo stesso
/// riepilogo vuoto anche dopo aver registrato dati veri, finché l'app non
/// viene riavviata.
final riepilogoRefertiProvider = FutureProvider.autoDispose
    .family<RiepilogoSquadraReferti, ChiaveStagioneStatistiche>((
      ref,
      chiave,
    ) async {
      final partite = await ref
          .watch(partiteRepositoryProvider)
          .perClubEPeriodo(
            clubId: chiave.clubId,
            dataInizio: chiave.dataInizio,
            dataFine: chiave.dataFine,
          );
      if (partite.isEmpty) return RiepilogoSquadraReferti.vuoto;

      final partitaPerId = {for (final p in partite) p.id: p};
      final referti = await ref
          .watch(refertiRepositoryProvider)
          .perPartite(partitaPerId.keys.toList());

      var vittorie = 0;
      var pareggi = 0;
      var sconfitte = 0;
      var golFatti = 0;
      var golSubiti = 0;
      final perAtleta = <String, (int reti, int espulsioni, int partite)>{};

      for (final r in referti) {
        final partita = partitaPerId[r.partitaId];
        if (partita == null) continue;
        final nostraCasa = partita.nostraSquadra == 'casa';
        final golNostri = nostraCasa ? r.risultatoCasa : r.risultatoTrasferta;
        final golAvversari = nostraCasa
            ? r.risultatoTrasferta
            : r.risultatoCasa;
        golFatti += golNostri;
        golSubiti += golAvversari;
        if (golNostri > golAvversari) {
          vittorie++;
        } else if (golNostri == golAvversari) {
          pareggi++;
        } else {
          sconfitte++;
        }

        final nostriGiocatori = nostraCasa
            ? r.giocatoriCasa
            : r.giocatoriTrasferta;
        for (final g in nostriGiocatori) {
          final atletaId = g.atletaId;
          if (atletaId == null) continue;
          final attuale = perAtleta[atletaId] ?? (0, 0, 0);
          perAtleta[atletaId] = (
            attuale.$1 + g.reti,
            attuale.$2 + g.espulsioni,
            attuale.$3 + 1,
          );
        }
      }

      return RiepilogoSquadraReferti(
        partite: referti.length,
        vittorie: vittorie,
        pareggi: pareggi,
        sconfitte: sconfitte,
        golFatti: golFatti,
        golSubiti: golSubiti,
        perAtleta: [
          for (final e in perAtleta.entries)
            RigaAtletaReferti(
              atletaId: e.key,
              reti: e.value.$1,
              espulsioni: e.value.$2,
              partite: e.value.$3,
            ),
        ],
      );
    });

/// Statistiche di squadra "da eventi live", per tutte le partite del club
/// con data nel periodo indicato (tipicamente una Stagione). Vedi la nota
/// su `autoDispose` di [riepilogoRefertiProvider]: stesso motivo.
final riepilogoEventiProvider = FutureProvider.autoDispose
    .family<RiepilogoSquadraEventi, ChiaveStagioneStatistiche>((
      ref,
      chiave,
    ) async {
      final partite = await ref
          .watch(partiteRepositoryProvider)
          .perClubEPeriodo(
            clubId: chiave.clubId,
            dataInizio: chiave.dataInizio,
            dataFine: chiave.dataFine,
          );
      if (partite.isEmpty) return RiepilogoSquadraEventi.vuoto;

      final eventi = await ref
          .watch(eventiPartitaRepositoryProvider)
          .perPartite([for (final p in partite) p.id]);
      return RiepilogoSquadraEventi.da(StatisticheEventi.da(eventi));
    });

/// Tiri grezzi (con posizione) di tutte le partite del club nel periodo
/// indicato, per la mappa di calore di squadra: stessa fonte dati di
/// [riepilogoEventiProvider], solo senza l'aggregazione. Stesso motivo di
/// `autoDispose` delle altre due.
final tiriStagionePerMappaProvider = FutureProvider.autoDispose
    .family<List<EventoPartita>, ChiaveStagioneStatistiche>((
      ref,
      chiave,
    ) async {
      final partite = await ref
          .watch(partiteRepositoryProvider)
          .perClubEPeriodo(
            clubId: chiave.clubId,
            dataInizio: chiave.dataInizio,
            dataFine: chiave.dataFine,
          );
      if (partite.isEmpty) return [];

      final eventi = await ref
          .watch(eventiPartitaRepositoryProvider)
          .perPartite([for (final p in partite) p.id]);
      return [
        for (final e in eventi)
          if (e.tipo == 'tiro' && e.posX != null && e.posY != null) e,
      ];
    });

/// Un portiere e, se serve, il periodo (una stagione): senza periodo
/// vale "da sempre".
typedef ChiaveNumeriPortiere = ({
  String atletaId,
  DateTime? dataInizio,
  DateTime? dataFine,
});

/// Parate e gol subiti di un portiere: parte dalle partite in cui è
/// stato in porta (tempi della distinta) o ha affrontato tiri dal vivo,
/// e usa [numeriPortiere] su eventi e referti di quelle partite.
final numeriPortiereProvider = FutureProvider.autoDispose
    .family<NumeriPortiere, ChiaveNumeriPortiere>((ref, chiave) async {
      final tempi = await ref
          .watch(distintaRepositoryProvider)
          .tempiInPortaDellAtleta(chiave.atletaId);
      final suoiTiri = await ref
          .watch(eventiPartitaRepositoryProvider)
          .perPortiere(chiave.atletaId);
      final ids = {...tempi.keys, for (final e in suoiTiri) e.partitaId};
      if (ids.isEmpty) return NumeriPortiere.vuoto;

      final dal = chiave.dataInizio;
      final al = chiave.dataFine;
      final partite = [
        for (final p
            in await ref.watch(partiteRepositoryProvider).perIds(ids.toList()))
          if ((dal == null || !p.data.isBefore(dal)) &&
              (al == null || !p.data.isAfter(al)))
            p,
      ];
      if (partite.isEmpty) return NumeriPortiere.vuoto;

      final idPartite = [for (final p in partite) p.id];
      final eventi = await ref
          .watch(eventiPartitaRepositoryProvider)
          .perPartite(idPartite);
      final referti = await ref
          .watch(refertiRepositoryProvider)
          .perPartite(idPartite);
      return numeriPortiere(
        atletaId: chiave.atletaId,
        partite: partite,
        tempiInPorta: tempi,
        eventi: eventi,
        referti: {for (final r in referti) r.partitaId: r},
      );
    });
