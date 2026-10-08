// Edge Function: genera-allenamento
//
// Riceve i parametri raccolti dal form "Genera con AI" (o, seduta per
// seduta, da "Genera settimana con AI") e li inoltra al provider AI,
// tenendo la API key lato server (mai esposta al client Flutter). Chiede
// output JSON strutturato e lo rivalida qui prima di restituirlo, così
// l'app riceve sempre una scheda con campi noti o un errore esplicito,
// mai testo libero da interpretare.
// Se in futuro si cambia provider AI, si riscrive solo questo file: il
// contratto verso l'app (corpo della richiesta e { scheda } in risposta)
// resta invariato.
//
// RIPROGETTAZIONE AI: provider passato da Gemini a OpenAI come già
// `detta-allenamento` (Gemini restava spesso "sovraccarico" anche dopo i
// ritentativi). `chiamaGemini` resta nel file, spenta dietro
// PROVIDER_ATTIVO, per tornare indietro in un attimo. Infrastruttura
// ai_usage/tetto settimanale copiata a mano da `detta-allenamento`
// (nessuna cartella `_shared/` in questo repo): tenerle allineate.

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

const NOME_FUNZIONE = "genera-allenamento";

// Scarto ammesso fra i metri della scheda e il volume richiesto (stesso
// margine dei controlli sulla settimana, `controlli_settimana_service.dart`):
// vedi adattaScheda.
const TOLLERANZA_VOLUME = 0.1;

const BLOCCHI = ["riscaldamento", "principale", "defaticamento", "altro"];
const STILI = ["libero", "dorso", "rana", "delfino", "misti"];
const ESECUZIONI = [
  "nuoto",
  "gambe",
  "braccia",
  "pull",
  "tecnica",
  "remate",
  "pallanuoto tecnico-tattico",
  "palleggio",
  "tiri",
  "uomo in più",
  "uomo in meno",
  "gioco da schierati",
  "schemi",
  "partita",
  "test",
  "a secco",
];
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

interface ParteBlocco {
  ordine: number;
  giri: number;
  ripetizioni: number;
  distanzaM?: number | null;
  durataS?: number | null;
  stile?: string | null;
  zona: string;
  esecuzione: string;
  recuperoS?: number | null;
}

interface BloccoDisponibile {
  id: string;
  codice: string;
  titolo: string;
  fase: string;
  metriTotali: number;
  parti: ParteBlocco[];
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
  // Vincolo stretto: vedi stimaMinutiSessione() e adattaScheda(), sotto.
  minutiMax?: number | null;
  // 25 o 50: solo contesto per il prompt (evitare distanze scomode).
  vascaM?: number | null;
  regimiAmmessi?: string[];
  vincoli?: string | null;
  corsie?: CorsiaGenerazione[];
  // RIPROGETTAZIONE AI, FASE 3: fino a ~40 blocchi approvati compatibili
  // scelti dal codice (non dall'AI) — vuoto se il club non ha ancora una
  // libreria, nel qual caso la generazione resta quella "libera" di
  // prima (nessun cambiamento di comportamento).
  blocchiDisponibili?: BloccoDisponibile[];
}

interface RipartenzaCorsia {
  nome: string;
  ripartenzaS: number;
}

interface SerieGenerata {
  ordine: number;
  blocco: string;
  ripetute: number;
  // Una serie è a distanza (distanzaM) o a tempo (durataS, secondi per
  // ripetuta), mai entrambe: come `Serie.aTempo` nell'app.
  distanzaM: number | null;
  durataS: number | null;
  stile: string;
  esecuzione: string;
  zona: string;
  recuperoS?: number | null;
  attrezzatura?: string | null;
  note?: string | null;
  ripartenzePerCorsia?: RipartenzaCorsia[];
  // RIPROGETTAZIONE AI, FASE 3.
  bloccoLibreriaId?: string | null;
  nuovo?: boolean;
}

