// Edge Function: compila-modulo
//
// Riceve il testo libero scritto dal coach nella casella "Scrivi il tuo
// allenamento" del form "Genera con AI" e chiede al provider AI di ricavarne i
// VALORI DEI CAMPI del form (vasca, volumi, tipi di lavoro, focus, attrezzi,
// vincoli). Non genera nessuna scheda: il coach rivede il modulo compilato e
// poi preme Genera. Ogni campo è opzionale: si restituisce solo quello che
// il testo dice davvero, mai un valore inventato per "completare".
// Output rivalidato qui (valori ammessi, intervalli): l'app riceve sempre
// campi noti o un errore esplicito.
// Come le altre Edge Function, è un file autonomo (nessun codice condiviso
// fra le funzioni): le costanti sono duplicate a mano — tenere allineate a
// `lib/features/ai_genera/domain/tipo_lavoro.dart` e `focus_lavoro.dart`.

// RIPROGETTAZIONE AI: provider passato da Gemini a OpenAI come
// `genera-allenamento`. `chiamaGemini` resta nel file, spenta dietro
// PROVIDER_ATTIVO, per tornare indietro in un attimo.
const PROVIDER_ATTIVO: "openai" | "gemini" = "openai";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const TEXT_MODEL = Deno.env.get("TEXT_MODEL") ?? "gpt-4o-mini";

const ZONE = ["A1", "A2", "B1", "B2", "C1", "C2", "C3", "D"];
const FOCUS = ["completo", "braccia", "gambe", "tecnica"];
const STILI = ["libero", "dorso", "rana", "delfino", "misti"];
const ATTREZZI_BRACCIA = ["pull", "palette"];
const ATTREZZI_GAMBE = ["pinne", "tavola", "boccaglio"];
const ATTREZZI_CENTRALE = ["pull", "palette", "boccaglio", "pinne"];

const VOLUME_MIN = 500;
const VOLUME_MAX = 6000;
const MINUTI_MIN = 20;
const MINUTI_MAX = 180;

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

const GLOSSARIO = `
Corrispondenze fra gergo e valori consentiti (usa il buon senso anche per
varianti non elencate):
- Tipi di lavoro (tipiLavoro): "aerobico leggero"/"defaticamento"/"A1" = A1;
  "aerobico"/"resistenza aerobica"/"A2" = A2; "soglia"/"soglia anaerobica"/
  "B1" = B1; "VO2max"/"VO2"/"potenza aerobica"/"B2" = B2; "tolleranza
  lattacida"/"lattato"/"C1" = C1; "picco di lattato"/"C2" = C2;
  "velocità"/"sprint"/"C3" = C3; "ritmo gara"/"D" = D. "Aerobico" senza
  altro = A1 e A2.
- Focus: "completo" (nessun accento particolare), "braccia" (lavoro di sole
  braccia, con pull/palette), "gambe" (lavoro di sole gambe, con
  pinne/tavola/boccaglio), "tecnica" (drills). Più focus insieme sono
  possibili, "completo" sta da solo.
- Stili: libero/crawl = libero; dorso; rana; delfino/farfalla = delfino;
  misti/quattro stili = misti. SL = libero, DO = dorso, RA = rana, FA =
  delfino, MX = misti.
- Distanze in km ("5 km") vanno convertite in metri (5000).
- "vasca da 25" / "in 25" = vascaM 25; "vasca lunga"/"da 50" = 50.
`.trim();

function costruisciPrompt(testo: string): string {
  return [
    "Un allenatore di nuoto ha descritto a parole l'allenamento che vuole " +
      "generare. Il tuo compito è ricavare da questo testo SOLO i valori " +
      "dei campi di un modulo, che poi il coach rivedrà.",
    "",
    "Regole importanti:",
    "- Compila un campo SOLO se il testo lo dice o lo implica chiaramente. " +
      "Non inventare valori per completare il modulo: un campo non " +
      "menzionato va lasciato vuoto.",
    "- volumeMetri è il volume totale della seduta; volumeLavoroCentraleMetri " +
      "è la sola parte centrale/principale (es. \"3 km di aerobico\" dentro " +
      "un totale di 5 km).",
    "- metriBraccia/metriGambe sono i metri dedicati a quel lavoro specifico " +
      "(es. \"400 di gambe e 600 di braccia con palette\").",
    "- Le indicazioni che non rientrano in nessun campo (es. \"no rana\", " +
      "\"niente pinne di gomma\", preferenze varie) vanno in vincoli, scritte " +
      "in modo breve e fedele.",
    "",
    GLOSSARIO,
    "",
    "Testo del coach:",
    `"${testo.trim()}"`,
  ].join("\n");
}

