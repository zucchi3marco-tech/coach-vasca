import 'package:flutter/foundation.dart';

/// Implementazione no-op per le piattaforme native (Android/iOS/desktop):
/// lì l'app non e' una PWA da installare da browser, quindi resta
/// sempre `false` e le funzioni non fanno nulla.
final ValueNotifier<bool> installabilitaPwa = ValueNotifier<bool>(false);

void avviaOsservazioneInstallabilitaPwa() {}

Future<void> installaPwa() async {}
