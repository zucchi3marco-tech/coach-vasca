// Edge Function: genera-settimana
//
// Prima metà del punto 4 di FASE 10: pianifica una settimana intera come
// scheletro leggero (numero di sedute, un codice breve per ciascuna,
// volume) — non il dettaglio delle serie, quello lo produce poi
// genera-allenamento una volta per seduta, riusando lo stesso contratto
// e la stessa API key lato server.
//
// La seconda metà del punto ("tenere conto delle settimane precedenti e
// delle gare in programma") è esplicitamente rimandata: qui si pianifica
// una sola settimana isolata.
//
// RIPROGETTAZIONE AI: provider passato da Gemini a OpenAI come
// `genera-allenamento` e `detta-allenamento`. `chiamaGemini` resta nel
// file, spenta dietro PROVIDER_ATTIVO. Infrastruttura ai_usage/tetto
// settimanale copiata a mano da `genera-allenamento`: tenerle allineate.

const PROVIDER_ATTIVO: "openai" | "gemini" = "openai";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const TEXT_MODEL = Deno.env.get("TEXT_MODEL") ?? "gpt-4o-mini";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Tetto di richieste AI (qualunque funzione scriva su ai_usage) per
// persona a settimana — stesso numero di `detta-allenamento`.
const LIMITE_SETTIMANALE_PER_PERSONA = 30;

const NOME_FUNZIONE = "genera-settimana";

interface CorsiaGenerazione {
  nome: string;
  passo100S: number;
  differenzialeS?: number | null;
}

interface RiassuntoProgrammazione {
  sedutePerSettimanaMedia?: number;
  volumeMedioPerSedutaMetri?: number;
  percentualeMetriPerZona?: Record<string, number>;
  percentualeMetriPerBlocco?: Record<string, number>;
  combinazioniStileEsecuzioneFrequenti?: string[];
  attrezzaturaFrequente?: string[];
}

interface ParametriSettimana {
  gruppo?: string;
  giorniSettimana?: string[];
  volumeSettimanaleMetri?: number;
  volumeLavoroCentraleSettimanaleMetri?: number | null;
  // Per ogni seduta uno o più focus (stringa singola accettata per compatibilità).
  focusPerSeduta?: (string | string[])[];
  attrezzaturaLavoroCentrale?: string[];
  minutiMax?: number | null;
  vascaM?: number | null;
  tipoSettimana?: string | null;
  vincoli?: string | null;
  corsie?: CorsiaGenerazione[];
  riassuntoProgrammazione?: RiassuntoProgrammazione | null;
}

interface SedutaGenerata {
  codice: string;
  volumeMetri: number;
}

interface SettimanaGenerata {
  sedute: SedutaGenerata[];
}

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

function riassuntoRiga(r: RiassuntoProgrammazione | null | undefined): string {
  if (r == null) return "";
  const zone = r.percentualeMetriPerZona
    ? Object.entries(r.percentualeMetriPerZona)
      .map(([zona, pct]) => `${zona} ${Math.round(pct)}%`)
      .join(", ")
    : "";
  const blocchi = r.percentualeMetriPerBlocco
    ? Object.entries(r.percentualeMetriPerBlocco)
      .map(([blocco, pct]) => `${blocco} ${Math.round(pct)}%`)
      .join(", ")
    : "";
  const combinazioni = Array.isArray(r.combinazioniStileEsecuzioneFrequenti)
    ? r.combinazioniStileEsecuzioneFrequenti.join(", ")
    : "";
  const attrezzatura = Array.isArray(r.attrezzaturaFrequente)
    ? r.attrezzaturaFrequente.join(", ")
    : "";
  return [
    "Come il gruppo è stato allenato finora (ultimi ~2 mesi, riassunto): " +
      `circa ${r.sedutePerSettimanaMedia?.toFixed(1) ?? "?"} sedute a ` +
      `settimana, ${Math.round(r.volumeMedioPerSedutaMetri ?? 0)}m di media ` +
      "a seduta" + (zone ? `, distribuzione per zona: ${zone}` : "") +
      (blocchi ? `, per blocco: ${blocchi}` : "") +
      (combinazioni ? `, combinazioni stile/esecuzione ricorrenti: ${combinazioni}` : "") +
      (attrezzatura ? `, attrezzatura più usata: ${attrezzatura}` : "") + ".",
    "Genera una settimana che segua questo stile di programmazione, " +
      "adattandolo ai parametri richiesti sopra (non è un vincolo rigido: " +
      "i parametri espliciti del coach vengono prima).",
  ].join(" ");
}

