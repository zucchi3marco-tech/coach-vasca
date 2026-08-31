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
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(filter.clubId),
    watch: () => repository.watchPerMicrociclo(filter.microcicloId),
  );
});
