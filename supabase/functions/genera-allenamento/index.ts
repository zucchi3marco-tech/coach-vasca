// Edge Function: genera-allenamento
//
// Riceve i parametri raccolti dal form "Genera con AI" (o, seduta per
// seduta, da "Genera settimana con AI") e li inoltra a Gemini, tenendo la
// API key lato server (mai esposta al client Flutter). Chiede output JSON
// strutturato (responseSchema) e lo rivalida qui prima di restituirlo,
// così l'app riceve sempre una scheda con campi noti o un errore
// esplicito, mai testo libero da interpretare.
// Se in futuro si cambia provider AI, si riscrive solo questo file: il
// contratto verso l'app (corpo della richiesta e { scheda } in risposta)
// resta invariato.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

const BLOCCHI = ["riscaldamento", "principale", "defaticamento", "altro"];
const STILI = ["libero", "dorso", "rana", "delfino", "misti"];
const ESECUZIONI = ["nuoto", "gambe", "braccia", "pull", "tecnica"];
// "C" (senza numero) è uno storico dell'enum del database, tenuto solo
// per le righe salvate prima dello split in C1/C2/C3 (FASE 9): non va
// più proposto per le serie nuove, in generazione come nel resto
// dell'app — vedi `ordineZone` in `lib/features/tabelle_passi`.
const ZONE = ["A1", "A2", "B1", "B2", "C1", "C2", "C3", "D"];

interface CorsiaGenerazione {
  nome: string;
  passo100S: number;
  differenzialeS?: number | null;
}

interface DettaglioFocus {
  metri?: number | null;
  attrezzatura?: string[];
  stile?: string | null;
}

interface ParametriGenerazione {
  gruppo?: string;
  volumeMetri?: number;
  volumeLavoroCentraleMetri?: number | null;
  // Uno o più fra 'completo' | 'braccia' | 'gambe' | 'tecnica' — quali
  // parti del corpo/nuotata enfatizzare (l'energia sta in regimiAmmessi,
  // sotto). Accetta anche una stringa singola (client vecchi, generatore
  // settimana).
  focus?: string | string[];
  dettaglioBraccia?: DettaglioFocus | null;
  dettaglioGambe?: DettaglioFocus | null;
  stileTecnica?: string | null;
  attrezzaturaLavoroCentrale?: string[];
  // Vincolo stretto: vedi stimaMinutiSessione() e il controllo dopo la
  // validazione, sotto.
  minutiMax?: number | null;
  // 25 o 50: solo contesto per il prompt (evitare distanze scomode).
  vascaM?: number | null;
  regimiAmmessi?: string[];
  vincoli?: string | null;
  corsie?: CorsiaGenerazione[];
}

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
  zona: string;
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

// Distillato della metodologia di periodizzazione del coach (documento
// fornito, FASE 10 punto 4): parametri per zona (durata, volume, distanze,
// recupero) e come usare il differenziale di gara T200-T100 per calcolare
// ripartenze realistiche invece di un numero indicativo generico.
//
// Tenere sincronizzato a mano con la mappa canonica
// `lib/features/ai_genera/domain/tipo_lavoro.dart` (nessun meccanismo di
// codice condiviso fra le Edge Function in questo repo).
const METODOLOGIA_ZONE = `
Metodologia per zona, da usare per calcolare le ripartenze (tempi di
partenza) quando sono forniti i passi di riferimento delle corsie:
- A1/A2 (aerobico, smaltimento/costruzione): distanze 100-400m (fino a 400
  per fondisti), recupero 5-30s (più lungo quanto più lunga la distanza).
  Passo più lento del passo di riferimento sui 100 (A1 il più lento, A2 un
  po' meno).
- B1 (soglia anaerobica): distanze 100-300m, recupero 10-30s. Passo vicino
  al passo di riferimento sui 100 (soglia).
- B2 (potenza aerobica/VO2max): distanze 200-400m (anche frazionate in
  50/100/200 con recuperi brevi 3-10s), recupero pieno 30s-2min fra le
  ripetute intere. Usa ESPLICITAMENTE il differenziale T200-T100 fornito:
  la ripartenza per una distanza intera vicina ai 200m è approssimabile a
  passo100S*(distanza/100) + differenzialeS; per distanze frazionate più
  corte usa un passo più vicino al passo100S puro (più veloce).
- C1 (tolleranza al lattato): distanze 50-100m, recupero 30s-2min passivi.
  Ripartenza vicina o leggermente sotto il passo100S (quasi massimale).
- C2 (picco di lattato): distanze 50-75m, recupero ampio 1'30-5' passivi.
  Ripartenza massimale.
- C3 (velocità/alattacido): distanze 10-50m, durata 8-10s per ripetuta,
  recupero elevato (fino a 2') per il recupero neuromuscolare. Non è una
  ripartenza basata sul passo100S: è velocità pura.
- D (ritmo gara): ripartenza il più vicina possibile al ritmo di gara reale
  alla distanza della serie, stimato da passo100S e differenzialeS.
Arrotonda ogni ripartenza a un valore realistico da usare a bordo vasca
(es. multiplo di 5 secondi).

Il riscaldamento è SEMPRE in zona A1, senza eccezioni.
`.trim();

