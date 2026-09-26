import 'package:coach_vasca/core/push/push_tipi.dart';
import 'package:coach_vasca/features/notifiche/application/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('senza chiave VAPID le notifiche push non sono configurate', () async {
    // Il repository non deve nemmeno essere costruito: chiedere lo stato
    // non richiede Supabase.
    final service = PushService(() => throw StateError('non deve servire'));
    expect(service.configurato, isFalse);
    expect(await service.stato(), StatoPush.nonSupportato);
    expect(await service.attiva(), StatoPush.nonSupportato);
    await service.risincronizza();
  });
}
