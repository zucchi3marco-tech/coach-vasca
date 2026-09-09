import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/gruppi_repository.dart';
import '../domain/gruppo.dart';

final gruppiListProvider = StreamProvider.family<List<Gruppo>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(gruppiRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(clubId),
    watch: () => repository.watchPerClub(clubId),
  );
});
