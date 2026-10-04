// Edge Function: detta-allenamento
//
// Riceve il testo dettato a voce dal coach (trascritto nel browser dalla
// Web Speech API, gratuita — questa funzione non tocca l'audio) e chiede
// al provider AI di STRUTTURARLO in una scheda, non di INVENTARLA come fa
// `genera-allenamento`: qui il compito è trascrivere fedelmente quello
// che è stato detto, riconoscendo il gergo del nuoto parlato (numeri,
// stili, zone, recuperi), non proporre una programmazione.
// Stessa forma di output di `genera-allenamento` (SchedaGenerata),
// rivalidata qui prima di rispondere: l'app riceve sempre una scheda con
// campi noti o un errore esplicito, mai testo libero da interpretare.
//
// RIPROGETTAZIONE AI, FASE 2: provider passato da Gemini a OpenAI (solo
// qui, solo l'interpretazione del testo — la trascrizione vocale resta
// quella gratuita del browser). `chiamaGemini` resta nel file, spenta
// (PROVIDER_ATTIVO = "openai"): se qualcosa con OpenAI non funziona, si
// torna a Gemini cambiando quella sola costante e redistribuendo.
//
// Se in futuro si cambia ancora provider, si riscrive solo questo file:
// il contratto verso l'app (corpo della richiesta e { scheda } in
// risposta) resta invariato. Nessuna cartella `_shared/` in questo
// repo (vedi `tipo_lavoro.dart`): l'infrastruttura ai_usage/tetto
// settimanale qui sotto va risincronizzata a mano quando arriverà
// anche in `genera-allenamento`/`genera-settimana` (FASE 3).