interface SchedaGenerata {
  titolo: string;
  note?: string | null;
  serie: SerieGenerata[];
  // La stima usata per il vincolo dei minuti massimi: l'app mostra
  // questa, così il coach vede lo stesso numero che è stato controllato.
  minutiStimati?: number;
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

// Le esecuzioni di pallanuoto aggiunte il 2026-10-08 (migrazione
// 20261008000200_esecuzioni_pallanuoto.sql): il lavoro tattico si fa a
// tempo, con le serie a tempo (durataS) della scheda.
const ISTRUZIONI_PALLANUOTO = [
  "Esecuzioni di pallanuoto, da usare SOLO per un gruppo di pallanuoto " +
    "(lo dicono il nome del gruppo, i vincoli o i blocchi della libreria), " +
    "mai per un gruppo di nuoto: \"palleggio\" (nuoto con la palla, testa " +
    "alta), \"tiri\" (partenza veloce e tiro in porta), \"uomo in più\" e " +
    "\"uomo in meno\" (superiorità e inferiorità numerica), \"gioco da " +
    "schierati\" (attacco e difesa a uomini schierati), \"schemi\" (schemi " +
    "di gioco), \"partita\" (partita o partitella), \"pallanuoto " +
    "tecnico-tattico\" (altro lavoro tattico). Con " +
    "queste esecuzioni lo stile è sempre \"libero\".",
  "\"palleggio\" e \"tiri\" vanno bene a metri (es. 8x25 palleggio, " +
    "6x25 tiri). \"uomo in più\", \"uomo in meno\", \"gioco da " +
    "schierati\", \"schemi\", \"partita\" e \"pallanuoto tecnico-tattico\" " +
    "sono lavoro a tempo: serie con durataS (es. 3 ripetute da 300 secondi " +
    "di uomo in più, con recupero), che non contano nel volume in metri.",
  "L'esecuzione \"test\" (un test cronometrico, per qualsiasi gruppo) " +
    "usala solo se i vincoli del coach chiedono un test.",
].join("\n");

// La libreria salva lo stile come nell'Excel originale ("Stile libero",
// "Delfino", ma anche "A scelta"/"Testa alta", non uno degli STILI
// ammessi per la serie generata): normalizzato qui, non lasciato
// all'AI, per mostrarglielo già nel formato che deve riusare.
function normalizzaStile(stile: string | null | undefined): string | null {
  if (!stile) return null;
  const s = stile.trim().toLowerCase();
  if (s.includes("libero")) return "libero";
  if (s.includes("dorso")) return "dorso";
  if (s.includes("rana")) return "rana";
  if (s.includes("delfino")) return "delfino";
  if (s.includes("misti")) return "misti";
  return null; // "a scelta", "testa alta": nessun suggerimento, scelga l'AI.
}

// RIPROGETTAZIONE AI, FASE 3: descrive un blocco e le sue parti nel
// prompt, con lo stesso formato che l'AI deve usare per riferirsi a loro
// (vedi istruzioniLibreria sotto).
function descriviParte(parte: ParteBlocco): string {
  const volume = parte.durataS != null
    ? `${parte.durataS}s`
    : `${parte.distanzaM}m`;
  const giri = parte.giri > 1 ? `${parte.giri}x ` : "";
  const stile = normalizzaStile(parte.stile);
  return `${giri}${parte.ripetizioni}x${volume}` +
    (stile ? ` ${stile}` : "") +
    ` zona ${parte.zona} ${parte.esecuzione}` +
    (parte.recuperoS != null ? ` rec ${parte.recuperoS}s` : "");
}

function istruzioniLibreria(blocchi: BloccoDisponibile[]): string {
  if (blocchi.length === 0) return "";
  const elenco = blocchi.map((b) => {
    const parti = b.parti.map(descriviParte).join("; ");
    return `- ID "${b.id}" (${b.codice}) "${b.titolo}" [fase: ${b.fase}, ~${b.metriTotali}m]: ${parti}`;
  });
  return [
    "Hai a disposizione una libreria di blocchi di allenamento già " +
      "approvati da questo coach, elencati sotto con il loro ID. Costruisci " +
      "la seduta con questi blocchi invece di inventare da zero: per ogni " +
      "parte (riscaldamento, principale, defaticamento) SCEGLI UNO O PIÙ " +
      "blocchi adatti a focus/regimi richiesti e mettili in sequenza " +
      "(anche lo stesso blocco più volte, se serve). Di ogni blocco puoi " +
      "adattare ripetute e distanza (o durata) fino al 25% in più o in " +
      "meno rispetto all'originale, indicando il suo ID in " +
      "bloccoLibreriaId per OGNI serie che ne deriva. Se un blocco ha più " +
      "parti, usa tutte le sue parti in sequenza (stessa zona/esecuzione/ " +
      "stile di ciascuna), tutte con lo stesso bloccoLibreriaId.",
    "Il volume richiesto viene PRIMA della fedeltà ai blocchi: un blocco " +
      "da solo raramente basta a coprire una parte della seduta. Se i " +
      "blocchi scelti, anche adattati, non arrivano ai metri richiesti, " +
      "aggiungine altri finché li raggiungi.",
    "Inventa una serie nuova SOLO se davvero nessun blocco disponibile è " +
      "adatto: in quel caso lascia bloccoLibreriaId vuoto e segna " +
      "nuovo=true. Per ogni altra serie, nuovo deve essere false.",
    "Alcuni blocchi sono \"a tempo\" (una durata in secondi, es. \"600s\", " +
      "invece di una distanza in metri): le loro serie sono a tempo, con " +
      "durataS (i secondi di una ripetuta) al posto di distanzaM.",
    "Le zone delle parti qui sotto usano anche sigle che NON sono fra " +
      "quelle ammesse per la zona della serie generata: \"V\" = C3, " +
      "\"RG\" = D; \"T\"/\"TT\"/\"TEST\" non sono zone di intensità " +
      "(tecnica, tattica, test) — per queste assegna comunque alla serie " +
      "generata la zona ammessa più vicina all'intensità reale (spesso " +
      "A1/A2 se leggero, C3/D se intenso).",
    "",
    "Blocchi disponibili:",
    ...elenco,
  ].join("\n");
}

// Metri indicativi per parte: con il solo totale il modello tendeva a
// prendere un blocco per parte e a fermarsi molto sotto il volume
// richiesto (osservato nelle prove con OpenAI).
function ripartizioneVolume(p: ParametriGenerazione): string {
  const totale = p.volumeMetri;
  if (!totale) return "";
  const arrotonda50 = (n: number) => Math.round(n / 50) * 50;
  const principale = Math.min(
    totale,
    p.volumeLavoroCentraleMetri ?? arrotonda50(totale * 0.6),
  );
  const resto = totale - principale;
  const riscaldamento = arrotonda50(resto * 0.65);
  const defaticamento = resto - riscaldamento;
  return `Ripartizione indicativa dei metri: riscaldamento circa ` +
    `${riscaldamento}, principale circa ${principale}, defaticamento circa ` +
    `${defaticamento} (le eventuali serie di tecnica, gambe o braccia ` +
    "rientrano nella parte in cui le metti).";
}

function costruisciPrompt(p: ParametriGenerazione): string {
  const regimi = Array.isArray(p.regimiAmmessi) ? p.regimiAmmessi.join(", ") : "";
  const corsie = Array.isArray(p.corsie) ? p.corsie : [];
  const blocchiDisponibili = Array.isArray(p.blocchiDisponibili)
    ? p.blocchiDisponibili
    : [];
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
    ripartizioneVolume(p),
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
      "Ogni serie è a distanza (distanzaM in metri, durataS vuoto) oppure a " +
      "tempo (durataS in secondi per ripetuta, es. 4 ripetute da 300 = " +
      "4x5', distanzaM vuoto): mai tutte e due. Le serie a tempo non " +
      "contano nel volume in metri. " +
      "La somma di ripetute*distanza delle serie a distanza deve " +
      "avvicinarsi il più possibile al volume totale richiesto" +
      (p.volumeMetri
        ? ` (fra ${Math.round(p.volumeMetri * (1 - TOLLERANZA_VOLUME))} e ` +
          `${Math.round(p.volumeMetri * (1 + TOLLERANZA_VOLUME))} metri)`
        : "") +
      ". Usa solo zone tra quelle " +
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
    ISTRUZIONI_PALLANUOTO,
    istruzioniLibreria(blocchiDisponibili),
    "Nel campo note di una serie scrivi solo indicazioni brevi su COME " +
      "eseguirla (es. \"respirazione ogni 3\", \"progressivi\"), oppure " +
      "lascialo vuoto: MAI distanze, ripetute, stili o il titolo di un " +
      "blocco, che stanno già negli altri campi.",
  ]
    .filter((riga) => riga.length > 0)
    .join("\n");
}

