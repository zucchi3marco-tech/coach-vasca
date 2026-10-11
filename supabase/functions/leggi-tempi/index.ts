// Edge Function: leggi-tempi
//
// Riceve la foto di un foglio (o di una lavagna) scritto a mano a bordo
// vasca, con i nomi degli atleti e i loro tempi, e la inoltra a Gemini
// (vision) per estrarne le righe in JSON. Analisi "Il Mako della
// pallanuoto", proposta 8: lo stesso meccanismo di `leggi-referto`. Il
// coach controlla e corregge nell'app prima di salvare: qui si legge
// soltanto, non si scrive niente nel database.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

interface RigaLetta {
  nome: string;
  tempiS: number[];
  distanzaM: number | null;
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

const PROMPT = [
  "Questa immagine e' un foglio o una lavagna scritti a mano a bordo " +
    "vasca da un allenatore di nuoto o di pallanuoto, con i risultati di " +
    "un allenamento o di un test.",
  "Ogni riga riguarda un atleta: il suo nome o cognome (a volte solo il " +
    "cognome, o il cognome con l'iniziale del nome) e uno o piu' tempi; a " +
    "volte anche la distanza nuotata in metri (per esempio nei test a " +
    "tempo come il T30).",
  "Per ogni atleta restituisci una riga con: il nome come lo leggi; tutti " +
    "i tempi della riga, in ordine, convertiti in secondi (1'05\"20 = " +
    "65.2; 1:05.2 = 65.2; 32\"5 = 32.5; 28.4 = 28.4; 2'10 = 130); la " +
    "distanza in metri se e' scritta nella riga, altrimenti null.",
  "Ignora intestazioni, date, titoli e righe senza un nome. Non inventare " +
    "atleti, tempi o distanze che non vedi scritti.",
].join(" ");

const responseSchema = {
  type: "OBJECT",
  properties: {
    righe: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          nome: { type: "STRING" },
          tempiS: { type: "ARRAY", items: { type: "NUMBER" } },
          distanzaM: { type: "INTEGER", nullable: true },
        },
        required: ["nome", "tempiS"],
      },
    },
  },
  required: ["righe"],
};

/// Le righe valide: un nome, tempi fra 0 e 2 ore, una distanza fra 1 e
/// 10 km se c'e'. Una riga senza tempi ne' distanza non serve.
function validaRighe(dati: unknown): RigaLetta[] {
  if (typeof dati !== "object" || dati === null) {
    throw new Error("la lettura non e' un oggetto JSON valido");
  }
  const grezze = (dati as Record<string, unknown>).righe;
  if (!Array.isArray(grezze)) {
    throw new Error("nessuna riga letta");
  }
  const righe: RigaLetta[] = [];
  for (const voce of grezze) {
    if (typeof voce !== "object" || voce === null) continue;
    const r = voce as Record<string, unknown>;
    if (typeof r.nome !== "string" || r.nome.trim() === "") continue;
    const tempiS = Array.isArray(r.tempiS)
      ? r.tempiS
        .map((t) => Number(t))
        .filter((t) => Number.isFinite(t) && t > 0 && t < 7200)
        .map((t) => Math.round(t * 100) / 100)
      : [];
    const distanza = Number(r.distanzaM);
    const distanzaM = Number.isInteger(distanza) && distanza > 0 &&
        distanza <= 10000
      ? distanza
      : null;
    if (tempiS.length === 0 && distanzaM === null) continue;
    righe.push({ nome: r.nome.trim(), tempiS, distanzaM });
  }
  if (righe.length === 0) {
    throw new Error("nessuna riga con un nome e un tempo");
  }
  return righe;
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
      {
        error: "GEMINI_API_KEY non configurata sul server",
        codice: "chiave_non_configurata",
      },
      500,
    );
  }

  let corpo: { immagineBase64?: string; mimeType?: string };
  try {
    corpo = await req.json();
  } catch {
    return jsonResponse(
      { error: "Corpo della richiesta non valido", codice: "richiesta_non_valida" },
      400,
    );
  }

  if (!corpo.immagineBase64 || !corpo.mimeType) {
    return jsonResponse(
      { error: "Immagine mancante", codice: "richiesta_non_valida" },
      400,
    );
  }

  let rispostaGemini: Response;
  try {
    rispostaGemini = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{
            parts: [
              { text: PROMPT },
              {
                inlineData: {
                  mimeType: corpo.mimeType,
                  data: corpo.immagineBase64,
                },
              },
            ],
          }],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema,
          },
        }),
      },
    );
  } catch (errore) {
    return jsonResponse(
      {
        error: `Impossibile contattare il provider AI: ${errore}`,
        codice: "provider_non_raggiungibile",
      },
      502,
    );
  }

  if (!rispostaGemini.ok) {
    const dettaglio = await rispostaGemini.text();
    return jsonResponse(
      {
        error: `Errore dal provider AI (${rispostaGemini.status}): ${dettaglio}`,
        codice: "provider_errore",
      },
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
      {
        error: "Il provider AI non ha restituito un JSON valido",
        codice: "risposta_non_valida",
      },
      502,
    );
  }

  try {
    return jsonResponse({ righe: validaRighe(grezzo) });
  } catch (errore) {
    return jsonResponse(
      {
        error: `Foglio letto non valido: ${(errore as Error).message}`,
        codice: "foglio_non_valido",
      },
      502,
    );
  }
});