function istruzioniFocus(p: ParametriGenerazione): string {
  const focus = (Array.isArray(p.focus) ? p.focus : [p.focus ?? "completo"])
    .filter((f): f is string => typeof f === "string");
  const attivi = focus.filter((f) => f !== "completo");
  if (attivi.length === 0) {
    return "Focus della seduta: completo, nessuna parte del corpo da enfatizzare in particolare.";
  }
  const righe: string[] = [
    `Focus della seduta (più aree insieme): ${attivi.join(", ")}. Ogni area ha il suo blocco di serie dedicato, indicato qui sotto.`,
  ];
  const attrezzi = (d?: DettaglioFocus | null) =>
    Array.isArray(d?.attrezzatura) ? d!.attrezzatura!.join(", ") : "";
  if (attivi.includes("braccia")) {
    const d = p.dettaglioBraccia;
    const a = attrezzi(d);
    righe.push(
      [
        `BRACCIA: dedica circa ${d?.metri ?? "una parte dei"} metri a serie di sole braccia.`,
        a
          ? `Usa esecuzione "pull" per queste serie, con attrezzatura fra: ${a}.`
          : 'Usa esecuzione "braccia" per queste serie (nessuna attrezzatura specifica indicata).',
        d?.stile ? `Stile per queste serie: ${d.stile}.` : "",
      ]
        .filter((r) => r.length > 0)
        .join(" "),
    );
  }
  if (attivi.includes("gambe")) {
    const d = p.dettaglioGambe;
    const a = attrezzi(d);
    righe.push(
      [
        `GAMBE: dedica circa ${d?.metri ?? "una parte dei"} metri a serie di sole gambe (esecuzione "gambe").`,
        a ? `Attrezzatura fra: ${a}.` : "",
        d?.stile ? `Stile per queste serie: ${d.stile}.` : "",
      ]
        .filter((r) => r.length > 0)
        .join(" "),
    );
  }
  if (attivi.includes("tecnica")) {
    righe.push(
      'TECNICA: una parte delle serie deve avere esecuzione "tecnica" (drills), volume contenuto per serie.' +
        (p.stileTecnica
          ? ` Lo stile principale della tecnica è ${p.stileTecnica}.`
          : ""),
    );
  }
  return righe.join("\n");
}

