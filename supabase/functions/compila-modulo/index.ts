// Edge Function: compila-modulo
//
// Riceve il testo libero scritto dal coach nella casella "Scrivi il tuo
// allenamento" del form "Genera con AI" e chiede a Gemini di ricavarne i
// VALORI DEI CAMPI del form (vasca, volumi, tipi di lavoro, focus, attrezzi,
// vincoli). Non genera nessuna scheda: il coach rivede il modulo compilato e
// poi preme Genera. Ogni campo è opzionale: si restituisce solo quello che
// il testo dice davvero, mai un valore inventato per "completare".
// Output rivalidato qui (valori ammessi, intervalli): l'app riceve sempre
// campi noti o un errore esplicito.
// Come le altre Edge Function, è un file autonomo (nessun codice condiviso
// fra le funzioni): le costanti sono duplicate a mano — tenere allineate a
// `lib/features/ai_genera/domain/tipo_lavoro.dart` e `focus_lavoro.dart`.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

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
      "menzionato va lasciato fuori.",
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

const responseSchema = {
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

function messaggioErroreProvider(status: number, corpoGrezzo: string): string {
  let statoGemini: string | undefined;
  try {
    statoGemini = JSON.parse(corpoGrezzo)?.error?.status;
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo non supportato" }, 405);
  }
  if (!GEMINI_API_KEY) {
    return jsonResponse(
      { error: "GEMINI_API_KEY non configurata sul server" },
      500,
    );
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

  // Gemini risponde spesso 503 per sovraccarico momentaneo: si ritenta.
  const TENTATIVI_MASSIMI = 3;
  const ATTESE_MS = [1500, 3000];

  let rispostaGemini: Response | undefined;
  let erroreRete: unknown;
  for (let tentativo = 1; tentativo <= TENTATIVI_MASSIMI; tentativo++) {
    try {
      rispostaGemini = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              responseMimeType: "application/json",
              responseSchema,
            },
          }),
        },
      );
      erroreRete = undefined;
    } catch (errore) {
      erroreRete = errore;
      rispostaGemini = undefined;
    }
    const daRiprovare = rispostaGemini?.status === 503 || erroreRete !== undefined;
    if (!daRiprovare || tentativo === TENTATIVI_MASSIMI) break;
    await new Promise((r) => setTimeout(r, ATTESE_MS[tentativo - 1]));
  }

  if (erroreRete !== undefined || rispostaGemini === undefined) {
    return jsonResponse(
      { error: `Impossibile contattare il provider AI: ${erroreRete}` },
      502,
    );
  }
  if (!rispostaGemini.ok) {
    const dettaglio = await rispostaGemini.text();
    return jsonResponse(
      { error: messaggioErroreProvider(rispostaGemini.status, dettaglio) },
      502,
    );
  }

  const dati = await rispostaGemini.json();
  const testoJson = dati?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  let grezzo: unknown;
  try {
    grezzo = JSON.parse(testoJson);
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
