import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
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

/// Scheda di oggi per ogni atleta del club (chiave: id atleta).
final schedeOggiClubProvider =
    Provider.family<Map<String, SchedaBenessere>, String>((ref, clubId) {
      final schede = ref.watch(schedeBenessereClubProvider(clubId)).value ?? [];
      final oggi = DateTime.now();
      return {
        for (final s in schede)
          if (s.data.year == oggi.year &&
              s.data.month == oggi.month &&
              s.data.day == oggi.day)
            s.atletaId: s,
      };
    });

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
