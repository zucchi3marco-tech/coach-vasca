-- ============================================================
-- FASE 8: STATISTICHE STAGIONALI (preparazione)
-- Per aggregare le statistiche di squadra/atleta serve sapere se il club
-- gioca in casa o in trasferta in ogni partita: campo esplicito (sempre
-- modificabile) invece di dedurlo dal nome squadra, che puo' differire
-- per sponsor/abbreviazioni/refertI compilati a mano.
-- ============================================================

alter table public.partite add column nostra_squadra text not null default 'casa' check (nostra_squadra in ('casa', 'trasferta'));
