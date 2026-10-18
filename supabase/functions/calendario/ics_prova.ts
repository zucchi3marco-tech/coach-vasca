// Prova di `ics.ts`, fuori da Supabase: `node supabase/functions/calendario/ics_prova.ts`
// (Node 24 legge il TypeScript da solo). Non viene pubblicata: la
// funzione importa solo `ics.ts`.

import assert from "node:assert/strict";
import { type Calendario, ics, leggiOra, piega } from "./ics.ts";

const calendario: Calendario = {
  nome: "Canottieri Milano",
  atleta: true,
  eventi: [
    {
      tipo: "partita",
      id: "a78b4608-609a-4ac7-b58b-93d669d77b40",
      data: "2026-10-24",
      ora: "18:00",
      titolo: "Canottieri Milano - NC Monza",
      luogo: "Piscina Cozzi, viale Tunisia 35; Milano",
      dettaglio: "U16 2027",
      squadra: "U16",
      per_me: true,
      aggiornato: "2026-10-13T19:27:36.222568+00:00",
    },
    {
      tipo: "gara",
      id: "b1",
      data: "2026-12-31",
      ora: null,
      titolo: "Trofeo di fine anno",
      luogo: null,
      dettaglio: null,
      squadra: null,
      per_me: false,
      aggiornato: "2026-10-13T19:27:36Z",
    },
    {
      tipo: "partita",
      id: "c1",
      data: "2026-10-25",
      ora: "23.30",
      titolo: "A - B",
      luogo: null,
      dettaglio: null,
      squadra: "U16",
      per_me: false,
      aggiornato: "2026-10-13T19:27:36Z",
    },
  ],
};

const testo = ics(calendario, new Date("2026-10-18T10:00:00Z"));
const righe = testo.split("\r\n");

// Inizio e fine, CRLF ovunque, nessuna riga oltre 75 byte.
assert.equal(righe[0], "BEGIN:VCALENDAR");
assert.equal(righe.at(-2), "END:VCALENDAR");
assert.ok(!testo.replace(/\r\n/g, "").includes("\n"));
for (const r of righe) {
  assert.ok(new TextEncoder().encode(r).length <= 75, r);
}
assert.ok(testo.includes("X-WR-CALNAME:Partite · Canottieri Milano"));

// La partita con l'ora: dalle 18 alle 20, ora di Roma, convocato.
assert.ok(testo.includes("DTSTART;TZID=Europe/Rome:20261024T180000"));
assert.ok(testo.includes("DTEND;TZID=Europe/Rome:20261024T200000"));
assert.ok(testo.includes("SUMMARY:Convocato · Canottieri Milano - NC Monza"));
assert.ok(testo.includes("UID:partita-a78b4608-609a-4ac7-b58b-93d669d77b40@watertactics"));
// Virgole e punti e virgola protetti nel luogo.
assert.ok(
  testo.replace(/\r\n /g, "").includes(
    "LOCATION:Piscina Cozzi\\, viale Tunisia 35\\; Milano",
  ),
);
assert.ok(testo.includes("DESCRIPTION:U16\\nU16 2027\\nConvocato"));

// La gara senza ora: tutto il giorno, anche a fine anno.
assert.ok(testo.includes("DTSTART;VALUE=DATE:20261231"));
assert.ok(testo.includes("DTEND;VALUE=DATE:20270101"));
assert.ok(testo.includes("SUMMARY:Gara · Trofeo di fine anno"));

// Alle 23.30 la fine passa al giorno dopo.
assert.ok(testo.includes("DTEND;TZID=Europe/Rome:20261026T013000"));

// L'allenatore vede la squadra davanti.
const perAllenatore = ics({ ...calendario, atleta: false });
assert.ok(perAllenatore.includes("SUMMARY:Convocato · U16 · Canottieri Milano - NC Monza"));

// L'ora scritta in modi diversi.
assert.deepEqual(leggiOra("18:00"), [18, 0]);
assert.deepEqual(leggiOra("ore 18.30"), [18, 30]);
assert.deepEqual(leggiOra("18"), [18, 0]);
assert.equal(leggiOra("da definire"), null);
assert.equal(leggiOra("25:00"), null);
assert.equal(leggiOra(null), null);

// Una riga lunga con le accentate si spezza senza tagliarle.
const lunga = piega("DESCRIPTION:" + "è".repeat(60));
for (const pezzo of lunga.split("\r\n")) {
  assert.ok(new TextEncoder().encode(pezzo).length <= 75);
  assert.ok(!pezzo.includes("�"));
}
assert.equal(lunga.replace(/\r\n /g, ""), "DESCRIPTION:" + "è".repeat(60));

console.log("ics.ts: tutto bene");
