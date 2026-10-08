-- ============================================================
-- Nuove esecuzioni di pallanuoto (richiesta del coach 2026-10-08,
-- provando "Scrivi l'allenamento"): palleggio, tiri, uomo in più, uomo
-- in meno, gioco da schierati, schemi. Stessa procedura di "remate" e
-- di "pallanuoto tecnico-tattico" / "a secco"
-- (20261004000100_esecuzione_tecnico_tattico_secco.sql).
-- ============================================================

alter type public.esecuzione_serie add value if not exists 'palleggio';
alter type public.esecuzione_serie add value if not exists 'tiri';
alter type public.esecuzione_serie add value if not exists 'uomo in più';
alter type public.esecuzione_serie add value if not exists 'uomo in meno';
alter type public.esecuzione_serie add value if not exists 'gioco da schierati';
alter type public.esecuzione_serie add value if not exists 'schemi';
