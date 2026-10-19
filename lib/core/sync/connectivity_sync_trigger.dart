import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rete/controllo_rete.dart';
import '../rete/stato_rete.dart';
import 'sync_engine.dart';

/// Ogni quanto, senza rete, si chiede al server se risponde di nuovo.
const intervalloControlloRete = Duration(seconds: 20);

/// Attiva la sincronizzazione della coda: un tentativo subito all'avvio,
/// poi uno ogni volta che la rete torna, sia quando il telefono si
/// ricollega sia quando il server risponde di nuovo dopo un periodo senza
/// rete. Senza rete chiede al server ogni [intervalloControlloRete] se
/// risponde: il wifi della piscina spesso torna senza avvisare, e così la
/// spia si spegne e la coda parte da sola.
///
/// Va "attivato" una sola volta con `ref.watch(connectivitySyncTriggerProvider)`
/// nella root dell'app (vedi app.dart).
final connectivitySyncTriggerProvider = Provider<void>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  final controllaRete = ref.watch(controllaReteProvider);

  syncEngine.processQueue();

  Timer? ricontrollo;
  var eraSenzaRete = !statoRete.inRete;
  void cambiato() {
    final senzaRete = !statoRete.inRete;
    if (senzaRete) {
      ricontrollo ??= Timer.periodic(
        intervalloControlloRete,
        (_) => controllaRete(),
      );
    } else {
      ricontrollo?.cancel();
      ricontrollo = null;
      if (eraSenzaRete) syncEngine.processQueue();
    }
    eraSenzaRete = senzaRete;
  }

  statoRete.addListener(cambiato);
  cambiato();

  final subscription = Connectivity().onConnectivityChanged.listen((results) {
    if (results.contains(ConnectivityResult.none)) {
      statoRete.chiamataFallita();
    } else {
      controllaRete();
      syncEngine.processQueue();
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    statoRete.removeListener(cambiato);
    ricontrollo?.cancel();
  });
});
