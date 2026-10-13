-- ============================================================
-- PROGRAMMI A SECCO (Fase 4 del "Mako della pallanuoto", proposta 10,
-- secondo passo: i programmi di prevenzione a settimane)
--
-- Scelte del coach: un programma sono settimane di sedute a secco gia'
-- scritte (la seduta A, la B...), ognuna con le sue dosi: di settimana in
-- settimana un po' di piu', e qualche settimana di scarico con meno serie.
-- Si mette nel calendario di una squadra scegliendo il primo giorno e i
-- giorni della settimana: l'app crea le sedute a secco (allenamenti con
-- tipo 'secco' e i loro esercizi), che poi si cambiano una a una come le
-- altre. Il programma resta un modello: cambiarlo non cambia le sedute
-- gia' create.
-- ============================================================

create table if not exists public.programmi_secco (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  nome text not null check (length(trim(nome)) between 1 and 80),
  -- A cosa serve e come si usa.
  descrizione text check (descrizione is null or length(descrizione) <= 1000),
  -- I minuti di ogni seduta (quelli del carico del secco).
  durata_min integer not null default 20 check (durata_min between 1 and 600),
  -- Le settimane in ordine, ognuna con le sue sedute (la A, la B...) e gli
  -- esercizi di ogni seduta con le dosi, come le righe di
  -- `esercizi_seduta`:
  -- [{"scarico": false, "sedute": [[{"esercizio_id": "...", "serie": 3,
  --   "ripetizioni": 12, "durata_s": null, "carico": null,
  --   "recupero_s": 45, "note": null}, ...], ...]}, ...]
  settimane jsonb not null default '[]'::jsonb check (
    jsonb_typeof(settimane) = 'array'
    and jsonb_array_length(settimane) <= 26
  ),
  -- Il programma pronto da cui e' nato ('spalla_tiratore'...), null per
  -- uno dell'allenatore.
  modello text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (club_id, modello)
);

create index if not exists idx_programmi_secco_club on public.programmi_secco(club_id);

drop trigger if exists trg_programmi_secco_updated_at on public.programmi_secco;
create trigger trg_programmi_secco_updated_at
before update on public.programmi_secco
for each row execute function public.set_updated_at();

alter table public.programmi_secco enable row level security;

-- Solo gli allenatori: l'atleta vede le sedute nel calendario, non i
-- programmi.
drop policy if exists programmi_secco_select on public.programmi_secco;
create policy programmi_secco_select on public.programmi_secco
  for select using (public.is_membro_club(club_id));

drop policy if exists programmi_secco_insert on public.programmi_secco;
create policy programmi_secco_insert on public.programmi_secco
  for insert with check (public.is_membro_club(club_id));

drop policy if exists programmi_secco_update on public.programmi_secco;
create policy programmi_secco_update on public.programmi_secco
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

drop policy if exists programmi_secco_delete on public.programmi_secco;
create policy programmi_secco_delete on public.programmi_secco
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- Le sedute nate da un programma: di quale programma e di quale
-- settimana. Eliminando il programma le sedute restano.
-- ------------------------------------------------------------
alter table public.allenamenti
  add column if not exists programma_id uuid
    references public.programmi_secco(id) on delete set null,
  add column if not exists programma_settimana smallint;

alter table public.allenamenti drop constraint if exists allenamenti_programma_settimana_check;
alter table public.allenamenti add constraint allenamenti_programma_settimana_check
  check (programma_settimana is null or programma_settimana between 1 and 26);

create index if not exists idx_allenamenti_programma on public.allenamenti(programma_id);

-- Solo una seduta a secco fa parte di un programma, e di un programma
-- dello stesso club.
create or replace function public.valida_programma_allenamento()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.programma_id is null then
    return new;
  end if;
  if new.tipo <> 'secco' then
    raise exception 'Solo le sedute a secco fanno parte di un programma';
  end if;
  if not exists (
    select 1 from public.programmi_secco p
    where p.id = new.programma_id and p.club_id = new.club_id
  ) then
    raise exception 'Programma di un altro club';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_allenamenti_programma_valida on public.allenamenti;
create trigger trg_allenamenti_programma_valida
before insert or update of programma_id, tipo, club_id on public.allenamenti
for each row execute function public.valida_programma_allenamento();
