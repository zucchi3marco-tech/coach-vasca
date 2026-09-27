import 'package:coach_vasca/core/push/push_tipi.dart';
import 'package:coach_vasca/features/notifiche/application/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'con la chiave VAPID impostata, su una piattaforma senza push '
    'resta comunque tutto innocuo (nessuna chiamata al repository)',
    () async {
      // Il repository non deve essere toccato: in questi test (VM, non
      // web) l'implementazione nativa non fa mai nulla di suo.
      final service = PushService(() => throw StateError('non deve servire'));
      expect(service.configurato, isTrue);
      expect(await service.stato(), StatoPush.nonSupportato);
      expect(await service.attiva(), StatoPush.nonSupportato);
      await service.risincronizza();
    },
  );
}