const PROVIDER_ATTIVO: "openai" | "gemini" = "openai";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const TEXT_MODEL = Deno.env.get("TEXT_MODEL") ?? "gpt-4o-mini";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Tetto di richieste AI (qualunque funzione scriva su ai_usage, non solo
// questa) per persona a settimana — numero concordato col coach,
// modificabile qui se serve cambiarlo.
const LIMITE_SETTIMANALE_PER_PERSONA = 30;

const BLOCCHI = ["riscaldamento", "principale", "defaticamento", "altro"];
const STILI = ["libero", "dorso", "rana", "delfino", "misti"];
const ESECUZIONI = ["nuoto", "gambe", "braccia", "pull", "tecnica", "remate"];
// "C" (senza numero) è uno storico dell'enum del database (righe salvate
// prima dello split in C1/C2/C3, FASE 9): non va proposto per le serie
// nuove — vedi `ordineZone` in `lib/features/tabelle_passi`.
const ZONE = ["A1", "A2", "B1", "B2", "C1", "C2", "C3", "D"];

interface RipartenzaCorsia {
  nome: string;
  ripartenzaS: number;
}

interface SerieGenerata {
  ordine: number;
  blocco: string;
  ripetute: number;
  distanzaM: number;
  stile: string;
  esecuzione: string;
  zona?: string | null;
  recuperoS?: number | null;
  attrezzatura?: string | null;
  note?: string | null;
  ripartenzePerCorsia?: RipartenzaCorsia[];
}

interface SchedaGenerata {
  titolo: string;
  note?: string | null;
  serie: SerieGenerata[];
}

interface RichiestaDettatura {
  testo?: string;
  gruppo?: string | null;
  clubId?: string;
}

// Il browser (Flutter Web) chiama questa funzione da un'origine diversa
// (localhost in sviluppo, il dominio dell'app in produzione): senza questi
// header ogni richiesta viene bloccata dal CORS prima ancora di arrivare
// qui, con un errore di rete generico lato client ("Failed to fetch").
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

// Glossario del gergo parlato più comune → i codici che il database
// riconosce: senza questo, "trazioni"/"pull boy"/"crawl" arriverebbero al
// provider senza un ponte esplicito verso gli enum consentiti, con più
// probabilità che li indovini male o che li lasci fuori.
const GLOSSARIO = `
Corrispondenze fra gergo parlato e valori consentiti (usa il buon senso
anche per varianti non elencate qui):
- Stile: "libero"/"crawl" = libero; "dorso" = dorso; "rana"/"bracciata
  rana" = rana; "delfino"/"farfalla" = delfino; "misti"/"quattro stili" =
  misti.
- Esecuzione (se non detta esplicitamente, usa "nuoto"): "gambe"/"kick" =
  gambe; "braccia"/"trazioni"/"pull" = pull (non "braccia": quel codice è
  riservato a un lavoro braccia diverso dal pull, usalo solo se il coach
  dice esplicitamente "solo braccia" senza nominare pull/pull-buoy);
  "tecnica"/"drill" = tecnica; "remate" solo per pallanuoto.
- Zona/regime, se nominati (altrimenti lascia il campo vuoto, non
  indovinare): "aerobico leggero"/"A1" = A1; "aerobico"/"A2" = A2;
  "soglia"/"B1" = B1; "VO2"/"potenza aerobica"/"B2" = B2;
  "tolleranza lattacida"/"C1" = C1; "picco di lattato"/"C2" = C2;
  "velocità"/"sprint"/"C3" = C3; "ritmo gara"/"D" = D.
- Blocco: "riscaldamento" = riscaldamento; "principale"/"parte centrale" o
  non specificato = principale; "defaticamento"/"scarico"/"finale" =
  defaticamento.
`.trim();

function costruisciPrompt(r: RichiestaDettatura): string {
  return [
    "Un allenatore di nuoto ha DETTATO A VOCE la scheda di un " +
      "allenamento; il testo qui sotto è la trascrizione automatica di " +
      "quella registrazione (può contenere piccoli errori di " +
      "riconoscimento vocale, soprattutto su numeri e termini tecnici: " +
      "usa il contesto per correggerli quando è ovvio, es. \"cento\" per " +
      "una distanza è quasi certamente 100 metri).",
    "",
    "Il tuo compito è TRASCRIVERE FEDELMENTE quello che è stato detto in " +
      "una scheda strutturata, NON inventare o completare una " +
      "programmazione: se il coach ha dettato solo 3 serie, la scheda " +
      "deve avere esattamente quelle 3 serie, non un allenamento completo " +
      "con riscaldamento e defaticamento aggiunti di tua iniziativa. Se un " +
      "dettaglio opzionale (zona, recupero, attrezzatura) non è stato " +
      "detto, lascia quel campo vuoto invece di indovinarlo.",
    "",
    "Se il coach detta una sequenza di distanze diverse una dopo l'altra " +
      "(una \"piramide\" o \"scaletta\", es. \"50, 100, 200, 100, 50\" " +
      "oppure \"cinquanta cento duecento cento cinquanta\"), NON è una " +
      "sola serie da sommare o da arrotondare: crea una serie separata " +
      "per ciascuna distanza, con ripetute=1 ciascuna, nello stesso " +
      "ordine in cui sono state dette, condividendo lo stesso stile/ " +
      "zona/recupero/esecuzione detti per quel gruppo (a meno che il " +
      "coach non ne specifichi di diversi per una distanza particolare).",
    "",
    GLOSSARIO,
    "",
    r.gruppo ? `Gruppo a cui è rivolto l'allenamento: ${r.gruppo}.` : "",
    "",
    "Testo dettato:",
    `"${(r.testo ?? "").trim()}"`,
    "",
    "Componi anche un titolo breve (max 6 parole) che descriva la seduta, " +
      "es. \"Seduta soglia 3000m\".",
  ]
    .filter((riga) => riga.length > 0)
    .join("\n");
}

// Schema "stile Gemini" (responseSchema di generateContent): tipi in
// MAIUSCOLO, i campi facoltativi semplicemente non sono in `required`.
const geminiResponseSchema = {
  type: "OBJECT",
  properties: {
    titolo: { type: "STRING" },
    note: { type: "STRING" },
    serie: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          ordine: { type: "INTEGER" },
          blocco: { type: "STRING", enum: BLOCCHI },
          ripetute: { type: "INTEGER" },
          distanzaM: { type: "INTEGER" },
          stile: { type: "STRING", enum: STILI },
          esecuzione: { type: "STRING", enum: ESECUZIONI },
          zona: { type: "STRING", enum: ZONE },
          recuperoS: { type: "INTEGER" },
          attrezzatura: { type: "STRING" },
          note: { type: "STRING" },
        },
        required: ["ordine", "blocco", "ripetute", "distanzaM", "stile", "esecuzione"],
      },
    },
  },
  required: ["titolo", "serie"],
};

