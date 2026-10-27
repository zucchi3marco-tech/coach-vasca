import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/impegni_repository.dart';
import '../domain/impegno.dart';

/// Gli impegni del club, dalla copia del telefono dopo un primo refresh.
final impegniListProvider = StreamProvider.family<List<Impegno>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(impegniRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(clubId),
    watch: () => repository.watchPerClub(clubId),
  );
});
