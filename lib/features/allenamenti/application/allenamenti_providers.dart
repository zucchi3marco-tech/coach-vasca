import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/allenamenti_repository.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/serie.dart';

final allenamentiListProvider = FutureProvider.family<List<Allenamento>, String>(
  (ref, clubId) {
    return ref.watch(allenamentiRepositoryProvider).fetchPerClub(clubId);
  },
);

final serieListProvider = FutureProvider.family<List<Serie>, String>((
  ref,
  allenamentoId,
) {
  return ref.watch(serieRepositoryProvider).fetchPerAllenamento(allenamentoId);
});
