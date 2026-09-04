-- ============================================================
-- FASE 8: STATISTICHE — CONTESTO DEL TIRO
-- Per distinguere, nelle statistiche "da eventi live", i gol segnati in
-- superiorità numerica o su rigore da quelli in azione normale.
-- Rilevante solo per tipo = 'tiro' (ignorato per espulsione/superiorita).
-- ============================================================

alter table public.eventi_partita add column contesto_tiro text not null default 'azione' check (contesto_tiro in ('azione', 'superiorita', 'rigore'));
