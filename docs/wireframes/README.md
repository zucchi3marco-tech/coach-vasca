# Wireframe — Fase 1

Bozza a bassa fedeltà delle 6 schermate previste dalla ROADMAP, pubblicata
come pagina interattiva: https://claude.ai/code/artifact/7338885b-8c1b-4f3d-ba8f-372309ddfca5

Non vincolante sul design finale (colori, spaziature, componenti reali) —
serve solo a fissare struttura, gerarchia delle informazioni e i punti di
integrazione con lo schema DB prima di iniziare la FASE 2.

## Schermate

1. **Login** — email + password (Supabase Auth), nessun dato visibile prima
   dell'accesso grazie alla RLS.
2. **Lista atleti** — elenco filtrabile per gruppo, stato attivo/inattivo,
   accesso alla scheda atleta.
3. **Test → tabella passi** — inserimento BVS/T30, passo medio calcolato dal
   DB (colonna generata), tabella delle 6 zone A1–D salvata in
   `tabelle_passi`.
4. **Calendario stagione** — vista mensile con i giorni che hanno un
   allenamento assegnato, etichetta del mesociclo/microciclo corrente.
5. **Scheda bordo vasca** — unica schermata pensata per tablet in
   orientamento landscape, testo grande e alto contrasto per l'uso reale in
   piscina; ogni blocco corrisponde a una riga `serie`.
6. **Placeholder "Genera con AI"** — punto di ingresso disabilitato in Fase
   1, riservato per il modulo AI della Fase 5.

Se l'artifact venisse aggiornato in una sessione futura, il link resta lo
stesso (redeploy sulla stessa pagina).
