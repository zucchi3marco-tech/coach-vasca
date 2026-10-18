// Edge Function: calendario
//
// Le partite e le gare di una persona come calendario da collegare al
// telefono (iCalendar, .ics), richiesta del coach 2026-10-17. La chiama il
// calendario del telefono, senza un utente collegato: per questo si
// pubblica con `--no-verify-jwt` e l'unica chiave è il codice segreto
// nell'indirizzo (`?c=...`, 48 cifre esadecimali, vedi `mio_calendario`).
// Dal codice la funzione `eventi_calendario` (chiave di servizio) risale
// alla persona e rende solo quello che vede nell'app: per un allenatore le
// partite e le gare del club, per un atleta quelle delle sue squadre, con
// "Convocato" o "Iscritto". Niente allenamenti e niente note. Il testo del
// calendario lo scrive `ics.ts`.
//
// SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY li mette Supabase.

import { createClient } from "npm:@supabase/supabase-js@2";
import { type Calendario, ics } from "./ics.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const CODICE = /^[0-9a-f]{48}$/;

function testo(body: string, status: number): Response {
  return new Response(body, {
    status,
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "GET" && req.method !== "HEAD") {
    return testo("Metodo non supportato", 405);
  }
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return testo("Configurazione incompleta", 500);
  }
  const codice = new URL(req.url).searchParams.get("c") ?? "";
  if (!CODICE.test(codice)) {
    return testo("Calendario non trovato", 404);
  }

  const db = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });
  const { data, error } = await db.rpc("eventi_calendario", {
    p_codice: codice,
  });
  if (error) {
    console.error("eventi_calendario", error.message);
    return testo("Il calendario non è disponibile, riprova più tardi", 500);
  }
  if (!data) {
    // Un codice cambiato con "Cambia indirizzo", o inventato.
    return testo("Calendario non trovato", 404);
  }

  return new Response(req.method === "HEAD" ? null : ics(data as Calendario), {
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Content-Disposition": 'inline; filename="partite.ics"',
      "Cache-Control": "private, max-age=900",
    },
  });
});