// Funzione (non una costante) perché bloccoLibreriaId deve elencare, in
// un enum, solo gli ID davvero disponibili in QUESTA richiesta — un
// vincolo esplicito che Gemini rispetta molto più fedelmente di un
// semplice campo STRING libero (osservato nei test): elenca gli ID
// scelti lasciando all'AI, come più oneroso, lasciarlo vuoto per
// "nuovo".
function costruisciSchemaGemini(blocchiDisponibili: BloccoDisponibile[]) {
  const idDisponibili = blocchiDisponibili.map((b) => b.id);
  return {
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
            durataS: { type: "INTEGER" },
            stile: { type: "STRING", enum: STILI },
            esecuzione: { type: "STRING", enum: ESECUZIONI },
            zona: { type: "STRING", enum: ZONE },
            recuperoS: { type: "INTEGER" },
            attrezzatura: { type: "STRING" },
            note: { type: "STRING" },
            ...(idDisponibili.length > 0
              ? { bloccoLibreriaId: { type: "STRING", enum: idDisponibili } }
              : {}),
            nuovo: { type: "BOOLEAN" },
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
            "stile",
            "esecuzione",
            "zona",
          ],
        },
      },
    },
    required: ["titolo", "serie"],
  };
}

// Stesso contenuto per gli "structured outputs" di OpenAI
// (response_format json_schema, strict: true): in modalità strict OGNI
// proprietà deve stare in `required` e ogni oggetto deve dichiarare
// additionalProperties: false — i campi facoltativi diventano nullable
// (`type: [tipo, "null"]`) invece di assenti.
function costruisciSchemaOpenAi(blocchiDisponibili: BloccoDisponibile[]) {
  const idDisponibili = blocchiDisponibili.map((b) => b.id);
  const proprietaSerie: Record<string, unknown> = {
    ordine: { type: "integer" },
    blocco: { type: "string", enum: BLOCCHI },
    ripetute: { type: "integer" },
    distanzaM: { type: ["integer", "null"] },
    durataS: { type: ["integer", "null"] },
    stile: { type: "string", enum: STILI },
    esecuzione: { type: "string", enum: ESECUZIONI },
    zona: { type: "string", enum: ZONE },
    recuperoS: { type: ["integer", "null"] },
    attrezzatura: { type: ["string", "null"] },
    note: { type: ["string", "null"] },
    ...(idDisponibili.length > 0
      ? {
        bloccoLibreriaId: {
          type: ["string", "null"],
          enum: [...idDisponibili, null],
        },
      }
      : {}),
    nuovo: { type: "boolean" },
    ripartenzePerCorsia: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          nome: { type: "string" },
          ripartenzaS: { type: "number" },
        },
        required: ["nome", "ripartenzaS"],
      },
    },
  };
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      titolo: { type: "string" },
      note: { type: ["string", "null"] },
      serie: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          properties: proprietaSerie,
          required: Object.keys(proprietaSerie),
        },
      },
    },
    required: ["titolo", "note", "serie"],
  };
}

