-- ============================================================
-- TEST_INGRESSO (Test_BVS_T30) e TABELLE_PASSI
-- club_id e' derivato automaticamente dal genitore (atleta/test),
-- cosi' non puo' essere falsificato dal client ne' disallineato.
-- ============================================================

create table public.test_ingresso (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  tipo public.tipo_test not null,
  data_test date not null default current_date,
  distanza_totale_m integer not null check (distanza_totale_m > 0),
  tempo_totale_s numeric(8, 2) not null check (tempo_totale_s > 0),
  -- Passo medio per 100m, base di calcolo per le tabelle_passi.
  passo_medio_100_s numeric(6, 2) generated always as
    (round(tempo_totale_s / distanza_totale_m * 100, 2)) stored,
  dettagli jsonb,
  note text,
  creato_da uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_test_ingresso_atleta on public.test_ingresso(atleta_id, data_test desc);
create index idx_test_ingresso_club on public.test_ingresso(club_id);

create trigger trg_test_ingresso_updated_at
before update on public.test_ingresso
for each row execute function public.set_updated_at();

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

create trigger trg_test_ingresso_club
before insert or update of atleta_id on public.test_ingresso
for each row execute function public.imposta_club_da_atleta();

alter table public.test_ingresso enable row level security;

create policy test_ingresso_select on public.test_ingresso
  for select using (public.is_membro_club(club_id));

create policy test_ingresso_insert on public.test_ingresso
  for insert with check (public.is_membro_club(club_id));

create policy test_ingresso_update on public.test_ingresso
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy test_ingresso_delete on public.test_ingresso
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- TABELLE_PASSI: passo target per ogni zona, derivato da un test.
-- ------------------------------------------------------------

create table public.tabelle_passi (
  id uuid primary key default gen_random_uuid(),
  test_id uuid not null references public.test_ingresso(id) on delete cascade,
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  zona public.zona_intensita not null,
  passo_100_s numeric(6, 2) not null check (passo_100_s > 0),
  percentuale_riferimento numeric(5, 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (test_id, zona)
);

create index idx_tabelle_passi_atleta on public.tabelle_passi(atleta_id);
create index idx_tabelle_passi_club on public.tabelle_passi(club_id);

create trigger trg_tabelle_passi_updated_at
before update on public.tabelle_passi
for each row execute function public.set_updated_at();

create or replace function public.imposta_da_test()
returns trigger
language plpgsql
as $$
begin
  select t.atleta_id, t.club_id into new.atleta_id, new.club_id
  from public.test_ingresso t where t.id = new.test_id;
  if new.club_id is null then
    raise exception 'Test % non trovato', new.test_id;
  end if;
  return new;
end;
$$;

create trigger trg_tabelle_passi_da_test
before insert or update of test_id on public.tabelle_passi
for each row execute function public.imposta_da_test();

alter table public.tabelle_passi enable row level security;

create policy tabelle_passi_select on public.tabelle_passi
  for select using (public.is_membro_club(club_id));

create policy tabelle_passi_insert on public.tabelle_passi
  for insert with check (public.is_membro_club(club_id));

create policy tabelle_passi_update on public.tabelle_passi
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy tabelle_passi_delete on public.tabelle_passi
  for delete using (public.is_membro_club(club_id));
