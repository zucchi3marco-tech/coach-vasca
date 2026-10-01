-- ============================================================
-- SCHEMI_TATTICI.GRUPPO_IDS: uno schema tattico puo' ora essere
-- assegnato a piu' gruppi contemporaneamente (prima una sola
-- colonna nullable `gruppo_id`, un solo gruppo o tutto il club).
-- Elenco jsonb invece di una tabella di giunzione: stesso schema
-- gia' usato da `referti_partita.giocatori_casa`/`parziali` (liste
-- jsonb scritte/lette con un insert/update diretto, senza passare
-- da una RPC) — una riga sostituisce l'intero elenco in un colpo
-- solo, niente da riconciliare quando una scrittura va in coda
-- offline. Lista vuota = visibile a tutto il club, stessa semantica
-- di prima con `gruppo_id is null`.
-- ============================================================

alter table public.schemi_tattici
  add column gruppo_ids jsonb not null default '[]'::jsonb;

update public.schemi_tattici
  set gruppo_ids = jsonb_build_array(gruppo_id)
  where gruppo_id is not null;

alter table public.schemi_tattici drop column gruppo_id;
