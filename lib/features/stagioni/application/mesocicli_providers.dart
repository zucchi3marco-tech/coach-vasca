import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/mesocicli_repository.dart';
import '../domain/mesociclo.dart';

final mesocicliListProvider = StreamProvider.family<List<Mesociclo>, String>((
  ref,
  macrocicloId,
) {
  final repository = ref.watch(mesocicliRepositoryProvider);
  refreshInBackground(() => repository.refreshFromRemote(macrocicloId));
  return repository.watchPerMacrociclo(macrocicloId);
});
