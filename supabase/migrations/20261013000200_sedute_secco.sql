-- ============================================================
-- SEDUTE A SECCO (Fase 4 del "Mako della pallanuoto", proposta 10, primo
-- passo)
--
-- Nella pallanuoto la preparazione a secco e' strutturale: forza,
-- prevenzione della spalla, gambe per la bicicletta. Scelte del coach:
-- una seduta a secco e' una seduta a parte nel calendario (un allenamento
-- con tipo 'secco'), con gli esercizi al posto delle serie; presenze,
-- domanda di fine seduta (RPE) e carico funzionano come per l'acqua, e il
-- carico va nella colonna del secco. Gli esercizi vengono dall'elenco del
-- club, che parte da un elenco pronto (spalla, scapole, core, gambe,
-- mobilita', forza) e cresce con quelli dell'allenatore.
-- ============================================================

-- Il tipo della seduta e, per il secco, quanto dura (i minuti del carico:
-- per l'acqua si stimano dalle serie).
alter table public.allenamenti
  add column if not exists tipo text not null default 'acqua',
  add column if not exists durata_min integer;

alter table public.allenamenti drop constraint if exists allenamenti_tipo_check;
alter table public.allenamenti add constraint allenamenti_tipo_check
  check (tipo in ('acqua', 'secco'));

alter table public.allenamenti drop constraint if exists allenamenti_durata_min_check;
alter table public.allenamenti add constraint allenamenti_durata_min_check
  check (durata_min is null or durata_min between 1 and 600);

-- ------------------------------------------------------------
-- L'elenco degli esercizi del club.
-- ------------------------------------------------------------
create table if not exists public.esercizi_secco (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  nome text not null check (length(trim(nome)) between 1 and 80),
  -- Per che cosa: spalla (cuffia dei rotatori), scapole, core, gambe (la
  -- bicicletta), forza, mobilita', altro.
  categoria text not null check (
    categoria in ('spalla', 'scapole', 'core', 'gambe', 'forza', 'mobilita', 'altro')
  ),
  -- Si conta a ripetizioni o a tempo (un plank).
  misura text not null default 'ripetizioni' check (misura in ('ripetizioni', 'tempo')),
  attrezzo text check (attrezzo is null or length(attrezzo) <= 80),
  -- Come si fa.
  descrizione text check (descrizione is null or length(descrizione) <= 1000),
  -- L'esercizio pronto da cui e' nato ('extrarotazione_elastico'...), null
  -- per uno dell'allenatore.
  modello text,
  archiviato boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (club_id, modello)
);

create index if not exists idx_esercizi_secco_club on public.esercizi_secco(club_id);

drop trigger if exists trg_esercizi_secco_updated_at on public.esercizi_secco;
create trigger trg_esercizi_secco_updated_at
before update on public.esercizi_secco
for each row execute function public.set_updated_at();

alter table public.esercizi_secco enable row level security;

-- L'atleta li legge: nome e come si fa non sono dati di nessuno.
drop policy if exists esercizi_secco_select on public.esercizi_secco;
create policy esercizi_secco_select on public.esercizi_secco
  for select using (
    public.is_membro_club(club_id) or club_id = public.mio_club_atleta()
  );

drop policy if exists esercizi_secco_insert on public.esercizi_secco;
create policy esercizi_secco_insert on public.esercizi_secco
  for insert with check (public.is_membro_club(club_id));

drop policy if exists esercizi_secco_update on public.esercizi_secco;
create policy esercizi_secco_update on public.esercizi_secco
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

drop policy if exists esercizi_secco_delete on public.esercizi_secco;
create policy esercizi_secco_delete on public.esercizi_secco
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- Gli esercizi di una seduta a secco: quante serie, ripetizioni o tempo,
-- con che carico ("8 kg", "elastico rosso"), quanto recupero.
-- ------------------------------------------------------------
create table if not exists public.esercizi_seduta (
  id uuid primary key default gen_random_uuid(),
  allenamento_id uuid not null references public.allenamenti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  -- Un esercizio usato in una seduta non si elimina dall'elenco: si
  -- archivia.
  esercizio_id uuid not null references public.esercizi_secco(id) on delete restrict,
  ordine integer not null,
  serie smallint not null default 3 check (serie between 1 and 20),
  ripetizioni smallint check (ripetizioni is null or ripetizioni between 1 and 500),
  durata_s integer check (durata_s is null or durata_s between 1 and 3600),
  carico text check (carico is null or length(carico) <= 40),
  recupero_s integer check (recupero_s is null or recupero_s between 0 and 900),
  note text check (note is null or length(note) <= 300),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((ripetizioni is null) <> (durata_s is null))
);

create index if not exists idx_esercizi_seduta_allenamento on public.esercizi_seduta(allenamento_id);
create index if not exists idx_esercizi_seduta_club on public.esercizi_seduta(club_id);

drop trigger if exists trg_esercizi_seduta_updated_at on public.esercizi_seduta;
create trigger trg_esercizi_seduta_updated_at
before update on public.esercizi_seduta
for each row execute function public.set_updated_at();

-- Il club viene dalla seduta (che dev'essere a secco), e l'esercizio
-- dev'essere dello stesso club.
create or replace function public.valida_esercizio_seduta()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_club uuid;
  v_tipo text;
begin
  select club_id, tipo into v_club, v_tipo
    from public.allenamenti where id = new.allenamento_id;
  if v_club is null then
    raise exception 'Seduta non trovata';
  end if;
  if v_tipo <> 'secco' then
    raise exception 'Gli esercizi stanno solo nelle sedute a secco';
  end if;
  new.club_id := v_club;
  if not exists (
    select 1 from public.esercizi_secco e
    where e.id = new.esercizio_id and e.club_id = v_club
  ) then
    raise exception 'Esercizio di un altro club';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_esercizi_seduta_valida on public.esercizi_seduta;
create trigger trg_esercizi_seduta_valida
before insert or update on public.esercizi_seduta
for each row execute function public.valida_esercizio_seduta();

alter table public.esercizi_seduta enable row level security;

-- L'atleta non legge la tabella (le note sono per l'allenatore, come per
-- le serie): passa da `esercizi_seduta_atleta`.
drop policy if exists esercizi_seduta_select on public.esercizi_seduta;
create policy esercizi_seduta_select on public.esercizi_seduta
  for select using (public.is_membro_club(club_id));

drop policy if exists esercizi_seduta_insert on public.esercizi_seduta;
create policy esercizi_seduta_insert on public.esercizi_seduta
  for insert with check (public.is_membro_club(club_id));

drop policy if exists esercizi_seduta_update on public.esercizi_seduta;
create policy esercizi_seduta_update on public.esercizi_seduta
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

drop policy if exists esercizi_seduta_delete on public.esercizi_seduta;
create policy esercizi_seduta_delete on public.esercizi_seduta
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- Per l'atleta collegato.
-- ------------------------------------------------------------

-- Gli esercizi di una seduta del suo club (del suo gruppo o senza
-- gruppo), con come si fa e senza le note: stessa regola di
-- `serie_allenamento_atleta`.
create or replace function public.esercizi_seduta_atleta(p_allenamento_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  esercizio_id uuid,
  ordine integer,
  nome text,
  categoria text,
  misura text,
  attrezzo text,
  descrizione text,
  serie smallint,
  ripetizioni smallint,
  durata_s integer,
  carico text,
  recupero_s integer
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.esercizio_id, s.ordine, e.nome,
         e.categoria, e.misura, e.attrezzo, e.descrizione, s.serie,
         s.ripetizioni, s.durata_s, s.carico, s.recupero_s
  from public.esercizi_seduta s
  join public.esercizi_secco e on e.id = s.esercizio_id
  join public.allenamenti a on a.id = s.allenamento_id
  join public.atleti at on at.user_id = auth.uid() and at.club_id = a.club_id
  where s.allenamento_id = p_allenamento_id
    and (a.gruppo_id is null or at.gruppo_id is null or a.gruppo_id = at.gruppo_id)
  order by s.ordine;
$$;

grant execute on function public.esercizi_seduta_atleta(uuid) to authenticated;

-- Le sedute che l'atleta vede in calendario: anche il tipo e la durata
-- (cambia cosa restituisce: si ricrea).
drop function if exists public.allenamenti_atleta();
create function public.allenamenti_atleta()
returns table (
  id uuid,
  club_id uuid,
  data date,
  titolo text,
  gruppo_id uuid,
  tipo text,
  durata_min integer
)
language sql
stable
security definer
set search_path = public
as $$
  select a.id, a.club_id, a.data, a.titolo, a.gruppo_id, a.tipo, a.durata_min
  from public.allenamenti a
  join public.atleti at on at.user_id = auth.uid()
  where a.club_id = at.club_id;
$$;

grant execute on function public.allenamenti_atleta() to authenticated;

-- Il carico: una seduta a secco vale i suoi minuti nella colonna del
-- secco, quindi servono tipo e durata.
drop function if exists public.allenamenti_per_carico(uuid);
create function public.allenamenti_per_carico(p_club_id uuid)
returns table (id uuid, data date, tipo text, durata_min integer)
language sql
stable
security definer
set search_path = public
as $$
  select a.id, a.data, a.tipo, a.durata_min
  from public.allenamenti a
  where a.club_id = p_club_id
    and (
      public.is_membro_club(p_club_id)
      or p_club_id = public.mio_club_atleta()
    );
$$;

grant execute on function public.allenamenti_per_carico(uuid) to authenticated;
