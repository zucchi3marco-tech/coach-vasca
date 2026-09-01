// Edge Function: genera-allenamento
//
// Riceve i parametri raccolti dal form "Genera con AI" e li inoltra a
// Gemini, tenendo la API key lato server (mai esposta al client Flutter).
// Chiede output JSON strutturato (responseSchema) e lo rivalida qui prima
// di restituirlo, così l'app riceve sempre una scheda con campi noti o un
// errore esplicito, mai testo libero da interpretare.
// Se in futuro si cambia provider AI, si riscrive solo questo file: il
// contratto verso l'app (corpo della richiesta e { scheda } in risposta)
// resta invariato.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

const BLOCCHI = ["riscaldamento", "principale", "defaticamento", "altro"];
const STILI = ["libero", "dorso", "rana", "delfino", "misti"];
const ESECUZIONI = ["nuoto", "gambe", "braccia", "pull", "tecnica"];
const ZONE = ["A1", "A2", "B1", "B2", "C", "D"];

interface ParametriGenerazione {
  gruppo?: string;
  livello?: string;
  volumeMetri?: number;
  focus?: string;
  regimiAmmessi?: string[];
  vincoli?: string | null;
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
}

interface SchedaGenerata {
  titolo: string;
  note?: string | null;
  serie: SerieGenerata[];
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

function costruisciPrompt(p: ParametriGenerazione): string {
  const regimi = Array.isArray(p.regimiAmmessi) ? p.regimiAmmessi.join(", ") : "";
  return [
    "Sei un allenatore di nuoto esperto. Genera una scheda di allenamento " +
      "per la seguente sessione, come elenco di serie.",
    `Gruppo: ${p.gruppo ?? ""}`,
    `Livello: ${p.livello ?? ""}`,
    `Volume totale: ${p.volumeMetri ?? ""} metri`,
    `Focus: ${p.focus ?? ""}`,
    `Regimi di allenamento ammessi: ${regimi}`,
    p.vincoli ? `Vincoli: ${p.vincoli}` : "",
    "Dividi la scheda in riscaldamento, parte principale e defaticamento. " +
      "La somma di ripetute*distanza di tutte le serie deve avvicinarsi il " +
      "più possibile al volume totale richiesto. Usa solo zone tra quelle " +
      "ammesse indicate sopra.",
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
    throw new Error("nessuna serie generata");
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

  let parametri: ParametriGenerazione;
  try {
    parametri = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo della richiesta non valido" }, 400);
  }

  const prompt = costruisciPrompt(parametri);

  let rispostaGemini: Response;
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
  } catch (errore) {
    return jsonResponse(
      { error: `Impossibile contattare il provider AI: ${errore}` },
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
      { error: `Scheda generata non valida: ${(errore as Error).message}` },
      502,
    );
  }
});
