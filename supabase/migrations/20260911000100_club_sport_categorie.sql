-- ============================================================
-- CLUB: sport praticato e categorie allenate (FASE 11), chiesti alla
-- prima registrazione insieme a nome e citta'. I club gia' esistenti
-- restano con questi campi vuoti (nessun backfill possibile: non
-- deducibile dai dati esistenti), l'allenatore li compila modificando
-- il club quando vuole.
-- ============================================================

alter table public.club
  add column sport text,
  add column categorie text[] not null default '{}';

alter table public.club
  add constraint club_sport_check
  check (sport is null or sport in ('nuoto', 'pallanuoto', 'nuoto_pallanuoto'));

drop function if exists public.create_club(text, text);

create or replace function public.create_club(
  p_nome text,
  p_citta text default null,
  p_sport text default null,
  p_categorie text[] default '{}'
)
returns public.club
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club public.club;
begin
  insert into public.club (nome, citta, sport, categorie)
  values (p_nome, p_citta, p_sport, coalesce(p_categorie, '{}'))
  returning * into v_club;

  return v_club;
end;
$$;

grant execute on function public.create_club(text, text, text, text[]) to authenticated;
