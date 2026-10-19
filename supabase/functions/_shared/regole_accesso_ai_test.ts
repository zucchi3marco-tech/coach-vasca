// Prove di `regole_accesso_ai.ts`, con un database finto. Si lanciano con
//   node --test supabase/functions/_shared/regole_accesso_ai_test.ts

import { test } from "node:test";
import assert from "node:assert/strict";

import {
  type DatiAccesso,
  decidiAccesso,
  type FiltroConteggio,
  FUNZIONE_PASSAGGIO,
  type RigaUso,
} from "./regole_accesso_ai.ts";

const CLUB = "11111111-2222-3333-4444-555555555555";
const ALTRO_CLUB = "99999999-2222-3333-4444-555555555555";
// Lunedì 19 ottobre 2026, le 10 a Roma.
const ORA = new Date("2026-10-19T08:00:00Z");

interface Finto extends DatiAccesso {
  prenotate: RigaUso[];
  annullate: string[];
  conteggi: FiltroConteggio[];
}

function dati(opzioni: {
  utente?: string | null | "rotto";
  club?: string | null | "rotto";
  prenota?: "rotto";
  diQuestaPersona?: number;
  delClub?: number;
  passaggi?: number;
  conta?: "rotto";
} = {}): Finto {
  const finto: Finto = {
    prenotate: [],
    annullate: [],
    conteggi: [],
    utente(_token) {
      if (opzioni.utente === "rotto") return Promise.reject(new Error("rete"));
      return Promise.resolve(opzioni.utente === undefined ? "u1" : opzioni.utente);
    },
    clubDelMembro(_userId, clubId) {
      if (opzioni.club === "rotto") return Promise.reject(new Error("rete"));
      const club = opzioni.club === undefined ? CLUB : opzioni.club;
      return Promise.resolve(clubId == null || clubId === club ? club : null);
    },
    prenota(riga) {
      if (opzioni.prenota === "rotto") return Promise.reject(new Error("rete"));
      finto.prenotate.push(riga);
      return Promise.resolve("riga1");
    },
    conta(filtro) {
      finto.conteggi.push(filtro);
      if (opzioni.conta === "rotto") return Promise.reject(new Error("rete"));
      if (filtro.passaggi) return Promise.resolve(opzioni.passaggi ?? 1);
      return Promise.resolve(
        filtro.userId ? opzioni.diQuestaPersona ?? 1 : opzioni.delClub ?? 1,
      );
    },
    annulla(id) {
      finto.annullate.push(id);
      return Promise.resolve();
    },
  };
  return finto;
}

const GENERA = { funzione: "genera-allenamento", modello: "gpt-4o-mini" };

test("senza account si ferma subito", async () => {
  const d = dati();
  for (const intestazione of [null, "", "Bearer ", "Basic abc"]) {
    const esito = await decidiAccesso(d, intestazione, GENERA, ORA);
    assert.equal(esito.ok, false);
    assert.equal(!esito.ok && esito.stato, 401);
  }
  assert.equal(d.prenotate.length, 0);
});

test("la chiave pubblica del sito non è un account", async () => {
  const d = dati({ utente: null });
  const esito = await decidiAccesso(d, "Bearer chiave-pubblica", GENERA, ORA);
  assert.deepEqual(esito.ok ? null : [esito.stato, esito.codice], [401, "accesso_richiesto"]);
  assert.equal(d.prenotate.length, 0);
});

test("se non si riesce a controllare l'account si blocca", async () => {
  const esito = await decidiAccesso(dati({ utente: "rotto" }), "Bearer t", GENERA, ORA);
  assert.deepEqual(esito.ok ? null : [esito.stato, esito.codice], [503, "controllo_non_riuscito"]);
});

test("un account che non è dello staff (un atleta) non passa", async () => {
  const d = dati({ club: null });
  const esito = await decidiAccesso(d, "Bearer t", GENERA, ORA);
  assert.deepEqual(esito.ok ? null : [esito.stato, esito.codice], [403, "solo_staff"]);
  assert.equal(d.prenotate.length, 0);
});

