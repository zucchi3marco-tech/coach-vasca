import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/tabelle_passi_repository.dart';
import '../domain/tabella_passo.dart';

final tabellePassiProvider = StreamProvider.family<List<TabellaPasso>, String>(
  (ref, testId) {
    final repository = ref.watch(tabellePassiRepositoryProvider);
    return streamConRefreshIniziale(
      refresh: () => repository.refreshFromRemote(testId),
      watch: () => repository.watchPerTest(testId),
    );
  },
);