function costruisciPrompt(p: ParametriSettimana): string {
  const corsie = Array.isArray(p.corsie) ? p.corsie : [];
  const righeCorsie = corsie.map((c) => {
    const diff = c.differenzialeS != null
      ? `, differenziale di gara T200-T100 = ${c.differenzialeS}s`
      : "";
    return `- Corsia "${c.nome}": passo di riferimento sui 100 stile libero = ${c.passo100S}s${diff}`;
  });
  const giorni = Array.isArray(p.giorniSettimana) ? p.giorniSettimana : [];
  const focusPerSeduta = Array.isArray(p.focusPerSeduta) ? p.focusPerSeduta : [];
  const righeSedute = giorni.map((g, i) =>
    `- Seduta ${i + 1}, ${g}: focus "${
      [focusPerSeduta[i] ?? ""].flat().join(" + ")
    }"`
  );
  return [
    "Sei un allenatore di nuoto esperto. Pianifica una settimana di " +
      "allenamento come elenco di sedute (non il dettaglio delle serie, " +
      "solo lo scheletro della settimana).",
    `Gruppo: ${p.gruppo ?? ""}`,
    `Volume settimanale totale: ${p.volumeSettimanaleMetri ?? ""} metri`,
    p.tipoSettimana
      ? `Tipo di settimana: ${p.tipoSettimana} (adatta volume/intensità di ` +
        "conseguenza: una settimana di scarico ha volumi e intensità più " +
        "bassi di una di carico, una settimana gara punta su freschezza e " +
        "ritmo gara)"
      : "",
    p.vincoli ? `Vincoli: ${p.vincoli}` : "",
    p.volumeLavoroCentraleSettimanaleMetri != null
      ? `Volume totale di lavoro centrale (blocco "principale") sull'intera settimana: circa ${p.volumeLavoroCentraleSettimanaleMetri} metri, ripartiti fra le sedute in proporzione al loro volume.`
      : "",
    p.minutiMax != null
      ? `Ogni seduta ha un tetto di ${p.minutiMax} minuti di lavoro (nuoto + recuperi, sull'atleta più lento): dimensiona il volume di ciascuna seduta perché ci stia.`
      : "",
    p.vascaM != null ? `Vasca da ${p.vascaM}m.` : "",
    riassuntoRiga(p.riassuntoProgrammazione),
    righeCorsie.length > 0
      ? [
          "Passi di riferimento calcolati dai personal best degli atleti " +
            "del gruppo:",
          ...righeCorsie,
        ].join("\n")
      : "",
    righeSedute.length > 0
      ? [
          "Il coach ha già scelto i giorni della settimana in cui si " +
            `allena (le corsie in piscina sono spesso fisse per giorno): ` +
            `genera esattamente ${righeSedute.length} sedute, in questo ` +
            "ordine, una per ciascuna riga (non decidere tu il giorno, è " +
            "già fissato):",
          ...righeSedute,
        ].join("\n")
      : "",
    "Per ogni seduta indica: un codice breve che descriva l'enfasi della " +
      "seduta coerente col focus richiesto (es. \"Aerobico A2\", " +
      "\"Soglia B1 + tecnica\", \"Lattato C1\", \"Velocità C3\", " +
      "\"Ritmo gara D\"; parole intere, senza abbreviazioni, e solo le zone " +
      "A1, A2, B1, B2, C1, C2, C3, D), e " +
      "il volume in metri di quella seduta — tieni conto della vicinanza " +
      "fra i giorni scelti (es. evita di mettere due sedute di alta " +
      "intensità in giorni consecutivi, quando possibile). La somma dei " +
      "volumi di tutte le sedute deve avvicinarsi il più possibile al " +
      "volume settimanale richiesto.",
  ]
    .filter((riga) => riga.length > 0)
    .join("\n");
}

const schemaGemini = {
  type: "OBJECT",
  properties: {
    sedute: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          codice: { type: "STRING" },
          volumeMetri: { type: "INTEGER" },
        },
        required: ["codice", "volumeMetri"],
      },
    },
  },
  required: ["sedute"],
};

// Stesso contenuto per gli "structured outputs" di OpenAI (strict: ogni
// oggetto con additionalProperties: false e tutte le proprietà richieste).
const schemaOpenAi = {
  type: "object",
  additionalProperties: false,
  properties: {
    sedute: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          codice: { type: "string" },
          volumeMetri: { type: "integer" },
        },
        required: ["codice", "volumeMetri"],
      },
    },
  },
  required: ["sedute"],
};

