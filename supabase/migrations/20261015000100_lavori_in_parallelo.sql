-- ============================================================
-- LAVORI IN PARALLELO (richiesta del coach 2026-10-15): il lavoro dei
-- portieri e quello specializzato (centroboa, marcatori, esterni) va
-- insieme a quello di tutti, nello stesso tempo, non dopo.
--
-- Le serie con lo stesso momento_id si fanno in parallelo: ogni
-- "colonna" del momento e' un gruppo di destinatari (tutti, un ruolo,
-- alcuni atleti). In un momento ogni atleta fa la colonna piu' precisa
-- fra quelle che lo comprendono: i suoi nomi, poi il suo ruolo, poi
-- "movimento", poi "tutti". Cosi' "tutti" in un momento con i portieri
-- vale per chi non e' portiere. Null: una serie normale, come prima.
-- ============================================================

-- Ruoli piu' precisi nella scheda dell'atleta. Centroboa, marcatore ed
-- esterno sono giocatori di movimento: una serie per "movimento" vale
-- anche per loro.
alter table public.atleti drop constraint if exists atleti_ruolo_check;
alter table public.atleti
  add constraint atleti_ruolo_check check (
    ruolo in ('portiere', 'movimento', 'centroboa', 'marcatore', 'esterno')
  );

alter table public.serie drop constraint if exists serie_per_ruolo_check;
alter table public.serie
  add constraint serie_per_ruolo_check check (
    per_ruolo in ('portiere', 'movimento', 'centroboa', 'marcatore', 'esterno')
  );

-- Come piramide_id: solo un'etichetta di raggruppamento, nessun vincolo.
alter table public.serie add column if not exists momento_id uuid;

create index if not exists serie_momento_idx
  on public.serie (allenamento_id, momento_id)
  where momento_id is not null;

-- La serie e' per l'atleta [p_atleta], che ha il ruolo [p_ruolo]? Come
-- prima, piu': "movimento" comprende centroboa, marcatori ed esterni.
create or replace function public.serie_per_atleta(
  p_per_ruolo text,
  p_solo uuid[],
  p_tranne uuid[],
  p_atleta uuid,
  p_ruolo text
)
returns boolean
language sql
immutable
as $$
  select case
    when p_solo is not null then p_atleta = any(p_solo)
    else (
      p_per_ruolo is null
      or p_per_ruolo = coalesce(p_ruolo, 'movimento')
      or (
        p_per_ruolo = 'movimento'
        and coalesce(p_ruolo, 'movimento') <> 'portiere'
      )
    )
      and not (p_atleta = any(coalesce(p_tranne, '{}'::uuid[])))
  end;
$$;

-- Quanto e' precisa una colonna: alcuni atleti 3, un ruolo 2,
-- "movimento" 1, tutti 0 (la stessa regola di `Destinatari.precedenza`).
create or replace function public.precedenza_destinatari(
  p_per_ruolo text,
  p_solo uuid[]
)
returns integer
language sql
immutable
as $$
  select case
    when p_solo is not null then 3
    when p_per_ruolo is null then 0
    when p_per_ruolo = 'movimento' then 1
    else 2
  end;
$$;

-- L'atleta fa la serie [p_serie]? Per lui e, se e' in un momento, nella
-- colonna piu' precisa fra quelle che lo comprendono (vedi
-- `serieDellAtleta` nell'app). Usata solo dentro le funzioni qui sotto.
create or replace function public.serie_fatta_da(
  p_serie public.serie,
  p_atleta uuid,
  p_ruolo text
)
returns boolean
language sql
stable
set search_path = public
as $$
  select public.serie_per_atleta(
      p_serie.per_ruolo, p_serie.solo_atleti, p_serie.tranne_atleti,
      p_atleta, p_ruolo
    )
    and (
      p_serie.momento_id is null
      or not exists (
        select 1
        from public.serie t
        where t.allenamento_id = p_serie.allenamento_id
          and t.momento_id = p_serie.momento_id
          and public.precedenza_destinatari(t.per_ruolo, t.solo_atleti)
            > public.precedenza_destinatari(p_serie.per_ruolo, p_serie.solo_atleti)
          and public.serie_per_atleta(
            t.per_ruolo, t.solo_atleti, t.tranne_atleti, p_atleta, p_ruolo
          )
      )
    );
$$;

revoke execute on function public.serie_fatta_da(public.serie, uuid, text)
  from public;

-- L'atleta che apre il prossimo allenamento vede solo le serie che fa.
-- Il tipo di ritorno non cambia.
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
    and (a.gruppo_id is null or at.gruppo_id is null or a.gruppo_id = at.gruppo_id)
    and public.serie_fatta_da(s, at.id, at.ruolo)
  order by s.ordine;
$$;

grant execute on function public.serie_allenamento_atleta(uuid) to authenticated;

-- Il carico conta per ogni atleta solo le sue serie. All'allenatore
-- arriva anche il momento (l'app sceglie la colonna di ogni atleta);
-- all'atleta collegato arrivano solo le serie che fa, gia' scelte qui,
-- senza gli elenchi di id e senza il momento.
drop function if exists public.serie_per_carico(uuid);

create or replace function public.serie_per_carico(p_club_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  ripetute integer,
  distanza_m integer,
  durata_s integer,
  zona text,
  esecuzione text,
  recupero_s integer,
  ripartenza_s numeric,
  passo_obiettivo_s numeric,
  recupero_dopo_s integer,
  per_ruolo text,
  solo_atleti uuid[],
  tranne_atleti uuid[],
  momento_id uuid
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.ripetute, s.distanza_m, s.durata_s,
         s.zona::text, s.esecuzione::text, s.recupero_s, s.ripartenza_s,
         s.passo_obiettivo_s, s.recupero_dopo_s, s.per_ruolo,
         case when public.is_membro_club(p_club_id) then s.solo_atleti end,
         case when public.is_membro_club(p_club_id) then s.tranne_atleti end,
         case when public.is_membro_club(p_club_id) then s.momento_id end
  from public.serie s
  where s.club_id = p_club_id
    and s.esito is distinct from 'saltata'
    and (
      public.is_membro_club(p_club_id)
      or (
        p_club_id = public.mio_club_atleta()
        and exists (
          select 1
          from public.atleti at
          where at.user_id = auth.uid()
            and at.club_id = p_club_id
            and public.serie_fatta_da(s, at.id, at.ruolo)
        )
      )
    );
$$;

grant execute on function public.serie_per_carico(uuid) to authenticated;