const schemaGemini = {
  type: "OBJECT",
  properties: {
    vascaM: { type: "INTEGER" },
    minutiMax: { type: "INTEGER" },
    volumeMetri: { type: "INTEGER" },
    volumeLavoroCentraleMetri: { type: "INTEGER" },
    tipiLavoro: { type: "ARRAY", items: { type: "STRING", enum: ZONE } },
    focus: { type: "ARRAY", items: { type: "STRING", enum: FOCUS } },
    metriBraccia: { type: "INTEGER" },
    attrezziBraccia: {
      type: "ARRAY",
      items: { type: "STRING", enum: ATTREZZI_BRACCIA },
    },
    stileBraccia: { type: "STRING", enum: STILI },
    metriGambe: { type: "INTEGER" },
    attrezziGambe: {
      type: "ARRAY",
      items: { type: "STRING", enum: ATTREZZI_GAMBE },
    },
    stileGambe: { type: "STRING", enum: STILI },
    stileTecnica: { type: "STRING", enum: STILI },
    attrezziLavoroCentrale: {
      type: "ARRAY",
      items: { type: "STRING", enum: ATTREZZI_CENTRALE },
    },
    vincoli: { type: "STRING" },
  },
};

// Lo stesso modulo per gli "structured outputs" di OpenAI: in modalità
// strict ogni proprietà deve stare in `required`, quindi i campi restano
// facoltativi diventando nullable (gli elenchi vuoti valgono già come
// "non detto"). Ricavato dallo schema Gemini per non tenerne due copie.
function schemaOpenAiDa(schema: Record<string, unknown>, facoltativo = false): unknown {
  const tipo = String(schema.type).toLowerCase();
  if (tipo === "object") {
    const proprieta = schema.properties as Record<string, Record<string, unknown>>;
    const richieste = (schema.required as string[] | undefined) ?? [];
    return {
      type: "object",
      additionalProperties: false,
      properties: Object.fromEntries(
        Object.entries(proprieta).map(([nome, figlio]) => [
          nome,
          schemaOpenAiDa(figlio, !richieste.includes(nome)),
        ]),
      ),
      required: Object.keys(proprieta),
    };
  }
  if (tipo === "array") {
    return {
      type: "array",
      items: schemaOpenAiDa(schema.items as Record<string, unknown>),
    };
  }
  const enumerato = schema.enum as unknown[] | undefined;
  if (!facoltativo) {
    return enumerato ? { type: tipo, enum: enumerato } : { type: tipo };
  }
  return enumerato
    ? { type: [tipo, "null"], enum: [...enumerato, null] }
    : { type: [tipo, "null"] };
}

const schemaOpenAi = schemaOpenAiDa(schemaGemini);

function arrotonda(n: number, passo: number): number {
  return Math.round(n / passo) * passo;
}

function intero(v: unknown, min: number, max: number, passo: number): number | undefined {
  const n = Number(v);
  if (v === undefined || v === null || !Number.isFinite(n)) return undefined;
  return Math.min(max, Math.max(min, arrotonda(n, passo)));
}

function elenco(v: unknown, ammessi: string[]): string[] {
  if (!Array.isArray(v)) return [];
  return [...new Set(v.filter((x): x is string => typeof x === "string" && ammessi.includes(x)))];
}

function stile(v: unknown): string | undefined {
  return typeof v === "string" && STILI.includes(v) ? v : undefined;
}