// Schema JSON standard per gli "structured outputs" di OpenAI
// (response_format json_schema, strict: true): a differenza di Gemini,
// in modalità strict OGNI proprietà deve stare in `required` e non può
// esistere un campo "davvero opzionale" — i campi facoltativi diventano
// nullable (`type: [tipo, "null"]`) invece di assenti.
const openAiResponseSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    titolo: { type: "string" },
    note: { type: ["string", "null"] },
    serie: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          ordine: { type: "integer" },
          blocco: { type: "string", enum: BLOCCHI },
          ripetute: { type: "integer" },
          distanzaM: { type: "integer" },
          stile: { type: "string", enum: STILI },
          esecuzione: { type: "string", enum: ESECUZIONI },
          zona: { type: ["string", "null"], enum: [...ZONE, null] },
          recuperoS: { type: ["integer", "null"] },
          attrezzatura: { type: ["string", "null"] },
          note: { type: ["string", "null"] },
        },
        required: [
          "ordine",
          "blocco",
          "ripetute",
          "distanzaM",
          "stile",
          "esecuzione",
          "zona",
          "recuperoS",
          "attrezzatura",
          "note",
        ],
      },
    },
  },
  required: ["titolo", "note", "serie"],
};

/// Rivalida la scheda restituita dal modello: anche con lo schema
/// impostato, il provider può comunque restituire un JSON che non lo
/// rispetta (bug del modello, cambio di comportamento, ecc.), quindi non
/// ci fidiamo alla cieca.
function validaScheda(dati: unknown): SchedaGenerata {
  if (typeof dati !== "object" || dati === null) {
    throw new Error("la scheda generata non è un oggetto JSON valido");
  }
  const scheda = dati as Record<string, unknown>;

  if (typeof scheda.titolo !== "string" || scheda.titolo.trim() === "") {
    throw new Error("titolo mancante o non valido");
  }
  if (!Array.isArray(scheda.serie) || scheda.serie.length === 0) {
    throw new Error(
      "non ho capito nessuna serie dal testo dettato: prova a ripetere più " +
        "chiaramente, o scrivilo a mano",
    );
  }

  const serieValidate: SerieGenerata[] = scheda.serie.map((voce, indice) => {
    if (typeof voce !== "object" || voce === null) {
      throw new Error(`serie #${indice + 1} non è un oggetto valido`);
    }
    const s = voce as Record<string, unknown>;

    const ordine = Number(s.ordine);
    if (!Number.isInteger(ordine) || ordine < 1) {
      throw new Error(`serie #${indice + 1}: ordine non valido`);
    }
    if (typeof s.blocco !== "string" || !BLOCCHI.includes(s.blocco)) {
      throw new Error(`serie #${indice + 1}: blocco "${s.blocco}" non riconosciuto`);
    }
    const ripetute = Number(s.ripetute);
    if (!Number.isInteger(ripetute) || ripetute < 1) {
      throw new Error(`serie #${indice + 1}: ripetute non valide`);
    }
    const distanzaM = Number(s.distanzaM);
    if (!Number.isInteger(distanzaM) || distanzaM < 25) {
      throw new Error(`serie #${indice + 1}: distanza non valida`);
    }
    if (typeof s.stile !== "string" || !STILI.includes(s.stile)) {
      throw new Error(`serie #${indice + 1}: stile "${s.stile}" non riconosciuto`);
    }
    if (typeof s.esecuzione !== "string" || !ESECUZIONI.includes(s.esecuzione)) {
      throw new Error(
        `serie #${indice + 1}: esecuzione "${s.esecuzione}" non riconosciuta`,
      );
    }
    let zona: string | null = null;
    if (s.zona !== undefined && s.zona !== null) {
      if (typeof s.zona !== "string" || !ZONE.includes(s.zona)) {
        throw new Error(`serie #${indice + 1}: zona "${s.zona}" non riconosciuta`);
      }
      zona = s.zona;
    }
    let recuperoS: number | null = null;
    if (s.recuperoS !== undefined && s.recuperoS !== null) {
      const valore = Number(s.recuperoS);
      if (!Number.isInteger(valore) || valore < 0) {
        throw new Error(`serie #${indice + 1}: recupero non valido`);
      }
      recuperoS = valore;
    }

    return {
      ordine,
      blocco: s.blocco,
      ripetute,
      distanzaM,
      stile: s.stile,
      esecuzione: s.esecuzione,
      zona,
      recuperoS,
      attrezzatura: typeof s.attrezzatura === "string" ? s.attrezzatura : null,
      note: typeof s.note === "string" ? s.note : null,
      ripartenzePerCorsia: [],
    };
  });

  return {
    titolo: scheda.titolo,
    note: typeof scheda.note === "string" ? scheda.note : null,
    serie: serieValidate,
  };
}