// Tempo della seduta calcolato dal codice, non dalle ripartenze dell'AI
// (inaffidabili: nelle prove scriveva il passo sui 100 al posto della
// ripartenza, o 0, e spesso non le dava per riscaldamento e
// defaticamento, che restavano a tempo zero). Per ogni serie:
// ripetute × (nuoto + recupero), con il passo della corsia più lenta — è
// l'atleta che finisce per ultimo — nella zona della serie, secondo lo
// stesso modello delle ripartenze dell'app (`passoBasePerZona` in
// `lib/features/ripartenze/domain/calcolo_ripartenze.dart`: tenere
// allineato). Senza corsie, il passo medio della libreria di blocchi.
const PASSO_MEDIO_LIBRERIA_S = 110; // s/100m, foglio Legenda dell'Excel
const OFFSET_SOGLIA_B1_S = 3.5;

// Gambe e tecnica sono più lente del nuoto completo: stima di partenza,
// non una formula del coach — da calibrare con l'uso reale.
const FATTORE_ESECUZIONE: Record<string, number> = {
  gambe: 1.3,
  tecnica: 1.15,
  braccia: 1.05,
  pull: 1.05,
};

// Recupero fra le ripetute quando l'AI non lo indica: stessi valori di
// `_recuperoFissoDefaultPerZona` e `distanzeFrazionamento` in
// calcolo_ripartenze.dart (B1 e D usano la tabella per distanza).
const RECUPERO_PER_ZONA: Record<string, number> = {
  A1: 20,
  A2: 15,
  B2: 60,
  C1: 60,
  C2: 180,
  C3: 60,
};
const RECUPERO_PER_DISTANZA: [number, number][] = [
  [50, 12],
  [100, 15],
  [150, 18],
  [200, 20],
  [300, 25],
  [400, 30],
  [500, 30],
];

function recuperoPredefinito(zona: string, distanzaM: number): number {
  const perZona = RECUPERO_PER_ZONA[zona];
  if (perZona != null) return perZona;
  return RECUPERO_PER_DISTANZA.reduce((a, b) =>
    Math.abs(b[0] - distanzaM) < Math.abs(a[0] - distanzaM) ? b : a
  )[1];
}

/// Passo di nuoto (s/100m) nella zona indicata.
function passoPerZona(zona: string, corsia: CorsiaGenerazione | null): number {
  if (corsia == null) return PASSO_MEDIO_LIBRERIA_S;
  const passo100 = corsia.passo100S;
  // T200-T100: senza il primato sui 200 (o con un valore incoerente,
  // più veloce del passo sui 100) si stima dal 100.
  const differenziale = corsia.differenzialeS != null &&
      corsia.differenzialeS >= passo100
    ? corsia.differenzialeS
    : passo100 * 1.15;
  switch (zona) {
    case "A1":
      return differenziale + OFFSET_SOGLIA_B1_S + 12;
    case "A2":
      return differenziale + OFFSET_SOGLIA_B1_S + 5;
    case "B1":
      return differenziale + OFFSET_SOGLIA_B1_S;
    case "B2":
      return differenziale;
    case "C1":
    case "D":
      return passo100 + 1.5;
    default: // C2, C3: vicino al massimale
      return passo100;
  }
}

