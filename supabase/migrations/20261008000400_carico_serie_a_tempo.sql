-- ============================================================
-- CARICO E VOLUMI DELL'ATLETA: anche il lavoro a tempo.
--
-- Segnalazione del coach (2026-10-08): nelle statistiche dell'atleta il
-- palleggio compariva a 0 m. `serie_per_carico` restituiva solo la
-- distanza, e le serie a tempo (palleggio, tattica, a secco...) non ne
-- hanno. Ora restituisce anche `durata_s`: l'app mostra i minuti per tipo
-- di lavoro e li conta nel carico.
--
-- Il tipo di ritorno cambia (una colonna in piu'): va eliminata prima di
-- ridefinirla, "create or replace" da solo non basta quando cambiano le
-- colonne OUT. Le app gia' aperte ignorano la colonna nuova.
-- ============================================================

drop function if exists public.serie_per_carico(uuid);

create or replace function public.serie_per_carico(p_club_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  ripetute integer,
  distanza_m integer,
  durata_s integer,
  zona text,
  esecuzione text
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.ripetute, s.distanza_m, s.durata_s,
         s.zona::text, s.esecuzione::text
  from public.serie s
  where s.club_id = p_club_id
    and s.esito is distinct from 'saltata'
    and (
      public.is_membro_club(p_club_id)
      or p_club_id = public.mio_club_atleta()
    );
$$;

grant execute on function public.serie_per_carico(uuid) to authenticated;
