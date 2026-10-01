import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/presenze_repository.dart';
import '../domain/presenza.dart';

final presenzeListProvider = StreamProvider.family<List<Presenza>, String>((
  ref,
  allenamentoId,
) {
  final repository = ref.watch(presenzeRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(allenamentoId),
    watch: () => repository.watchPerAllenamento(allenamentoId),
  );
});

/// Tutte le presenze proprie di un atleta (FASE 9, "le mie presenze").
final presenzePerAtletaProvider = StreamProvider.family<List<Presenza>, String>(
  (ref, atletaId) {
    final repository = ref.watch(presenzeRepositoryProvider);
    return streamConRefreshIniziale(
      refresh: () => repository.refreshFromRemotePerAtleta(atletaId),
      watch: () => repository.watchPerAtleta(atletaId),
    );
  },
);

/// Tutte le presenze del club (lista atleti: % presenze per ogni riga).
final presenzeClubProvider = StreamProvider.family<List<Presenza>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(presenzeRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemotePerClub(clubId),
    watch: () => repository.watchPerClub(clubId),
  );
});
