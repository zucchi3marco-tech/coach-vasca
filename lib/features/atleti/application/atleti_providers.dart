import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/atleti_repository.dart';
import '../domain/atleta.dart';

typedef AtletiFilter = ({String clubId, bool includeInactive});

/// Legge dalla cache locale in tempo reale (Drift): la UI si aggiorna da
/// sola quando arrivano dati piu' recenti dal refresh in background, senza
/// bisogno di invalidare manualmente il provider dopo ogni modifica.
final atletiListProvider = StreamProvider.family<List<Atleta>, AtletiFilter>((
  ref,
  filter,
) {
  final repository = ref.watch(atletiRepositoryProvider);
  refreshInBackground(() => repository.refreshFromRemote(filter.clubId));
  return repository.watchAtleti(
    clubId: filter.clubId,
    includeInactive: filter.includeInactive,
  );
});
