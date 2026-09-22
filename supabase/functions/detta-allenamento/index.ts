// Edge Function: detta-allenamento
//
// Riceve il testo dettato a voce dal coach (trascritto nel browser dalla
// Web Speech API, gratuita — questa funzione non tocca l'audio) e chiede
// a Gemini di STRUTTURARLO in una scheda, non di INVENTARLA come fa
// `genera-allenamento`: qui il compito è trascrivere fedelmente quello
// che è stato detto, riconoscendo il gergo del nuoto parlato (numeri,
// stili, zone, recuperi), non proporre una programmazione.
// Stessa forma di output di `genera-allenamento` (SchedaGenerata),
// rivalidata qui prima di rispondere: l'app riceve sempre una scheda con
// campi noti o un errore esplicito, mai testo libero da interpretare.
// Se in futuro si cambia provider AI, si riscrive solo questo file: il
// contratto verso l'app (corpo della richiesta e { scheda } in risposta)
// resta invariato.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

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
// riconosce: senza questo, "trazioni"/"pull boy"/"crawl" arriverebbero a
// Gemini senza un ponte esplicito verso gli enum consentiti, con più
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
  "resistenza lattacida"/"C1" = C1; "lattacido"/"C2" = C2;
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

const responseSchema = {
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

/// Rivalida la scheda restituita dal modello: anche con responseSchema
/// impostato, il provider può comunque restituire un JSON che non rispetta
/// lo schema (bug del modello, cambio di comportamento, ecc.), quindi non
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

  const prompt = costruisciPrompt(richiesta);

  // Gemini risponde spesso 503 "UNAVAILABLE" per sovraccarico momentaneo
  // (il messaggio stesso dice "usually temporary, please try again later")
  // — senza un ritentativo qui, questi picchi si vedevano come "il
  // generatore non funziona" lato coach, pur essendo transitori.
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
      { error: `Errore dal provider AI (${rispostaGemini.status}): ${dettaglio}` },
      502,
    );
  }

  const dati = await rispostaGemini.json();
  const testoJson = dati?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  let schedaGrezza: unknown;
  try {
    schedaGrezza = JSON.parse(testoJson);
  } catch {
    return jsonResponse(
      { error: "Il provider AI non ha restituito un JSON valido" },
      502,
    );
  }

  try {
    const scheda = validaScheda(schedaGrezza);
    return jsonResponse({ scheda });
  } catch (errore) {
    return jsonResponse(
      { error: `Non sono riuscito a interpretare la dettatura: ${(errore as Error).message}` },
      502,
    );
  }
});
