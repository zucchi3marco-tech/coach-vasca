import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/personal_best_repository.dart';
import '../domain/personal_best.dart';

final personalBestListProvider =
    StreamProvider.family<List<PersonalBest>, String>((ref, atletaId) {
      final repository = ref.watch(personalBestRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemote(atletaId),
        watch: () => repository.watchPerAtleta(atletaId),
      );
    });
