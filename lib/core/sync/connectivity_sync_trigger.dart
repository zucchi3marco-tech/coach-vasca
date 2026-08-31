import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_engine.dart';

/// Attiva la sincronizzazione della coda: un tentativo subito all'avvio,
/// poi uno ogni volta che la connettivita' torna disponibile. Va "attivato"
/// una sola volta con `ref.watch(connectivitySyncTriggerProvider)` nella
/// root dell'app (vedi app.dart).
final connectivitySyncTriggerProvider = Provider<void>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);

  syncEngine.processQueue();

  final subscription = Connectivity().onConnectivityChanged.listen((
    results,
  ) {
    if (!results.contains(ConnectivityResult.none)) {
      syncEngine.processQueue();
    }
  });

  ref.onDispose(subscription.cancel);
});
