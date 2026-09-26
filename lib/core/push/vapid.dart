/// Chiave PUBBLICA VAPID per le notifiche push (non e' un segreto: e' quella
/// che il browser presenta al servizio push). La coppia si genera una volta
/// con `npx web-push generate-vapid-keys`; la chiave privata sta solo nei
/// segreti di Supabase (`VAPID_PRIVATE_KEY`), mai nel repository. Vuota =
/// notifiche push non ancora configurate: la voce di menu non compare.
const vapidPublicKey = '';