function stimaMinutiSessione(
  serie: SerieGenerata[],
  corsie: CorsiaGenerazione[],
): number {
  const piuLenta = corsie.length > 0
    ? corsie.reduce((a, b) => (b.passo100S > a.passo100S ? b : a))
    : null;
  let secondi = 0;
  for (const s of serie) {
    // A tempo: la durata più il recupero scritto, come
    // `secondiPerRipetuta` in lib/features/allenamenti/domain/durata_serie.dart.
    if (s.distanzaM == null) {
      secondi += s.ripetute * ((s.durataS ?? 0) + (s.recuperoS ?? 0));
      continue;
    }
    const passo = passoPerZona(s.zona, piuLenta) *
      (FATTORE_ESECUZIONE[s.esecuzione] ?? 1);
    const recupero = s.recuperoS ?? recuperoPredefinito(s.zona, s.distanzaM);
    secondi += s.ripetute * (passo * s.distanzaM / 100 + recupero);
  }
  return secondi / 60;
}

/// Le serie a tempo non hanno metri: nel volume contano zero, come
/// `distanzaTotaleM` nell'app.
function metriSerie(serie: SerieGenerata[]): number {
  return serie.reduce((somma, s) => somma + s.ripetute * (s.distanzaM ?? 0), 0);
}

function metriScheda(scheda: SchedaGenerata): number {
  return metriSerie(scheda.serie);
}

function scartoVolume(scheda: SchedaGenerata, volumeRichiesto: number): number {
  return Math.abs(metriScheda(scheda) - volumeRichiesto) / volumeRichiesto;
}

/// Porta le serie scelte da `scala` a circa `obiettivo` metri senza
/// cambiare la struttura della scheda, tutte nella stessa proporzione:
/// una serie con più ripetute cambia il numero di ripetute, una serie
/// singola (un "400 sciolti", i gradini di una piramide) la distanza, a
/// passi di 50m. Il resto lasciato dagli arrotondamenti lo assorbe la
/// serie a ripetute la cui distanza ci sta meglio. Le serie a tempo non
/// si toccano: non hanno metri.
function scalaSerie(
  serie: SerieGenerata[],
  scala: (s: SerieGenerata) => boolean,
  obiettivo: number,
): SerieGenerata[] {
  const metri = (elenco: SerieGenerata[]) => metriSerie(elenco.filter(scala));
  const attuali = metri(serie);
  if (attuali === 0 || obiettivo <= 0) return serie;
  const fattore = obiettivo / attuali;
  const scalate = serie.map((s) => {
    if (!scala(s) || s.distanzaM == null) return s;
    if (s.ripetute > 1) {
      return { ...s, ripetute: Math.max(1, Math.round(s.ripetute * fattore)) };
    }
    if (s.distanzaM < 50) return s;
    const distanza = s.distanzaM * fattore;
    const passo = distanza >= 400 ? 100 : 50;
    return {
      ...s,
      distanzaM: Math.max(50, Math.round(distanza / passo) * passo),
    };
  });

  const resto = obiettivo - metri(scalate);
  let migliore = -1;
  let ripetuteInPiu = 0;
  let restoMinimo = Math.abs(resto);
  scalate.forEach((s, indice) => {
    if (!scala(s) || s.distanzaM == null || s.ripetute < 2) return;
    const k = Math.round(resto / s.distanzaM);
    if (k === 0 || s.ripetute + k < 1) return;
    const residuo = Math.abs(resto - k * s.distanzaM);
    if (residuo < restoMinimo) {
      migliore = indice;
      ripetuteInPiu = k;
      restoMinimo = residuo;
    }
  });
  if (migliore >= 0) {
    scalate[migliore] = {
      ...scalate[migliore],
      ripetute: scalate[migliore].ripetute + ripetuteInPiu,
    };
  }
  return scalate;
}