// Il messaggio grezzo di Gemini e' JSON tecnico in inglese (es. "quota
// exceeded... RESOURCE_EXHAUSTED" o "model overloaded... UNAVAILABLE"):
// qui si traduce nei due casi piu' comuni (limite di richieste al minuto
// del piano gratuito, modello momentaneamente sovraccarico) in un
// messaggio comprensibile, e in un messaggio generico altrimenti — mai
// il JSON grezzo mostrato al coach.
function messaggioErroreGemini(status: number, corpoGrezzo: string): string {
  let statoGemini: string | undefined;
  try {
    const corpo = JSON.parse(corpoGrezzo);
    statoGemini = corpo?.error?.status;
  } catch {
    // corpo non JSON: si usa il messaggio generico sotto.
  }
  if (statoGemini === "RESOURCE_EXHAUSTED" || status === 429) {
    return "Troppe richieste al servizio AI in poco tempo (il piano attuale " +
      "ne permette solo poche al minuto). Aspetta un minuto e riprova.";
  }
  if (statoGemini === "UNAVAILABLE" || status === 503) {
    return "Il servizio AI è momentaneamente sovraccarico. Riprova tra " +
      "qualche istante.";
  }
  return `Il servizio AI non ha risposto correttamente (errore ${status}). ` +
    "Riprova tra qualche istante.";
}

function messaggioErroreOpenAi(status: number, corpoGrezzo: string): string {
  let codiceOpenAi: string | undefined;
  try {
    const corpo = JSON.parse(corpoGrezzo);
    codiceOpenAi = corpo?.error?.code ?? corpo?.error?.type;
  } catch {
    // corpo non JSON: si usa il messaggio generico sotto.
  }
  if (status === 429 || codiceOpenAi === "rate_limit_exceeded") {
    return "Troppe richieste al servizio AI in poco tempo. Aspetta un minuto " +
      "e riprova.";
  }
  if (status === 503 || status === 500) {
    return "Il servizio AI è momentaneamente sovraccarico. Riprova tra " +
      "qualche istante.";
  }
  return `Il servizio AI non ha risposto correttamente (errore ${status}). ` +
    "Riprova tra qualche istante.";
}

type RispostaProvider =
  | { ok: true; testoJson: string; gettoni: number | null }
  | { ok: false; errorMessage: string };

