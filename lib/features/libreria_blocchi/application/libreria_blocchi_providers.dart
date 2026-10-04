import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/training_blocks_repository.dart';
import '../domain/training_block.dart';

final trainingBlocksListProvider =
    StreamProvider.family<List<TrainingBlock>, String>((ref, clubId) {
      final repository = ref.watch(trainingBlocksRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemote(clubId),
        watch: () => repository.watchPerClub(clubId),
      );
    });

final trainingBlockPartiProvider =
    StreamProvider.family<List<TrainingBlockParte>, String>((ref, bloccoId) {
      final repository = ref.watch(trainingBlocksRepositoryProvider);
      return repository.watchParti(bloccoId);
    });
