-- ============================================================
-- ALTRA SQUADRA IN GIORNI FISSI (richiesta del coach 2026-10-15):
-- alcuni atleti di una categoria si allenano certi giorni con la loro
-- e altri con un'altra. Nella scheda dell'atleta resta la sua squadra
-- (gruppo_id); in piu' l'altra squadra e i giorni della settimana in cui
-- si allena con lei (1 = lunedi' ... 7 = domenica, come in Dart).
--
-- Quei giorni e' atteso agli allenamenti dell'altra squadra e non a
-- quelli della sua (lo decide l'app: presenze e percentuali). Vede gli
-- allenamenti, le serie, gli esercizi a secco e le partite di tutte e
-- due le squadre, ogni giorno.
-- ============================================================

alter table public.atleti
  add column if not exists altro_gruppo_id uuid
    references public.gruppi(id) on delete set null,
  add column if not exists giorni_altro_gruppo smallint[]
    check (
      giorni_altro_gruppo is null
      or giorni_altro_gruppo <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]
    );

-- L'altra squadra dev'essere del club dell'atleta e diversa dalla sua;
-- senza altra squadra non restano giorni.
create or replace function public.valida_altro_gruppo_atleta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.altro_gruppo_id is null
     or new.altro_gruppo_id is not distinct from new.gruppo_id then
    new.altro_gruppo_id := null;
    new.giorni_altro_gruppo := null;
    return new;
  end if;
  if not exists (
    select 1 from public.gruppi
    where id = new.altro_gruppo_id and club_id = new.club_id
  ) then
    raise exception 'La squadra scelta non e'' di questo club';
  end if;
  if new.giorni_altro_gruppo is not null
     and cardinality(new.giorni_altro_gruppo) = 0 then
    new.giorni_altro_gruppo := null;
  end if;
  return new;
end;
$$;

-- L'atleta legge i nomi delle squadre del suo club ("Under 14", "Prima
-- squadra"): servono a dirgli con quale squadra e' ogni allenamento.
-- Solo nome e ordine, niente di personale.
drop policy if exists gruppi_select_atleta on public.gruppi;
create policy gruppi_select_atleta on public.gruppi
  for select using (club_id = public.mio_club_atleta());

drop trigger if exists trg_atleti_altro_gruppo on public.atleti;
create trigger trg_atleti_altro_gruppo
before insert or update of altro_gruppo_id, giorni_altro_gruppo, gruppo_id, club_id
on public.atleti
for each row execute function public.valida_altro_gruppo_atleta();

-- Un record del gruppo [p_gruppo] (null: di tutto il club) e' anche per
-- l'atleta della squadra [p_squadra] che si allena anche con [p_altra]?
-- La regola di prima (senza gruppo vede tutto), piu' l'altra squadra.
create or replace function public.nel_gruppo_atleta(
  p_gruppo uuid,
  p_squadra uuid,
  p_altra uuid
)
returns boolean
language sql
immutable
as $$
  select p_gruppo is null
    or p_squadra is null
    or p_gruppo = p_squadra
    or p_gruppo = p_altra;
$$;

-- L'atleta che apre un allenamento vede solo le serie che fa: della sua
-- squadra o dell'altra. Il tipo di ritorno non cambia.
create or replace function public.serie_allenamento_atleta(p_allenamento_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  club_id uuid,
  ordine integer,
  blocco text,
  ripetute integer,
  distanza_m integer,
  durata_s integer,
  stile text,
  esecuzione text,
  zona text,
  passo_obiettivo_s numeric,
  recupero_s integer,
  ripartenza_s numeric,
  attrezzatura text,
  recupero_dopo_s integer
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.club_id, s.ordine, s.blocco::text,
         s.ripetute, s.distanza_m, s.durata_s, s.stile::text, s.esecuzione::text,
         s.zona::text, s.passo_obiettivo_s, s.recupero_s, s.ripartenza_s,
         s.attrezzatura, s.recupero_dopo_s
  from public.serie s
  join public.allenamenti a on a.id = s.allenamento_id
  join public.atleti at on at.user_id = auth.uid() and at.club_id = a.club_id
  where s.allenamento_id = p_allenamento_id
    and public.nel_gruppo_atleta(a.gruppo_id, at.gruppo_id, at.altro_gruppo_id)
    and public.serie_fatta_da(s, at.id, at.ruolo)
  order by s.ordine;
$$;

grant execute on function public.serie_allenamento_atleta(uuid) to authenticated;

-- Gli esercizi di una seduta a secco: della sua squadra o dell'altra.
-- Il tipo di ritorno non cambia.
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
  video_youtube text,
  video_da_s integer,
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
         e.categoria, e.misura, e.attrezzo, e.descrizione, e.video_youtube,
         e.video_da_s, s.serie, s.ripetizioni, s.durata_s, s.carico,
         s.recupero_s
  from public.esercizi_seduta s
  join public.esercizi_secco e on e.id = s.esercizio_id
  join public.allenamenti a on a.id = s.allenamento_id
  join public.atleti at on at.user_id = auth.uid() and at.club_id = a.club_id
  where s.allenamento_id = p_allenamento_id
    and public.nel_gruppo_atleta(a.gruppo_id, at.gruppo_id, at.altro_gruppo_id)
  order by s.ordine;
$$;

grant execute on function public.esercizi_seduta_atleta(uuid) to authenticated;

-- Le serie a secco che l'atleta registra: anche per le sedute dell'altra
-- squadra.
create or replace function public.valida_serie_secco_fatta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_riga record;
  v_atleta record;
begin
  select s.allenamento_id, s.esercizio_id, s.club_id, a.gruppo_id
    into v_riga
  from public.esercizi_seduta s
  join public.allenamenti a on a.id = s.allenamento_id
  where s.id = new.riga_id;
  if not found then
    raise exception 'Esercizio della seduta non trovato';
  end if;

  select club_id, gruppo_id, altro_gruppo_id into v_atleta
  from public.atleti where id = new.atleta_id;
  if not found then
    raise exception 'Atleta non trovato';
  end if;

  if v_riga.club_id <> v_atleta.club_id then
    raise exception 'Seduta di un altro club';
  end if;
  if not public.nel_gruppo_atleta(
    v_riga.gruppo_id, v_atleta.gruppo_id, v_atleta.altro_gruppo_id
  ) then
    raise exception 'Seduta di un altro gruppo';
  end if;

  new.club_id := v_atleta.club_id;
  new.allenamento_id := v_riga.allenamento_id;
  new.esercizio_id := v_riga.esercizio_id;
  return new;
end;
$$;
