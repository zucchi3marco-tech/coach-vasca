import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/allenamenti_repository.dart';
import '../domain/allenamento.dart';

typedef AllenamentiPerMicrocicloFilter = ({String clubId, String microcicloId});

final allenamentiPerMicrocicloProvider = StreamProvider.family<
  List<Allenamento>,
  AllenamentiPerMicrocicloFilter
>((ref, filter) {
  final repository = ref.watch(allenamentiRepositoryProvider);
  refreshInBackground(() => repository.refreshFromRemote(filter.clubId));
  return repository.watchPerMicrociclo(filter.microcicloId);
});
