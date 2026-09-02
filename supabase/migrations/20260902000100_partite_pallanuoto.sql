-- ============================================================
-- PALLANUOTO V2 (FASE 7): PARTITE e DISTINTA
-- La distinta e' l'elenco ufficiale dei convocati per una partita
-- (numero di calottina, capitano/vice, portieri, fuoriquota), come da
-- modello FIN. Non e' il referto di gara (eventi, punteggio): quello
-- arriva in un punto successivo della roadmap.
-- ============================================================

-- Numero di tessera FIN dell'atleta: fisso per stagione, serve nella
-- distinta insieme al numero di calottina (che invece puo' cambiare
-- partita per partita).
alter table public.atleti add column numero_tessera_fin text;

create table public.partite (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  data date not null,
  ora text,
  luogo text,
  campionato text,
  colore_calottina text,
  squadra_casa text not null,
  squadra_trasferta text not null,
  numero_max_convocati integer not null default 15 check (numero_max_convocati in (13, 15)),
  note text,
  creato_da uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_partite_club_data on public.partite(club_id, data);

create trigger trg_partite_updated_at
before update on public.partite
for each row execute function public.set_updated_at();

alter table public.partite enable row level security;

create policy partite_select on public.partite
  for select using (public.is_membro_club(club_id));

create policy partite_insert on public.partite
  for insert with check (public.is_membro_club(club_id));

create policy partite_update on public.partite
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy partite_delete on public.partite
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- DISTINTA_GIOCATORI: una riga per atleta convocato in una partita.
-- club_id derivato dalla partita, con validazione incrociata che
-- l'atleta appartenga allo stesso club (stesso schema di "presenze").
-- ------------------------------------------------------------

create table public.distinta_giocatori (
  id uuid primary key default gen_random_uuid(),
  partita_id uuid not null references public.partite(id) on delete cascade,
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  numero_calottina integer not null check (numero_calottina > 0),
  capitano boolean not null default false,
  vice_capitano boolean not null default false,
  portiere boolean not null default false,
  fuoriquota boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (partita_id, atleta_id),
  unique (partita_id, numero_calottina)
);

create index idx_distinta_partita on public.distinta_giocatori(partita_id);
create index idx_distinta_atleta on public.distinta_giocatori(atleta_id);
create index idx_distinta_club on public.distinta_giocatori(club_id);

-- Un solo capitano e un solo vice capitano per partita.
create unique index idx_distinta_capitano_singolo on public.distinta_giocatori(partita_id) where capitano is true;
create unique index idx_distinta_vice_capitano_singolo on public.distinta_giocatori(partita_id) where vice_capitano is true;

create trigger trg_distinta_giocatori_updated_at
before update on public.distinta_giocatori
for each row execute function public.set_updated_at();

create or replace function public.imposta_e_valida_distinta_giocatore()
returns trigger
language plpgsql
as $$
declare
  v_club_partita uuid;
  v_club_atleta uuid;
begin
  select club_id into v_club_partita from public.partite where id = new.partita_id;
  if v_club_partita is null then
    raise exception 'Partita % non trovata', new.partita_id;
  end if;

  select club_id into v_club_atleta from public.atleti where id = new.atleta_id;
  if v_club_atleta is null then
    raise exception 'Atleta % non trovato', new.atleta_id;
  end if;

  if v_club_atleta <> v_club_partita then
    raise exception 'Atleta e partita appartengono a club diversi';
  end if;

  new.club_id := v_club_partita;
  return new;
end;
$$;

create trigger trg_distinta_giocatori_club
before insert or update of partita_id, atleta_id on public.distinta_giocatori
for each row execute function public.imposta_e_valida_distinta_giocatore();

-- Non si puo' superare il numero massimo di convocati impostato sulla partita.
create or replace function public.valida_numero_max_convocati()
returns trigger
language plpgsql
as $$
declare
  v_max integer;
  v_count integer;
begin
  select numero_max_convocati into v_max from public.partite where id = new.partita_id;
  select count(*) into v_count from public.distinta_giocatori where partita_id = new.partita_id;
  if v_count >= v_max then
    raise exception 'Numero massimo di convocati (%) gia'' raggiunto per questa partita', v_max;
  end if;
  return new;
end;
$$;

create trigger trg_distinta_giocatori_max_convocati
before insert on public.distinta_giocatori
for each row execute function public.valida_numero_max_convocati();

alter table public.distinta_giocatori enable row level security;

create policy distinta_giocatori_select on public.distinta_giocatori
  for select using (public.is_membro_club(club_id));

create policy distinta_giocatori_insert on public.distinta_giocatori
  for insert with check (public.is_membro_club(club_id));

create policy distinta_giocatori_update on public.distinta_giocatori
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy distinta_giocatori_delete on public.distinta_giocatori
  for delete using (public.is_membro_club(club_id));