function costruisciPrompt(p: ParametriGenerazione): string {
  const regimi = Array.isArray(p.regimiAmmessi) ? p.regimiAmmessi.join(", ") : "";
  const corsie = Array.isArray(p.corsie) ? p.corsie : [];
  const righeCorsie = corsie.map((c) => {
    const diff = c.differenzialeS != null
      ? `, differenziale di gara T200-T100 = ${c.differenzialeS}s`
      : "";
    return `- Corsia "${c.nome}": passo di riferimento sui 100 stile libero = ${c.passo100S}s${diff}`;
  });
  const attrezziCentrale = Array.isArray(p.attrezzaturaLavoroCentrale)
    ? p.attrezzaturaLavoroCentrale
    : [];
  return [
    "Sei un allenatore di nuoto esperto. Genera una scheda di allenamento " +
      "per la seguente sessione, come elenco di serie.",
    `Gruppo: ${p.gruppo ?? ""}`,
    `Volume totale: ${p.volumeMetri ?? ""} metri`,
    p.volumeLavoroCentraleMetri != null
      ? `Volume del blocco "principale" (lavoro centrale): circa ${p.volumeLavoroCentraleMetri} metri, il resto (riscaldamento, defaticamento, eventuale tecnica) copre la differenza rispetto al volume totale.`
      : "",
    istruzioniFocus(p),
    attrezziCentrale.length > 0
      ? `Per le serie del blocco "principale", quando prevedi attrezzatura preferisci fra: ${attrezziCentrale.join(", ")}.`
      : "",
    `Regimi di allenamento ammessi: ${regimi}`,
    p.vincoli ? `Vincoli: ${p.vincoli}` : "",
    p.vascaM != null
      ? `Vasca da ${p.vascaM}m: evita distanze scomode rispetto a questa lunghezza (preferisci multipli o mezzi di ${p.vascaM}m dove sensato).`
      : "",
    "Dividi la scheda in riscaldamento, parte principale e defaticamento. " +
      "La somma di ripetute*distanza di tutte le serie deve avvicinarsi il " +
      "più possibile al volume totale richiesto. Usa solo zone tra quelle " +
      "ammesse indicate sopra. OGNI serie deve avere una zona assegnata " +
      "(mai vuota): il riscaldamento è sempre zona A1.",
    p.minutiMax != null
      ? `Vincolo di tempo: la scheda intera (nuoto + recuperi, sull'atleta ` +
          `più lento fra le corsie indicate sotto, o un ritmo prudente se ` +
          `non ce ne sono) non deve superare ${p.minutiMax} minuti. Se il ` +
          "volume richiesto non ci sta, riduci le ripetute mantenendo la " +
          "struttura della scheda, piuttosto che ignorare il limite."
      : "",
    righeCorsie.length > 0
      ? [
          "",
          "Passi di riferimento calcolati dai personal best degli atleti " +
            "del gruppo:",
          ...righeCorsie,
          "",
          METODOLOGIA_ZONE,
          "",
          "Per ogni serie della parte principale (e del defaticamento se " +
            "in zona A2 o superiore), calcola in ripartenzePerCorsia una " +
            "ripartenza per OGNUNA delle corsie elencate sopra, usando il " +
            "loro passo/differenziale secondo la metodologia della zona " +
            "assegnata a quella serie. Non è richiesta per il " +
            "riscaldamento a bassa intensità (A1) o per serie tecniche " +
            "senza zona.",
        ].join("\n")
      : "",
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
          ripartenzePerCorsia: {
            type: "ARRAY",
            items: {
              type: "OBJECT",
              properties: {
                nome: { type: "STRING" },
                ripartenzaS: { type: "NUMBER" },
              },
              required: ["nome", "ripartenzaS"],
            },
          },
        },
        required: [
          "ordine",
          "blocco",
          "ripetute",
          "distanzaM",
          "stile",
          "esecuzione",
          "zona",
        ],
      },
    },
  },
  required: ["titolo", "serie"],
};

