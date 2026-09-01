import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/microcicli_repository.dart';
import '../domain/microciclo.dart';

final microcicliListProvider = StreamProvider.family<List<Microciclo>, String>(
  (ref, mesocicloId) {
    final repository = ref.watch(microcicliRepositoryProvider);
    return streamConRefreshIniziale(
      refresh: () => repository.refreshFromRemote(mesocicloId),
      watch: () => repository.watchPerMesociclo(mesocicloId),
    );
  },
);

/// Elenco piatto di tutti i microcicli del club, per il selettore
/// "sposta scheda". Non reattivo (FutureProvider): e' una lista aperta on
/// demand per un'azione occasionale, non serve seguirla in tempo reale.
final microcicliDelClubProvider = FutureProvider.family<List<Microciclo>, String>(
  (ref, clubId) {
    return ref.watch(microcicliRepositoryProvider).fetchTuttiPerClub(clubId);
  },
);
