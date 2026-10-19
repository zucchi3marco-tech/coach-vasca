// Prove di `periodi_roma.ts`. Si lanciano con Node (che legge il
// TypeScript da solo dalla versione 23.6):
//   node --test supabase/functions/_shared/periodi_roma_test.ts
// oppure con Deno: deno test supabase/functions/_shared/

import { test } from "node:test";
import assert from "node:assert/strict";

import { inizioMeseRoma, inizioSettimanaRoma } from "./periodi_roma.ts";

const settimana = (ora: string) => inizioSettimanaRoma(new Date(ora)).toISOString();
const mese = (ora: string) => inizioMeseRoma(new Date(ora)).toISOString();

test("la settimana parte lunedì a mezzanotte, ora italiana", () => {
  // Lunedì 19 ottobre 2026, le 10 a Roma (ora legale, +2).
  assert.equal(settimana("2026-10-19T08:00:00Z"), "2026-10-18T22:00:00.000Z");
  // Proprio la mezzanotte del lunedì.
  assert.equal(settimana("2026-10-18T22:00:00Z"), "2026-10-18T22:00:00.000Z");
  // Un secondo prima è ancora la settimana di prima.
  assert.equal(settimana("2026-10-18T21:59:59Z"), "2026-10-11T22:00:00.000Z");
});

test("la settimana in cui torna l'ora solare (25 ottobre 2026)", () => {
  // Domenica 25 alle 23:30 a Roma (ora solare, +1): la settimana è
  // partita lunedì 19, ancora con l'ora legale.
  assert.equal(settimana("2026-10-25T22:30:00Z"), "2026-10-18T22:00:00.000Z");
  // Lunedì 26 alle 00:30 a Roma: settimana nuova, mezzanotte a +1.
  assert.equal(settimana("2026-10-25T23:30:00Z"), "2026-10-25T23:00:00.000Z");
});

test("la settimana in cui arriva l'ora legale (28 marzo 2027)", () => {
  // Mercoledì 31 marzo 2027: la settimana è partita lunedì 29 (+2).
  assert.equal(settimana("2027-03-31T10:00:00Z"), "2027-03-28T22:00:00.000Z");
  // Domenica 28 alle 12 (+2): la settimana è partita lunedì 22 (+1).
  assert.equal(settimana("2027-03-28T10:00:00Z"), "2027-03-21T23:00:00.000Z");
});

test("la settimana a cavallo dell'anno", () => {
  // Venerdì 1 gennaio 2027: la settimana è partita lunedì 28 dicembre.
  assert.equal(settimana("2027-01-01T05:00:00Z"), "2026-12-27T23:00:00.000Z");
});

test("il mese parte il primo a mezzanotte, ora italiana", () => {
  assert.equal(mese("2026-10-19T08:00:00Z"), "2026-09-30T22:00:00.000Z");
  // 1 novembre alle 00:10 a Roma (+1): mese nuovo.
  assert.equal(mese("2026-10-31T23:10:00Z"), "2026-10-31T23:00:00.000Z");
  // 31 ottobre alle 23:50 a Roma: ancora ottobre.
  assert.equal(mese("2026-10-31T22:50:00Z"), "2026-09-30T22:00:00.000Z");
  // Gennaio, e marzo prima dell'ora legale.
  assert.equal(mese("2027-01-01T05:00:00Z"), "2026-12-31T23:00:00.000Z");
  assert.equal(mese("2027-03-31T10:00:00Z"), "2027-02-28T23:00:00.000Z");
});
