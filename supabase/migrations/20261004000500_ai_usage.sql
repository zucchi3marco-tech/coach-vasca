-- ============================================================
-- RIPROGETTAZIONE AI, FASE 2: traccia ogni chiamata AI (chi, quale
-- funzione, quale modello, quando, quanti gettoni di testo) — tabella
-- nuova, non si riusa `generazioni_ai` (pensata per rivedere i prompt,
-- il suo campo "chi" non viene mai compilato). Usata per il tetto di
-- richieste settimanali per persona (vedi detta-allenamento/index.ts).
--
-- Scritta SOLO dalle Edge Function con la service_role key (bypassano
-- la RLS): nessuna policy di insert/update/delete per gli utenti
-- normali, solo lettura per il coach sul proprio club.
-- ============================================================

create table public.ai_usage (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  funzione text not null,
  modello text not null,
  gettoni integer,
  creato_il timestamptz not null default now()
);

create index idx_ai_usage_club on public.ai_usage(club_id);
create index idx_ai_usage_user_data on public.ai_usage(user_id, creato_il);

alter table public.ai_usage enable row level security;

create policy ai_usage_select on public.ai_usage
  for select using (public.is_membro_club(club_id));
