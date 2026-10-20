import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../../../core/utils/giorni.dart';
import '../data/schede_benessere_repository.dart';
import '../domain/scheda_benessere.dart';

/// Tutte le schede di un atleta, dalla piu' recente (aggiornate dal
/// server al primo ascolto, poi dalla cache locale in tempo reale).
final schedeBenessereAtletaProvider =
    StreamProvider.family<List<SchedaBenessere>, String>((ref, atletaId) {
      final repository = ref.watch(schedeBenessereRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemote(atletaId),
        watch: () => repository.watchPerAtleta(atletaId),
      );
    });

/// Le schede di tutto il club, per la vista squadra dell'allenatore.
final schedeBenessereClubProvider =
    StreamProvider.family<List<SchedaBenessere>, String>((ref, clubId) {
      final repository = ref.watch(schedeBenessereRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemoteClub(clubId),
        watch: () => repository.watchPerClub(clubId),
      );
    });

/// Il club e un giorno (a mezzanotte, vedi `soloData`).
typedef GiornoDelClub = ({String clubId, DateTime giorno});

/// La scheda di un giorno per ogni atleta del club (chiave: id atleta):
/// quella del giorno dell'appello accanto ai nomi, anche per un appello
/// passato.
final schedeDelGiornoClubProvider =
    Provider.family<Map<String, SchedaBenessere>, GiornoDelClub>((ref, chiave) {
      final schede =
          ref.watch(schedeBenessereClubProvider(chiave.clubId)).value ?? [];
      final giorno = chiave.giorno;
      return {
        for (final s in schede)
          if (s.data.year == giorno.year &&
              s.data.month == giorno.month &&
              s.data.day == giorno.day)
            s.atletaId: s,
      };
    });

/// Scheda di oggi per ogni atleta del club (chiave: id atleta).
final schedeOggiClubProvider =
    Provider.family<Map<String, SchedaBenessere>, String>(
      (ref, clubId) => ref.watch(
        schedeDelGiornoClubProvider((
          clubId: clubId,
          giorno: soloData(DateTime.now()),
        )),
      ),
    );

/// La scheda di oggi, se gia' compilata.
final schedaBenessereOggiProvider = Provider.family<SchedaBenessere?, String>((
  ref,
  atletaId,
) {
  final schede = ref.watch(schedeBenessereAtletaProvider(atletaId)).value;
  if (schede == null) return null;
  final oggi = DateTime.now();
  return schede
      .where(
        (s) =>
            s.data.year == oggi.year &&
            s.data.month == oggi.month &&
            s.data.day == oggi.day,
      )
      .firstOrNull;
});
