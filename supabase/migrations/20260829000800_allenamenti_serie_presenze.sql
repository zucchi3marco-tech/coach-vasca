-- ============================================================
-- ALLENAMENTI -> SERIE, e PRESENZE
-- Un allenamento puo' esistere senza essere agganciato a un
-- microciclo (scheda manuale, FASE 2, prima ancora del calendario
-- di stagione della FASE 4).
-- ============================================================

create table public.allenamenti (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  microciclo_id uuid references public.microcicli(id) on delete set null,
  data date not null,
  titolo text,
  gruppo text,
  note text,
  creato_da uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_allenamenti_club_data on public.allenamenti(club_id, data);
create index idx_allenamenti_microciclo on public.allenamenti(microciclo_id);

create trigger trg_allenamenti_updated_at
before update on public.allenamenti
for each row execute function public.set_updated_at();

-- Se l'allenamento e' agganciato a un microciclo, deve appartenere allo stesso club.
-- club_id resta il campo autoritativo (impostato dal client/RLS), qui si valida soltanto.
create or replace function public.valida_club_microciclo()
returns trigger
language plpgsql
as $$
declare
  v_club_microciclo uuid;
begin
  if new.microciclo_id is not null then
    select club_id into v_club_microciclo from public.microcicli where id = new.microciclo_id;
    if v_club_microciclo is null then
      raise exception 'Microciclo % non trovato', new.microciclo_id;
    end if;
    if v_club_microciclo <> new.club_id then
      raise exception 'Il microciclo appartiene a un club diverso dall''allenamento';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_allenamenti_valida_microciclo
before insert or update of microciclo_id, club_id on public.allenamenti
for each row execute function public.valida_club_microciclo();

alter table public.allenamenti enable row level security;

create policy allenamenti_select on public.allenamenti
  for select using (public.is_membro_club(club_id));

create policy allenamenti_insert on public.allenamenti
  for insert with check (public.is_membro_club(club_id));

create policy allenamenti_update on public.allenamenti
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy allenamenti_delete on public.allenamenti
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- Deriva club_id da un allenamento (usata da serie; presenze ha
-- una variante dedicata piu' sotto perche' valida anche l'atleta).
-- ------------------------------------------------------------

create or replace function public.imposta_club_da_allenamento()
returns trigger
language plpgsql
as $$
begin
  select club_id into new.club_id from public.allenamenti where id = new.allenamento_id;
  if new.club_id is null then
    raise exception 'Allenamento % non trovato', new.allenamento_id;
  end if;
  return new;
end;
$$;

-- ------------------------------------------------------------
-- SERIE: righe della scheda (riscaldamento/principale/defaticamento).
-- ------------------------------------------------------------

create table public.serie (
  id uuid primary key default gen_random_uuid(),
  allenamento_id uuid not null references public.allenamenti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  ordine integer not null default 1,
  blocco public.blocco_serie not null default 'principale',
  ripetute integer not null default 1 check (ripetute > 0),
  distanza_m integer not null check (distanza_m > 0),
  zona public.zona_intensita,
  passo_obiettivo_s numeric(6, 2),
  recupero_s integer check (recupero_s >= 0),
  attrezzatura text,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_serie_allenamento on public.serie(allenamento_id, ordine);
create index idx_serie_club on public.serie(club_id);

create trigger trg_serie_updated_at
before update on public.serie
for each row execute function public.set_updated_at();

create trigger trg_serie_club
before insert or update of allenamento_id on public.serie
for each row execute function public.imposta_club_da_allenamento();

alter table public.serie enable row level security;

create policy serie_select on public.serie
  for select using (public.is_membro_club(club_id));

create policy serie_insert on public.serie
  for insert with check (public.is_membro_club(club_id));

create policy serie_update on public.serie
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy serie_delete on public.serie
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- PRESENZE: una riga per atleta per allenamento.
-- club_id derivato dall'allenamento, con validazione incrociata
-- che l'atleta appartenga allo stesso club.
-- ------------------------------------------------------------

create table public.presenze (
  id uuid primary key default gen_random_uuid(),
  allenamento_id uuid not null references public.allenamenti(id) on delete cascade,
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  stato public.stato_presenza not null default 'presente',
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (allenamento_id, atleta_id)
);

create index idx_presenze_allenamento on public.presenze(allenamento_id);
create index idx_presenze_atleta on public.presenze(atleta_id);
create index idx_presenze_club on public.presenze(club_id);

create trigger trg_presenze_updated_at
before update on public.presenze
for each row execute function public.set_updated_at();

create or replace function public.imposta_e_valida_presenza()
returns trigger
language plpgsql
as $$
declare
  v_club_allenamento uuid;
  v_club_atleta uuid;
begin
  select club_id into v_club_allenamento from public.allenamenti where id = new.allenamento_id;
  if v_club_allenamento is null then
    raise exception 'Allenamento % non trovato', new.allenamento_id;
  end if;

  select club_id into v_club_atleta from public.atleti where id = new.atleta_id;
  if v_club_atleta is null then
    raise exception 'Atleta % non trovato', new.atleta_id;
  end if;

  if v_club_atleta <> v_club_allenamento then
    raise exception 'Atleta e allenamento appartengono a club diversi';
  end if;

  new.club_id := v_club_allenamento;
  return new;
end;
$$;

create trigger trg_presenze_club
before insert or update of allenamento_id, atleta_id on public.presenze
for each row execute function public.imposta_e_valida_presenza();

alter table public.presenze enable row level security;

create policy presenze_select on public.presenze
  for select using (public.is_membro_club(club_id));

create policy presenze_insert on public.presenze
  for insert with check (public.is_membro_club(club_id));

create policy presenze_update on public.presenze
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy presenze_delete on public.presenze
  for delete using (public.is_membro_club(club_id));
