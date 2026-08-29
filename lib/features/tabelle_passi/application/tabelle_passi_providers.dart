import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tabelle_passi_repository.dart';
import '../domain/tabella_passo.dart';

final tabellePassiProvider = FutureProvider.family<List<TabellaPasso>, String>(
  (ref, testId) {
    return ref.watch(tabellePassiRepositoryProvider).fetchPerTest(testId);
  },
);
