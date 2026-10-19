// Le regole del controllo comune delle funzioni AI (proposta «Funzioni AI
// verificate, con tetto di spesa»), senza il database: `accesso_ai.ts`
// gli passa le letture vere, `regole_accesso_ai_test.ts` delle finte.
//
// Prima di chiamare il modello:
// 1. chi chiama deve essere entrato con un account vero (la chiave
//    pubblica del sito da sola non basta più);
// 2. deve essere dello staff di un club (responsabile, allenatore o
//    assistente: gli atleti non usano l'AI);
// 3. la richiesta si segna subito in `ai_usage` e poi si contano quelle
//    del periodo, questa compresa: così due richieste partite insieme non
//    superano il tetto di nascosto. Oltre il tetto la riga si toglie e la
//    richiesta si ferma.
// Se un controllo non riesce (database lento, rete) si blocca con «riprova
// tra poco»: meglio un no in più che una spesa senza tetto.

import { inizioMeseRoma, inizioSettimanaRoma } from "./periodi_roma.ts";

// Scelti dal coach il 2026-10-19: 30 a persona a settimana (da lunedì) e
// 300 per club al mese (dal primo).
export const LIMITE_SETTIMANALE_PER_PERSONA = 30;
export const LIMITE_MENSILE_PER_CLUB = 300;

// Una domanda all'assistente può fare fino a 6 passaggi (il modello chiede
// dei dati, il telefono li legge, il modello continua): la domanda conta
// una volta sola, i passaggi dopo il primo si segnano con questo nome e
// hanno un tetto loro, 6 per ogni richiesta della settimana.
export const FUNZIONE_PASSAGGIO = "assistente-passaggio";
export const PASSAGGI_PER_RICHIESTA = 6;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface RigaUso {
  club_id: string;
  user_id: string;
  funzione: string;
  modello: string;
}

export interface FiltroConteggio {
  userId?: string;
  clubId?: string;
  // true: solo i passaggi dell'assistente; false: tutto il resto.
  passaggi: boolean;
  dal: Date;
}

/// Le letture e scritture che servono. Un errore del database o della
/// rete si lancia come eccezione: qui diventa «riprova tra poco».
export interface DatiAccesso {
  /// L'id dell'account se il token è valido, `null` se non lo è.
  utente(token: string): Promise<string | null>;
  /// Il club dello staff (quello indicato, se c'è), `null` se non è staff.
  clubDelMembro(userId: string, clubId: string | null): Promise<string | null>;
  /// Segna la richiesta e ne restituisce l'id.
  prenota(riga: RigaUso): Promise<string>;
  conta(filtro: FiltroConteggio): Promise<number>;
  /// Toglie una richiesta segnata e poi fermata (non lancia).
  annulla(id: string): Promise<void>;
}

export interface OpzioniAccesso {
  /// Il nome della funzione, come finisce in `ai_usage`.
  funzione: string;
  modello: string;
  /// Solo l'assistente dice per quale club chiede; per le altre funzioni
  /// è il club dell'iscrizione.
  clubId?: unknown;
  /// Un passaggio dell'assistente dentro la stessa domanda.
  passaggio?: boolean;
}

export type EsitoAccesso =
  | { ok: true; userId: string; clubId: string; rigaId: string }
  | { ok: false; stato: number; errore: string; codice: string };

const NON_ENTRATO: EsitoAccesso = {
  ok: false,
  stato: 401,
  errore: "Per usare l'AI devi entrare con il tuo account.",
  codice: "accesso_richiesto",
};

const SOLO_STAFF: EsitoAccesso = {
  ok: false,
  stato: 403,
  errore: "Le funzioni AI sono solo per lo staff del club.",
  codice: "solo_staff",
};

const CONTROLLO_NON_RIUSCITO: EsitoAccesso = {
  ok: false,
  stato: 503,
  errore: "Non riesco a controllare le richieste AI in questo momento. " +
    "Riprova tra poco.",
  codice: "controllo_non_riuscito",
};

