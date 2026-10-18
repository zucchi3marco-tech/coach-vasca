-- ============================================================
-- Partite e gare nel calendario del telefono (richiesta del coach
-- 2026-10-17: "collegamento al calendario del telefono per le partite
-- comunque gli eventi, no per gli allenamenti"; scelta del coach: un
-- calendario collegato che si aggiorna da solo).
--
-- Ognuno (allenatore o atleta con l'account) ha un indirizzo personale
-- con un codice segreto: il telefono lo aggiunge una volta come
-- calendario e lo rilegge da solo. L'indirizzo lo serve la Edge
-- Function `calendario`, che non ha un utente collegato (la chiama il
-- calendario del telefono): con la chiave di servizio chiama
-- `eventi_calendario`, che dal codice risale alla persona e rende solo
-- le partite e le gare che la persona vede nell'app.
-- - Allenatore (membro del club): tutte quelle del club.
-- - Atleta: quelle della sua squadra, dell'altra con cui si allena in
--   giorni fissi e quelle di tutto il club (`nel_gruppo_atleta`), con
--   "convocato" (in distinta e convocazione inviata) o "iscritto".
-- Niente allenamenti, niente note, niente dati di altri atleti.
-- ============================================================

create table public.calendari_collegati (
  user_id uuid primary key references auth.users(id) on delete cascade,
  codice text not null unique,
  created_at timestamptz not null default now()
);

alter table public.calendari_collegati enable row level security;

-- Ognuno vede solo il suo; si crea e si cambia solo con mio_calendario.
create policy calendari_collegati_select on public.calendari_collegati
  for select using (user_id = auth.uid());

-- Il codice del calendario di chi chiama: lo crea la prima volta; con
-- p_nuovo ne fa uno nuovo e il vecchio indirizzo smette di funzionare
-- ("Cambia indirizzo", se lo si è condiviso per sbaglio).
create or replace function public.mio_calendario(p_nuovo boolean default false)
returns text
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_codice text;
begin
  if auth.uid() is null then
    raise exception 'Serve un utente collegato';
  end if;
  if not p_nuovo then
    select codice into v_codice
    from public.calendari_collegati
    where user_id = auth.uid();
    if v_codice is not null then
      return v_codice;
    end if;
  end if;
  v_codice := encode(extensions.gen_random_bytes(24), 'hex');
  insert into public.calendari_collegati (user_id, codice)
  values (auth.uid(), v_codice)
  on conflict (user_id) do update
    set codice = excluded.codice, created_at = now();
  return v_codice;
end;
$$;

revoke all on function public.mio_calendario(boolean) from public, anon;
grant execute on function public.mio_calendario(boolean) to authenticated;

-- Il calendario di un codice: null se il codice non c'è; se no il nome
-- del calendario e gli eventi dagli ultimi 60 giorni in poi. Solo per la
-- Edge Function (chiave di servizio): da fuori nessuno la chiama.
create or replace function public.eventi_calendario(p_codice text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with chi as (
    select user_id from public.calendari_collegati where codice = p_codice
  ),
  staff as (
    select m.club_id
    from public.club_membri m
    join chi on chi.user_id = m.user_id
  ),
  atleta as (
    select a.id, a.club_id, a.gruppo_id, a.altro_gruppo_id
    from public.atleti a
    join chi on chi.user_id = a.user_id
    where a.attivo
  ),
  eventi as (
    select
      'partita' as tipo,
      p.id,
      p.data,
      p.ora,
      p.squadra_casa || ' - ' || p.squadra_trasferta as titolo,
      p.luogo,
      p.campionato as dettaglio,
      g.nome as squadra,
      exists (
        select 1
        from public.distinta_giocatori d
        join atleta on atleta.id = d.atleta_id
        where d.partita_id = p.id
      ) and p.convocazione_inviata_at is not null as per_me,
      p.updated_at as aggiornato
    from public.partite p
    left join public.gruppi g on g.id = p.gruppo_id
    where p.data >= current_date - 60
      and (
        p.club_id in (select club_id from staff)
        or exists (
          select 1 from atleta
          where atleta.club_id = p.club_id
            and public.nel_gruppo_atleta(
              p.gruppo_id, atleta.gruppo_id, atleta.altro_gruppo_id
            )
        )
      )
    union all
    select
      'gara',
      ga.id,
      ga.data,
      ga.ora,
      ga.nome,
      ga.luogo,
      null,
      g.nome,
      exists (
        select 1
        from public.gara_iscritti i
        join atleta on atleta.id = i.atleta_id
        where i.gara_id = ga.id
      ),
      ga.updated_at
    from public.gare ga
    left join public.gruppi g on g.id = ga.gruppo_id
    where ga.data >= current_date - 60
      and (
        ga.club_id in (select club_id from staff)
        or exists (
          select 1 from atleta
          where atleta.club_id = ga.club_id
            and public.nel_gruppo_atleta(
              ga.gruppo_id, atleta.gruppo_id, atleta.altro_gruppo_id
            )
        )
      )
  )
  select case
    when not exists (select 1 from chi) then null
    else jsonb_build_object(
      'nome',
      coalesce(
        (select c.nome from public.club c
          where c.id in (select club_id from staff union select club_id from atleta)
          order by c.nome limit 1),
        'WaterTactics'
      ),
      'atleta',
      exists (select 1 from atleta) and not exists (select 1 from staff),
      'eventi',
      coalesce(
        (select jsonb_agg(to_jsonb(e) order by e.data, e.ora) from eventi e),
        '[]'::jsonb
      )
    )
  end;
$$;

revoke all on function public.eventi_calendario(text) from public, anon, authenticated;
grant execute on function public.eventi_calendario(text) to service_role;
