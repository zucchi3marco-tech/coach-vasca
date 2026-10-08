-- ============================================================
-- Altre due esecuzioni (richiesta del coach 2026-10-08, dalla guida
-- "Come si scrive"): "partita" (pallanuoto, a tempo, senza stile) e
-- "test" (un test cronometrico, con lo stile). Stessa procedura di
-- 20261008000200_esecuzioni_pallanuoto.sql.
-- ============================================================

alter type public.esecuzione_serie add value if not exists 'partita';
alter type public.esecuzione_serie add value if not exists 'test';
