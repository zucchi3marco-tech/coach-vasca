import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atleti_repository.dart';
import '../domain/atleta.dart';

typedef AtletiFilter = ({String clubId, bool includeInactive});

final atletiListProvider = FutureProvider.family<List<Atleta>, AtletiFilter>((
  ref,
  filter,
) {
  return ref
      .watch(atletiRepositoryProvider)
      .fetchAtleti(
        clubId: filter.clubId,
        includeInactive: filter.includeInactive,
      );
});
