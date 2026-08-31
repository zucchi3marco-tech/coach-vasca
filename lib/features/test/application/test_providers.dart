import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/test_repository.dart';
import '../domain/test_ingresso.dart';

final testListProvider = StreamProvider.family<List<TestIngresso>, String>((
  ref,
  atletaId,
) {
  final repository = ref.watch(testRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(atletaId),
    watch: () => repository.watchPerAtleta(atletaId),
  );
});
