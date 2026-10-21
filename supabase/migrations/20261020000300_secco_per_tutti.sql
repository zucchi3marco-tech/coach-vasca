-- ============================================================
-- IL SECCO PER TUTTA LA SQUADRA (proposta 12 del «Piano di
-- WaterTactics», periodo 2, problema 17)
--
-- Scelte del coach (2026-10-20): la variante di un esercizio è per un
-- atleta, con la proposta per chi ha male alla spalla; ogni serie si
-- vota facile, giusta o dura. Il tablet della squadra registra con
-- l'account dell'allenatore, che può già scrivere le serie di tutti
-- (`serie_secco_fatte_insert`): per quello non serve niente qui.
-- ============================================================

-- ------------------------------------------------------------
-- La variante di un esercizio della seduta
--
-- Una riga in più della seduta, con `variante_di` (l'esercizio che
-- sostituisce, della stessa seduta) e `solo_atleti` (per chi): chi ha
-- una variante non fa l'esercizio di tutti, fa la sua. Togliendo
-- l'esercizio se ne vanno anche le sue varianti.
-- `tranne_atleti`: chi non fa l'esercizio e basta («Non lo fa»).
-- Niente chiave esterna sugli id degli atleti, come per le serie in
-- acqua (`serie.solo_atleti`).
-- ------------------------------------------------------------
alter table public.esercizi_seduta
  add column if not exists variante_di uuid
    references public.esercizi_seduta(id) on delete cascade,
  add column if not exists solo_atleti uuid[],
  add column if not exists tranne_atleti uuid[];

alter table public.esercizi_seduta
  drop constraint if exists esercizi_seduta_variante_check;
alter table public.esercizi_seduta
  add constraint esercizi_seduta_variante_check check (
    (variante_di is null and solo_atleti is null)
    or (
      variante_di is not null
      and solo_atleti is not null
      and cardinality(solo_atleti) > 0
      and tranne_atleti is null
    )
  );

alter table public.esercizi_seduta
  drop constraint if exists esercizi_seduta_tranne_check;
alter table public.esercizi_seduta
  add constraint esercizi_seduta_tranne_check check (
    tranne_atleti is null or cardinality(tranne_atleti) > 0
  );

create index if not exists idx_esercizi_seduta_variante_di
  on public.esercizi_seduta(variante_di);

-- La regola di prima (il club dalla seduta, che dev'essere a secco;
-- l'esercizio dello stesso club), più la variante: di un esercizio della
-- stessa seduta, e mai la variante di una variante.
create or replace function public.valida_esercizio_seduta()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_club uuid;
  v_tipo text;
  v_originale record;
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
  if new.variante_di is not null then
    select allenamento_id, variante_di into v_originale
      from public.esercizi_seduta where id = new.variante_di;
    if not found or v_originale.allenamento_id <> new.allenamento_id then
      raise exception 'Variante di un esercizio di un''altra seduta';
    end if;
    if v_originale.variante_di is not null then
      raise exception 'Una variante non ha varianti';
    end if;
  end if;
  return new;
end;
$$;

-- Gli esercizi di una seduta a secco per l'atleta collegato: della sua
-- squadra o dell'altra (come prima), e solo i suoi. Una variante solo se
-- è per lui; un esercizio di tutti no se ne è escluso o se ha una sua
-- variante. La stessa regola nell'app (`eserciziDellAtleta`). Il tipo di
-- ritorno non cambia.
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
    and case
      when s.variante_di is not null then at.id = any(s.solo_atleti)
      else not (at.id = any(coalesce(s.tranne_atleti, '{}'::uuid[])))
        and not exists (
          select 1 from public.esercizi_seduta v
          where v.variante_di = s.id and at.id = any(v.solo_atleti)
        )
    end
  order by s.ordine;
$$;

grant execute on function public.esercizi_seduta_atleta(uuid) to authenticated;

-- ------------------------------------------------------------
-- Il voto di ogni serie a secco: com'è andata, detto durante il
-- recupero. Si può non dire (null).
-- ------------------------------------------------------------
alter table public.serie_secco_fatte
  add column if not exists voto text;

alter table public.serie_secco_fatte
  drop constraint if exists serie_secco_fatte_voto_check;
alter table public.serie_secco_fatte
  add constraint serie_secco_fatte_voto_check check (
    voto is null or voto in ('facile', 'giusta', 'dura')
  );
