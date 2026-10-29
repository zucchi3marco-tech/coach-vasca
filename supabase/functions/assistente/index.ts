// Edge Function: assistente
//
// La chat dell'allenatore (proposta 9 del piano "Il Mako della
// pallanuoto"): risponde sui dati del club e propone azioni (una
// convocazione, una seduta nuova o le modifiche a una che c'e', in acqua o
// a secco, un programma a secco, l'appello, un messaggio per il gruppo dei
// genitori) che l'allenatore conferma nell'app.
//
// Decisione del 13 ottobre 2026, per i dati di minorenni: i dati restano
// sul telefono. Questa funzione non legge niente del club: e' solo il
// "cervello". Riceve la conversazione e restituisce la risposta del
// modello o le chiamate agli strumenti, che l'app esegue sul telefono
// (con i suoi conti) rimandando qui solo il risultato: codici al posto dei
// nomi (G1, G2...) e numeri gia' calcolati. Benessere, dolori e sintomi
// non arrivano mai: i filtri sulla salute li applica l'app
// (`scegli_atleti`), e i dati sulla salute li mostra direttamente
// all'allenatore (`mostra_benessere`). Quando il modello sul telefono sara'
// pronto (piano dell'AI locale) prendera' il posto di questo.
//
// Solo per lo staff del club, con i tetti delle altre funzioni AI: il
// controllo comune è in `_shared/accesso_ai.ts`. Una domanda conta una
// volta sola: i passaggi successivi (la conversazione che finisce con il
// risultato di uno strumento) si segnano a parte.

import { accessoAi } from "../_shared/accesso_ai.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const MODELLO = Deno.env.get("ASSISTENTE_MODEL") ?? Deno.env.get("TEXT_MODEL") ??
  "gpt-4o-mini";

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

const MESSAGGI_MASSIMI = 80;
const CARATTERI_MASSIMI = 120_000;
const TENTATIVI_MASSIMI = 3;
const ATTESE_MS = [1500, 3000];
const TEMPO_MASSIMO_MS = 55_000;
const LIMITE_TENTATIVO_MS = 30_000;

// Un esercizio a secco con la sua dose: lo stesso per sedute, programmi e
// modifiche.
const DOSE_SECCO = {
  type: "object",
  properties: {
    esercizio: { type: "string", description: "Il codice di esercizi_secco (E1, E2...)" },
    serie: { type: "integer", minimum: 1, maximum: 10 },
    ripetizioni: { type: "integer", minimum: 1, maximum: 500 },
    secondi: { type: "integer", minimum: 5, maximum: 3600, description: "Solo per gli esercizi a tempo" },
    recupero_secondi: { type: "integer", minimum: 0, maximum: 600 },
    carico: { type: "string", description: "\"70%\" solo per gli esercizi con massimale; altro solo se l'ha detto l'allenatore" },
    note: { type: "string" },
  },
  required: ["esercizio"],
  additionalProperties: false,
};

