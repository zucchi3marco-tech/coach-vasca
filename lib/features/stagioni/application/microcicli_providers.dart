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
