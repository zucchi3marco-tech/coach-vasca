// Edge Function: promemoria-visite
//
// Chiamata una volta al giorno (workflow GitHub "Manutenzione"): crea le
// notifiche per le visite mediche degli atleti in scadenza, alle soglie
// 30 giorni, 7 giorni e scadenza (oggi o nelle ultime due settimane).
// - una notifica per il club (tutti i coach), con il nome dell'atleta;
// - una personale per l'atleta, se ha un account collegato.
// L'insert scatena il Database Webhook che manda anche il push
// (`invia-push`).
//
// Puo' essere richiamata quante volte si vuole senza duplicati: ogni
// notifica ha una `chiave` unica (atleta + data di scadenza + soglia) e
// l'upsert ignora quelle gia' presenti; rinnovata la visita, la nuova data
// genera chiavi nuove. Chi la chiama con la chiave `anon` (pubblica) non
// puo' quindi far altro che ripetere il controllo.
// File autonomo come le altre Edge Function (nessun codice condiviso).

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const GIORNI_MS = 24 * 60 * 60 * 1000;
const FINESTRA_SCADUTE_GIORNI = 14;

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

function formattaData(iso: string): string {
  const [anno, mese, giorno] = iso.split("-");
  return `${giorno}/${mese}/${anno}`;
}

/// Giorni mancanti alla scadenza (negativi se scaduta), con date senza ora:
/// confronto fra due mezzanotti UTC, senza fusi orari di mezzo.
function giorniAllaScadenza(scadenzaIso: string, oggiIso: string): number {
  return Math.round(
    (Date.parse(`${scadenzaIso}T00:00:00Z`) -
      Date.parse(`${oggiIso}T00:00:00Z`)) / GIORNI_MS,
  );
}

/// La soglia corrente, o null se non c'e' nulla da segnalare.
function soglia(giorni: number): "30" | "7" | "scaduta" | null {
  if (giorni <= 0) return giorni >= -FINESTRA_SCADUTE_GIORNI ? "scaduta" : null;
  if (giorni <= 7) return "7";
  if (giorni <= 30) return "30";
  return null;
}

function frase(giorni: number, dataIt: string): string {
  if (giorni <= 0) return `scaduta il ${dataIt}`;
  if (giorni === 1) return `scade domani (${dataIt})`;
  return `scade tra ${giorni} giorni (${dataIt})`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo non supportato" }, 405);
  }
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return jsonResponse({ error: "Configurazione incompleta" }, 500);
  }

  const db = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const oggi = new Date().toISOString().slice(0, 10);
  const fino = new Date(Date.now() + 30 * GIORNI_MS).toISOString().slice(0, 10);
  const da = new Date(Date.now() - FINESTRA_SCADUTE_GIORNI * GIORNI_MS)
    .toISOString().slice(0, 10);

  const { data: atleti, error } = await db
    .from("atleti")
    .select("id, club_id, nome, cognome, user_id, visita_medica_scadenza")
    .eq("attivo", true)
    .not("visita_medica_scadenza", "is", null)
    .gte("visita_medica_scadenza", da)
    .lte("visita_medica_scadenza", fino);
  if (error) return jsonResponse({ error: error.message }, 500);

  const righe: Record<string, unknown>[] = [];
  for (const a of atleti ?? []) {
    const scadenza = a.visita_medica_scadenza as string;
    const giorni = giorniAllaScadenza(scadenza, oggi);
    const s = soglia(giorni);
    if (s === null) continue;
    const dataIt = formattaData(scadenza);
    righe.push({
      club_id: a.club_id,
      tipo: "visita_medica",
      messaggio: `${a.nome} ${a.cognome}: visita medica ${frase(giorni, dataIt)}`,
      atleta_id: a.id,
      chiave: `visita:club:${a.id}:${scadenza}:${s}`,
    });
    if (a.user_id) {
      righe.push({
        club_id: a.club_id,
        tipo: "visita_medica",
        messaggio: `La tua visita medica ${frase(giorni, dataIt)}`,
        user_id: a.user_id,
        atleta_id: a.id,
        chiave: `visita:atleta:${a.id}:${scadenza}:${s}`,
      });
    }
  }

  if (righe.length === 0) return jsonResponse({ create: 0 });

  const { data: inserite, error: erroreInsert } = await db
    .from("notifiche")
    .upsert(righe, { onConflict: "chiave", ignoreDuplicates: true })
    .select("id");
  if (erroreInsert) return jsonResponse({ error: erroreInsert.message }, 500);

  return jsonResponse({ controllate: righe.length, create: inserite?.length ?? 0 });
});
