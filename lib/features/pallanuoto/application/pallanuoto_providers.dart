import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/distinta_repository.dart';
import '../data/eventi_partita_repository.dart';
import '../data/partite_repository.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';

final partiteListProvider = StreamProvider.family<List<Partita>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(partiteRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(clubId),
    watch: () => repository.watchPerClub(clubId),
  );
});

final distintaListProvider =
    StreamProvider.family<List<DistintaGiocatore>, String>((ref, partitaId) {
      final repository = ref.watch(distintaRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemote(partitaId),
        watch: () => repository.watchPerPartita(partitaId),
      );
    });

final eventiPartitaListProvider =
    StreamProvider.family<List<EventoPartita>, String>((ref, partitaId) {
      final repository = ref.watch(eventiPartitaRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemote(partitaId),
        watch: () => repository.watchPerPartita(partitaId),
      );
    });
