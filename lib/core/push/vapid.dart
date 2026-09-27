/// Chiave PUBBLICA VAPID per le notifiche push (non e' un segreto: e' quella
/// che il browser presenta al servizio push). La coppia si genera una volta
/// con `npx web-push generate-vapid-keys`; la chiave privata sta solo nei
/// segreti di Supabase (`VAPID_PRIVATE_KEY`), mai nel repository. Vuota =
/// notifiche push non ancora configurate: la voce di menu non compare.
const vapidPublicKey =
    'BGxbt-KqVVNN6q-oYRh4QdhJZONQ5xg5WMZcnfqFN4WP230ksmmbGjb2HTH3aLqsq4V3mq7HYeiiQcgsJI9ug_k';
