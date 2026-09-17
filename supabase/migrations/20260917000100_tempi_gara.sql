-- ============================================================
-- TEMPI GARA (nuoto): storico dei tempi nuotati per stile+distanza,
-- con data e lunghezza vasca (25 o 50 m) — a differenza di
-- personal_best (un solo tempo, il migliore, sovrascritto ad ogni
-- modifica), qui ogni tempo inserito resta una voce separata nello
-- storico, per costruire la curva delle prestazioni nel tempo.
-- Stesso schema di permessi di personal_best (coach o atleta stesso).
-- ============================================================

create table public.tempi_gara (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  stile text not null,
  distanza_m integer not null check (distanza_m > 0),
  vasca_m integer not null check (vasca_m in (25, 50)),
  tempo_s numeric(7, 2) not null check (tempo_s > 0),
  data date not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_tempi_gara_atleta on public.tempi_gara(atleta_id);
create index idx_tempi_gara_club on public.tempi_gara(club_id);

create trigger trg_tempi_gara_updated_at
before update on public.tempi_gara
for each row execute function public.set_updated_at();

-- club_id derivato dall'atleta (stesso pattern di personal_best).
create trigger trg_tempi_gara_club
before insert or update of atleta_id on public.tempi_gara
for each row execute function public.imposta_club_da_atleta();

alter table public.tempi_gara enable row level security;

-- Il coach (membro del club) legge e scrive; l'atleta collegato legge e
-- scrive solo i propri (stesso schema finale di personal_best).
create policy tempi_gara_select on public.tempi_gara
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

create policy tempi_gara_insert on public.tempi_gara
  for insert with check (
    atleta_id = public.mia_atleta_id() or public.is_membro_club(club_id)
  );

create policy tempi_gara_update on public.tempi_gara
  for update using (
    atleta_id = public.mia_atleta_id() or public.is_membro_club(club_id)
  )
  with check (
    atleta_id = public.mia_atleta_id() or public.is_membro_club(club_id)
  );

create policy tempi_gara_delete on public.tempi_gara
  for delete using (
    atleta_id = public.mia_atleta_id() or public.is_membro_club(club_id)
  );