// Gli strumenti: li esegue l'app, qui c'e' solo come chiamarli.
const STRUMENTI = [
  {
    type: "function",
    function: {
      name: "squadra",
      description:
        "Gli atleti della squadra scelta nell'app, con codice (G1, G2...) e ruolo. Non ci sono nomi.",
      parameters: { type: "object", properties: {}, additionalProperties: false },
    },
  },
  {
    type: "function",
    function: {
      name: "partite",
      description:
        "Le partite della squadra: prossime o giocate, con id, data, ora, avversario, casa o trasferta, risultato, convocati e massimo dei convocati; le prossime anche con campionato, ritrovo, piscina, calottina, rientro previsto, cosa portare e note per le famiglie, quando ci sono.",
      parameters: {
        type: "object",
        properties: {
          quali: { type: "string", enum: ["prossime", "giocate"] },
          quante: { type: "integer", minimum: 1, maximum: 20 },
        },
        required: ["quali"],
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "statistiche_partite",
      description:
        "Le statistiche calcolate dall'app dagli eventi registrati dal vivo: gol fatti e subiti, tiri, superiorita' e inferiorita' (con i gol), rigori, espulsioni, palle perse e recuperate, assist; per squadra e per atleta (codici). O le ultime N partite giocate o le partite indicate.",
      parameters: {
        type: "object",
        properties: {
          ultime: { type: "integer", minimum: 1, maximum: 30 },
          partite_id: { type: "array", items: { type: "string" }, maxItems: 30 },
        },
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "presenze",
      description:
        "Le presenze agli allenamenti degli ultimi N giorni, per atleta (codici): presente (chi è in ritardo conta come presente), di_cui_in_ritardo, assente, giustificato, percentuale.",
      parameters: {
        type: "object",
        properties: { giorni: { type: "integer", minimum: 1, maximum: 365 } },
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "carico",
      description:
        "Il carico di allenamento di ogni atleta (codici): carico degli ultimi 7 giorni, rapporto con la media delle ultime 4 settimane (ACWR) e la sua fascia. E' carico di lavoro, non salute.",
      parameters: { type: "object", properties: {}, additionalProperties: false },
    },
  },
  {
    type: "function",
    function: {
      name: "allenamenti",
      description:
        "Le sedute della squadra fra due date (AAAA-MM-GG): data, tipo (acqua o secco), titolo, metri, lavoro a tempo, durata del secco, quanti presenti.",
      parameters: {
        type: "object",
        properties: {
          da: { type: "string", description: "AAAA-MM-GG" },
          a: { type: "string", description: "AAAA-MM-GG" },
        },
        required: ["da", "a"],
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "scegli_atleti",
      description:
        "Gli atleti della squadra (codici) che passano i filtri. I filtri sulla salute li applica l'app con le schede benessere degli ultimi 3 giorni: tu ricevi solo chi resta, mai i motivi. Usalo per convocare o preparare sedute 'escludendo chi ha male alla spalla' e simili.",
      parameters: {
        type: "object",
        properties: {
          escludi_dolore_spalla: { type: "boolean" },
          escludi_dolori: { type: "boolean", description: "qualsiasi dolore" },
          escludi_sintomi: { type: "boolean", description: "febbre, raffreddore..." },
          escludi_da_sentire: {
            type: "boolean",
            description: "chi ha la prontezza 'da sentire'",
          },
          ruolo: { type: "string", enum: ["portieri", "movimento"] },
          ordina_per: { type: "string", enum: ["presenze", "carico_basso"] },
          quanti: { type: "integer", minimum: 1, maximum: 40 },
        },
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "mostra_benessere",
      description:
        "Mostra direttamente all'allenatore, in una scheda dell'app, il benessere della squadra (prontezza, dolori, sintomi). Tu non ricevi i dati: usalo quando ti chiede di salute, dolori o benessere, poi digli che li trova nella scheda.",
      parameters: {
        type: "object",
        properties: {
          cosa: { type: "string", enum: ["tutto", "dolori", "sintomi", "da_sentire"] },
          giorni: { type: "integer", minimum: 1, maximum: 14 },
        },
        required: ["cosa"],
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "proponi_convocazione",
      description:
        "Propone all'allenatore la distinta di una partita: l'app gli mostra i convocati e lui conferma. Non e' ancora fatta finche' non conferma.",
      parameters: {
        type: "object",
        properties: {
          partita_id: { type: "string" },
          atleti: { type: "array", items: { type: "string" }, minItems: 1, maxItems: 20 },
        },
        required: ["partita_id", "atleti"],
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "proponi_seduta",
      description:
        "Propone all'allenatore una seduta in acqua scritta nel formato di 'Scrivi l'allenamento' (vedi le istruzioni): l'app la legge, gliela mostra e lui la crea. Non e' ancora creata finche' non conferma.",
      parameters: {
        type: "object",
        properties: {
          data: { type: "string", description: "AAAA-MM-GG" },
          titolo: { type: "string" },
          testo: { type: "string", description: "Una serie per riga" },
        },
        required: ["data", "testo"],
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "proponi_appello",
      description:
        "Propone all'allenatore l'appello di una seduta: l'app gli mostra tutti gli atleti attesi con lo stato e lui lo salva (puo' cambiare qualcuno). Chi non nomini e' presente; chi era gia' segnato resta com'era. Senza allenamento_id l'app prende l'unica seduta della squadra nel giorno (oggi se manca la data); se ce n'e' piu' d'una te le elenca. Non e' salvato finche' non conferma.",
      parameters: {
        type: "object",
        properties: {
          allenamento_id: { type: "string" },
          data: { type: "string", description: "AAAA-MM-GG" },
          assenti: { type: "array", items: { type: "string" }, maxItems: 40 },
          in_ritardo: { type: "array", items: { type: "string" }, maxItems: 40 },
          giustificati: { type: "array", items: { type: "string" }, maxItems: 40 },
          presenti: {
            type: "array",
            items: { type: "string" },
            maxItems: 40,
            description: "solo se li nomina: gli altri sono presenti lo stesso",
          },
        },
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "leggi_seduta",
      description:
        "Legge una seduta che c'e' gia': id, data, titolo, note e, in acqua, il testo delle serie nel formato di 'Scrivi l'allenamento'; a secco i minuti e gli esercizi di tutti con codice, nome e dose (delle varianti per gli atleti solo quante sono). Senza allenamento_id l'app prende l'unica seduta della squadra nel giorno (oggi se manca la data); se ce n'e' piu' d'una te le elenca.",
      parameters: {
        type: "object",
        properties: {
          allenamento_id: { type: "string" },
          data: { type: "string", description: "AAAA-MM-GG" },
        },
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "proponi_modifica_seduta",
      description:
        "Propone all'allenatore le modifiche a una seduta che c'e' gia': l'app gli mostra prima e dopo e lui le salva. In acqua 'testo' e' TUTTO il testo delle serie dopo la modifica (le righe non toccate copiate uguali da leggi_seduta); a secco 'esercizi' e' TUTTA la lista degli esercizi dopo la modifica, nell'ordine (quelli non toccati copiati uguali), e 'minuti' la durata se cambia. Titolo e note solo se cambiano (stringa vuota = toglierli). La data non si cambia. Non e' salvato finche' non conferma.",
      parameters: {
        type: "object",
        properties: {
          allenamento_id: { type: "string" },
          testo: { type: "string", description: "Solo in acqua: tutte le serie, una per riga" },
          esercizi: { type: "array", items: DOSE_SECCO, minItems: 1, maxItems: 20, description: "Solo a secco: tutti gli esercizi" },
          minuti: { type: "integer", minimum: 5, maximum: 600, description: "Solo a secco" },
          titolo: { type: "string" },
          note: { type: "string" },
        },
        required: ["allenamento_id"],
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "impegni",
      description:
        "Gli impegni della squadra e del club fra due date (di base da oggi per 60 giorni): collegiali, trasferte, riposi (anche piscina chiusa o vacanze), tornei, altro; con tipo, nome, dal, al, giorni, luogo e note.",
      parameters: {
        type: "object",
        properties: {
          da: { type: "string", description: "AAAA-MM-GG" },
          a: { type: "string", description: "AAAA-MM-GG" },
        },
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "proponi_messaggio_famiglie",
      description:
        "Propone all'allenatore un messaggio per il gruppo WhatsApp dei genitori: l'app glielo mostra con i nomi al posto dei codici, lui lo puo' correggere e lo manda con Condividi o Copia. Non e' inviato finche' non lo manda lui.",
      parameters: {
        type: "object",
        properties: {
          testo: { type: "string", description: "Il messaggio intero, pronto da incollare" },
        },
        required: ["testo"],
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "esercizi_secco",
      description:
        "L'elenco degli esercizi a secco del club: codice (E1, E2...), nome, categoria (spalla, scapole, core, gambe, forza, mobilita', altro), misura (ripetizioni o tempo), attrezzo e 'massimale' se c'e' un test di massimale. Sono gli unici esercizi che puoi usare.",
      parameters: { type: "object", properties: {}, additionalProperties: false },
    },
  },
  {
    type: "function",
    function: {
      name: "proponi_seduta_secco",
      description:
        "Propone all'allenatore una seduta a secco per un giorno, con gli esercizi dell'elenco del club e le dosi: l'app gliela mostra e lui la crea nel calendario della squadra. Non e' creata finche' non conferma.",
      parameters: {
        type: "object",
        properties: {
          data: { type: "string", description: "AAAA-MM-GG" },
          titolo: { type: "string" },
          minuti: { type: "integer", minimum: 5, maximum: 600 },
          esercizi: { type: "array", items: DOSE_SECCO, minItems: 1, maxItems: 20 },
        },
        required: ["data", "esercizi"],
        additionalProperties: false,
      },
    },
  },
  {
    type: "function",
    function: {
      name: "proponi_programma_secco",
      description:
        "Propone all'allenatore un programma a secco a settimane: scrivi solo le sedute della prima settimana (la A, la B...); le settimane dopo le fa l'app, un po' di piu' ogni settimana, e quelle di 'scarico' con una serie in meno. L'allenatore lo crea fra i programmi del club e poi lo mette nel calendario. Non e' creato finche' non conferma.",
      parameters: {
        type: "object",
        properties: {
          nome: { type: "string" },
          descrizione: { type: "string", description: "A cosa serve, in una o due frasi" },
          minuti: { type: "integer", minimum: 5, maximum: 120, description: "Di ogni seduta" },
          settimane: { type: "integer", minimum: 1, maximum: 12 },
          scarico: { type: "array", items: { type: "integer", minimum: 2, maximum: 12 }, description: "Le settimane di scarico, da 1" },
          sedute: {
            type: "array",
            minItems: 1,
            maxItems: 4,
            description: "Le sedute della prima settimana",
            items: { type: "array", items: DOSE_SECCO, minItems: 1, maxItems: 15 },
          },
        },
        required: ["nome", "settimane", "sedute"],
        additionalProperties: false,
      },
    },
  },
];

// La seduta da cui l'allenatore ha aperto la chat, se c'e': solo id, data,
// giorno e tipo, controllati.
function sedutaAperta(contesto: Record<string, unknown>): string {
  const s = contesto.seduta_aperta;
  if (typeof s !== "object" || s === null) return "";
  const r = s as Record<string, unknown>;
  const pulito = (v: unknown) =>
    typeof v === "string" && /^[\w\-:àèéìòù ]{1,40}$/.test(v) ? v : null;
  const id = pulito(r.id);
  if (!id) return "";
  return `\nL'allenatore ha aperto la chat dalla seduta ${id} (${pulito(r.tipo) ?? "acqua"}) di ${pulito(r.giorno) ?? ""} ${pulito(r.data) ?? ""}: se non dice altro, parla di questa (allenamento_id ${id}).`;
}

const NOMI_STRUMENTI = new Set(STRUMENTI.map((s) => s.function.name));

function istruzioni(contesto: Record<string, unknown>): string {
  const sport = contesto.sport === "nuoto" ? "nuoto" : "pallanuoto";
  return `Sei l'assistente di un allenatore di ${sport} di un club italiano, dentro l'app WaterTactics.
Oggi e' ${contesto.giorno ?? ""} ${contesto.oggi ?? ""}. Squadra scelta nell'app: ${contesto.squadra ?? "tutto il club"}.${sedutaAperta(contesto)}

Regole:
- Gli atleti sono minorenni. Li conosci solo per codice (G1, G2...): scrivi sempre il codice, l'app lo trasforma nel nome. Non inventare nomi e non chiederli.
- Non hai dati sulla salute (benessere, dolori, sintomi) e non devi chiederli. Per scegliere atleti con filtri sulla salute usa scegli_atleti; se l'allenatore chiede di salute o dolori usa mostra_benessere e digli che li trova nella scheda.
- Prima di rispondere sui numeri leggi i dati con gli strumenti. Non inventare numeri: se un dato manca, dillo.
- Per fare qualcosa (convocare, preparare o cambiare una seduta anche a secco, preparare un programma a secco, fare l'appello, scrivere alle famiglie) usa gli strumenti proponi_*: l'allenatore conferma nell'app. Non dire che e' fatto: di' che c'e' una proposta da controllare e confermare.
- L'appello ("assenti G3 e G5, G7 in ritardo", "tutti presenti") si fa con proponi_appello, subito, senza leggere prima la squadra: chi non e' nominato lo segna presente l'app. "Giustificato" e' chi ha avvisato o ha un motivo.
- Per cambiare una seduta che c'e' ("togli il 400 iniziale", "aggiungi 6x50 gambe dopo il riscaldamento", "cambia il titolo") leggila con leggi_seduta, poi usa proponi_modifica_seduta con tutto il testo delle serie: cambia solo le righe richieste e copia le altre identiche, nello stesso ordine. Se cambia solo titolo o note, non mandare il testo.
  - "Togli 2x100" o "aggiungi 2x100" da una serie che c'e' (12x100) cambia le ripetute di quella serie (12x100 diventa 10x100 o 14x100) e lascia il resto della riga uguale; togli una riga intera solo se lo chiede ("togli il 400 iniziale", "togli l'ultima serie").
  - Il blocco e la serie giusti: se l'allenatore nomina un blocco che nella seduta non c'e' (un riscaldamento quando le serie sono tutte nel principale) o non e' chiaro quale serie intende (due 12x100), chiedi prima di proporre, citando le serie possibili.
  - Dopo la proposta controlla righe_tolte e righe_aggiunte: devono essere solo quello che ha chiesto. Se non lo sono, rifai la proposta corretta. All'allenatore di' esattamente cosa cambia ("il 12x100 A2 diventa 10x100"), mai una cosa diversa da quelle righe.
- Per un messaggio alle famiglie ("scrivi ai genitori che giovedi' non c'e' allenamento", "ricorda la partita di sabato", "avvisa del collegiale") usa proponi_messaggio_famiglie con il testo pronto da incollare nel gruppo WhatsApp dei genitori. Se servono date o dettagli leggili prima con partite, allenamenti o impegni; la data scrivila per intero ("giovedi' 30 ottobre"). Le sedute non hanno orario: scrivi un'ora solo se l'ha detta l'allenatore o c'e' nei dati, non inventarla. Poche righe, tono cordiale e chiaro, la prima riga in grassetto di WhatsApp (*cosi'*), niente firma e niente emoji. Nomina un atleta (con il suo codice) solo se l'ha nominato l'allenatore. Il messaggio va a tutti i genitori: mai motivi di salute, infortuni o dolori di un atleta, nemmeno se li dice l'allenatore. Se l'allenatore chiede di cambiarlo, manda di nuovo il testo intero.
- Il secco ("prepara 20' di core e spalla per venerdi'", "un programma di 4 settimane per la spalla, 2 sedute da 20'"): leggi prima esercizi_secco e usa SOLO quegli esercizi, con il loro codice; non inventarne e non suggerirne altri. Se per quello che chiede mancano esercizi adatti (niente per le gambe), diglielo e usa quelli adatti che ci sono; se non ce n'e' nessuno non proporre niente e digli che li aggiunge da "Elenco esercizi del club".
  - Una seduta per un giorno: proponi_seduta_secco. Piu' settimane: proponi_programma_secco con le sedute della sola prima settimana (le altre le fa crescere l'app); se l'allenatore non dice altro, lo scarico e' ogni quarta settimana.
  - Dosi: 'secondi' per gli esercizi a tempo, 'ripetizioni' per gli altri, recupero in secondi; stai nei minuti chiesti (te li stima l'app). Gli atleti sono ragazzi: dosi prudenti, da prevenzione. Carico: una percentuale ("70%") solo per gli esercizi con massimale; un carico scritto ("elastico rosso") solo se l'ha detto l'allenatore; se no niente carico.
  - Per cambiare una seduta a secco leggila con leggi_seduta e manda a proponi_modifica_seduta tutta la lista 'esercizi', con gli esercizi non toccati copiati uguali (stesso codice e stesse dosi, nello stesso ordine). "Una serie in piu' di squat" cambia le serie di quell'esercizio, non aggiunge esercizi. Controlla righe_tolte e righe_aggiunte come per l'acqua.
- Se nella domanda c'e' "un atleta" al posto di un nome, quel nome e' di piu' atleti: chiedi quale (nome e cognome) prima di usarlo.
- Niente diagnosi mediche. Il carico (ACWR) e' una fascia di riferimento, non una previsione di infortuni.
- Rispondi in italiano, breve e concreto, come un collega competente. Niente punti esclamativi, niente elenchi lunghi se non servono.

Formato delle sedute (proponi_seduta e proponi_modifica_seduta), una serie per riga:
- titoli di blocco da soli su una riga: Riscaldamento, Principale, Defaticamento, Altro;
- "400 sl A1" una distanza; "8x100 sl B1 @1:40 r15" ripetute con zona, ripartenza e recupero; "3x5' uomo in +" serie a tempo;
- stili: sl, do, ra, df, mix; esecuzioni: gambe, braccia, pull, tecnica; pallanuoto senza stile: palleggio, tiri, schemi, gioco da schierati, partita, uomo in +, uomo in -, tecnico-tattico;
- zone: A1 A2 B1 B2 C1 C2 C3 D; "rec 2'" da solo su una riga = recupero dopo la serie sopra; "2x" da solo ripete le righe sotto fino alla riga vuota;
- "Portieri", "Movimento" o "G3, G7" da soli su una riga: per chi sono le serie sotto, fino al prossimo titolo; "Portieri: 10' tiri" davanti a una serie vale solo per quella.`;
}

type Messaggio = {
  role: string;
  content?: unknown;
  tool_calls?: unknown;
  tool_call_id?: unknown;
};

// Solo i campi che servono, con i tipi giusti: il resto si scarta.
function pulisciMessaggi(grezzi: unknown): Messaggio[] | string {
  if (!Array.isArray(grezzi) || grezzi.length === 0) return "Conversazione vuota";
  if (grezzi.length > MESSAGGI_MASSIMI) return "Conversazione troppo lunga: ricominciala";
  let caratteri = 0;
  const puliti: Messaggio[] = [];
  for (const m of grezzi) {
    if (typeof m !== "object" || m === null) return "Messaggio non valido";
    const r = m as Record<string, unknown>;
    const contenuto = typeof r.content === "string" ? r.content : null;
    caratteri += contenuto?.length ?? 0;
    if (r.role === "user") {
      if (!contenuto) return "Domanda vuota";
      puliti.push({ role: "user", content: contenuto });
    } else if (r.role === "assistant") {
      const chiamate = Array.isArray(r.tool_calls)
        ? r.tool_calls.flatMap((c) => {
          const cc = c as Record<string, unknown>;
          const f = cc.function as Record<string, unknown> | undefined;
          if (typeof cc.id !== "string" || !f || typeof f.name !== "string") return [];
          if (!NOMI_STRUMENTI.has(f.name)) return [];
          const argomenti = typeof f.arguments === "string" ? f.arguments : "{}";
          caratteri += argomenti.length;
          return [{ id: cc.id, type: "function", function: { name: f.name, arguments: argomenti } }];
        })
        : [];
      puliti.push({
        role: "assistant",
        content: contenuto,
        ...(chiamate.length > 0 ? { tool_calls: chiamate } : {}),
      });
    } else if (r.role === "tool") {
      if (typeof r.tool_call_id !== "string") return "Risultato senza chiamata";
      puliti.push({ role: "tool", tool_call_id: r.tool_call_id, content: contenuto ?? "{}" });
    } else {
      return "Ruolo non valido";
    }
  }
  if (caratteri > CARATTERI_MASSIMI) return "Conversazione troppo lunga: ricominciala";
  return puliti;
}

function messaggioErroreOpenAi(status: number, corpoGrezzo: string): string {
  let codice: string | undefined;
  try {
    const corpo = JSON.parse(corpoGrezzo);
    codice = corpo?.error?.code ?? corpo?.error?.type;
  } catch {
    // corpo non JSON: messaggio generico.
  }
  if (codice === "insufficient_quota") {
    return "Il credito del servizio AI è esaurito: va ricaricato l'account " +
      "OpenAI prima di poter usare di nuovo l'assistente.";
  }
  if (status === 401) {
    return "La chiave del servizio AI non è valida: va controllata nelle " +
      "impostazioni del server.";
  }
  if (status === 429 || codice === "rate_limit_exceeded") {
    return "Troppe richieste al servizio AI in poco tempo. Aspetta un minuto e riprova.";
  }
  if (status >= 500) {
    return "Il servizio AI è momentaneamente sovraccarico. Riprova tra qualche istante.";
  }
  return `Il servizio AI ha risposto con un errore (${status}). Riprova.`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo non supportato" }, 405);
  }
  if (!OPENAI_API_KEY) {
    return jsonResponse({ error: "Assistente non configurato sul server" }, 500);
  }

  let richiesta: { club_id?: unknown; contesto?: unknown; messaggi?: unknown };
  try {
    richiesta = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo della richiesta non valido" }, 400);
  }
  if (typeof richiesta.club_id !== "string") {
    return jsonResponse({ error: "Club mancante" }, 400);
  }

  // Solo lo staff del club, e la chiave dell'AI costa: prima di tutto il
  // resto. Se l'ultimo messaggio è il risultato di uno strumento, è un
  // passaggio della stessa domanda.
  const grezzi = Array.isArray(richiesta.messaggi) ? richiesta.messaggi : [];
  const ultimo = grezzi[grezzi.length - 1] as { role?: unknown } | undefined;
  const accesso = await accessoAi(req, {
    funzione: "assistente",
    modello: MODELLO,
    clubId: richiesta.club_id,
    passaggio: ultimo?.role === "tool",
  });
  if (accesso instanceof Response) return accesso;

  const messaggi = pulisciMessaggi(richiesta.messaggi);
  if (typeof messaggi === "string") {
    return jsonResponse({ error: messaggi }, 400);
  }
  const contesto = typeof richiesta.contesto === "object" && richiesta.contesto !== null
    ? richiesta.contesto as Record<string, unknown>
    : {};

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
          model: MODELLO,
          messages: [{ role: "system", content: istruzioni(contesto) }, ...messaggi],
          tools: STRUMENTI,
          temperature: 0.2,
        }),
      });
      erroreRete = undefined;
    } catch (errore) {
      erroreRete = errore;
      risposta = undefined;
    }
    corpoErrore = risposta !== undefined && !risposta.ok ? await risposta.text() : "";
    const daRiprovare = erroreRete !== undefined ||
      (risposta !== undefined && [429, 500, 502, 503].includes(risposta.status) &&
        !corpoErrore.includes("insufficient_quota"));
    const attesa = ATTESE_MS[tentativo - 1];
    const tempoRimasto = TEMPO_MASSIMO_MS - (Date.now() - inizio) - (attesa ?? 0);
    if (!daRiprovare || tentativo === TENTATIVI_MASSIMI || tempoRimasto < 10_000) break;
    await new Promise((r) => setTimeout(r, attesa));
  }

  if (erroreRete instanceof DOMException && erroreRete.name === "TimeoutError") {
    return jsonResponse({
      error: "Il servizio AI sta impiegando troppo a rispondere. Riprova tra qualche istante.",
    }, 504);
  }
  if (erroreRete !== undefined || risposta === undefined) {
    return jsonResponse({ error: "Impossibile contattare il servizio AI. Riprova." }, 502);
  }
  if (!risposta.ok) {
    return jsonResponse({ error: messaggioErroreOpenAi(risposta.status, corpoErrore) }, 502);
  }

  const dati = await risposta.json();
  await accesso.registraGettoni(dati?.usage?.total_tokens);
  const messaggio = dati?.choices?.[0]?.message;
  if (!messaggio) {
    return jsonResponse({ error: "Il servizio AI non ha risposto. Riprova." }, 502);
  }
  const chiamate = Array.isArray(messaggio.tool_calls)
    ? messaggio.tool_calls.filter((c: { function?: { name?: string } }) =>
      NOMI_STRUMENTI.has(c?.function?.name ?? "")
    )
    : [];
  return jsonResponse({
    messaggio: {
      role: "assistant",
      content: typeof messaggio.content === "string" ? messaggio.content : null,
      ...(chiamate.length > 0 ? { tool_calls: chiamate } : {}),
    },
    gettoni: dati?.usage?.total_tokens ?? null,
  });
});
