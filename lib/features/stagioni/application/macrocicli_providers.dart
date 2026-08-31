import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/macrocicli_repository.dart';
import '../domain/macrociclo.dart';

final macrocicliListProvider = StreamProvider.family<List<Macrociclo>, String>(
  (ref, stagioneId) {
    final repository = ref.watch(macrocicliRepositoryProvider);
    refreshInBackground(() => repository.refreshFromRemote(stagioneId));
    return repository.watchPerStagione(stagioneId);
  },
);
