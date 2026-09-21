import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/gare_repository.dart';
import '../domain/gara.dart';

final gareListProvider = StreamProvider.family<List<Gara>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(gareRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(clubId),
    watch: () => repository.watchPerClub(clubId),
  );
});
