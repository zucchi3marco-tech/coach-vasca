-- ============================================================
-- GARE (nuoto): l'evento di calendario del nuoto, come la partita
-- lo è per la pallanuoto. Si crea dal calendario della stagione
-- (tocco su un giorno). gruppo_id nullo = gara di tutto il club,
-- visibile a ogni gruppo e a ogni atleta; con gruppo = solo quel
-- gruppo (stessa regola di partite e schemi tattici: l'isolamento per
-- gruppo è un filtro dell'app, il confine di sicurezza resta il club).
-- ============================================================

create table public.gare (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  gruppo_id uuid references public.gruppi(id) on delete set null,
  data date not null,
  ora text,
  luogo text,
  nome text not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_gare_club_data on public.gare(club_id, data);

create trigger trg_gare_updated_at
before update on public.gare
for each row execute function public.set_updated_at();

alter table public.gare enable row level security;

-- Il coach (membro del club) legge e scrive; l'atleta collegato solo
-- legge (per i suoi prossimi eventi).
create policy gare_select on public.gare
  for select using (public.is_membro_club(club_id));

create policy gare_select_atleta on public.gare
  for select using (club_id = public.mio_club_atleta());

create policy gare_insert on public.gare
  for insert with check (public.is_membro_club(club_id));

create policy gare_update on public.gare
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy gare_delete on public.gare
  for delete using (public.is_membro_club(club_id));
