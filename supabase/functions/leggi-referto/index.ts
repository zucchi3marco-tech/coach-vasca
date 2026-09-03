// Edge Function: leggi-referto
//
// Riceve la foto di un verbale di partita di pallanuoto (referto FIN) gia'
// compilato a mano e la inoltra a Gemini (vision) per estrarne i dati in
// JSON strutturato, invece di scrivere un OCR dedicato per un modulo
// cartaceo pieno di tabelle e abbreviazioni. Stessa architettura di
// genera-allenamento: chiave del provider solo lato server, output sempre
// validato prima di tornare all'app.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

interface GiocatoreReferto {
  numeroCalottina: number;
  nome: string;
  reti: number;
  espulsioni: number;
}

interface ParzialeReferto {
  casa: number;
  trasferta: number;
}

interface RefertoLetto {
  squadraCasa: string;
  squadraTrasferta: string;
  risultatoCasa: number;
  risultatoTrasferta: number;
  parziali: ParzialeReferto[];
  giocatoriCasa: GiocatoreReferto[];
  giocatoriTrasferta: GiocatoreReferto[];
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
  "Questa immagine e' un verbale di partita di pallanuoto (referto FIN, " +
    "modulo CONI/FIN/GUG \"Verbale di Partita di Pallanuoto\"), compilato a " +
    "mano durante una gara.",
  "Il modulo ha due blocchi squadra (calottina B in alto, calottina N in " +
    "basso), ciascuno con una tabella Giocatori (colonne: numero di " +
    "tessera FIN, numero di calottina) e una colonna RETI dove i gol " +
    "segnati da quel giocatore sono indicati con trattini/tacche (conta " +
    "quante tacche ci sono per ogni riga).",
  "Ogni blocco squadra ha anche una tabella \"Falli Personali\" con coppie " +
    "Tempo/Evento per riga di giocatore: conta come espulsione ogni evento " +
    "con codice ET (espulsione temporanea) o EDCS (espulsione definitiva).",
  "In alto ci sono i \"Risultati parziali\" per le due squadre (colonne B e " +
    "N) nei quattro tempi di gioco.",
  "Estrai i dati con questa corrispondenza: la squadra elencata per prima " +
    "(in alto) e' \"casa\", quella elencata per seconda (in basso) e' " +
    "\"trasferta\". Il risultato finale e' la somma dei quattro parziali. " +
    "Il nome del giocatore e' quello scritto a mano accanto al numero, per " +
    "come riesci a leggerlo. Se una riga giocatore non ha reti o " +
    "espulsioni, restituisci 0. Non inventare giocatori o numeri che non " +
    "vedi scritti nel modulo.",
].join(" ");

const responseSchema = {
  type: "OBJECT",
  properties: {
    squadraCasa: { type: "STRING" },
    squadraTrasferta: { type: "STRING" },
    risultatoCasa: { type: "INTEGER" },
    risultatoTrasferta: { type: "INTEGER" },
    parziali: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          casa: { type: "INTEGER" },
          trasferta: { type: "INTEGER" },
        },
        required: ["casa", "trasferta"],
      },
    },
    giocatoriCasa: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          numeroCalottina: { type: "INTEGER" },
          nome: { type: "STRING" },
          reti: { type: "INTEGER" },
          espulsioni: { type: "INTEGER" },
        },
        required: ["numeroCalottina", "nome", "reti", "espulsioni"],
      },
    },
    giocatoriTrasferta: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          numeroCalottina: { type: "INTEGER" },
          nome: { type: "STRING" },
          reti: { type: "INTEGER" },
          espulsioni: { type: "INTEGER" },
        },
        required: ["numeroCalottina", "nome", "reti", "espulsioni"],
      },
    },
  },
  required: [
    "squadraCasa",
    "squadraTrasferta",
    "risultatoCasa",
    "risultatoTrasferta",
    "parziali",
    "giocatoriCasa",
    "giocatoriTrasferta",
  ],
};

