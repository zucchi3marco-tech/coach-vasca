-- ============================================================
-- SCHEDA BENESSERE: l'atleta la compila prima di allenamento o partita
-- (per ora due domande: dolori e ore di sonno), l'allenatore del club la
-- legge. Una sola scheda per atleta al giorno: ricompilarla la aggiorna.
-- ============================================================

create table public.schede_benessere (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  data date not null,
  -- Impegno a cui si riferisce (facoltativo): il prossimo allenamento o
  -- la prossima partita al momento della compilazione.
  evento_tipo text check (evento_tipo in ('allenamento', 'partita')),
  evento_id uuid,
  dolori boolean not null,
  -- Zone del corpo (testo libero da elenco chiuso lato app) e intensita'
  -- 1-10: valorizzate solo se dolori = true.
  zone_dolore text[] not null default '{}',
  intensita_dolore smallint check (intensita_dolore between 1 and 10),
  ore_sonno numeric(3, 1) not null check (ore_sonno between 0 and 24),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (atleta_id, data),
  check (dolori or (intensita_dolore is null and zone_dolore = '{}'))
);

create index idx_schede_benessere_club_data
  on public.schede_benessere(club_id, data desc);

create trigger trg_schede_benessere_updated_at
before update on public.schede_benessere
for each row execute function public.set_updated_at();

-- club_id derivato dall'atleta, come per personal_best.
create trigger trg_schede_benessere_club
before insert or update of atleta_id on public.schede_benessere
for each row execute function public.imposta_club_da_atleta();

alter table public.schede_benessere enable row level security;

-- L'allenatore (membro del club) legge; l'atleta collegato legge e
-- scrive solo le proprie.
create policy schede_benessere_select on public.schede_benessere
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

create policy schede_benessere_insert on public.schede_benessere
  for insert with check (atleta_id = public.mia_atleta_id());

create policy schede_benessere_update on public.schede_benessere
  for update using (atleta_id = public.mia_atleta_id())
  with check (atleta_id = public.mia_atleta_id());

create policy schede_benessere_delete on public.schede_benessere
  for delete using (atleta_id = public.mia_atleta_id());