// Gemini risponde spesso 503 "UNAVAILABLE" per sovraccarico momentaneo,
// OpenAI 429/500/503 per gli stessi motivi — senza un ritentativo qui,
// questi picchi si vedevano come "il generatore non funziona" lato
// coach, pur essendo transitori.
const TENTATIVI_MASSIMI = 3;
const ATTESE_MS = [1500, 3000];

async function chiamaGemini(prompt: string): Promise<RispostaProvider> {
  if (!GEMINI_API_KEY) {
    return { ok: false, errorMessage: "GEMINI_API_KEY non configurata sul server" };
  }

  let risposta: Response | undefined;
  let erroreRete: unknown;
  for (let tentativo = 1; tentativo <= TENTATIVI_MASSIMI; tentativo++) {
    try {
      risposta = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              responseMimeType: "application/json",
              responseSchema: geminiResponseSchema,
            },
          }),
        },
      );
      erroreRete = undefined;
    } catch (errore) {
      erroreRete = errore;
      risposta = undefined;
    }
    const daRiprovare = risposta?.status === 503 || erroreRete !== undefined;
    if (!daRiprovare || tentativo === TENTATIVI_MASSIMI) break;
    await new Promise((r) => setTimeout(r, ATTESE_MS[tentativo - 1]));
  }

  if (erroreRete !== undefined || risposta === undefined) {
    return { ok: false, errorMessage: `Impossibile contattare il provider AI: ${erroreRete}` };
  }
  if (!risposta.ok) {
    const dettaglio = await risposta.text();
    return { ok: false, errorMessage: messaggioErroreGemini(risposta.status, dettaglio) };
  }

  const dati = await risposta.json();
  const testoJson = dati?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
  return { ok: true, testoJson, gettoni: dati?.usageMetadata?.totalTokenCount ?? null };
}

async function chiamaOpenAi(prompt: string): Promise<RispostaProvider> {
  if (!OPENAI_API_KEY) {
    return { ok: false, errorMessage: "OPENAI_API_KEY non configurata sul server" };
  }

  let risposta: Response | undefined;
  let erroreRete: unknown;
  for (let tentativo = 1; tentativo <= TENTATIVI_MASSIMI; tentativo++) {
    try {
      risposta = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: TEXT_MODEL,
          messages: [{ role: "user", content: prompt }],
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "scheda_generata",
              strict: true,
              schema: openAiResponseSchema,
            },
          },
        }),
      });
      erroreRete = undefined;
    } catch (errore) {
      erroreRete = errore;
      risposta = undefined;
    }
    const daRiprovare =
      (risposta !== undefined && [429, 500, 503].includes(risposta.status)) ||
      erroreRete !== undefined;
    if (!daRiprovare || tentativo === TENTATIVI_MASSIMI) break;
    await new Promise((r) => setTimeout(r, ATTESE_MS[tentativo - 1]));
  }

  if (erroreRete !== undefined || risposta === undefined) {
    return { ok: false, errorMessage: `Impossibile contattare il provider AI: ${erroreRete}` };
  }
  if (!risposta.ok) {
    const dettaglio = await risposta.text();
    return { ok: false, errorMessage: messaggioErroreOpenAi(risposta.status, dettaglio) };
  }

  const dati = await risposta.json();
  const testoJson = dati?.choices?.[0]?.message?.content ?? "";
  return { ok: true, testoJson, gettoni: dati?.usage?.total_tokens ?? null };
}

/// Decodifica il payload del JWT (già verificato dal gateway Supabase
/// prima che la richiesta arrivasse qui: non serve riverificarlo) per
/// sapere chi ha chiamato — serve per il tetto settimanale e per
/// ai_usage. `null` se l'header manca o non è un JWT valido.
function idUtenteDaRichiesta(req: Request): string | null {
  const header = req.headers.get("Authorization");
  if (!header?.startsWith("Bearer ")) return null;
  const jwt = header.slice("Bearer ".length);
  const parti = jwt.split(".");
  if (parti.length !== 3) return null;
  try {
    const payload = JSON.parse(atob(parti[1].replace(/-/g, "+").replace(/_/g, "/")));
    return typeof payload.sub === "string" ? payload.sub : null;
  } catch {
    return null;
  }
}

