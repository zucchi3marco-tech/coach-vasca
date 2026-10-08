-- ============================================================
-- BORDO VASCA: ogni serie si segna come "fatta" o "saltata" durante la
-- seduta (idea presa da Swimtraxx Hub, richiesta del coach 2026-10-08).
-- NULL = non ancora segnata (le serie salvate finora restano così).
--
-- Serve al volume reale: il carico dell'atleta (Banister, volumi per
-- zona) non conta più le serie saltate. Le altre — fatte o non segnate —
-- contano come prima, così nulla cambia per chi non usa la funzione.
-- ============================================================

alter table public.serie
  add column esito text check (esito in ('fatta', 'saltata'));

-- Stesse colonne di prima (create or replace basta), con le serie
-- saltate escluse.
create or replace function public.serie_per_carico(p_club_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  ripetute integer,
  distanza_m integer,
  zona text,
  esecuzione text
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.ripetute, s.distanza_m,
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
