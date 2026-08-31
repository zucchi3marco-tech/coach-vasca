import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/presenze_repository.dart';
import '../domain/presenza.dart';

final presenzeListProvider = StreamProvider.family<List<Presenza>, String>((
  ref,
  allenamentoId,
) {
  final repository = ref.watch(presenzeRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(allenamentoId),
    watch: () => repository.watchPerAllenamento(allenamentoId),
  );
});
