-- ============================================================
-- ISCRITTI ALLE GARE (nuoto): quali atleti partecipano a una gara.
-- Stessa struttura di distinta_giocatori: il club è ricavato dalla
-- gara lato server e si verifica che l'atleta sia dello stesso club.
-- ============================================================

create table public.gara_iscritti (
  id uuid primary key default gen_random_uuid(),
  gara_id uuid not null references public.gare(id) on delete cascade,
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (gara_id, atleta_id)
);

create index idx_gara_iscritti_gara on public.gara_iscritti(gara_id);
create index idx_gara_iscritti_atleta on public.gara_iscritti(atleta_id);
create index idx_gara_iscritti_club on public.gara_iscritti(club_id);

create trigger trg_gara_iscritti_updated_at
before update on public.gara_iscritti
for each row execute function public.set_updated_at();

create or replace function public.imposta_e_valida_gara_iscritto()
returns trigger
language plpgsql
as $$
declare
  v_club_gara uuid;
  v_club_atleta uuid;
begin
  select club_id into v_club_gara from public.gare where id = new.gara_id;
  if v_club_gara is null then
    raise exception 'Gara % non trovata', new.gara_id;
  end if;

  select club_id into v_club_atleta from public.atleti where id = new.atleta_id;
  if v_club_atleta is null then
    raise exception 'Atleta % non trovato', new.atleta_id;
  end if;

  if v_club_atleta <> v_club_gara then
    raise exception 'Atleta e gara appartengono a club diversi';
  end if;

  new.club_id := v_club_gara;
  return new;
end;
$$;

create trigger trg_gara_iscritti_club
before insert or update of gara_id, atleta_id on public.gara_iscritti
for each row execute function public.imposta_e_valida_gara_iscritto();

alter table public.gara_iscritti enable row level security;

create policy gara_iscritti_select on public.gara_iscritti
  for select using (public.is_membro_club(club_id));

-- L'atleta collegato vede solo le proprie iscrizioni.
create policy gara_iscritti_select_atleta on public.gara_iscritti
  for select using (atleta_id = public.mia_atleta_id());

create policy gara_iscritti_insert on public.gara_iscritti
  for insert with check (public.is_membro_club(club_id));

create policy gara_iscritti_update on public.gara_iscritti
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy gara_iscritti_delete on public.gara_iscritti
  for delete using (public.is_membro_club(club_id));
