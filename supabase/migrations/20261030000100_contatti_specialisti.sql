-- ============================================================
-- PROFILO FISICO, passo D: la traccia dei contatti con gli specialisti
-- (scelte del coach del 2026-10-29 e del 2026-10-30).
-- Ogni atleta ha un codice suo, sempre lo stesso («WT-4K7Q»): va nel
-- messaggio WhatsApp già scritto, o lo dice alla prima visita se
-- passa dal sito. Quando l'atleta tocca «Scrivi su WhatsApp» o «Apri il
-- sito» si segna il contatto: atleta, specialista, giorno, tipo di
-- problema, canale e codice (due tocchi allo stesso specialista nello
-- stesso giorno sono un contatto solo). Lo legge solo il responsabile
-- del club, che spunta le visite che lo specialista gli conferma: su
-- queste si calcola la royalty.
-- Lo registra solo l'atleta maggiorenne o con il consenso del genitore
-- (`profilo_fisico_aperto`); togliere il consenso non cancella i
-- contatti già fatti (scelta del coach).
-- Si scrive solo dalle due funzioni qui sotto: nessuna policy di
-- inserimento sulle tabelle.
-- ============================================================

create table if not exists public.codici_specialisti (
  atleta_id uuid primary key references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  codice text not null unique check (codice ~ '^WT-[A-Z0-9]{4}$'),
  created_at timestamptz not null default now()
);

create table if not exists public.contatti_specialisti (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  -- Il nome e il tipo restano anche se lo specialista si toglie, per la
  -- royalty dei mesi passati.
  specialista_id uuid references public.specialisti(id) on delete set null,
  specialista_nome text not null,
  specialista_tipo text not null check (
    specialista_tipo in (
      'nutrizionista', 'fisioterapista', 'osteopata', 'massoterapista'
    )
  ),
  problema text not null check (
    problema in ('dolore', 'rigidita', 'gambe', 'energia', 'non_lo_so')
  ),
  canale text not null check (canale in ('whatsapp', 'sito')),
  codice text not null,
  giorno date not null default current_date,
  visita_confermata_il date,
  created_at timestamptz not null default now(),
  unique (atleta_id, specialista_id, giorno)
);

create index if not exists idx_contatti_specialisti_club_giorno
  on public.contatti_specialisti(club_id, giorno desc);

alter table public.codici_specialisti enable row level security;
alter table public.contatti_specialisti enable row level security;

-- Il codice: l'atleta legge il suo.
drop policy if exists codici_specialisti_select on public.codici_specialisti;
create policy codici_specialisti_select on public.codici_specialisti
  for select using (atleta_id = public.mia_atleta_id());

-- I contatti: solo il responsabile li legge e spunta la visita.
drop policy if exists contatti_specialisti_select
  on public.contatti_specialisti;
create policy contatti_specialisti_select on public.contatti_specialisti
  for select using (public.is_owner_club(club_id));

drop policy if exists contatti_specialisti_update
  on public.contatti_specialisti;
create policy contatti_specialisti_update on public.contatti_specialisti
  for update using (public.is_owner_club(club_id))
  with check (public.is_owner_club(club_id));

-- Del contatto si cambia solo la spunta della visita.
revoke insert, update, delete on public.codici_specialisti from authenticated, anon;
revoke insert, update, delete on public.contatti_specialisti from authenticated, anon;
grant update (visita_confermata_il) on public.contatti_specialisti to authenticated;

-- Il codice dell'atleta collegato: lo crea la prima volta.
create or replace function public.mio_codice_specialisti()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_atleta uuid := public.mia_atleta_id();
  v_club uuid;
  v_codice text;
  v_lettere constant text := 'ACDEFGHJKLMNPQRTUVWXY34679';
begin
  if v_atleta is null then
    raise exception 'Solo un atleta ha il codice per gli specialisti'
      using errcode = '42501';
  end if;
  select codice into v_codice
  from public.codici_specialisti where atleta_id = v_atleta;
  if v_codice is not null then
    return v_codice;
  end if;
  select club_id into v_club from public.atleti where id = v_atleta;
  loop
    v_codice := 'WT-' || (
      select string_agg(
        substr(v_lettere, 1 + floor(random() * length(v_lettere))::int, 1),
        ''
      )
      from generate_series(1, 4)
    );
    begin
      insert into public.codici_specialisti (atleta_id, club_id, codice)
      values (v_atleta, v_club, v_codice)
      on conflict (atleta_id) do nothing;
      exit;
    exception when unique_violation then
      -- Codice già di un altro atleta: se ne prova un altro.
    end;
  end loop;
  select codice into v_codice
  from public.codici_specialisti where atleta_id = v_atleta;
  return v_codice;
end;
$$;

grant execute on function public.mio_codice_specialisti() to authenticated;

-- Segna il contatto dell'atleta collegato con uno specialista del suo
-- club. Due tocchi nello stesso giorno sono un contatto solo.
create or replace function public.registra_contatto_specialista(
  p_specialista_id uuid,
  p_problema text,
  p_canale text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_atleta uuid := public.mia_atleta_id();
  v_specialista public.specialisti%rowtype;
  v_codice text;
begin
  if v_atleta is null then
    raise exception 'Solo un atleta contatta gli specialisti'
      using errcode = '42501';
  end if;
  if not public.profilo_fisico_aperto(v_atleta) then
    raise exception 'Serve il consenso del genitore' using errcode = '42501';
  end if;
  select s.* into v_specialista
  from public.specialisti s
  join public.atleti a on a.club_id = s.club_id
  where s.id = p_specialista_id and a.id = v_atleta;
  if not found then
    raise exception 'Specialista non del tuo club' using errcode = '42501';
  end if;
  v_codice := public.mio_codice_specialisti();
  insert into public.contatti_specialisti (
    club_id, atleta_id, specialista_id, specialista_nome, specialista_tipo,
    problema, canale, codice
  ) values (
    v_specialista.club_id, v_atleta, v_specialista.id, v_specialista.nome,
    v_specialista.tipo, p_problema, p_canale, v_codice
  )
  on conflict (atleta_id, specialista_id, giorno) do nothing;
end;
$$;

grant execute on function public.registra_contatto_specialista(uuid, text, text)
  to authenticated;
