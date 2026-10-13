// Edge Function: campionati-fin
//
// Classifiche e calendari dei campionati regionali di pallanuoto della
// FIN Lombardia (richiesta del coach del 13 ottobre 2026). Il sito
// (finlombardia.net) non si puo' leggere direttamente dall'app web: il
// browser blocca le pagine di un altro sito. Questa funzione le scarica e
// le restituisce cosi' come sono; a leggerle ci pensa l'app
// (`lettore_fin.dart`, con i suoi test).
//
// Solo due pagine, con parametri controllati: non e' un proxy aperto.
//   { pagina: "elenco", stagione?: "2026-2027" } -> PN-ElencoCampionati.php
//   { pagina: "girone", cmp_id: 244 }            -> PN-Incontri.php
// Risposta: { html, letto_il }.
//
// Per chiunque abbia fatto l'accesso (allenatori, atleti, famiglie): sono
// dati pubblici. Una copia di 10 minuti per pagina evita di chiedere al
// sito FIN la stessa pagina per ogni telefono.
// File autonomo come le altre Edge Function (nessun codice condiviso).

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");

const BASE = "https://www.finlombardia.net/PHP";
const COPIA_MS = 10 * 60 * 1000;
const ATTESA_MS = 15 * 1000;
const COPIE_MASSIME = 200;

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

const copie = new Map<string, { html: string; lettoIl: number }>();

function indirizzo(richiesta: Record<string, unknown>): string | null {
  if (richiesta.pagina === "elenco") {
    const stagione = richiesta.stagione;
    if (stagione === undefined || stagione === null || stagione === "") {
      return `${BASE}/PN-ElencoCampionati.php`;
    }
    if (typeof stagione !== "string" || !/^\d{4}-\d{4}$/.test(stagione)) {
      return null;
    }
    return `${BASE}/PN-ElencoCampionati.php?Stagione=${stagione}`;
  }
  if (richiesta.pagina === "girone") {
    const id = richiesta.cmp_id;
    if (typeof id !== "number" || !Number.isInteger(id) || id <= 0 || id > 1e7) {
      return null;
    }
    return `${BASE}/PN-Incontri.php?CMPid=${id}`;
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo non supportato" }, 405);
  }
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return jsonResponse({ error: "Funzione non configurata sul server" }, 500);
  }

  let richiesta: Record<string, unknown>;
  try {
    richiesta = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo della richiesta non valido" }, 400);
  }
  const url = indirizzo(richiesta ?? {});
  if (!url) {
    return jsonResponse({ error: "Pagina non valida" }, 400);
  }

  // Chi chiama deve aver fatto l'accesso all'app: la chiave pubblica da
  // sola non basta.
  const autorizzazione = req.headers.get("Authorization") ?? "";
  const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: autorizzazione } },
    auth: { persistSession: false },
  });
  const { data: utente } = await db.auth.getUser(
    autorizzazione.replace(/^Bearer\s+/i, ""),
  );
  if (!utente?.user) {
    return jsonResponse({ error: "Accesso richiesto" }, 401);
  }

  const copia = copie.get(url);
  if (copia && Date.now() - copia.lettoIl < COPIA_MS) {
    return jsonResponse({
      html: copia.html,
      letto_il: new Date(copia.lettoIl).toISOString(),
    });
  }

  let risposta: Response;
  try {
    risposta = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; WaterTactics/1.0)",
        "Accept": "text/html",
        "Accept-Language": "it-IT,it;q=0.9",
      },
      signal: AbortSignal.timeout(ATTESA_MS),
    });
  } catch (e) {
    console.error("campionati-fin: sito FIN non raggiungibile", url, e);
    if (copia) {
      return jsonResponse({
        html: copia.html,
        letto_il: new Date(copia.lettoIl).toISOString(),
      });
    }
    return jsonResponse(
      { error: "Il sito della FIN non risponde. Riprova tra qualche minuto." },
      502,
    );
  }
  if (!risposta.ok) {
    console.error("campionati-fin: risposta FIN", risposta.status, url);
    if (copia) {
      return jsonResponse({
        html: copia.html,
        letto_il: new Date(copia.lettoIl).toISOString(),
      });
    }
    return jsonResponse(
      {
        error:
          `Il sito della FIN ha risposto con un errore (${risposta.status}). Riprova più tardi.`,
      },
      502,
    );
  }
  const html = await risposta.text();
  const lettoIl = Date.now();
  copie.delete(url);
  copie.set(url, { html, lettoIl });
  // Una stagione ha qualche decina di gironi: oltre, via le piu' vecchie.
  while (copie.size > COPIE_MASSIME) {
    copie.delete(copie.keys().next().value!);
  }
  return jsonResponse({ html, letto_il: new Date(lettoIl).toISOString() });
});
