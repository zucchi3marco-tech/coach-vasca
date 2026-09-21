import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/gara_iscritti_repository.dart';
import '../domain/gara_iscritto.dart';

final garaIscrittiProvider = StreamProvider.family<List<GaraIscritto>, String>((
  ref,
  garaId,
) {
  final repository = ref.watch(garaIscrittiRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(garaId),
    watch: () => repository.watchPerGara(garaId),
  );
});
