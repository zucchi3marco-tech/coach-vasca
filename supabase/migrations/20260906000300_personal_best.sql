-- ============================================================
-- PERSONAL BEST (FASE 9): l'atleta inserisce i propri PB, il coach
-- li vede ma non li modifica.
-- ============================================================

create table public.personal_best (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  stile text not null,
  distanza_m integer not null check (distanza_m > 0),
  tempo_s numeric(7, 2) not null check (tempo_s > 0),
  data date,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_personal_best_atleta on public.personal_best(atleta_id);
create index idx_personal_best_club on public.personal_best(club_id);

create trigger trg_personal_best_updated_at
before update on public.personal_best
for each row execute function public.set_updated_at();

-- club_id derivato dall'atleta (stesso pattern di imposta_club_da_allenamento).
create or replace function public.imposta_club_da_atleta()
returns trigger
language plpgsql
as $$
begin
  select club_id into new.club_id from public.atleti where id = new.atleta_id;
  if new.club_id is null then
    raise exception 'Atleta % non trovato', new.atleta_id;
  end if;
  return new;
end;
$$;

create trigger trg_personal_best_club
before insert or update of atleta_id on public.personal_best
for each row execute function public.imposta_club_da_atleta();

alter table public.personal_best enable row level security;

-- Il coach (membro del club) legge; l'atleta collegato legge e scrive
-- solo i propri.
create policy personal_best_select on public.personal_best
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

create policy personal_best_insert on public.personal_best
  for insert with check (atleta_id = public.mia_atleta_id());

create policy personal_best_update on public.personal_best
  for update using (atleta_id = public.mia_atleta_id())
  with check (atleta_id = public.mia_atleta_id());

create policy personal_best_delete on public.personal_best
  for delete using (atleta_id = public.mia_atleta_id());