function validaGiocatore(voce: unknown, indice: number, squadra: string): GiocatoreReferto {
  if (typeof voce !== "object" || voce === null) {
    throw new Error(`${squadra}: giocatore #${indice + 1} non e' un oggetto valido`);
  }
  const g = voce as Record<string, unknown>;
  const numeroCalottina = Number(g.numeroCalottina);
  if (!Number.isInteger(numeroCalottina) || numeroCalottina <= 0) {
    throw new Error(`${squadra}: giocatore #${indice + 1} ha un numero di calottina non valido`);
  }
  if (typeof g.nome !== "string" || g.nome.trim() === "") {
    throw new Error(`${squadra}: giocatore #${indice + 1} non ha un nome valido`);
  }
  const reti = Number(g.reti);
  if (!Number.isInteger(reti) || reti < 0) {
    throw new Error(`${squadra}: giocatore #${indice + 1} ha reti non valide`);
  }
  const espulsioni = Number(g.espulsioni);
  if (!Number.isInteger(espulsioni) || espulsioni < 0) {
    throw new Error(`${squadra}: giocatore #${indice + 1} ha espulsioni non valide`);
  }
  return { numeroCalottina, nome: g.nome.trim(), reti, espulsioni };
}

function validaReferto(dati: unknown): RefertoLetto {
  if (typeof dati !== "object" || dati === null) {
    throw new Error("il referto letto non e' un oggetto JSON valido");
  }
  const r = dati as Record<string, unknown>;

  if (typeof r.squadraCasa !== "string" || r.squadraCasa.trim() === "") {
    throw new Error("squadra casa mancante");
  }
  if (typeof r.squadraTrasferta !== "string" || r.squadraTrasferta.trim() === "") {
    throw new Error("squadra trasferta mancante");
  }
  const risultatoCasa = Number(r.risultatoCasa);
  const risultatoTrasferta = Number(r.risultatoTrasferta);
  if (!Number.isInteger(risultatoCasa) || risultatoCasa < 0) {
    throw new Error("risultato casa non valido");
  }
  if (!Number.isInteger(risultatoTrasferta) || risultatoTrasferta < 0) {
    throw new Error("risultato trasferta non valido");
  }
  if (!Array.isArray(r.parziali) || r.parziali.length === 0) {
    throw new Error("parziali mancanti");
  }
  const parziali = r.parziali.map((p, indice) => {
    if (typeof p !== "object" || p === null) {
      throw new Error(`parziale #${indice + 1} non valido`);
    }
    const parz = p as Record<string, unknown>;
    const casa = Number(parz.casa);
    const trasferta = Number(parz.trasferta);
    if (!Number.isInteger(casa) || casa < 0 || !Number.isInteger(trasferta) || trasferta < 0) {
      throw new Error(`parziale #${indice + 1} non valido`);
    }
    return { casa, trasferta };
  });
  if (!Array.isArray(r.giocatoriCasa) || r.giocatoriCasa.length === 0) {
    throw new Error("nessun giocatore letto per la squadra di casa");
  }
  if (!Array.isArray(r.giocatoriTrasferta) || r.giocatoriTrasferta.length === 0) {
    throw new Error("nessun giocatore letto per la squadra in trasferta");
  }

  return {
    squadraCasa: r.squadraCasa.trim(),
    squadraTrasferta: r.squadraTrasferta.trim(),
    risultatoCasa,
    risultatoTrasferta,
    parziali,
    giocatoriCasa: r.giocatoriCasa.map((g, i) => validaGiocatore(g, i, "casa")),
    giocatoriTrasferta: r.giocatoriTrasferta.map((g, i) => validaGiocatore(g, i, "trasferta")),
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

  let refertoGrezzo: unknown;
  try {
    refertoGrezzo = JSON.parse(testoJson);
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
    const referto = validaReferto(refertoGrezzo);
    return jsonResponse({ referto });
  } catch (errore) {
    return jsonResponse(
      {
        error: `Referto letto non valido: ${(errore as Error).message}`,
        codice: "referto_non_valido",
      },
      502,
    );
  }
});
