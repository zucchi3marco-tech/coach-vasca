import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/test_repository.dart';
import '../domain/test_ingresso.dart';

final testListProvider = FutureProvider.family<List<TestIngresso>, String>((
  ref,
  atletaId,
) {
  return ref.watch(testRepositoryProvider).fetchTestPerAtleta(atletaId);
});
