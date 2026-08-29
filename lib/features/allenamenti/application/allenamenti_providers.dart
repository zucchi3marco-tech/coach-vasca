import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/allenamenti_repository.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/serie.dart';

final allenamentiListProvider = StreamProvider.family<List<Allenamento>, String>(
  (ref, clubId) {
    final repository = ref.watch(allenamentiRepositoryProvider);
    refreshInBackground(() => repository.refreshFromRemote(clubId));
    return repository.watchPerClub(clubId);
  },
);

final serieListProvider = StreamProvider.family<List<Serie>, String>((
  ref,
  allenamentoId,
) {
  final repository = ref.watch(serieRepositoryProvider);
  refreshInBackground(() => repository.refreshFromRemote(allenamentoId));
  return repository.watchPerAllenamento(allenamentoId);
});
