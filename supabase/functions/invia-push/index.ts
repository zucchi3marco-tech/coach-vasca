// Edge Function: invia-push
//
// Chiamata da un Database Webhook sull'INSERT della tabella `notifiche`:
// manda la notifica anche sul telefono (Web Push) ai destinatari.
// - notifica personale (user_id valorizzato): solo quell'utente;
// - notifica del club (user_id nullo): tutti i membri del club.
//
// Non ci si fida del contenuto della richiesta (la chiave `anon` e' pubblica:
// chiunque potrebbe chiamare questa funzione con un corpo falso). Dalla
// richiesta si prende solo l'id: la notifica si rilegge dal database e si
// "prenota" con un UPDATE atomico su push_inviata_at, quindi un id inventato
// non fa nulla e una stessa notifica parte una volta sola.
//
// Segreti (supabase secrets set): VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY,
// VAPID_SUBJECT. SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY li mette Supabase.
// File autonomo come le altre Edge Function (nessun codice condiviso).

import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY");
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY");
const VAPID_SUBJECT = Deno.env.get("VAPID_SUBJECT");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo non supportato" }, 405);
  }
  if (
    !VAPID_PUBLIC_KEY || !VAPID_PRIVATE_KEY || !VAPID_SUBJECT ||
    !SUPABASE_URL || !SERVICE_ROLE_KEY
  ) {
    return jsonResponse({ error: "Configurazione push incompleta" }, 500);
  }

  let corpo: { record?: { id?: string }; id?: string };
  try {
    corpo = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo della richiesta non valido" }, 400);
  }
  const id = corpo.record?.id ?? corpo.id;
  if (typeof id !== "string" || !UUID.test(id)) {
    return jsonResponse({ error: "Id notifica mancante" }, 400);
  }

  const db = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // Prenota la notifica: solo la prima chiamata la trova ancora non inviata.
  const { data: notifica, error: erroreNotifica } = await db
    .from("notifiche")
    .update({ push_inviata_at: new Date().toISOString() })
    .eq("id", id)
    .is("push_inviata_at", null)
    .select("id, club_id, tipo, messaggio, user_id")
    .maybeSingle();
  if (erroreNotifica) {
    return jsonResponse({ error: erroreNotifica.message }, 500);
  }
  if (!notifica) return jsonResponse({ inviate: 0, motivo: "gia inviata" });

  let destinatari: string[];
  if (notifica.user_id) {
    destinatari = [notifica.user_id];
  } else {
    const { data: membri, error } = await db
      .from("club_membri")
      .select("user_id")
      .eq("club_id", notifica.club_id);
    if (error) return jsonResponse({ error: error.message }, 500);
    destinatari = (membri ?? []).map((m) => m.user_id);
  }
  if (destinatari.length === 0) return jsonResponse({ inviate: 0 });

  const { data: iscrizioni, error: erroreIscrizioni } = await db
    .from("push_subscriptions")
    .select("id, endpoint, p256dh, auth_key")
    .in("user_id", destinatari);
  if (erroreIscrizioni) {
    return jsonResponse({ error: erroreIscrizioni.message }, 500);
  }

  webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);
  const payload = JSON.stringify({
    title: "WaterTactics",
    body: notifica.messaggio,
    tag: notifica.tipo,
    url: "/",
  });

  let inviate = 0;
  const daCancellare: string[] = [];
  await Promise.all(
    (iscrizioni ?? []).map(async (i) => {
      try {
        await webpush.sendNotification(
          { endpoint: i.endpoint, keys: { p256dh: i.p256dh, auth: i.auth_key } },
          payload,
          { TTL: 60 * 60 * 24 },
        );
        inviate++;
      } catch (errore) {
        // 404/410: l'iscrizione non esiste piu' (app disinstallata,
        // permesso revocato): si toglie, non si riprova.
        const stato = (errore as { statusCode?: number }).statusCode;
        if (stato === 404 || stato === 410) daCancellare.push(i.id);
      }
    }),
  );
  if (daCancellare.length > 0) {
    await db.from("push_subscriptions").delete().in("id", daCancellare);
  }

  return jsonResponse({ inviate, rimosse: daCancellare.length });
});
