-- ============================================================
-- CLUB: l'allenatore scegliera' un solo sport (nuoto o pallanuoto),
-- non piu' "nuoto e pallanuoto" insieme — nessun club esistente usa
-- 'nuoto_pallanuoto' (verificato), quindi il restringimento non
-- richiede backfill.
-- ============================================================

alter table public.club
  drop constraint club_sport_check;

alter table public.club
  add constraint club_sport_check
  check (sport is null or sport in ('nuoto', 'pallanuoto'));
