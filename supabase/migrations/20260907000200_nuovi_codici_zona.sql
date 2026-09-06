-- ============================================================
-- NUOVI CODICI ZONA (FASE 9): split della zona C in C1/C2/C3, piu'
-- granulare. "C" resta un valore valido dell'enum per compatibilita'
-- con le serie e le tabelle_passi gia' salvate (mai rimosso da un
-- enum Postgres in uso): semplicemente non viene piu' proposto nelle
-- schermate per le nuove serie (vedi SerieFormScreen).
--
-- Aggiunge anche "remate" all'esecuzione, per il lavoro di pallanuoto
-- (le altre voci — nuoto/gambe/braccia/pull/tecnica — esistevano gia').
-- ============================================================

alter type public.zona_intensita add value if not exists 'C1' after 'B2';
alter type public.zona_intensita add value if not exists 'C2' after 'C1';
alter type public.zona_intensita add value if not exists 'C3' after 'C2';

alter type public.esecuzione_serie add value if not exists 'remate';