/// Volume e tempo li garantisce il codice, non l'AI: nelle prove sia
/// gpt-4o-mini sia gpt-4.1-mini sbagliavano le somme dei metri del 10-30%
/// (in meno il primo, in più il secondo) anche con un secondo tentativo
/// guidato, e il tempo non lo sapevano stimare.
/// 1. Metri: il lavoro centrale va al volume indicato dal coach, se c'è,
///    e il resto della seduta copre la differenza (rispetto ai metri
///    centrali reali, dopo gli arrotondamenti); altrimenti si scala tutto
///    insieme.
/// 2. Tempo: se la scheda non sta nei minuti massimi (stima sull'atleta
///    più lento, vedi stimaMinutiSessione) la si accorcia tutta in
///    proporzione — il tempo in vasca è un limite fisso, il volume no.
function adattaScheda(
  scheda: SchedaGenerata,
  parametri: ParametriGenerazione,
): SchedaGenerata {
  let serie = scheda.serie;

  const totale = parametri.volumeMetri;
  const centrale = parametri.volumeLavoroCentraleMetri;
  const principale = (s: SerieGenerata) => s.blocco === "principale";
  const metriCentraliAi = metriSerie(serie.filter(principale));
  const centraleFuori = centrale != null && centrale > 0 &&
    Math.abs(metriCentraliAi - centrale) / centrale > TOLLERANZA_VOLUME;
  if (totale && (scartoVolume(scheda, totale) > TOLLERANZA_VOLUME / 2 || centraleFuori)) {
    const haAltro = serie.some((s) => !principale(s));
    if (centrale != null && centrale > 0 && centrale < totale && haAltro) {
      serie = scalaSerie(serie, principale, centrale);
      const metriCentrali = metriSerie(serie.filter(principale));
      serie = scalaSerie(serie, (s) => !principale(s), totale - metriCentrali);
    } else {
      serie = scalaSerie(serie, () => true, totale);
    }
  }

  const minutiMax = parametri.minutiMax;
  if (minutiMax != null && minutiMax > 0) {
    const corsie = Array.isArray(parametri.corsie) ? parametri.corsie : [];
    // Più giri perché gli arrotondamenti (ripetute intere, passi di 50m)
    // possono lasciare la scheda appena sopra il limite.
    for (let giro = 0; giro < 4; giro++) {
      const minuti = stimaMinutiSessione(serie, corsie);
      if (minuti <= minutiMax) break;
      // Le serie a tempo durano quello che durano: si accorcia solo il
      // nuoto, nel tempo che resta.
      const minutiATempo = stimaMinutiSessione(
        serie.filter((s) => s.distanzaM == null),
        corsie,
      );
      const minutiNuoto = minuti - minutiATempo;
      if (minutiNuoto <= 0 || minutiMax <= minutiATempo) break;
      const obiettivo = Math.floor(
        metriSerie(serie) * ((minutiMax - minutiATempo) / minutiNuoto) * 0.97,
      );
      serie = scalaSerie(serie, () => true, obiettivo);
    }
  }
  return { ...scheda, serie };
}

/// Le misure stanno già in ripetute/distanza: una nota che le ripete
/// (spesso il titolo del blocco di libreria, "200 sciolto") smentirebbe la
/// serie non appena adattaScheda ne cambia i metri.
function pulisciNota(nota: string): string | null {
  const pulita = nota.replace(/^\s*(\d+\s*[x×]\s*)?\d+(m\b)?\s*/i, "").trim();
  return pulita.length > 0 ? pulita : null;
}

/// `null` se l'AI non ha indicato un bloccoLibreriaId o se l'ID non
/// corrisponde a nessun blocco disponibile. I blocchi a tempo vanno bene
/// anche loro, ora che la scheda ha le serie a tempo.
function _bloccoLibreriaIdValido(
  s: Record<string, unknown>,
  blocchiPerId: Map<string, BloccoDisponibile>,
): string | null {
  if (typeof s.bloccoLibreriaId !== "string") return null;
  return blocchiPerId.has(s.bloccoLibreriaId) ? s.bloccoLibreriaId : null;
}

// Le zone dei blocchi usano anche sigle dell'Excel che non sono nella
// zona_intensita della serie generata — solo quelle usate davvero nella
// libreria oggi (V, RG), le altre (T/TT/TEST) non sono mai distanza/
// ripetizioni comparabili a una serie di nuoto, quindi non servono qui.
const _ZONA_BLOCCO_VERSO_SERIE: Record<string, string> = { V: "C3", RG: "D" };

function _zonaEquivalente(zonaBlocco: string, zonaSerie: string): boolean {
  return zonaBlocco === zonaSerie || _ZONA_BLOCCO_VERSO_SERIE[zonaBlocco] === zonaSerie;
}