const LIMITE_SETTIMANA: EsitoAccesso = {
  ok: false,
  stato: 429,
  errore: `Hai già usato le ${LIMITE_SETTIMANALE_PER_PERSONA} richieste AI ` +
    "di questa settimana: si riparte lunedì. Fino ad allora si può fare " +
    "tutto a mano.",
  codice: "limite_settimanale",
};

const LIMITE_MESE: EsitoAccesso = {
  ok: false,
  stato: 429,
  errore: `Il club ha già usato le ${LIMITE_MENSILE_PER_CLUB} richieste AI ` +
    "di questo mese: si riparte il primo del mese. Fino ad allora si può " +
    "fare tutto a mano.",
  codice: "limite_mensile",
};

function tokenDa(autorizzazione: string | null): string | null {
  const token = autorizzazione?.match(/^Bearer\s+(.+)$/i)?.[1]?.trim();
  return token ? token : null;
}

export async function decidiAccesso(
  dati: DatiAccesso,
  autorizzazione: string | null,
  opzioni: OpzioniAccesso,
  ora: Date = new Date(),
): Promise<EsitoAccesso> {
  const token = tokenDa(autorizzazione);
  if (!token) return NON_ENTRATO;

  let userId: string | null;
  try {
    userId = await dati.utente(token);
  } catch {
    return CONTROLLO_NON_RIUSCITO;
  }
  if (!userId) return NON_ENTRATO;

  let clubChiesto: string | null = null;
  if (opzioni.clubId !== undefined) {
    if (typeof opzioni.clubId !== "string" || !UUID.test(opzioni.clubId)) return SOLO_STAFF;
    clubChiesto = opzioni.clubId;
  }
  let clubId: string | null;
  try {
    clubId = await dati.clubDelMembro(userId, clubChiesto);
  } catch {
    return CONTROLLO_NON_RIUSCITO;
  }
  if (!clubId) return SOLO_STAFF;

  const passaggio = opzioni.passaggio === true;
  let rigaId: string;
  try {
    rigaId = await dati.prenota({
      club_id: clubId,
      user_id: userId,
      funzione: passaggio ? FUNZIONE_PASSAGGIO : opzioni.funzione,
      modello: opzioni.modello,
    });
  } catch {
    return CONTROLLO_NON_RIUSCITO;
  }

  let fermata: EsitoAccesso | null;
  try {
    fermata = passaggio
      ? await oltreIlTettoDeiPassaggi(dati, userId, ora)
      : await oltreITetti(dati, userId, clubId, ora);
  } catch {
    fermata = CONTROLLO_NON_RIUSCITO;
  }
  if (fermata) {
    await dati.annulla(rigaId);
    return fermata;
  }
  return { ok: true, userId, clubId, rigaId };
}

async function oltreITetti(
  dati: DatiAccesso,
  userId: string,
  clubId: string,
  ora: Date,
): Promise<EsitoAccesso | null> {
  const [diQuestaPersona, delClub] = await Promise.all([
    dati.conta({ userId, passaggi: false, dal: inizioSettimanaRoma(ora) }),
    dati.conta({ clubId, passaggi: false, dal: inizioMeseRoma(ora) }),
  ]);
  if (diQuestaPersona > LIMITE_SETTIMANALE_PER_PERSONA) return LIMITE_SETTIMANA;
  if (delClub > LIMITE_MENSILE_PER_CLUB) return LIMITE_MESE;
  return null;
}

async function oltreIlTettoDeiPassaggi(
  dati: DatiAccesso,
  userId: string,
  ora: Date,
): Promise<EsitoAccesso | null> {
  const passaggi = await dati.conta({
    userId,
    passaggi: true,
    dal: inizioSettimanaRoma(ora),
  });
  return passaggi > LIMITE_SETTIMANALE_PER_PERSONA * PASSAGGI_PER_RICHIESTA
    ? LIMITE_SETTIMANA
    : null;
}
