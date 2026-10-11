-- ============================================================
-- FASI DELLA STAGIONE CON GLI OBIETTIVI (analisi "Il Mako della
-- pallanuoto", proposta 4): preparazione, andata, ritorno, playoff...
-- ognuna con le sue date, i metri a settimana che la squadra dovrebbe
-- fare e il carico a settimana di un atleta. Il grafico "Volume per
-- settimana" e quello del carico disegnano l'obiettivo accanto a quanto
-- si e' fatto.
--
-- Stanno dentro la stagione (una lista JSON) e non in una tabella a
-- parte: si scrivono insieme alla stagione, si copiano con lei quando la
-- si duplica, e vanno offline con lei. Ogni fase:
--   {"nome": "Andata", "data_inizio": "2026-10-05",
--    "data_fine": "2027-01-31", "obiettivo_metri": 18000,
--    "obiettivo_carico": 2400}
-- (gli obiettivi possono mancare).
-- ============================================================

alter table public.stagioni
  add column fasi jsonb not null default '[]'::jsonb
  check (jsonb_typeof(fasi) = 'array');
