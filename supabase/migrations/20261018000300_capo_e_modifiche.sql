-- ============================================================
-- Il club, secondo e terzo pezzo (richiesta del coach 2026-10-17: "far
-- vedere che c'è stata una modifica all'allenatore di quella categoria o
-- squadra così da poterla controllare"). Scelte del coach: un capo
-- allenatore per squadra; il capo vede chi, quando e cosa è cambiato
-- (prima e ora).
--
-- - `gruppi.capo_user_id`: il capo allenatore della squadra (un
--   allenatore o il responsabile del club), lo sceglie il responsabile.
-- - `modifiche_allenamento`: quando qualcuno che non è il capo cambia un
--   allenamento della squadra (i dati, le serie, gli esercizi del secco),
--   se ne apre una "da controllare" con com'era prima; altre modifiche
--   prima del "Visto" del capo si aggiungono alla stessa. Al capo arriva
--   una notifica (anche sul telefono, con il webhook delle notifiche).
--   Segnare a bordo vasca una serie fatta o saltata non è una modifica.
-- ============================================================

-- ------------------------------------------------------------
-- Il capo allenatore della squadra.
-- ------------------------------------------------------------

alter table public.gruppi
  add column capo_user_id uuid references auth.users(id) on delete set null;

-- Lo sceglie solo il responsabile, e dev'essere un allenatore del club.
create or replace function public.valida_capo_squadra()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and new.capo_user_id is not distinct from old.capo_user_id then
    return new;
  end if;
  if new.capo_user_id is null then
    return new;
  end if;
  if auth.uid() is not null and not public.is_owner_club(new.club_id) then
    raise exception 'Solo il responsabile del club sceglie il capo allenatore';
  end if;
  if not exists (
    select 1 from public.club_membri
    where club_id = new.club_id
      and user_id = new.capo_user_id
      and ruolo in ('owner', 'coach')
  ) then
    raise exception 'Il capo allenatore dev''essere un allenatore del club';
  end if;
  return new;
end;
$$;

create trigger trg_gruppi_capo
before insert or update of capo_user_id on public.gruppi
for each row execute function public.valida_capo_squadra();

-- Chi diventa assistente o esce dal club non è più capo.
create or replace function public.togli_capo_squadra()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' or new.ruolo = 'assistente' then
    update public.gruppi
    set capo_user_id = null
    where club_id = old.club_id and capo_user_id = old.user_id;
  end if;
  return null;
end;
$$;

create trigger trg_club_membri_capo
after update of ruolo or delete on public.club_membri
for each row execute function public.togli_capo_squadra();

-- Il responsabile sceglie (o toglie, con null) il capo di una squadra.
create or replace function public.scegli_capo_squadra(p_gruppo_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club uuid;
begin
  select club_id into v_club from public.gruppi where id = p_gruppo_id;
  if v_club is null then
    raise exception 'Squadra non trovata';
  end if;
  if not public.is_owner_club(v_club) then
    raise exception 'Solo il responsabile del club sceglie il capo allenatore';
  end if;
  update public.gruppi set capo_user_id = p_user_id where id = p_gruppo_id;
end;
$$;

revoke all on function public.scegli_capo_squadra(uuid, uuid) from public, anon;
grant execute on function public.scegli_capo_squadra(uuid, uuid) to authenticated;

-- ------------------------------------------------------------
-- Le modifiche da controllare.
-- ------------------------------------------------------------

create table public.modifiche_allenamento (
  id uuid primary key default gen_random_uuid(),
  allenamento_id uuid not null references public.allenamenti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  capo_user_id uuid not null references auth.users(id) on delete cascade,
  -- I nomi di chi l'ha cambiato, nell'ordine.
  autori text[] not null default '{}',
  -- L'allenamento l'ha aggiunto un altro: non c'è un "prima".
  nuovo boolean not null default false,
  -- Com'era prima della prima modifica: {allenamento, serie, esercizi}.
  prima jsonb,
  aperta_at timestamptz not null default now(),
  ultima_at timestamptz not null default now(),
  visto_at timestamptz
);

create unique index idx_modifiche_allenamento_aperta
  on public.modifiche_allenamento(allenamento_id) where visto_at is null;
create index idx_modifiche_allenamento_capo
  on public.modifiche_allenamento(capo_user_id) where visto_at is null;

alter table public.modifiche_allenamento enable row level security;

-- Le vede solo il capo che le deve controllare; si scrivono solo dai
-- trigger e da segna_modifica_vista.
create policy modifiche_allenamento_select on public.modifiche_allenamento
  for select using (capo_user_id = auth.uid());

alter table public.notifiche drop constraint notifiche_tipo_check;
alter table public.notifiche add constraint notifiche_tipo_check check (
  tipo in (
    'atleta_registrato',
    'convocazione_gara',
    'convocazione_partita',
    'visita_medica',
    'benessere',
    'video_partita',
    'allenamento_modificato'
  )
);

-- Il nome di chi modifica, per la notifica e "Modificato da".
create or replace function public.nome_membro(p_club_id uuid, p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select nullif(trim(nome), '') from public.club_membri
      where club_id = p_club_id and user_id = p_user_id),
    'Un allenatore'
  );
$$;

-- Chiamata dai trigger prima di ogni modifica di un allenamento (o dopo
-- averne aggiunto uno, con p_nuovo): se chi modifica non è il capo della
-- squadra apre una modifica da controllare, con com'era prima, e avvisa
-- il capo; se ce n'è già una aperta si aggiunge a quella.
create or replace function public.registra_modifica_allenamento(
  p_allenamento_id uuid,
  p_nuovo boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_utente uuid := auth.uid();
  v_club uuid;
  v_titolo text;
  v_data date;
  v_capo uuid;
  v_squadra text;
  v_nome text;
  v_id uuid;
begin
  -- Le modifiche fatte da SQL o dal server non contano.
  if v_utente is null then
    return;
  end if;
  select a.club_id, a.titolo, a.data, g.capo_user_id, g.nome
  into v_club, v_titolo, v_data, v_capo, v_squadra
  from public.allenamenti a
  left join public.gruppi g on g.id = a.gruppo_id
  where a.id = p_allenamento_id;
  if v_capo is null or v_capo = v_utente then
    return;
  end if;
  v_nome := public.nome_membro(v_club, v_utente);

  update public.modifiche_allenamento
  set ultima_at = now(),
      autori = case when v_nome = any(autori) then autori else autori || v_nome end
  where allenamento_id = p_allenamento_id and visto_at is null;
  if found then
    return;
  end if;

  insert into public.modifiche_allenamento (
    allenamento_id, club_id, capo_user_id, autori, nuovo, prima
  )
  values (
    p_allenamento_id,
    v_club,
    v_capo,
    array[v_nome],
    p_nuovo,
    case when p_nuovo then null else jsonb_build_object(
      'allenamento',
      (select to_jsonb(a) - 'updated_at' from public.allenamenti a where a.id = p_allenamento_id),
      'serie',
      coalesce(
        (select jsonb_agg(to_jsonb(s) - 'updated_at' order by s.ordine)
          from public.serie s where s.allenamento_id = p_allenamento_id),
        '[]'::jsonb
      ),
      'esercizi',
      coalesce(
        (select jsonb_agg(to_jsonb(e) - 'updated_at' order by e.ordine)
          from public.esercizi_seduta e where e.allenamento_id = p_allenamento_id),
        '[]'::jsonb
      )
    ) end
  )
  returning id into v_id;

  insert into public.notifiche (club_id, tipo, messaggio, user_id, chiave)
  values (
    v_club,
    'allenamento_modificato',
    format(
      '%s ha %s «%s» · %s',
      v_nome,
      case when p_nuovo then 'aggiunto' else 'modificato' end,
      coalesce(nullif(trim(v_titolo), ''), 'Allenamento'),
      concat_ws(', ', v_squadra, to_char(v_data, 'DD/MM'))
    ),
    v_capo,
    'modifica:' || v_id
  )
  on conflict (chiave) do nothing;
end;
$$;

revoke all on function public.registra_modifica_allenamento(uuid, boolean) from public, anon, authenticated;

-- Un allenamento tolto da un altro: al capo resta solo la notifica (la
-- modifica se ne va con l'allenamento).
create or replace function public.avvisa_allenamento_tolto(p_allenamento public.allenamenti)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_utente uuid := auth.uid();
  v_capo uuid;
  v_squadra text;
begin
  if v_utente is null then
    return;
  end if;
  select capo_user_id, nome into v_capo, v_squadra
  from public.gruppi where id = p_allenamento.gruppo_id;
  if v_capo is null or v_capo = v_utente then
    return;
  end if;
  insert into public.notifiche (club_id, tipo, messaggio, user_id, chiave)
  values (
    p_allenamento.club_id,
    'allenamento_modificato',
    format(
      '%s ha tolto «%s» · %s',
      public.nome_membro(p_allenamento.club_id, v_utente),
      coalesce(nullif(trim(p_allenamento.titolo), ''), 'Allenamento'),
      concat_ws(', ', v_squadra, to_char(p_allenamento.data, 'DD/MM'))
    ),
    v_capo,
    'tolto:' || p_allenamento.id
  )
  on conflict (chiave) do nothing;
end;
$$;

revoke all on function public.avvisa_allenamento_tolto(public.allenamenti) from public, anon, authenticated;

create or replace function public.modifica_da_allenamento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.registra_modifica_allenamento(new.id, true);
    return null;
  end if;
  if tg_op = 'DELETE' then
    perform public.avvisa_allenamento_tolto(old);
    return old;
  end if;
  if (to_jsonb(new) - 'updated_at') = (to_jsonb(old) - 'updated_at') then
    return new;
  end if;
  perform public.registra_modifica_allenamento(old.id);
  return new;
end;
$$;

create trigger trg_allenamenti_modifica
before update or delete on public.allenamenti
for each row execute function public.modifica_da_allenamento();

create trigger trg_allenamenti_modifica_nuovo
after insert on public.allenamenti
for each row execute function public.modifica_da_allenamento();

-- Serie ed esercizi: prima della modifica, così "prima" è com'era. Segnare
-- una serie fatta o saltata (esito) non conta.
create or replace function public.modifica_da_riga_allenamento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and (to_jsonb(new) - 'updated_at' - 'esito')
       = (to_jsonb(old) - 'updated_at' - 'esito') then
    return new;
  end if;
  perform public.registra_modifica_allenamento(
    case when tg_op = 'DELETE' then old.allenamento_id else new.allenamento_id end
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger trg_serie_modifica
before insert or update or delete on public.serie
for each row execute function public.modifica_da_riga_allenamento();

create trigger trg_esercizi_seduta_modifica
before insert or update or delete on public.esercizi_seduta
for each row execute function public.modifica_da_riga_allenamento();

-- Il capo ha controllato: la modifica si chiude; la prossima ne apre
-- un'altra.
create or replace function public.segna_modifica_vista(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.modifiche_allenamento
  set visto_at = now()
  where id = p_id and capo_user_id = auth.uid() and visto_at is null;
end;
$$;

revoke all on function public.segna_modifica_vista(uuid) from public, anon;
grant execute on function public.segna_modifica_vista(uuid) to authenticated;