/// L'AI, nei test, usa spesso il contenuto esatto di un blocco (stesse
/// ripetute/distanza/zona) senza però compilare bloccoLibreriaId come
/// chiesto nel prompt: questo controllo di contenuto (stessa zona,
/// stesso stile se il blocco ne specifica uno, volume entro il 25%)
/// recupera il collegamento anche quando l'etichetta manca — più
/// affidabile di fidarsi solo di quello che l'AI dichiara.
function _bloccoPerContenuto(
  ripetute: number,
  distanzaM: number | null,
  durataS: number | null,
  stile: string,
  esecuzione: string,
  zona: string,
  blocchi: BloccoDisponibile[],
): string | null {
  for (const blocco of blocchi) {
    for (const parte of blocco.parti) {
      // A tempo: stessa esecuzione e durata entro il 25% (le zone delle
      // parti a tempo sono spesso T/TT, non zone di intensità).
      if (durataS != null) {
        if (parte.durataS == null || parte.esecuzione !== esecuzione) continue;
        const tempoParte = parte.giri * parte.ripetizioni * parte.durataS;
        if (tempoParte <= 0) continue;
        const scartoTempo = Math.abs(ripetute * durataS - tempoParte) / tempoParte;
        if (scartoTempo <= 0.25) return blocco.id;
        continue;
      }
      if (parte.distanzaM == null || distanzaM == null) continue;
      if (!_zonaEquivalente(parte.zona, zona)) continue;
      const stileParte = normalizzaStile(parte.stile);
      if (stileParte != null && stileParte !== stile) continue;
      const volumeParte = parte.giri * parte.ripetizioni * parte.distanzaM;
      const volumeSerie = ripetute * distanzaM;
      if (volumeParte <= 0) continue;
      const scarto = Math.abs(volumeSerie - volumeParte) / volumeParte;
      if (scarto <= 0.25) return blocco.id;
    }
  }
  return null;
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

  const blocchiPerId = new Map(
    (Array.isArray(parametri.blocchiDisponibili) ? parametri.blocchiDisponibili : [])
      .map((b) => [b.id, b] as const),
  );

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
    // A distanza o a tempo: con una distanza valida vale quella (OpenAI
    // compila sempre tutti e due i campi, spesso con 0 o null).
    const distanza = Number(s.distanzaM);
    const durata = Number(s.durataS);
    let distanzaM: number | null = null;
    let durataS: number | null = null;
    if (s.distanzaM != null && Number.isInteger(distanza) && distanza >= 25) {
      distanzaM = distanza;
    } else if (s.durataS != null && Number.isInteger(durata) && durata >= 10) {
      durataS = durata;
    } else {
      throw new Error(`serie #${indice + 1}: distanza o durata non valida`);
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
    // Il bloccoLibreriaId dichiarato dall'AI, se valido, altrimenti un
    // confronto per contenuto con la libreria (vedi _bloccoPerContenuto):
    // nei test l'AI sceglie spesso il contenuto giusto senza compilare
    // l'etichetta come chiesto, quindi non ci si fida solo di quella.
    const bloccoLibreriaId = _bloccoLibreriaIdValido(s, blocchiPerId) ??
      _bloccoPerContenuto(
        ripetute,
        distanzaM,
        durataS,
        s.stile as string,
        s.esecuzione,
        zona,
        [...blocchiPerId.values()],
      );
    let recuperoS: number | null = null;
    if (s.recuperoS !== undefined && s.recuperoS !== null) {
      const valore = Number(s.recuperoS);
      if (!Number.isInteger(valore) || valore < 0) {
        throw new Error(`serie #${indice + 1}: recupero non valido`);
      }
      recuperoS = valore;
    }

    // Le ripartenze dell'AI sono solo un ripiego (l'app le ricalcola dal
    // codice quando conosce i passi): una voce senza senso si scarta
    // invece di buttare l'intera scheda. Con gli structured outputs di
    // OpenAI il campo è sempre presente, e per le serie dove non serve
    // (riscaldamento A1, tecnica) il modello mette spesso 0.
    let ripartenzePerCorsia: RipartenzaCorsia[] = [];
    if (Array.isArray(s.ripartenzePerCorsia)) {
      ripartenzePerCorsia = s.ripartenzePerCorsia.flatMap((voceRip) => {
        if (typeof voceRip !== "object" || voceRip === null) return [];
        const r = voceRip as Record<string, unknown>;
        const ripartenzaS = Number(r.ripartenzaS);
        if (typeof r.nome !== "string" || r.nome.trim() === "") return [];
        if (!Number.isFinite(ripartenzaS) || ripartenzaS <= 0) return [];
        return [{ nome: r.nome, ripartenzaS }];
      });
    }

    return {
      ordine,
      blocco: s.blocco,
      ripetute,
      distanzaM,
      durataS,
      stile: s.stile,
      esecuzione: s.esecuzione,
      zona,
      recuperoS,
      attrezzatura: typeof s.attrezzatura === "string" ? s.attrezzatura : null,
      note: typeof s.note === "string" ? pulisciNota(s.note) : null,
      // Una serie a tempo non ha ripartenze.
      ripartenzePerCorsia: durataS != null ? [] : ripartenzePerCorsia,
      // RIPROGETTAZIONE AI, FASE 3: "nuovo" è semplicemente "non
      // riconducibile a nessun blocco della libreria", per etichetta o
      // per contenuto — mai un errore, solo un'informazione per l'app
      // (che la archivia come bozza al salvataggio). Se il club non ha
      // ancora nessun blocco approvato, "nuovo" non ha senso: resta
      // sempre false, non si archivia nulla.
      bloccoLibreriaId,
      nuovo: blocchiPerId.size > 0 && bloccoLibreriaId == null,
    };
  });

  // Nelle prove OpenAI ha restituito una volta una seduta fatta solo di
  // riscaldamento: non è una scheda da adattare, va richiesta.
  if (!serieValidate.some((s) => s.blocco === "principale")) {
    throw new Error("manca la parte principale");
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

  let parametri: ParametriGenerazione;
  try {
    parametri = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo della richiesta non valido" }, 400);
  }

  const userId = idUtenteDaRichiesta(req);
  const rifiuto = await tettoSuperato(userId);
  if (rifiuto) return rifiuto;

  const prompt = costruisciPrompt(parametri);

  const inizio = Date.now();
  let esito = await generaScheda(prompt, parametri);
  // Una risposta arrivata ma inutilizzabile (JSON rotto, seduta
  // incompleta) si richiede una volta, se c'è
  // ancora tempo; un errore del servizio no, ha già i suoi ritentativi.
  if (!esito.ok && esito.daRichiedere && Date.now() - inizio < 25_000) {
    esito = await generaScheda(prompt, parametri);
  }
  if (!esito.ok) return jsonResponse({ error: esito.errore }, 502);

  let scheda = adattaScheda(esito.scheda, parametri);
  const corsie = Array.isArray(parametri.corsie) ? parametri.corsie : [];
  const minuti = Math.round(stimaMinutiSessione(scheda.serie, corsie));

  // Quando metri e tempo non si possono rispettare insieme la scheda
  // arriva comunque, con un avviso: mai un errore per una scheda
  // utilizzabile.
  const volume = parametri.volumeMetri;
  const minutiMax = parametri.minutiMax;
  let avviso: string | null = null;
  if (minutiMax != null && minuti > minutiMax) {
    avviso = `Attenzione: servono circa ${minuti} minuti, più dei ` +
      `${minutiMax} indicati.`;
  } else if (volume && scartoVolume(scheda, volume) > TOLLERANZA_VOLUME) {
    avviso = minutiMax != null && metriScheda(scheda) < volume
      ? `Per stare in ${minutiMax} minuti la scheda fa ` +
        `${metriScheda(scheda)} m invece dei ${volume} richiesti.`
      : `Attenzione: questa scheda fa ${metriScheda(scheda)} m invece dei ` +
        `${volume} richiesti.`;
  }
  scheda = {
    ...scheda,
    note: avviso ? (scheda.note ? `${avviso} ${scheda.note}` : avviso) : scheda.note,
    minutiStimati: minuti,
  };

  if (userId) {
    await registraUsoAi({
      userId,
      modello: PROVIDER_ATTIVO === "openai" ? TEXT_MODEL : GEMINI_MODEL,
      gettoni: esito.gettoni,
    });
  }
  return jsonResponse({ scheda });
});