/// Rivalida e normalizza: anche con responseSchema il modello può restituire
/// valori fuori intervallo o incoerenti, quindi qui si tengono solo valori
/// validi (volumi a passi di 100, minuti a passi di 5, lavoro centrale e
/// dettagli entro il volume totale).
function validaModulo(dati: unknown): Record<string, unknown> {
  if (typeof dati !== "object" || dati === null) {
    throw new Error("la risposta non è un oggetto JSON valido");
  }
  const d = dati as Record<string, unknown>;
  const out: Record<string, unknown> = {};

  const vasca = Number(d.vascaM);
  if (vasca === 25 || vasca === 50) out.vascaM = vasca;

  const minuti = intero(d.minutiMax, MINUTI_MIN, MINUTI_MAX, 5);
  if (minuti !== undefined) out.minutiMax = minuti;

  const volume = intero(d.volumeMetri, VOLUME_MIN, VOLUME_MAX, 100);
  if (volume !== undefined) out.volumeMetri = volume;
  const tetto = volume ?? VOLUME_MAX;

  const centrale = intero(d.volumeLavoroCentraleMetri, 0, tetto, 100);
  if (centrale !== undefined) out.volumeLavoroCentraleMetri = centrale;

  const tipi = elenco(d.tipiLavoro, ZONE);
  if (tipi.length > 0) out.tipiLavoro = tipi;

  let focus = elenco(d.focus, FOCUS);
  if (focus.includes("completo") && focus.length > 1) {
    focus = focus.filter((f) => f !== "completo");
  }
  const braccia = {
    metri: intero(d.metriBraccia, 0, tetto, 100),
    attrezzi: elenco(d.attrezziBraccia, ATTREZZI_BRACCIA),
    stile: stile(d.stileBraccia),
  };
  const gambe = {
    metri: intero(d.metriGambe, 0, tetto, 100),
    attrezzi: elenco(d.attrezziGambe, ATTREZZI_GAMBE),
    stile: stile(d.stileGambe),
  };
  const haDettaglio = (x: typeof braccia) =>
    x.metri !== undefined || x.attrezzi.length > 0 || x.stile !== undefined;
  // Un dettaglio implica il focus corrispondente, anche se il modello non
  // lo ha elencato.
  if (haDettaglio(braccia) && !focus.includes("braccia")) {
    focus = [...focus.filter((f) => f !== "completo"), "braccia"];
  }
  if (haDettaglio(gambe) && !focus.includes("gambe")) {
    focus = [...focus.filter((f) => f !== "completo"), "gambe"];
  }
  const stileTec = stile(d.stileTecnica);
  if (stileTec !== undefined && !focus.includes("tecnica")) {
    focus = [...focus.filter((f) => f !== "completo"), "tecnica"];
  }
  if (focus.length > 0) out.focus = focus;
  if (haDettaglio(braccia)) {
    if (braccia.metri !== undefined) out.metriBraccia = braccia.metri;
    if (braccia.attrezzi.length > 0) out.attrezziBraccia = braccia.attrezzi;
    if (braccia.stile !== undefined) out.stileBraccia = braccia.stile;
  }
  if (haDettaglio(gambe)) {
    if (gambe.metri !== undefined) out.metriGambe = gambe.metri;
    if (gambe.attrezzi.length > 0) out.attrezziGambe = gambe.attrezzi;
    if (gambe.stile !== undefined) out.stileGambe = gambe.stile;
  }
  if (stileTec !== undefined) out.stileTecnica = stileTec;

  const centraleAttrezzi = elenco(d.attrezziLavoroCentrale, ATTREZZI_CENTRALE);
  if (centraleAttrezzi.length > 0) out.attrezziLavoroCentrale = centraleAttrezzi;

  if (typeof d.vincoli === "string" && d.vincoli.trim() !== "") {
    out.vincoli = d.vincoli.trim().slice(0, 500);
  }
  return out;
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo non supportato" }, 405);
  }

  let richiesta: { testo?: string };
  try {
    richiesta = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo della richiesta non valido" }, 400);
  }
  if (!richiesta.testo || richiesta.testo.trim().length < 5) {
    return jsonResponse(
      { error: "Il testo è troppo corto per essere interpretato" },
      400,
    );
  }
  if (richiesta.testo.length > 2000) {
    return jsonResponse({ error: "Il testo è troppo lungo (max 2000 caratteri)" }, 400);
  }

  const prompt = costruisciPrompt(richiesta.testo);

  const risultato = PROVIDER_ATTIVO === "openai"
    ? await chiamaOpenAi(prompt, "modulo_compilato", schemaOpenAi)
    : await chiamaGemini(prompt, schemaGemini);

  if (!risultato.ok) {
    return jsonResponse({ error: risultato.errorMessage }, 502);
  }

  let grezzo: unknown;
  try {
    grezzo = JSON.parse(risultato.testoJson);
  } catch {
    return jsonResponse(
      { error: "Il provider AI non ha restituito un JSON valido" },
      502,
    );
  }

  try {
    return jsonResponse({ modulo: validaModulo(grezzo) });
  } catch (errore) {
    return jsonResponse(
      { error: `Non sono riuscito a interpretare il testo: ${(errore as Error).message}` },
      502,
    );
  }
});
