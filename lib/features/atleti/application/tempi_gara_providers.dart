import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/tempi_gara_repository.dart';
import '../domain/tempo_gara.dart';

final tempiGaraListProvider = StreamProvider.family<List<TempoGara>, String>((
  ref,
  atletaId,
) {
  final repository = ref.watch(tempiGaraRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(atletaId),
    watch: () => repository.watchPerAtleta(atletaId),
  );
});

/// I risultati collegati a una gara (tutti gli atleti).
final tempiGaraPerGaraProvider = StreamProvider.family<List<TempoGara>, String>(
  (ref, garaId) {
    final repository = ref.watch(tempiGaraRepositoryProvider);
    return streamConRefreshIniziale(
      refresh: () => repository.refreshFromRemotePerGara(garaId),
      watch: () => repository.watchPerGara(garaId),
    );
  },
);