// Stessa formula, tenuta manualmente sincronizzata, della funzione
// `stimaMinutiSessione` in `lib/features/ai_genera/application/
// tempo_stimato_service.dart` (lì è solo informativa; qui è il
// riferimento per il vincolo bloccante). Una serie senza ripartenze non
// ha un passo noto: la sua parte di nuoto non entra nella stima — che
// resta quindi un'approssimazione per difetto, mai un rifiuto per
// mancanza di dati.
function stimaMinutiSessione(serie: SerieGenerata[]): number {
  let secondiTotali = 0;
  for (const s of serie) {
    const ripartenze = s.ripartenzePerCorsia ?? [];
    if (ripartenze.length > 0) {
      const ripartenzaPiuLenta = Math.max(...ripartenze.map((r) => r.ripartenzaS));
      secondiTotali += s.ripetute * (s.distanzaM / 100) * ripartenzaPiuLenta;
    }
    secondiTotali += s.ripetute * (s.recuperoS ?? 0);
  }
  return secondiTotali / 60;
}

/// Rivalida la scheda restituita dal modello: anche con responseSchema
/// impostato, il provider può comunque restituire un JSON che non rispetta
/// lo schema (bug del modello, cambio di comportamento, ecc.), quindi non
/// ci fidiamo alla cieca.
function validaScheda(dati: unknown, parametri: ParametriGenerazione): SchedaGenerata {
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
    // La zona è sempre obbligatoria (era opzionale): serve alle statistiche
    // di carico, che ignorano le serie senza zona. Il riscaldamento è
    // forzato ad A1 sotto come rete di sicurezza, anche se il prompt lo
    // chiede già esplicitamente.
    if (typeof s.zona !== "string" || !ZONE.includes(s.zona)) {
      throw new Error(`serie #${indice + 1}: zona "${s.zona}" non riconosciuta`);
    }
    let zona = s.zona;
    if (s.blocco === "riscaldamento" && zona !== "A1") {
      zona = "A1";
    }
    let recuperoS: number | null = null;
    if (s.recuperoS !== undefined && s.recuperoS !== null) {
      const valore = Number(s.recuperoS);
      if (!Number.isInteger(valore) || valore < 0) {
        throw new Error(`serie #${indice + 1}: recupero non valido`);
      }
      recuperoS = valore;
    }

    let ripartenzePerCorsia: RipartenzaCorsia[] = [];
    if (s.ripartenzePerCorsia !== undefined && s.ripartenzePerCorsia !== null) {
      if (!Array.isArray(s.ripartenzePerCorsia)) {
        throw new Error(`serie #${indice + 1}: ripartenzePerCorsia non valido`);
      }
      ripartenzePerCorsia = s.ripartenzePerCorsia.map((voceRip, indiceRip) => {
        if (typeof voceRip !== "object" || voceRip === null) {
          throw new Error(
            `serie #${indice + 1}: ripartenza #${indiceRip + 1} non valida`,
          );
        }
        const r = voceRip as Record<string, unknown>;
        if (typeof r.nome !== "string" || r.nome.trim() === "") {
          throw new Error(
            `serie #${indice + 1}: nome corsia mancante nella ripartenza #${indiceRip + 1}`,
          );
        }
        const ripartenzaS = Number(r.ripartenzaS);
        if (!Number.isFinite(ripartenzaS) || ripartenzaS <= 0) {
          throw new Error(
            `serie #${indice + 1}: ripartenzaS non valida per la corsia "${r.nome}"`,
          );
        }
        return { nome: r.nome, ripartenzaS };
      });
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
      ripartenzePerCorsia,
    };
  });

  if (parametri.minutiMax != null) {
    const minutiStimati = stimaMinutiSessione(serieValidate);
    const limiteConTolleranza = parametri.minutiMax * 1.1;
    if (minutiStimati > limiteConTolleranza) {
      throw new Error(
        `la scheda generata richiede circa ${Math.round(minutiStimati)} minuti, ` +
          `oltre il limite di ${parametri.minutiMax} richiesto (stima sull'atleta ` +
          "più lento del gruppo): riprova, magari riducendo il volume",
      );
    }
  }

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

  let parametri: ParametriGenerazione;
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
    const scheda = validaScheda(schedaGrezza, parametri);
    return jsonResponse({ scheda });
  } catch (errore) {
    return jsonResponse(
      { error: `Scheda generata non valida: ${(errore as Error).message}` },
      502,
    );
  }
});
