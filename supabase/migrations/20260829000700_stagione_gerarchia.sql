-- ============================================================
-- STAGIONI -> MACROCICLI -> MESOCICLI -> MICROCICLI
-- Gerarchia di programmazione (FASE 4). club_id e' sempre
-- derivato dal livello superiore per garantire coerenza.
-- ============================================================

create table public.stagioni (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  nome text not null,
  data_inizio date not null,
  data_fine date not null,
  obiettivo text,
  gruppo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (data_fine >= data_inizio)
);

create index idx_stagioni_club on public.stagioni(club_id);

create trigger trg_stagioni_updated_at
before update on public.stagioni
for each row execute function public.set_updated_at();

alter table public.stagioni enable row level security;

create policy stagioni_select on public.stagioni
  for select using (public.is_membro_club(club_id));

create policy stagioni_insert on public.stagioni
  for insert with check (public.is_membro_club(club_id));

create policy stagioni_update on public.stagioni
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy stagioni_delete on public.stagioni
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- MACROCICLI
-- ------------------------------------------------------------

create table public.macrocicli (
  id uuid primary key default gen_random_uuid(),
  stagione_id uuid not null references public.stagioni(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  nome text not null,
  ordine integer not null default 1,
  data_inizio date not null,
  data_fine date not null,
  obiettivo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (data_fine >= data_inizio)
);

create index idx_macrocicli_stagione on public.macrocicli(stagione_id);
create index idx_macrocicli_club on public.macrocicli(club_id);

create trigger trg_macrocicli_updated_at
before update on public.macrocicli
for each row execute function public.set_updated_at();

create or replace function public.imposta_club_da_stagione()
returns trigger
language plpgsql
as $$
begin
  select club_id into new.club_id from public.stagioni where id = new.stagione_id;
  if new.club_id is null then
    raise exception 'Stagione % non trovata', new.stagione_id;
  end if;
  return new;
end;
$$;

create trigger trg_macrocicli_club
before insert or update of stagione_id on public.macrocicli
for each row execute function public.imposta_club_da_stagione();

alter table public.macrocicli enable row level security;

create policy macrocicli_select on public.macrocicli
  for select using (public.is_membro_club(club_id));

create policy macrocicli_insert on public.macrocicli
  for insert with check (public.is_membro_club(club_id));

create policy macrocicli_update on public.macrocicli
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy macrocicli_delete on public.macrocicli
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- MESOCICLI
-- ------------------------------------------------------------

create table public.mesocicli (
  id uuid primary key default gen_random_uuid(),
  macrociclo_id uuid not null references public.macrocicli(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  nome text not null,
  ordine integer not null default 1,
  data_inizio date not null,
  data_fine date not null,
  obiettivo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (data_fine >= data_inizio)
);

create index idx_mesocicli_macrociclo on public.mesocicli(macrociclo_id);
create index idx_mesocicli_club on public.mesocicli(club_id);

create trigger trg_mesocicli_updated_at
before update on public.mesocicli
for each row execute function public.set_updated_at();

create or replace function public.imposta_club_da_macrociclo()
returns trigger
language plpgsql
as $$
begin
  select club_id into new.club_id from public.macrocicli where id = new.macrociclo_id;
  if new.club_id is null then
    raise exception 'Macrociclo % non trovato', new.macrociclo_id;
  end if;
  return new;
end;
$$;

create trigger trg_mesocicli_club
before insert or update of macrociclo_id on public.mesocicli
for each row execute function public.imposta_club_da_macrociclo();

alter table public.mesocicli enable row level security;

create policy mesocicli_select on public.mesocicli
  for select using (public.is_membro_club(club_id));

create policy mesocicli_insert on public.mesocicli
  for insert with check (public.is_membro_club(club_id));

create policy mesocicli_update on public.mesocicli
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy mesocicli_delete on public.mesocicli
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- MICROCICLI
-- ------------------------------------------------------------

create table public.microcicli (
  id uuid primary key default gen_random_uuid(),
  mesociclo_id uuid not null references public.mesocicli(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  nome text,
  numero_settimana integer,
  ordine integer not null default 1,
  data_inizio date not null,
  data_fine date not null,
  tipo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (data_fine >= data_inizio)
);

create index idx_microcicli_mesociclo on public.microcicli(mesociclo_id);
create index idx_microcicli_club on public.microcicli(club_id);

create trigger trg_microcicli_updated_at
before update on public.microcicli
for each row execute function public.set_updated_at();

create or replace function public.imposta_club_da_mesociclo()
returns trigger
language plpgsql
as $$
begin
  select club_id into new.club_id from public.mesocicli where id = new.mesociclo_id;
  if new.club_id is null then
    raise exception 'Mesociclo % non trovato', new.mesociclo_id;
  end if;
  return new;
end;
$$;

create trigger trg_microcicli_club
before insert or update of mesociclo_id on public.microcicli
for each row execute function public.imposta_club_da_mesociclo();

alter table public.microcicli enable row level security;

create policy microcicli_select on public.microcicli
  for select using (public.is_membro_club(club_id));

create policy microcicli_insert on public.microcicli
  for insert with check (public.is_membro_club(club_id));

create policy microcicli_update on public.microcicli
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy microcicli_delete on public.microcicli
  for delete using (public.is_membro_club(club_id));
