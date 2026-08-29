import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/presenze_repository.dart';
import '../domain/presenza.dart';

final presenzeListProvider = FutureProvider.family<List<Presenza>, String>((
  ref,
  allenamentoId,
) {
  return ref.watch(presenzeRepositoryProvider).fetchPerAllenamento(allenamentoId);
});
