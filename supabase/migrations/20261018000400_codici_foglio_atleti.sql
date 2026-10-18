-- ============================================================
-- Il foglio dei codici (fase 5, «Atleti da un foglio Excel»): il
-- responsabile o un allenatore stampa un biglietto per ogni atleta
-- senza account, con un codice personale nuovo.
--
-- Scelta del coach (2026-10-18): i codici del foglio valgono 30 giorni
-- (quello creato dalla scheda dell'atleta resta di 7), una volta sola.
-- Vale solo l'ultimo foglio: i codici non usati fatti prima per gli
-- stessi atleti scadono subito, così un foglio vecchio o perso non apre
-- più niente.
-- ============================================================

create or replace function public.genera_codici_foglio(p_atleta_ids uuid[])
returns table (atleta uuid, nuovo_codice text, scade timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ids uuid[];
  v_club_ids uuid[];
  v_trovati int;
begin
  select coalesce(array_agg(distinct x), '{}') into v_ids
  from unnest(coalesce(p_atleta_ids, '{}')) as x;
  if cardinality(v_ids) = 0 then
    return;
  end if;
  if cardinality(v_ids) > 500 then
    raise exception 'Al massimo 500 atleti in un foglio';
  end if;

  select count(*), coalesce(array_agg(distinct a.club_id), '{}')
  into v_trovati, v_club_ids
  from public.atleti a
  where a.id = any(v_ids);

  if v_trovati <> cardinality(v_ids) or cardinality(v_club_ids) <> 1 then
    raise exception 'Atleti non trovati';
  end if;
  if not public.e_allenatore_club(v_club_ids[1]) then
    raise exception 'Non autorizzato';
  end if;

  update public.inviti_atleta i
  set scade_il = now()
  where i.atleta_id = any(v_ids)
    and i.usato_il is null
    and i.scade_il > now();

  -- Chi ha già l'account non ha bisogno di un codice: resta fuori.
  return query
  insert into public.inviti_atleta as i
    (atleta_id, club_id, codice, creato_da, scade_il)
  select
    a.id,
    a.club_id,
    upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 10)),
    auth.uid(),
    now() + interval '30 days'
  from public.atleti a
  where a.id = any(v_ids)
    and a.user_id is null
  returning i.atleta_id, i.codice, i.scade_il;
end;
$$;

revoke all on function public.genera_codici_foglio(uuid[]) from public, anon;
grant execute on function public.genera_codici_foglio(uuid[]) to authenticated;
