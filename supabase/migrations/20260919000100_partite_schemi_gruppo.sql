-- ============================================================
-- Isolamento per gruppo, estensione a Partite e Schemi tattici
-- (FASE — richiesta 2026-09-19): finora questi due domini non
-- avevano affatto il concetto di gruppo (erano condivisi per tutto il
-- club by design). Stesso pattern già usato per allenamenti/stagioni
-- (migrazione 20260909000100_gruppi.sql): colonna nullable, nessun
-- vincolo di RLS aggiuntivo (l'isolamento per gruppo è un filtro
-- applicato lato app, non un confine di sicurezza — quello resta il
-- club, già garantito da is_membro_club).
-- ============================================================

alter table public.partite
  add column gruppo_id uuid references public.gruppi(id) on delete set null;

alter table public.schemi_tattici
  add column gruppo_id uuid references public.gruppi(id) on delete set null;
