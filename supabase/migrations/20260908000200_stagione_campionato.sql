-- ============================================================
-- CAMPIONATO SULLA STAGIONE (FASE 10, punto 1): non si sceglie piu'
-- partita per partita — si imposta una volta sulla stagione e le partite
-- con data compresa fra data_inizio/data_fine lo ereditano
-- automaticamente (calcolato lato app al salvataggio della partita).
-- ============================================================

alter table public.stagioni add column campionato text;
