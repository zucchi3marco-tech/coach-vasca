import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/atleti_repository.dart';
import '../domain/atleta.dart';

typedef AtletiFilter = ({String clubId, bool includeInactive});

/// Legge dalla cache locale in tempo reale (Drift): aspetta un primo
/// refresh dal server, poi la UI si aggiorna da sola ad ogni modifica
/// successiva, senza bisogno di invalidare manualmente il provider.
final atletiListProvider = StreamProvider.family<List<Atleta>, AtletiFilter>((
  ref,
  filter,
) {
  final repository = ref.watch(atletiRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(filter.clubId),
    watch: () => repository.watchAtleti(
      clubId: filter.clubId,
      includeInactive: filter.includeInactive,
    ),
  );
});
