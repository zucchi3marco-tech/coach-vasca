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
  focusPerSeduta?: string[];
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
    `- Seduta ${i + 1}, ${g}: focus "${focusPerSeduta[i] ?? ""}"`
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
      "\"Soglia B1 + tecnica\", \"Velocità C1/C2\", \"Ritmo gara D\"), e " +
      "il volume in metri di quella seduta — tieni conto della vicinanza " +
      "fra i giorni scelti (es. evita di mettere due sedute di alta " +
      "intensità in giorni consecutivi, quando possibile). La somma dei " +
      "volumi di tutte le sedute deve avvicinarsi il più possibile al " +
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
          codice: { type: "STRING" },
          volumeMetri: { type: "INTEGER" },
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
function messaggioErroreProvider(status: number, corpoGrezzo: string): string {
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
      { error: messaggioErroreProvider(rispostaGemini.status, dettaglio) },
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
    const settimana = validaSettimana(
      settimanaGrezza,
      Array.isArray(parametri.giorniSettimana)
        ? parametri.giorniSettimana.length
        : undefined,
    );
    return jsonResponse({ settimana });
  } catch (errore) {
    return jsonResponse(
      { error: `Settimana generata non valida: ${(errore as Error).message}` },
      502,
    );
  }
});
