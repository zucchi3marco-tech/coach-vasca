import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/test_repository.dart';
import '../domain/test_ingresso.dart';

final testListProvider = StreamProvider.family<List<TestIngresso>, String>((
  ref,
  atletaId,
) {
  final repository = ref.watch(testRepositoryProvider);
  refreshInBackground(() => repository.refreshFromRemote(atletaId));
  return repository.watchPerAtleta(atletaId);
});
