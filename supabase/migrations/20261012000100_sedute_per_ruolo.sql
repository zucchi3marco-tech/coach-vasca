-- ============================================================
-- SEDUTE PER RUOLO (fase 2 del "Mako della pallanuoto", proposta 2):
-- in quasi ogni seduta i portieri fanno un lavoro diverso, e capita che
-- un infortunato faccia altro. Ogni serie dice per chi e': tutti, i
-- portieri, i giocatori di movimento, solo alcuni atleti o tutti tranne
-- alcuni. Volume e carico si contano per atleta.
-- ============================================================

-- Il ruolo nella scheda dell'atleta. Null: non indicato, conta come
-- movimento.
alter table public.atleti
  add column ruolo text check (ruolo in ('portiere', 'movimento'));

-- Chi nell'ultima distinta era portiere parte gia' come portiere.
with ultime as (
  select distinct on (d.atleta_id) d.atleta_id, d.portiere
  from public.distinta_giocatori d
  join public.partite p on p.id = d.partita_id
  order by d.atleta_id, p.data desc
)
update public.atleti a
set ruolo = 'portiere'
from ultime u
where u.atleta_id = a.id
  and u.portiere
  and a.ruolo is null;

-- Per chi e' la serie. Tutto null: tutto il gruppo.
-- - per_ruolo: solo i portieri o solo i giocatori di movimento;
-- - solo_atleti: solo questi atleti (e allora niente ruolo ne' esclusi);
-- - tranne_atleti: tutti (o tutti quelli del ruolo) tranne questi.
-- Niente chiave esterna sugli id: un atleta eliminato resta nell'elenco
-- ma non corrisponde piu' a nessuno.
alter table public.serie
  add column per_ruolo text check (per_ruolo in ('portiere', 'movimento')),
  add column solo_atleti uuid[]
    check (solo_atleti is null or cardinality(solo_atleti) > 0),
  add column tranne_atleti uuid[]
    check (tranne_atleti is null or cardinality(tranne_atleti) > 0),
  add constraint serie_destinatari_check check (
    solo_atleti is null or (per_ruolo is null and tranne_atleti is null)
  );

-- La stessa regola dell'app (`Destinatari.perAtleta`): la serie e' anche
-- per l'atleta [p_atleta], che ha il ruolo [p_ruolo]?
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
    else (p_per_ruolo is null or p_per_ruolo = coalesce(p_ruolo, 'movimento'))
      and not (p_atleta = any(coalesce(p_tranne, '{}'::uuid[])))
  end;
$$;

-- L'atleta che apre il prossimo allenamento vede solo le sue serie. Il
-- tipo di ritorno non cambia.
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
    and public.serie_per_atleta(
      s.per_ruolo, s.solo_atleti, s.tranne_atleti, at.id, at.ruolo
    )
  order by s.ordine;
$$;

grant execute on function public.serie_allenamento_atleta(uuid) to authenticated;

-- Il carico conta per ogni atleta solo le sue serie: la funzione
-- restituisce anche i destinatari. All'atleta collegato arrivano solo le
-- serie che fa lui, senza gli elenchi di id (chi e' escluso da una serie,
-- per esempio per un dolore, non lo deve leggere un compagno).
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
  tranne_atleti uuid[]
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
         case when public.is_membro_club(p_club_id) then s.tranne_atleti end
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
            and public.serie_per_atleta(
              s.per_ruolo, s.solo_atleti, s.tranne_atleti, at.id, at.ruolo
            )
        )
      )
    );
$$;

grant execute on function public.serie_per_carico(uuid) to authenticated;