/// Quante chiamate AI (qualunque funzione) ha già fatto questo utente
/// negli ultimi 7 giorni. In caso di errore di rete verso il database
/// non blocca la dettatura per un problema che non è dell'utente:
/// torna 0 (fail-open), diversamente da un tetto superato per davvero.
async function richiesteUltimaSettimana(userId: string): Promise<number> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return 0;
  const seiGiorniFa = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  try {
    const risposta = await fetch(
      `${SUPABASE_URL}/rest/v1/ai_usage?select=id&user_id=eq.${userId}&creato_il=gte.${seiGiorniFa}`,
      {
        headers: {
          apikey: SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
          Prefer: "count=exact",
        },
      },
    );
    const header = risposta.headers.get("content-range");
    const totale = header?.split("/")[1];
    if (totale && totale !== "*") return Number(totale);
    const righe = await risposta.json();
    return Array.isArray(righe) ? righe.length : 0;
  } catch {
    return 0;
  }
}

/// Registra la chiamata — se fallisce, lo scrive solo nei log: non deve
/// far fallire una dettatura già andata a buon fine.
async function registraUsoAi(
  params: { clubId: string; userId: string; modello: string; gettoni: number | null },
): Promise<void> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return;
  try {
    await fetch(`${SUPABASE_URL}/rest/v1/ai_usage`, {
      method: "POST",
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        club_id: params.clubId,
        user_id: params.userId,
        funzione: "detta-allenamento",
        modello: params.modello,
        gettoni: params.gettoni,
      }),
    });
  } catch (errore) {
    console.error("registraUsoAi fallita:", errore);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo non supportato" }, 405);
  }

  let richiesta: RichiestaDettatura;
  try {
    richiesta = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo della richiesta non valido" }, 400);
  }

  if (!richiesta.testo || richiesta.testo.trim().length < 10) {
    return jsonResponse(
      { error: "Il testo dettato è troppo corto per essere interpretato" },
      400,
    );
  }

  const userId = idUtenteDaRichiesta(req);
  if (userId) {
    const richiesteFatte = await richiesteUltimaSettimana(userId);
    if (richiesteFatte >= LIMITE_SETTIMANALE_PER_PERSONA) {
      return jsonResponse(
        {
          error: `Hai raggiunto il limite di ${LIMITE_SETTIMANALE_PER_PERSONA} ` +
            "richieste AI per questa settimana. Riprova la settimana prossima, " +
            "o scrivi la scheda a mano.",
        },
        429,
      );
    }
  }

  const prompt = costruisciPrompt(richiesta);

  const risultato = PROVIDER_ATTIVO === "openai"
    ? await chiamaOpenAi(prompt)
    : await chiamaGemini(prompt);

  if (!risultato.ok) {
    return jsonResponse({ error: risultato.errorMessage }, 502);
  }

  let schedaGrezza: unknown;
  try {
    schedaGrezza = JSON.parse(risultato.testoJson);
  } catch {
    return jsonResponse(
      { error: "Il provider AI non ha restituito un JSON valido" },
      502,
    );
  }

  try {
    const scheda = validaScheda(schedaGrezza);
    if (userId && richiesta.clubId) {
      await registraUsoAi({
        clubId: richiesta.clubId,
        userId,
        modello: PROVIDER_ATTIVO === "openai" ? TEXT_MODEL : GEMINI_MODEL,
        gettoni: risultato.gettoni,
      });
    }
    return jsonResponse({ scheda });
  } catch (errore) {
    return jsonResponse(
      { error: `Non sono riuscito a interpretare la dettatura: ${(errore as Error).message}` },
      502,
    );
  }
});
