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

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

interface CorsiaGenerazione {
  nome: string;
  passo100S: number;
  differenzialeS?: number | null;
}

interface ParametriSettimana {
  gruppo?: string;
  numeroSedute?: number;
  volumeSettimanaleMetri?: number;
  focus?: string;
  tipoMicrociclo?: string | null;
  vincoli?: string | null;
  corsie?: CorsiaGenerazione[];
}

interface SedutaGenerata {
  giorno: number;
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

function costruisciPrompt(p: ParametriSettimana): string {
  const corsie = Array.isArray(p.corsie) ? p.corsie : [];
  const righeCorsie = corsie.map((c) => {
    const diff = c.differenzialeS != null
      ? `, differenziale di gara T200-T100 = ${c.differenzialeS}s`
      : "";
    return `- Corsia "${c.nome}": passo di riferimento sui 100 stile libero = ${c.passo100S}s${diff}`;
  });
  return [
    "Sei un allenatore di nuoto esperto. Pianifica una settimana di " +
      "allenamento come elenco di sedute (non il dettaglio delle serie, " +
      "solo lo scheletro della settimana).",
    `Gruppo: ${p.gruppo ?? ""}`,
    `Numero di sedute nella settimana: ${p.numeroSedute ?? ""}`,
    `Volume settimanale totale: ${p.volumeSettimanaleMetri ?? ""} metri`,
    `Focus generale: ${p.focus ?? ""}`,
    p.tipoMicrociclo
      ? `Tipo di settimana: ${p.tipoMicrociclo} (adatta volume/intensità di ` +
        "conseguenza: una settimana di scarico ha volumi e intensità più " +
        "bassi di una di carico, una settimana gara punta su freschezza e " +
        "ritmo gara)"
      : "",
    p.vincoli ? `Vincoli: ${p.vincoli}` : "",
    righeCorsie.length > 0
      ? [
          "Passi di riferimento calcolati dai personal best degli atleti " +
            "del gruppo:",
          ...righeCorsie,
        ].join("\n")
      : "",
    "Per ogni seduta indica: giorno (numero da 1 a 7, 1 = primo giorno " +
      "della settimana; distribuisci le sedute in modo sensato, non tutte " +
      "consecutive se sono più di 4 e non due sedute di alta intensità di " +
      "fila), un codice breve che descriva l'enfasi della seduta (es. " +
      "\"Aerobico A2\", \"Soglia B1 + tecnica\", \"Velocità C1/C2\", " +
      "\"Ritmo gara D\"), e il volume in metri di quella seduta. La somma " +
      "dei volumi di tutte le sedute deve avvicinarsi il più possibile al " +
      "volume settimanale richiesto.",
  ]
    .filter((riga) => riga.length > 0)
    .join("\n");
}

const responseSchema = {
  type: "OBJECT",
  properties: {
    sedute: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          giorno: { type: "INTEGER" },
          codice: { type: "STRING" },
          volumeMetri: { type: "INTEGER" },
        },
        required: ["giorno", "codice", "volumeMetri"],
      },
    },
  },
  required: ["sedute"],
};

function validaSettimana(dati: unknown): SettimanaGenerata {
  if (typeof dati !== "object" || dati === null) {
    throw new Error("la settimana generata non è un oggetto JSON valido");
  }
  const settimana = dati as Record<string, unknown>;
  if (!Array.isArray(settimana.sedute) || settimana.sedute.length === 0) {
    throw new Error("nessuna seduta generata");
  }

  const sedute: SedutaGenerata[] = settimana.sedute.map((voce, indice) => {
    if (typeof voce !== "object" || voce === null) {
      throw new Error(`seduta #${indice + 1} non è un oggetto valido`);
    }
    const s = voce as Record<string, unknown>;

    const giorno = Number(s.giorno);
    if (!Number.isInteger(giorno) || giorno < 1 || giorno > 7) {
      throw new Error(`seduta #${indice + 1}: giorno non valido`);
    }
    if (typeof s.codice !== "string" || s.codice.trim() === "") {
      throw new Error(`seduta #${indice + 1}: codice mancante`);
    }
    const volumeMetri = Number(s.volumeMetri);
    if (!Number.isInteger(volumeMetri) || volumeMetri <= 0) {
      throw new Error(`seduta #${indice + 1}: volume non valido`);
    }

    return { giorno, codice: s.codice, volumeMetri };
  });

  return { sedute };
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

  let parametri: ParametriSettimana;
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

  let settimanaGrezza: unknown;
  try {
    settimanaGrezza = JSON.parse(testoJson);
  } catch {
    return jsonResponse(
      { error: "Il provider AI non ha restituito un JSON valido" },
      502,
    );
  }

  try {
    const settimana = validaSettimana(settimanaGrezza);
    return jsonResponse({ settimana });
  } catch (errore) {
    return jsonResponse(
      { error: `Settimana generata non valida: ${(errore as Error).message}` },
      502,
    );
  }
});
