-- ============================================================
-- RECUPERO FRA UNA SERIE E L'ALTRA (richiesta del coach 2026-10-11):
-- nel compilatore una riga da sola "rec 2'" (o "pausa 2'") dopo una
-- serie e' il riposo prima della serie successiva. Diverso da
-- `recupero_s`, che e' il recupero fra le ripetute della stessa serie.
--
-- Una colonna sulla serie che lo precede, non una riga a parte: il
-- recupero non e' una serie e non deve contare nel volume, nel numero
-- delle serie o nel carico come lavoro. Conta nella durata stimata.
-- ============================================================

alter table public.serie
  add column recupero_dopo_s integer
  check (recupero_dopo_s > 0 and recupero_dopo_s <= 3600);

-- L'atleta che apre il prossimo allenamento vede anche i recuperi fra le
-- serie. Il tipo di ritorno cambia: va eliminata prima di ridefinirla.
drop function if exists public.serie_allenamento_atleta(uuid);

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
  order by s.ordine;
$$;

grant execute on function public.serie_allenamento_atleta(uuid) to authenticated;

-- Il carico conta i minuti della seduta, recuperi fra le serie compresi.
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
  recupero_dopo_s integer
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.ripetute, s.distanza_m, s.durata_s,
         s.zona::text, s.esecuzione::text, s.recupero_s, s.ripartenza_s,
         s.passo_obiettivo_s, s.recupero_dopo_s
  from public.serie s
  where s.club_id = p_club_id
    and s.esito is distinct from 'saltata'
    and (
      public.is_membro_club(p_club_id)
      or p_club_id = public.mio_club_atleta()
    );
$$;

grant execute on function public.serie_per_carico(uuid) to authenticated;