test("l'assistente controlla il club che chiede", async () => {
  const assistente = { funzione: "assistente", modello: "gpt-4o-mini" };
  const mio = await decidiAccesso(dati(), "Bearer t", { ...assistente, clubId: CLUB }, ORA);
  assert.equal(mio.ok, true);
  const altro = await decidiAccesso(dati(), "Bearer t", { ...assistente, clubId: ALTRO_CLUB }, ORA);
  assert.equal(!altro.ok && altro.stato, 403);
  for (const strano of ["non-un-id", 42, null]) {
    const esito = await decidiAccesso(dati(), "Bearer t", { ...assistente, clubId: strano }, ORA);
    assert.equal(!esito.ok && esito.stato, 403);
  }
});

test("se non si riesce a leggere il club si blocca", async () => {
  const esito = await decidiAccesso(dati({ club: "rotto" }), "Bearer t", GENERA, ORA);
  assert.equal(!esito.ok && esito.stato, 503);
});

test("sotto i tetti passa e la richiesta resta segnata", async () => {
  const d = dati({ diQuestaPersona: 30, delClub: 300 });
  const esito = await decidiAccesso(d, "Bearer t", GENERA, ORA);
  assert.deepEqual(esito, { ok: true, userId: "u1", clubId: CLUB, rigaId: "riga1" });
  assert.deepEqual(d.prenotate, [
    { club_id: CLUB, user_id: "u1", funzione: "genera-allenamento", modello: "gpt-4o-mini" },
  ]);
  assert.deepEqual(d.annullate, []);
  // Settimana da lunedì 19 alle 00:00, mese dal 1 ottobre alle 00:00
  // (ora di Roma), e i passaggi dell'assistente non contano.
  assert.deepEqual(d.conteggi, [
    { userId: "u1", passaggi: false, dal: new Date("2026-10-18T22:00:00Z") },
    { clubId: CLUB, passaggi: false, dal: new Date("2026-09-30T22:00:00Z") },
  ]);
});

test("la trentunesima richiesta della settimana si ferma e si toglie", async () => {
  const d = dati({ diQuestaPersona: 31 });
  const esito = await decidiAccesso(d, "Bearer t", GENERA, ORA);
  assert.deepEqual(esito.ok ? null : [esito.stato, esito.codice], [429, "limite_settimanale"]);
  assert.match(esito.ok ? "" : esito.errore, /30 richieste AI.*lunedì/);
  assert.deepEqual(d.annullate, ["riga1"]);
});

test("oltre le 300 del club nel mese si ferma e si toglie", async () => {
  const d = dati({ delClub: 301 });
  const esito = await decidiAccesso(d, "Bearer t", GENERA, ORA);
  assert.deepEqual(esito.ok ? null : [esito.stato, esito.codice], [429, "limite_mensile"]);
  assert.match(esito.ok ? "" : esito.errore, /300 richieste AI.*primo del mese/);
  assert.deepEqual(d.annullate, ["riga1"]);
});

test("se non si riesce a segnare o a contare si blocca", async () => {
  const nonSegnata = await decidiAccesso(dati({ prenota: "rotto" }), "Bearer t", GENERA, ORA);
  assert.equal(!nonSegnata.ok && nonSegnata.stato, 503);
  const d = dati({ conta: "rotto" });
  const nonContata = await decidiAccesso(d, "Bearer t", GENERA, ORA);
  assert.equal(!nonContata.ok && nonContata.stato, 503);
  assert.deepEqual(d.annullate, ["riga1"]);
});

test("i passaggi dell'assistente hanno un tetto loro, 6 per richiesta", async () => {
  const passaggio = {
    funzione: "assistente",
    modello: "gpt-4o-mini",
    clubId: CLUB,
    passaggio: true,
  };
  const d = dati({ passaggi: 180, diQuestaPersona: 999, delClub: 999 });
  const esito = await decidiAccesso(d, "Bearer t", passaggio, ORA);
  assert.equal(esito.ok, true);
  assert.equal(d.prenotate[0].funzione, FUNZIONE_PASSAGGIO);
  assert.deepEqual(d.conteggi, [
    { userId: "u1", passaggi: true, dal: new Date("2026-10-18T22:00:00Z") },
  ]);

  const troppi = dati({ passaggi: 181 });
  const fermato = await decidiAccesso(troppi, "Bearer t", passaggio, ORA);
  assert.equal(!fermato.ok && fermato.codice, "limite_settimanale");
  assert.deepEqual(troppi.annullate, ["riga1"]);
});
