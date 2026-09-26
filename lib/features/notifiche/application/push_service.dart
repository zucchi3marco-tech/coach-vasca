import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/push/push_notifiche.dart';
import '../../../core/push/vapid.dart';
import '../data/push_repository.dart';

/// Attivazione delle notifiche push per l'utente collegato.
class PushService {
  PushService(this._repository);

  /// Letto solo quando serve: chiedere lo stato non deve richiedere un
  /// client Supabase.
  final PushRepository Function() _repository;

  /// Senza chiave VAPID nel codice le notifiche push non sono ancora
  /// configurate: nessuna voce di menu, nessun tentativo.
  bool get configurato => vapidPublicKey.isNotEmpty;

  Future<StatoPush> stato() async =>
      configurato ? statoPush() : StatoPush.nonSupportato;

  /// Da chiamare da un tocco dell'utente (il browser lo esige). Restituisce
  /// lo stato dopo il tentativo.
  Future<StatoPush> attiva() async {
    if (!configurato) return StatoPush.nonSupportato;
    final iscrizione = await attivaPush(vapidPublicKey);
    if (iscrizione != null) {
      await _repository().registra(iscrizione, userAgent: userAgentBrowser());
    }
    return statoPush();
  }

  /// All'avvio: se il permesso c'e' gia', ri-registra l'iscrizione (il
  /// servizio push puo' cambiarne l'indirizzo, e un telefono puo' passare
  /// da un account all'altro). Non chiede mai nulla all'utente.
  Future<void> risincronizza() async {
    if (!configurato) return;
    final iscrizione = await iscrizioneCorrente();
    if (iscrizione == null) return;
    await _repository().registra(iscrizione, userAgent: userAgentBrowser());
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(() => ref.read(pushRepositoryProvider));
});

/// Una volta per utente e sessione, dopo l'accesso. Un errore qui non deve
/// mai disturbare l'app: e' solo manutenzione dell'iscrizione.
final pushRisincronizzaProvider = FutureProvider.family<void, String>((
  ref,
  userId,
) async {
  try {
    await ref.read(pushServiceProvider).risincronizza();
  } catch (_) {}
});
