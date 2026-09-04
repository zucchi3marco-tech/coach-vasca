import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pallanuoto/data/eventi_partita_repository.dart';
import '../../pallanuoto/data/partite_repository.dart';
import '../../referti/data/referti_repository.dart';
import '../domain/statistiche_stagionali.dart';

typedef ChiaveStagioneStatistiche = ({
  String clubId,
  DateTime dataInizio,
  DateTime dataFine,
});

/// Statistiche di squadra "da referti", per tutte le partite del club con
/// data nel periodo indicato (tipicamente una Stagione).
final riepilogoRefertiProvider =
    FutureProvider.family<RiepilogoSquadraReferti, ChiaveStagioneStatistiche>((
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
/// con data nel periodo indicato (tipicamente una Stagione).
final riepilogoEventiProvider =
    FutureProvider.family<RiepilogoSquadraEventi, ChiaveStagioneStatistiche>((
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

      var tiriTot = 0;
      var golTot = 0;
      var golSuperioritaTot = 0;
      var golRigoreTot = 0;
      var espTot = 0;
      final partiteConEventi = <String>{};
      final perAtleta =
          <String, (int tiri, int gol, int golSup, int golRig, int esp)>{};

      for (final e in eventi) {
        final atletaId = e.atletaId;
        if (e.squadra != 'nostra' || atletaId == null) continue;
        if (e.tipo == 'tiro') {
          partiteConEventi.add(e.partitaId);
          tiriTot++;
          final isGol = e.esito == 'gol';
          final isSuperiorita = isGol && e.contestoTiro == 'superiorita';
          final isRigore = isGol && e.contestoTiro == 'rigore';
          if (isGol) golTot++;
          if (isSuperiorita) golSuperioritaTot++;
          if (isRigore) golRigoreTot++;
          final attuale = perAtleta[atletaId] ?? (0, 0, 0, 0, 0);
          perAtleta[atletaId] = (
            attuale.$1 + 1,
            attuale.$2 + (isGol ? 1 : 0),
            attuale.$3 + (isSuperiorita ? 1 : 0),
            attuale.$4 + (isRigore ? 1 : 0),
            attuale.$5,
          );
        } else if (e.tipo == 'espulsione') {
          partiteConEventi.add(e.partitaId);
          espTot++;
          final attuale = perAtleta[atletaId] ?? (0, 0, 0, 0, 0);
          perAtleta[atletaId] = (
            attuale.$1,
            attuale.$2,
            attuale.$3,
            attuale.$4,
            attuale.$5 + 1,
          );
        }
      }

      return RiepilogoSquadraEventi(
        partite: partiteConEventi.length,
        tiri: tiriTot,
        gol: golTot,
        golSuperiorita: golSuperioritaTot,
        golRigore: golRigoreTot,
        espulsioni: espTot,
        perAtleta: [
          for (final e in perAtleta.entries)
            RigaAtletaEventi(
              atletaId: e.key,
              tiri: e.value.$1,
              gol: e.value.$2,
              golSuperiorita: e.value.$3,
              golRigore: e.value.$4,
              espulsioni: e.value.$5,
            ),
        ],
      );
    });
