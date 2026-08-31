import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/stagioni_repository.dart';
import '../domain/stagione.dart';

final stagioniListProvider = StreamProvider.family<List<Stagione>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(stagioniRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(clubId),
    watch: () => repository.watchPerClub(clubId),
  );
});
