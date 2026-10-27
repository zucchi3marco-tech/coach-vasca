-- ============================================================
-- LA SEDUTA APERTA DA UN COLLEGA («Piano di WaterTactics», periodo 2,
-- problema 6, passo 1, 2026-10-27). Due allenatori sulla stessa seduta:
-- chi salva per ultimo cancellava le modifiche dell'altro senza dirlo.
-- Scelta del coach: un avviso («Marco la sta modificando dalle 18:05»),
-- ma si può modificare lo stesso; se nel frattempo un collega ha salvato,
-- l'app lo dice prima di salvare e si sceglie quale versione tenere.
--
-- Due cose nuove, solo sul server:
--   versioni_seduta: un numero che sale a ogni cambio della seduta, delle
--     sue serie o dei suoi esercizi a secco (segnare fatto/saltato e i
--     metri fatti non conta, come per il capo squadra), con chi e quando;
--   sedute_aperte: chi ha la seduta aperta adesso (l'app lo rinnova ogni
--     minuto; dopo 2 minuti senza notizie non conta più).
-- Si leggono e si scrivono solo dalle due funzioni qui sotto.
-- ============================================================

create table if not exists public.versioni_seduta (
  allenamento_id uuid primary key references public.allenamenti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  versione bigint not null default 0,
  cambiata_da uuid references auth.users(id) on delete set null,
  cambiata_nome text,
  cambiata_at timestamptz not null default now()
);

create table if not exists public.sedute_aperte (
  allenamento_id uuid not null references public.allenamenti(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  nome text,
  dal timestamptz not null default now(),
  visto_at timestamptz not null default now(),
  primary key (allenamento_id, user_id)
);

alter table public.versioni_seduta enable row level security;
alter table public.sedute_aperte enable row level security;
-- Nessuna regola: niente lettura o scrittura diretta, solo le funzioni.

-- La seduta è cambiata: la versione sale. Una seduta appena tolta (le
-- sue serie se ne vanno con lei) non ha più versione.
create or replace function public.versione_seduta_sale(p_allenamento_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club uuid;
  v_utente uuid := auth.uid();
begin
  select club_id into v_club from public.allenamenti where id = p_allenamento_id;
  if v_club is null then
    return;
  end if;
  insert into public.versioni_seduta as v (
    allenamento_id, club_id, versione, cambiata_da, cambiata_nome, cambiata_at
  )
  values (
    p_allenamento_id,
    v_club,
    1,
    v_utente,
    case when v_utente is null then null else public.nome_membro(v_club, v_utente) end,
    now()
  )
  on conflict (allenamento_id) do update
    set versione = v.versione + 1,
        cambiata_da = excluded.cambiata_da,
        cambiata_nome = excluded.cambiata_nome,
        cambiata_at = excluded.cambiata_at;
end;
$$;

revoke all on function public.versione_seduta_sale(uuid) from public, anon, authenticated;

create or replace function public.versione_da_allenamento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and (to_jsonb(new) - 'updated_at') = (to_jsonb(old) - 'updated_at') then
    return null;
  end if;
  perform public.versione_seduta_sale(new.id);
  return null;
end;
$$;

drop trigger if exists trg_allenamenti_versione on public.allenamenti;
create trigger trg_allenamenti_versione
after insert or update on public.allenamenti
for each row execute function public.versione_da_allenamento();

create or replace function public.versione_da_riga_seduta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and (to_jsonb(new) - 'updated_at' - 'esito' - 'metri_fatti' - 'secondi_fatti')
       = (to_jsonb(old) - 'updated_at' - 'esito' - 'metri_fatti' - 'secondi_fatti') then
    return null;
  end if;
  perform public.versione_seduta_sale(
    case when tg_op = 'DELETE' then old.allenamento_id else new.allenamento_id end
  );
  return null;
end;
$$;

drop trigger if exists trg_serie_versione on public.serie;
create trigger trg_serie_versione
after insert or update or delete on public.serie
for each row execute function public.versione_da_riga_seduta();

drop trigger if exists trg_esercizi_seduta_versione on public.esercizi_seduta;
create trigger trg_esercizi_seduta_versione
after insert or update or delete on public.esercizi_seduta
for each row execute function public.versione_da_riga_seduta();

-- ------------------------------------------------------------
-- Le due funzioni dell'app
-- ------------------------------------------------------------

-- «Ho aperta questa seduta» (all'apertura e poi ogni minuto): restituisce
-- la versione, chi l'ha cambiata per ultimo e chi altro la sta guardando.
create or replace function public.seduta_aperta(p_allenamento_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_utente uuid := auth.uid();
  v_club uuid;
  v_versione public.versioni_seduta;
  v_altri jsonb;
begin
  select club_id into v_club from public.allenamenti where id = p_allenamento_id;
  if v_utente is null or v_club is null or not public.is_membro_club(v_club) then
    raise exception 'Seduta non trovata';
  end if;

  insert into public.sedute_aperte as s (allenamento_id, user_id, club_id, nome)
  values (p_allenamento_id, v_utente, v_club, public.nome_membro(v_club, v_utente))
  on conflict (allenamento_id, user_id) do update
    set visto_at = now(),
        -- Riaperta dopo una pausa lunga: conta da adesso.
        dal = case when s.visto_at < now() - interval '2 minutes' then now() else s.dal end,
        nome = excluded.nome;

  -- Le righe vecchie se ne vanno da sole.
  delete from public.sedute_aperte
  where allenamento_id = p_allenamento_id and visto_at < now() - interval '1 day';

  select * into v_versione from public.versioni_seduta
  where allenamento_id = p_allenamento_id;

  select coalesce(jsonb_agg(jsonb_build_object('nome', s.nome, 'dal', s.dal) order by s.dal), '[]'::jsonb)
  into v_altri
  from public.sedute_aperte s
  where s.allenamento_id = p_allenamento_id
    and s.user_id <> v_utente
    and s.visto_at > now() - interval '2 minutes';

  return jsonb_build_object(
    'versione', coalesce(v_versione.versione, 0),
    'cambiata_nome', v_versione.cambiata_nome,
    'cambiata_at', v_versione.cambiata_at,
    'cambiata_da_me', coalesce(v_versione.cambiata_da = v_utente, false),
    'altri', v_altri
  );
end;
$$;

-- «L'ho chiusa».
create or replace function public.seduta_chiusa(p_allenamento_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.sedute_aperte
  where allenamento_id = p_allenamento_id and user_id = auth.uid();
$$;

revoke all on function public.seduta_aperta(uuid) from public, anon;
revoke all on function public.seduta_chiusa(uuid) from public, anon;
grant execute on function public.seduta_aperta(uuid) to authenticated;
grant execute on function public.seduta_chiusa(uuid) to authenticated;
