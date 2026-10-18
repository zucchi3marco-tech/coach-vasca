// Il calendario in formato iCalendar (.ics) per la Edge Function
// `calendario`: senza Deno né Supabase, così si prova anche fuori (vedi
// `ics_prova.ts`).

export type Evento = {
  tipo: "partita" | "gara";
  id: string;
  data: string; // "2026-10-24"
  ora: string | null; // "18:00", "18.30", "18"
  titolo: string;
  luogo: string | null;
  dettaglio: string | null; // il campionato
  squadra: string | null;
  per_me: boolean; // convocato (partita) o iscritto (gara)
  aggiornato: string;
};

export type Calendario = { nome: string; atleta: boolean; eventi: Evento[] };

// Quanto dura un evento con l'ora: una partita con il riscaldamento, una
// gara di nuoto (una sessione).
const ORE_DURATA = { partita: 2, gara: 3 } as const;

// L'ora italiana, con il cambio dell'ora: senza, il telefono non saprebbe
// a che ora mettere "18:00".
const FUSO_ROMA = [
  "BEGIN:VTIMEZONE",
  "TZID:Europe/Rome",
  "X-LIC-LOCATION:Europe/Rome",
  "BEGIN:DAYLIGHT",
  "TZOFFSETFROM:+0100",
  "TZOFFSETTO:+0200",
  "TZNAME:CEST",
  "DTSTART:19700329T020000",
  "RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU",
  "END:DAYLIGHT",
  "BEGIN:STANDARD",
  "TZOFFSETFROM:+0200",
  "TZOFFSETTO:+0100",
  "TZNAME:CET",
  "DTSTART:19701025T030000",
  "RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU",
  "END:STANDARD",
  "END:VTIMEZONE",
];

// Il testo di un campo: virgole, punti e virgola, barre e a capo protetti.
export function campo(valore: string): string {
  return valore
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\r?\n/g, "\\n");
}

// Le righe oltre 75 byte vanno spezzate (con uno spazio all'inizio della
// riga dopo), senza tagliare una lettera accentata a metà.
export function piega(riga: string): string {
  const codifica = new TextEncoder();
  const pezzi: string[] = [];
  let pezzo = "";
  let byte = 0;
  for (const lettera of riga) {
    const n = codifica.encode(lettera).length;
    const massimo = pezzi.length === 0 ? 75 : 74;
    if (byte + n > massimo) {
      pezzi.push(pezzo);
      pezzo = "";
      byte = 0;
    }
    pezzo += lettera;
    byte += n;
  }
  pezzi.push(pezzo);
  return pezzi.join("\r\n ");
}

function due(n: number): string {
  return n.toString().padStart(2, "0");
}

// "2026-10-24" + 0 giorni -> "20261024".
function giorno(data: string, piu = 0): string {
  const [a, m, g] = data.split("-").map(Number);
  const d = new Date(Date.UTC(a, m - 1, g + piu));
  return `${d.getUTCFullYear()}${due(d.getUTCMonth() + 1)}${
    due(d.getUTCDate())
  }`;
}

// "18:00", "18.30", "ore 18", "18" -> [18, 0]; null se non è un'ora.
export function leggiOra(ora: string | null): [number, number] | null {
  if (!ora) return null;
  const m = ora.match(/(\d{1,2})(?:[:.,](\d{2}))?/);
  if (!m) return null;
  const h = Number(m[1]);
  const min = m[2] ? Number(m[2]) : 0;
  if (h > 23 || min > 59) return null;
  return [h, min];
}

// L'ora locale di Roma, "20261024T180000", spostata di [piuOre].
function locale(data: string, ora: [number, number], piuOre = 0): string {
  const [a, m, g] = data.split("-").map(Number);
  const d = new Date(Date.UTC(a, m - 1, g, ora[0] + piuOre, ora[1]));
  return `${d.getUTCFullYear()}${due(d.getUTCMonth() + 1)}${
    due(d.getUTCDate())
  }T${due(d.getUTCHours())}${due(d.getUTCMinutes())}00`;
}

function utc(istante: Date): string {
  return istante.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
}

function evento(e: Evento, atleta: boolean, adesso: string): string[] {
  const segno = e.per_me
    ? (e.tipo === "partita" ? "Convocato" : "Iscritto")
    : null;
  const nome = e.tipo === "gara" ? `Gara · ${e.titolo}` : e.titolo;
  // All'allenatore, che vede tutte le squadre, la squadra davanti.
  const titolo = [segno, !atleta ? e.squadra : null, nome]
    .filter((x): x is string => !!x)
    .join(" · ");
  const descrizione = [e.squadra, e.dettaglio, segno]
    .filter((x): x is string => !!x)
    .join("\n");
  const ora = leggiOra(e.ora);
  const quando = ora
    ? [
      `DTSTART;TZID=Europe/Rome:${locale(e.data, ora)}`,
      `DTEND;TZID=Europe/Rome:${locale(e.data, ora, ORE_DURATA[e.tipo])}`,
    ]
    : [
      `DTSTART;VALUE=DATE:${giorno(e.data)}`,
      `DTEND;VALUE=DATE:${giorno(e.data, 1)}`,
    ];
  return [
    "BEGIN:VEVENT",
    `UID:${e.tipo}-${e.id}@watertactics`,
    `DTSTAMP:${adesso}`,
    `LAST-MODIFIED:${utc(new Date(e.aggiornato))}`,
    ...quando,
    `SUMMARY:${campo(titolo)}`,
    ...(e.luogo ? [`LOCATION:${campo(e.luogo)}`] : []),
    ...(descrizione ? [`DESCRIPTION:${campo(descrizione)}`] : []),
    "TRANSP:OPAQUE",
    "END:VEVENT",
  ];
}

/** Il calendario intero, con le righe già spezzate e gli a capo CRLF. */
export function ics(calendario: Calendario, adesso = new Date()): string {
  const timbro = utc(adesso);
  const righe = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//WaterTactics//Partite e gare//IT",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    `X-WR-CALNAME:${campo(`Partite · ${calendario.nome}`)}`,
    "X-WR-TIMEZONE:Europe/Rome",
    // Ogni quanto ripassare: i telefoni lo prendono come un consiglio.
    "REFRESH-INTERVAL;VALUE=DURATION:PT4H",
    "X-PUBLISHED-TTL:PT4H",
    ...FUSO_ROMA,
    ...calendario.eventi.flatMap((e) => evento(e, calendario.atleta, timbro)),
    "END:VCALENDAR",
  ];
  return righe.map(piega).join("\r\n") + "\r\n";
}
