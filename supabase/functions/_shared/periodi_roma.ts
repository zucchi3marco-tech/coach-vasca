// Quando ripartono i tetti delle richieste AI: lunedì alle 00:00 per la
// settimana e il primo del mese alle 00:00 per il mese, all'ora italiana
// (non sette giorni a scorrimento: «si riparte lunedì» è più facile da
// capire). Restituisce istanti veri, da confrontare con `creato_il`.
//
// Nessun import: lo provano sia Deno sia Node (`periodi_roma_test.ts`).

const FUSO = "Europe/Rome";

const formato = new Intl.DateTimeFormat("en-US", {
  timeZone: FUSO,
  hourCycle: "h23",
  year: "numeric",
  month: "numeric",
  day: "numeric",
  hour: "numeric",
  minute: "numeric",
  second: "numeric",
});

interface OraRoma {
  anno: number;
  mese: number;
  giorno: number;
  ore: number;
  minuti: number;
  secondi: number;
}

function oraRoma(istante: Date): OraRoma {
  const parti = formato.formatToParts(istante);
  const valore = (tipo: string) => Number(parti.find((p) => p.type === tipo)?.value);
  return {
    anno: valore("year"),
    mese: valore("month"),
    giorno: valore("day"),
    ore: valore("hour"),
    minuti: valore("minute"),
    secondi: valore("second"),
  };
}

/// Di quanto l'ora di Roma è avanti rispetto a UTC in quell'istante (1 o
/// 2 ore, con l'ora legale).
function scartoRomaMs(istante: Date): number {
  const r = oraRoma(istante);
  const comeUtc = Date.UTC(r.anno, r.mese - 1, r.giorno, r.ore, r.minuti, r.secondi);
  return comeUtc - Math.floor(istante.getTime() / 1000) * 1000;
}

/// La mezzanotte di quel giorno a Roma. `giorno` può uscire dal mese
/// (0, -3, 32…): si conta come fa `Date.UTC`.
function mezzanotteRoma(anno: number, mese: number, giorno: number): Date {
  const utc = Date.UTC(anno, mese - 1, giorno);
  let istante = utc - scartoRomaMs(new Date(utc));
  // L'ora legale in Italia cambia alle 2 o alle 3 di notte, mai a
  // mezzanotte: il secondo calcolo di solito non cambia niente.
  istante = utc - scartoRomaMs(new Date(istante));
  return new Date(istante);
}

export function inizioSettimanaRoma(ora: Date = new Date()): Date {
  const r = oraRoma(ora);
  // 0 = domenica … 6 = sabato; lunedì vale 0 giorni indietro.
  const giornoSettimana = new Date(Date.UTC(r.anno, r.mese - 1, r.giorno)).getUTCDay();
  const giorniDaLunedi = (giornoSettimana + 6) % 7;
  return mezzanotteRoma(r.anno, r.mese, r.giorno - giorniDaLunedi);
}

export function inizioMeseRoma(ora: Date = new Date()): Date {
  const r = oraRoma(ora);
  return mezzanotteRoma(r.anno, r.mese, 1);
}
