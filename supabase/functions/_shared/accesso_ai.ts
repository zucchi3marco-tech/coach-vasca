// Il controllo comune delle funzioni AI, con il database vero: le regole
// sono in `regole_accesso_ai.ts`. Ogni funzione che chiama un modello lo
// usa subito dopo aver letto il corpo della richiesta:
//
//   const accesso = await accessoAi(req, { funzione: "…", modello: "…" });
//   if (accesso instanceof Response) return accesso;
//   … chiamata al modello …
//   await accesso.registraGettoni(gettoni);
//
// Usa la chiave service_role (già presente sul server per ogni funzione):
// verifica il token con il servizio degli account, legge `club_membri` e
// scrive `ai_usage`, che gli utenti possono solo leggere.

import { createClient } from "npm:@supabase/supabase-js@2";

import {
  type DatiAccesso,
  decidiAccesso,
  FUNZIONE_PASSAGGIO,
  type OpzioniAccesso,
} from "./regole_accesso_ai.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export interface AccessoConsentito {
  userId: string;
  clubId: string;
  /// Aggiunge i gettoni consumati alla riga della richiesta. Se non
  /// riesce lo scrive solo nei log: la risposta è già pronta.
  registraGettoni(gettoni: number | null | undefined): Promise<void>;
}

function risposta(stato: number, corpo: unknown): Response {
  return new Response(JSON.stringify(corpo), {
    status: stato,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

export async function accessoAi(
  req: Request,
  opzioni: OpzioniAccesso,
): Promise<Response | AccessoConsentito> {
  const url = Deno.env.get("SUPABASE_URL");
  const chiave = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !chiave) {
    return risposta(500, {
      error: "Il server non è configurato per l'AI.",
      codice: "server_non_configurato",
    });
  }
  const db = createClient(url, chiave, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const dati: DatiAccesso = {
    async utente(token) {
      const { data, error } = await db.auth.getUser(token);
      if (error) {
        // 4xx: token scaduto, falso o senza utente (la chiave pubblica del
        // sito). Il resto è un problema del servizio: si riprova.
        const stato = error.status ?? 0;
        if (stato >= 400 && stato < 500) return null;
        throw error;
      }
      const utente = data.user;
      return utente && !utente.is_anonymous ? utente.id : null;
    },
    async clubDelMembro(userId, clubId) {
      let domanda = db.from("club_membri").select("club_id").eq("user_id", userId);
      if (clubId) domanda = domanda.eq("club_id", clubId);
      const { data, error } = await domanda.order("created_at").limit(1);
      if (error) throw error;
      const trovato = data?.[0]?.club_id;
      return typeof trovato === "string" ? trovato : null;
    },
    async prenota(riga) {
      const { data, error } = await db.from("ai_usage").insert(riga).select("id").single();
      if (error) throw error;
      return data.id as string;
    },
    async conta({ userId, clubId, passaggi, dal }) {
      let domanda = db
        .from("ai_usage")
        .select("id", { count: "exact", head: true })
        .gte("creato_il", dal.toISOString());
      domanda = userId ? domanda.eq("user_id", userId) : domanda.eq("club_id", clubId ?? "");
      domanda = passaggi
        ? domanda.eq("funzione", FUNZIONE_PASSAGGIO)
        : domanda.neq("funzione", FUNZIONE_PASSAGGIO);
      const { count, error } = await domanda;
      if (error) throw error;
      if (count == null) throw new Error("Conteggio di ai_usage mancante");
      return count;
    },
    async annulla(id) {
      const { error } = await db.from("ai_usage").delete().eq("id", id);
      if (error) console.error("ai_usage: richiesta fermata non tolta:", error.message);
    },
  };

  const esito = await decidiAccesso(dati, req.headers.get("Authorization"), opzioni);
  if (!esito.ok) {
    return risposta(esito.stato, { error: esito.errore, codice: esito.codice });
  }
  const rigaId = esito.rigaId;
  return {
    userId: esito.userId,
    clubId: esito.clubId,
    async registraGettoni(gettoni) {
      if (gettoni == null) return;
      const { error } = await db.from("ai_usage").update({ gettoni }).eq("id", rigaId);
      if (error) console.error("ai_usage: gettoni non registrati:", error.message);
    },
  };
}
