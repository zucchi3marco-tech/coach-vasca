import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'push_tipi.dart';

bool get _apiPresenti {
  final navigator = web.window.navigator as JSObject;
  return globalContext.has('Notification') &&
      globalContext.has('PushManager') &&
      navigator.has('serviceWorker');
}

bool get _iosOApple {
  final ua = web.window.navigator.userAgent;
  final tocco = web.window.navigator.maxTouchPoints > 1;
  return RegExp(r'iPhone|iPad|iPod').hasMatch(ua) ||
      (ua.contains('Macintosh') && tocco);
}

bool get _appInstallata {
  if (web.window.matchMedia('(display-mode: standalone)').matches) return true;
  final navigator = web.window.navigator as JSObject;
  final standalone = navigator.getProperty('standalone'.toJS);
  return standalone.isDefinedAndNotNull &&
      (standalone as JSBoolean).toDart == true;
}

Uint8List _decodificaChiave(String base64Url) {
  final normale = base64Url.replaceAll('-', '+').replaceAll('_', '/');
  final conPadding = normale.padRight((normale.length + 3) ~/ 4 * 4, '=');
  return base64.decode(conPadding);
}

Future<web.ServiceWorkerRegistration> _registrazione() async {
  final reg = await web.window.navigator.serviceWorker
      .register('push/sw.js'.toJS, web.RegistrationOptions(scope: 'push/'))
      .toDart;
  // pushManager.subscribe richiede un service worker gia' attivo: alla
  // primissima registrazione puo' mancare ancora qualche istante.
  for (var i = 0; i < 50 && reg.active == null; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  return reg;
}

IscrizionePush _estrai(web.PushSubscription sub) {
  final json = (sub as JSObject).callMethod<JSObject>('toJSON'.toJS);
  final keys = json.getProperty<JSObject>('keys'.toJS);
  return IscrizionePush(
    endpoint: json.getProperty<JSString>('endpoint'.toJS).toDart,
    p256dh: keys.getProperty<JSString>('p256dh'.toJS).toDart,
    authKey: keys.getProperty<JSString>('auth'.toJS).toDart,
  );
}

Future<StatoPush> statoPush() async {
  if (_iosOApple && !_appInstallata) return StatoPush.installaPrima;
  if (!_apiPresenti) return StatoPush.nonSupportato;
  switch (web.Notification.permission) {
    case 'denied':
      return StatoPush.negato;
    case 'granted':
      return (await iscrizioneCorrente()) != null
          ? StatoPush.attivo
          : StatoPush.daAttivare;
    default:
      return StatoPush.daAttivare;
  }
}

/// Chiede il permesso (va chiamata da un tocco dell'utente) e iscrive il
/// browser alle notifiche. `null` se il permesso non e' stato dato.
Future<IscrizionePush?> attivaPush(String chiavePubblicaVapid) async {
  if (!_apiPresenti) return null;
  final permesso = (await web.Notification.requestPermission().toDart).toDart;
  if (permesso != 'granted') return null;
  final reg = await _registrazione();
  final esistente = await reg.pushManager.getSubscription().toDart;
  final sub =
      esistente ??
      await reg.pushManager
          .subscribe(
            web.PushSubscriptionOptionsInit(
              userVisibleOnly: true,
              applicationServerKey: _decodificaChiave(chiavePubblicaVapid).toJS,
            ),
          )
          .toDart;
  return _estrai(sub);
}

/// L'iscrizione gia' attiva su questo browser, senza chiedere nulla (serve
/// a ri-registrarla a ogni avvio: il servizio push puo' cambiarne
/// l'indirizzo).
Future<IscrizionePush?> iscrizioneCorrente() async {
  if (!_apiPresenti || web.Notification.permission != 'granted') return null;
  try {
    final reg = await web.window.navigator.serviceWorker
        .getRegistration('push/')
        .toDart;
    if (reg == null) return null;
    final sub = await reg.pushManager.getSubscription().toDart;
    return sub == null ? null : _estrai(sub);
  } catch (_) {
    return null;
  }
}

String? userAgentBrowser() => web.window.navigator.userAgent;