type EsitoGenerazione =
  | { ok: true; scheda: SchedaGenerata; gettoni: number | null }
  | { ok: false; errore: string; daRichiedere: boolean };

/// Una richiesta al provider, con la risposta già rivalidata.
async function generaScheda(
  prompt: string,
  parametri: ParametriGenerazione,
): Promise<EsitoGenerazione> {
  const blocchiDisponibili = Array.isArray(parametri.blocchiDisponibili)
    ? parametri.blocchiDisponibili
    : [];
  const risultato = PROVIDER_ATTIVO === "openai"
    ? await chiamaOpenAi(prompt, "scheda_generata", costruisciSchemaOpenAi(blocchiDisponibili))
    : await chiamaGemini(prompt, costruisciSchemaGemini(blocchiDisponibili));
  if (!risultato.ok) {
    return { ok: false, errore: risultato.errorMessage, daRichiedere: false };
  }

  let schedaGrezza: unknown;
  try {
    schedaGrezza = JSON.parse(risultato.testoJson);
  } catch {
    return {
      ok: false,
      errore: "Il provider AI non ha restituito un JSON valido",
      daRichiedere: true,
    };
  }
  try {
    return {
      ok: true,
      scheda: validaScheda(schedaGrezza, parametri),
      gettoni: risultato.gettoni,
    };
  } catch (errore) {
    return {
      ok: false,
      errore: `Scheda generata non valida: ${(errore as Error).message}`,
      daRichiedere: true,
    };
  }
}
