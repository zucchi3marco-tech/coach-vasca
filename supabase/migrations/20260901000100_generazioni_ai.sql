-- ============================================================
-- STORICO GENERAZIONI AI (FASE 5, punto 6)
-- Traccia ogni chiamata al modulo "Genera con AI": parametri
-- inviati, esito (successo/errore), scheda ottenuta e se e'
-- stata poi salvata come allenamento vero. Serve a rivedere e
-- migliorare i prompt nel tempo, non e' dato operativo che
-- serve in vasca: nessuna cache locale Drift, si legge sempre
-- da remoto.
-- ============================================================

create table public.generazioni_ai (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  creato_da uuid references auth.users(id) on delete set null,
  parametri jsonb not null,
  esito text not null check (esito in ('successo', 'errore')),
  scheda jsonb,
  messaggio_errore text,
  allenamento_id uuid references public.allenamenti(id) on delete set null,
  created_at timestamptz not null default now()
);

create index idx_generazioni_ai_club on public.generazioni_ai(club_id);

alter table public.generazioni_ai enable row level security;

create policy generazioni_ai_select on public.generazioni_ai
  for select using (public.is_membro_club(club_id));

create policy generazioni_ai_insert on public.generazioni_ai
  for insert with check (public.is_membro_club(club_id));

-- Solo per collegare a posteriori l'allenamento salvato (nessun altro
-- campo dello storico e' pensato per essere modificato).
create policy generazioni_ai_update on public.generazioni_ai
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));
