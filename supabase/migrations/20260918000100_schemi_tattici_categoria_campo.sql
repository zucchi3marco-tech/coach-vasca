-- ============================================================
-- SCHEMI TATTICI: categoria (gruppo libero scelto dall'allenatore,
-- es. "Transizioni", "Superiorità", "Inferiorità", "Difesa",
-- "Attacco" — non un elenco chiuso, l'allenatore può crearne quante
-- ne vuole) e campo (intero o solo metà campo) — FASE 16, revisione
-- della lavagna tattica dopo il primo giro d'uso.
-- ============================================================

alter table public.schemi_tattici
  add column categoria text not null default '',
  add column campo text not null default 'intero' check (campo in ('intero', 'meta'));

create index idx_schemi_tattici_categoria on public.schemi_tattici(club_id, categoria);
