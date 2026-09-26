// Service worker delle notifiche push. Ha uno scope suo (/push/) per non
// scontrarsi con quello di Flutter: la sottoscrizione push funziona lo
// stesso, e qui si mostra la notifica anche ad app chiusa.

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) =>
  event.waitUntil(self.clients.claim()),
);

self.addEventListener('push', (event) => {
  let dati = {};
  try {
    dati = event.data ? event.data.json() : {};
  } catch (_) {
    dati = { body: event.data ? event.data.text() : '' };
  }
  event.waitUntil(
    self.registration.showNotification(dati.title || 'WaterTactics', {
      body: dati.body || '',
      tag: dati.tag,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data: { url: dati.url || '/' },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || '/';
  event.waitUntil(
    (async () => {
      const finestre = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });
      for (const finestra of finestre) {
        if ('focus' in finestra) {
          await finestra.focus();
          return;
        }
      }
      await self.clients.openWindow(url);
    })(),
  );
});
