-- ============================================================
-- PROFILO FISICO, passo A: altezza e peso (idea del coach del
-- 2026-10-25, scelte del 2026-10-29).
-- L'atleta scrive altezza e peso nel suo profilo, solo se vuole: una
-- riga per giorno, così si vede la crescita nella stagione. Sono dati
-- sulla salute: li leggono solo l'atleta e lo staff del club, e non
-- vanno mai all'AI (l'assistente non li legge).
-- Per chi ha meno di 18 anni serve il consenso di un genitore: lo segna
-- lo staff nella scheda dell'atleta, come un modulo di carta
-- (`consensi_profilo_fisico`). Senza consenso la sezione resta chiusa;
-- togliere il consenso cancella le misure dell'atleta minorenne.
-- Lo stesso consenso varrà per gli specialisti (passi B-D).
-- ============================================================

create table if not exists public.consensi_profilo_fisico (
  atleta_id uuid primary key references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  ricevuto_il date not null default current_date,
  segnato_da uuid default auth.uid(),
  created_at timestamptz not null default now()
);

drop trigger if exists trg_consensi_profilo_fisico_club
  on public.consensi_profilo_fisico;
create trigger trg_consensi_profilo_fisico_club
before insert or update of atleta_id on public.consensi_profilo_fisico
for each row execute function public.imposta_club_da_atleta();

create table if not exists public.misure_fisiche (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  data date not null default current_date
    check (data >= date '2000-01-01'),
  altezza_cm numeric(4, 1) check (altezza_cm between 80 and 230),
  peso_kg numeric(4, 1) check (peso_kg between 20 and 200),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (atleta_id, data),
  check (altezza_cm is not null or peso_kg is not null)
);

create index if not exists idx_misure_fisiche_atleta_data
  on public.misure_fisiche(atleta_id, data desc);

drop trigger if exists trg_misure_fisiche_updated_at on public.misure_fisiche;
create trigger trg_misure_fisiche_updated_at
before update on public.misure_fisiche
for each row execute function public.set_updated_at();

drop trigger if exists trg_misure_fisiche_club on public.misure_fisiche;
create trigger trg_misure_fisiche_club
before insert or update of atleta_id on public.misure_fisiche
for each row execute function public.imposta_club_da_atleta();

-- La sezione è aperta per l'atleta maggiorenne o con il consenso del
-- genitore.
create or replace function public.profilo_fisico_aperto(p_atleta_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.atleti a
    where a.id = p_atleta_id
      and (
        a.data_nascita <= (current_date - interval '18 years')::date
        or exists (
          select 1 from public.consensi_profilo_fisico c
          where c.atleta_id = a.id
        )
      )
  );
$$;

grant execute on function public.profilo_fisico_aperto(uuid) to authenticated;

-- Tolto il consenso, le misure di un minorenne non restano.
create or replace function public.togli_misure_senza_consenso()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.misure_fisiche m
  using public.atleti a
  where m.atleta_id = old.atleta_id
    and a.id = old.atleta_id
    and a.data_nascita > (current_date - interval '18 years')::date;
  return old;
end;
$$;

drop trigger if exists trg_consensi_profilo_fisico_togli
  on public.consensi_profilo_fisico;
create trigger trg_consensi_profilo_fisico_togli
after delete on public.consensi_profilo_fisico
for each row execute function public.togli_misure_senza_consenso();

alter table public.consensi_profilo_fisico enable row level security;
alter table public.misure_fisiche enable row level security;

-- Il consenso: lo segna e lo toglie lo staff; l'atleta legge il suo.
drop policy if exists consensi_profilo_fisico_select
  on public.consensi_profilo_fisico;
create policy consensi_profilo_fisico_select on public.consensi_profilo_fisico
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

drop policy if exists consensi_profilo_fisico_insert
  on public.consensi_profilo_fisico;
create policy consensi_profilo_fisico_insert on public.consensi_profilo_fisico
  for insert with check (public.is_membro_club(club_id));

drop policy if exists consensi_profilo_fisico_delete
  on public.consensi_profilo_fisico;
create policy consensi_profilo_fisico_delete on public.consensi_profilo_fisico
  for delete using (public.is_membro_club(club_id));

-- Le misure: lo staff legge; l'atleta legge, scrive e toglie le sue,
-- e scrive solo con la sezione aperta.
drop policy if exists misure_fisiche_select on public.misure_fisiche;
create policy misure_fisiche_select on public.misure_fisiche
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

drop policy if exists misure_fisiche_insert on public.misure_fisiche;
create policy misure_fisiche_insert on public.misure_fisiche
  for insert with check (
    atleta_id = public.mia_atleta_id()
    and public.profilo_fisico_aperto(atleta_id)
  );

drop policy if exists misure_fisiche_update on public.misure_fisiche;
create policy misure_fisiche_update on public.misure_fisiche
  for update using (atleta_id = public.mia_atleta_id())
  with check (
    atleta_id = public.mia_atleta_id()
    and public.profilo_fisico_aperto(atleta_id)
  );

drop policy if exists misure_fisiche_delete on public.misure_fisiche;
create policy misure_fisiche_delete on public.misure_fisiche
  for delete using (atleta_id = public.mia_atleta_id());