function validaSettimana(dati: unknown, numeroSeduteAtteso?: number): SettimanaGenerata {
  if (typeof dati !== "object" || dati === null) {
    throw new Error("la settimana generata non è un oggetto JSON valido");
  }
  const settimana = dati as Record<string, unknown>;
  if (!Array.isArray(settimana.sedute) || settimana.sedute.length === 0) {
    throw new Error("nessuna seduta generata");
  }
  if (
    numeroSeduteAtteso != null &&
    settimana.sedute.length !== numeroSeduteAtteso
  ) {
    throw new Error(
      `attesi ${numeroSeduteAtteso} giorni/focus richiesti, ` +
        `ricevute ${settimana.sedute.length} sedute`,
    );
  }

  const sedute: SedutaGenerata[] = settimana.sedute.map((voce, indice) => {
    if (typeof voce !== "object" || voce === null) {
      throw new Error(`seduta #${indice + 1} non è un oggetto valido`);
    }
    const s = voce as Record<string, unknown>;

    if (typeof s.codice !== "string" || s.codice.trim() === "") {
      throw new Error(`seduta #${indice + 1}: codice mancante`);
    }
    const volumeMetri = Number(s.volumeMetri);
    if (!Number.isInteger(volumeMetri) || volumeMetri <= 0) {
      throw new Error(`seduta #${indice + 1}: volume non valido`);
    }

    return { codice: s.codice, volumeMetri };
  });

  return { sedute };
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
  // Con il credito dell'account esaurito OpenAI risponde 429 come per le
  // troppe richieste, ma aspettare non serve: va detto chiaramente.
  if (codiceOpenAi === "insufficient_quota") {
    return "Il credito del servizio AI è esaurito: va ricaricato l'account " +
      "OpenAI prima di poter usare di nuovo l'AI.";
  }
  if (status === 401) {
    return "La chiave del servizio AI non è valida: va controllata nelle " +
      "impostazioni del server.";
  }
  if (status === 429 || codiceOpenAi === "rate_limit_exceeded") {
    return "Troppe richieste al servizio AI in poco tempo. Aspetta un minuto " +
      "e riprova.";
  }
  if (status >= 500) {
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
// OpenAI 429/500/502/503 per gli stessi motivi — senza un ritentativo
// qui, questi picchi si vedevano come "il generatore non funziona" lato
// coach, pur essendo transitori.
const TENTATIVI_MASSIMI = 3;
const ATTESE_MS = [1500, 3000];

// L'app smette di aspettare dopo 60 secondi, e OpenAI ogni tanto impiega
// oltre un minuto a rispondere a una richiesta che di solito chiude in
// 10: ogni tentativo ha un tetto, e un nuovo tentativo parte solo se c'è
// ancora il tempo per farlo finire prima che l'app abbia rinunciato.
const TEMPO_MASSIMO_MS = 55_000;
const LIMITE_TENTATIVO_MS = 30_000;

async function chiamaGemini(prompt: string, schema: unknown): Promise<RispostaProvider> {
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
              responseSchema: schema,
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

async function chiamaOpenAi(
  prompt: string,
  nomeSchema: string,
  schema: unknown,
): Promise<RispostaProvider> {
  if (!OPENAI_API_KEY) {
    return { ok: false, errorMessage: "OPENAI_API_KEY non configurata sul server" };
  }

  const inizio = Date.now();
  let risposta: Response | undefined;
  let corpoErrore = "";
  let erroreRete: unknown;
  for (let tentativo = 1; tentativo <= TENTATIVI_MASSIMI; tentativo++) {
    try {
      risposta = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        signal: AbortSignal.timeout(
          Math.min(LIMITE_TENTATIVO_MS, TEMPO_MASSIMO_MS - (Date.now() - inizio)),
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: TEXT_MODEL,
          messages: [{ role: "user", content: prompt }],
          response_format: {
            type: "json_schema",
            json_schema: { name: nomeSchema, strict: true, schema },
          },
        }),
      });
      erroreRete = undefined;
    } catch (errore) {
      erroreRete = errore;
      risposta = undefined;
    }
    corpoErrore = risposta !== undefined && !risposta.ok ? await risposta.text() : "";
    const daRiprovare = erroreRete !== undefined ||
      (risposta !== undefined &&
        [429, 500, 502, 503].includes(risposta.status) &&
        !corpoErrore.includes("insufficient_quota"));
    const attesa = ATTESE_MS[tentativo - 1];
    const tempoRimasto = TEMPO_MASSIMO_MS - (Date.now() - inizio) - (attesa ?? 0);
    if (!daRiprovare || tentativo === TENTATIVI_MASSIMI || tempoRimasto < 10_000) break;
    await new Promise((r) => setTimeout(r, attesa));
  }

  if (erroreRete instanceof DOMException && erroreRete.name === "TimeoutError") {
    return {
      ok: false,
      errorMessage: "Il servizio AI sta impiegando troppo a rispondere. Riprova " +
        "tra qualche istante.",
    };
  }
  if (erroreRete !== undefined || risposta === undefined) {
    return { ok: false, errorMessage: `Impossibile contattare il provider AI: ${erroreRete}` };
  }
  if (!risposta.ok) {
    return { ok: false, errorMessage: messaggioErroreOpenAi(risposta.status, corpoErrore) };
  }

  const dati = await risposta.json();
  const messaggio = dati?.choices?.[0]?.message;
  // Con gli structured outputs il modello può rifiutarsi di rispondere
  // (campo `refusal` al posto del contenuto): meglio dirlo che lasciarlo
  // diventare un generico "JSON non valido".
  if (typeof messaggio?.refusal === "string" && messaggio.refusal.length > 0) {
    return {
      ok: false,
      errorMessage: "Il servizio AI non ha voluto rispondere a questa richiesta: " +
        "prova a riformularla.",
    };
  }
  return {
    ok: true,
    testoJson: messaggio?.content ?? "",
    gettoni: dati?.usage?.total_tokens ?? null,
  };
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
/// non blocca la richiesta per un problema che non è dell'utente:
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

/// Il club a cui attribuire la chiamata: l'app non lo manda a questa
/// funzione, quindi si legge dalle iscrizioni dell'utente (in V1 un
/// coach opera su un solo club). `null` se non si trova.
async function clubDiUtente(userId: string): Promise<string | null> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return null;
  try {
    const risposta = await fetch(
      `${SUPABASE_URL}/rest/v1/club_membri?select=club_id&user_id=eq.${userId}&limit=1`,
      {
        headers: {
          apikey: SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        },
      },
    );
    const righe = await risposta.json();
    const clubId = Array.isArray(righe) ? righe[0]?.club_id : null;
    return typeof clubId === "string" ? clubId : null;
  } catch {
    return null;
  }
}

