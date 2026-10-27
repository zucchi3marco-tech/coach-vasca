-- ============================================================
-- IMPEGNI (proposta 18 passo A, «Piano di WaterTactics» periodo 3,
-- 2026-10-27): quello che non è un allenamento, una partita o una gara
-- ma occupa dei giorni del calendario. Collegiale, trasferta, riposo
-- (anche piscina chiusa e vacanze), torneo, altro (con un nome).
-- Dal giorno al giorno, anche uno solo. gruppo_id nullo = di tutto il
-- club (stessa regola di partite e gare: l'isolamento per gruppo è un
-- filtro dell'app, il confine di sicurezza resta il club).
-- Scelte del coach: li vedono staff e atleti nell'app, non il calendario
-- del telefono; su un giorno di riposo un allenamento si salva con un
-- avviso. Le selezioni con atleti di altri club vengono dopo, con i club
-- pilota.
-- ============================================================

create table if not exists public.impegni (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  gruppo_id uuid references public.gruppi(id) on delete set null,
  tipo text not null
    check (tipo in ('collegiale', 'trasferta', 'riposo', 'torneo', 'altro')),
  dal date not null,
  al date not null,
  nome text check (nome is null or char_length(nome) <= 80),
  luogo text check (luogo is null or char_length(luogo) <= 120),
  note text check (note is null or char_length(note) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (al >= dal),
  check (al - dal <= 366),
  -- «Altro» si riconosce solo dal nome.
  check (tipo <> 'altro' or char_length(trim(coalesce(nome, ''))) > 0)
);

create index if not exists idx_impegni_club_dal on public.impegni(club_id, dal);

drop trigger if exists trg_impegni_updated_at on public.impegni;
create trigger trg_impegni_updated_at
before update on public.impegni
for each row execute function public.set_updated_at();

alter table public.impegni enable row level security;

-- Lo staff (membri del club) legge e scrive; l'atleta collegato legge.
drop policy if exists impegni_select on public.impegni;
create policy impegni_select on public.impegni
  for select using (public.is_membro_club(club_id));

drop policy if exists impegni_select_atleta on public.impegni;
create policy impegni_select_atleta on public.impegni
  for select using (club_id = public.mio_club_atleta());

drop policy if exists impegni_insert on public.impegni;
create policy impegni_insert on public.impegni
  for insert with check (public.is_membro_club(club_id));

drop policy if exists impegni_update on public.impegni;
create policy impegni_update on public.impegni
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

drop policy if exists impegni_delete on public.impegni;
create policy impegni_delete on public.impegni
  for delete using (public.is_membro_club(club_id));