/// Registra la chiamata — se fallisce, lo scrive solo nei log: non deve
/// far fallire una generazione già andata a buon fine.
async function registraUsoAi(
  params: { userId: string; modello: string; gettoni: number | null },
): Promise<void> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return;
  try {
    const clubId = await clubDiUtente(params.userId);
    if (clubId == null) return;
    await fetch(`${SUPABASE_URL}/rest/v1/ai_usage`, {
      method: "POST",
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        club_id: clubId,
        user_id: params.userId,
        funzione: NOME_FUNZIONE,
        modello: params.modello,
        gettoni: params.gettoni,
      }),
    });
  } catch (errore) {
    console.error("registraUsoAi fallita:", errore);
  }
}

/// Risposta 429 pronta se l'utente ha già raggiunto il tetto settimanale,
/// `null` se può procedere (o se non si sa chi è).
async function tettoSuperato(userId: string | null): Promise<Response | null> {
  if (!userId) return null;
  const richiesteFatte = await richiesteUltimaSettimana(userId);
  if (richiesteFatte < LIMITE_SETTIMANALE_PER_PERSONA) return null;
  return jsonResponse(
    {
      error: `Hai raggiunto il limite di ${LIMITE_SETTIMANALE_PER_PERSONA} ` +
        "richieste AI per questa settimana. Riprova la settimana prossima, " +
        "o scrivi la scheda a mano.",
    },
    429,
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo non supportato" }, 405);
  }

  let parametri: ParametriSettimana;
  try {
    parametri = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo della richiesta non valido" }, 400);
  }

  const userId = idUtenteDaRichiesta(req);
  const rifiuto = await tettoSuperato(userId);
  if (rifiuto) return rifiuto;

  const prompt = costruisciPrompt(parametri);

  const risultato = PROVIDER_ATTIVO === "openai"
    ? await chiamaOpenAi(prompt, "settimana_generata", schemaOpenAi)
    : await chiamaGemini(prompt, schemaGemini);

  if (!risultato.ok) {
    return jsonResponse({ error: risultato.errorMessage }, 502);
  }

  let settimanaGrezza: unknown;
  try {
    settimanaGrezza = JSON.parse(risultato.testoJson);
  } catch {
    return jsonResponse(
      { error: "Il provider AI non ha restituito un JSON valido" },
      502,
    );
  }

  try {
    const settimana = validaSettimana(
      settimanaGrezza,
      Array.isArray(parametri.giorniSettimana)
        ? parametri.giorniSettimana.length
        : undefined,
    );
    if (userId) {
      await registraUsoAi({
        userId,
        modello: PROVIDER_ATTIVO === "openai" ? TEXT_MODEL : GEMINI_MODEL,
        gettoni: risultato.gettoni,
      });
    }
    return jsonResponse({ settimana });
  } catch (errore) {
    return jsonResponse(
      { error: `Settimana generata non valida: ${(errore as Error).message}` },
      502,
    );
  }
});
