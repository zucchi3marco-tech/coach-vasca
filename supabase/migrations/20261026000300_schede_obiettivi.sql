-- ============================================================
-- SCHEDE OBIETTIVI (proposta 14 passo B, «Piano di WaterTactics»
-- periodo 2, 2026-10-26). L'allenatore sceglie le domande (pronte o sue)
-- e manda la scheda agli atleti di una stagione (del suo gruppo, o a
-- tutti se la stagione è di club); l'atleta risponde; l'allenatore scrive
-- due righe di ritorno. Scelte del coach: quante schede vuole in una
-- stagione, le risposte le leggono allenatori e assistenti, nessuna
-- domanda sulla salute (le pronte non ne hanno; l'app lo ricorda).
--
-- Le domande non cambiano dopo che qualcuno ha risposto: le risposte
-- sono una lista nello stesso ordine delle domande.
-- ============================================================

create table if not exists public.schede_obiettivi (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  stagione_id uuid references public.stagioni(id) on delete cascade,
  gruppo_id uuid references public.gruppi(id) on delete set null,
  titolo text not null
    check (char_length(trim(titolo)) between 1 and 80),
  domande jsonb not null
    check (
      jsonb_typeof(domande) = 'array'
      and jsonb_array_length(domande) between 1 and 10
    ),
  chiusa boolean not null default false,
  creata_da uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_schede_obiettivi_club
  on public.schede_obiettivi(club_id);

create table if not exists public.risposte_obiettivi (
  id uuid primary key default gen_random_uuid(),
  scheda_id uuid not null references public.schede_obiettivi(id) on delete cascade,
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  risposte jsonb not null check (jsonb_typeof(risposte) = 'array'),
  ritorno text check (ritorno is null or char_length(ritorno) <= 1000),
  ritorno_da uuid references auth.users(id) on delete set null,
  ritorno_at timestamptz,
  inviata_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (scheda_id, atleta_id)
);

create index if not exists idx_risposte_obiettivi_atleta
  on public.risposte_obiettivi(atleta_id);

-- ------------------------------------------------------------
-- Chi può vedere e scrivere
-- ------------------------------------------------------------

-- La scheda riguarda l'atleta collegato a questo account: del suo club e
-- del suo gruppo (o dell'altra squadra), oppure di tutto il club.
create or replace function public.scheda_obiettivi_mia(p_scheda_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.schede_obiettivi s
    join public.atleti a on a.user_id = auth.uid() and a.club_id = s.club_id
    where s.id = p_scheda_id
      and (s.gruppo_id is null
        or s.gruppo_id = a.gruppo_id
        or s.gruppo_id = a.altro_gruppo_id)
  );
$$;

-- Come sopra, e la scheda è ancora aperta: si può rispondere.
create or replace function public.scheda_obiettivi_aperta_per_me(p_scheda_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.scheda_obiettivi_mia(p_scheda_id)
    and exists (
      select 1 from public.schede_obiettivi
      where id = p_scheda_id and not chiusa
    );
$$;

grant execute on function public.scheda_obiettivi_mia(uuid) to authenticated;
grant execute on function public.scheda_obiettivi_aperta_per_me(uuid) to authenticated;

alter table public.schede_obiettivi enable row level security;
alter table public.risposte_obiettivi enable row level security;

drop policy if exists schede_obiettivi_select on public.schede_obiettivi;
create policy schede_obiettivi_select on public.schede_obiettivi
  for select using (
    public.is_membro_club(club_id) or public.scheda_obiettivi_mia(id)
  );

drop policy if exists schede_obiettivi_insert on public.schede_obiettivi;
create policy schede_obiettivi_insert on public.schede_obiettivi
  for insert with check (public.is_membro_club(club_id));

drop policy if exists schede_obiettivi_update on public.schede_obiettivi;
create policy schede_obiettivi_update on public.schede_obiettivi
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

drop policy if exists schede_obiettivi_delete on public.schede_obiettivi;
create policy schede_obiettivi_delete on public.schede_obiettivi
  for delete using (public.is_membro_club(club_id));

drop policy if exists risposte_obiettivi_select on public.risposte_obiettivi;
create policy risposte_obiettivi_select on public.risposte_obiettivi
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

-- Risponde solo l'atleta, per sé, a una scheda sua e aperta.
drop policy if exists risposte_obiettivi_insert on public.risposte_obiettivi;
create policy risposte_obiettivi_insert on public.risposte_obiettivi
  for insert with check (
    atleta_id = public.mia_atleta_id()
    and public.scheda_obiettivi_aperta_per_me(scheda_id)
  );

-- L'atleta corregge le sue finché la scheda è aperta; l'allenatore
-- scrive il ritorno (cosa può cambiare ciascuno lo decide il trigger).
drop policy if exists risposte_obiettivi_update on public.risposte_obiettivi;
create policy risposte_obiettivi_update on public.risposte_obiettivi
  for update using (
    public.is_membro_club(club_id)
    or (atleta_id = public.mia_atleta_id()
      and public.scheda_obiettivi_aperta_per_me(scheda_id))
  ) with check (
    public.is_membro_club(club_id)
    or (atleta_id = public.mia_atleta_id()
      and public.scheda_obiettivi_aperta_per_me(scheda_id))
  );

drop policy if exists risposte_obiettivi_delete on public.risposte_obiettivi;
create policy risposte_obiettivi_delete on public.risposte_obiettivi
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- Regole che l'app non può aggirare
-- ------------------------------------------------------------

-- Le domande: testi da 1 a 300 caratteri, e non cambiano dopo la prima
-- risposta.
create or replace function public.scheda_obiettivi_prima_di_salvare()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from jsonb_array_elements(new.domande) d
    where jsonb_typeof(d) <> 'string'
      or char_length(trim(d #>> '{}')) not between 1 and 300
  ) then
    raise exception 'Ogni domanda va scritta, al massimo 300 caratteri';
  end if;
  if tg_op = 'UPDATE' then
    new.club_id := old.club_id;
    new.creata_da := old.creata_da;
    new.created_at := old.created_at;
    if new.domande is distinct from old.domande and exists (
      select 1 from public.risposte_obiettivi where scheda_id = old.id
    ) then
      raise exception 'Le domande non si cambiano dopo la prima risposta';
    end if;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_schede_obiettivi_salva on public.schede_obiettivi;
create trigger trg_schede_obiettivi_salva
before insert or update on public.schede_obiettivi
for each row execute function public.scheda_obiettivi_prima_di_salvare();

-- Le risposte: il club è quello della scheda, una risposta per domanda
-- (al massimo 1000 caratteri ciascuna). L'atleta non tocca il ritorno,
-- l'allenatore non tocca le risposte; chi scrive il ritorno e quando lo
-- mette il database.
create or replace function public.risposta_obiettivi_prima_di_salvare()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_scheda public.schede_obiettivi;
  v_allenatore boolean;
begin
  select * into v_scheda from public.schede_obiettivi where id = new.scheda_id;
  new.club_id := v_scheda.club_id;
  v_allenatore := auth.uid() is not null
    and public.is_membro_club(v_scheda.club_id);

  if tg_op = 'UPDATE' then
    new.scheda_id := old.scheda_id;
    new.atleta_id := old.atleta_id;
    new.inviata_at := old.inviata_at;
    if v_allenatore then
      new.risposte := old.risposte;
    end if;
  end if;

  if auth.uid() is not null and not v_allenatore then
    if tg_op = 'UPDATE' then
      new.ritorno := old.ritorno;
      new.ritorno_da := old.ritorno_da;
      new.ritorno_at := old.ritorno_at;
    else
      new.ritorno := null;
      new.ritorno_da := null;
      new.ritorno_at := null;
    end if;
  elsif tg_op = 'UPDATE' and new.ritorno is distinct from old.ritorno then
    new.ritorno := nullif(trim(new.ritorno), '');
    new.ritorno_da := auth.uid();
    new.ritorno_at := case when new.ritorno is null then null else now() end;
  end if;

  if jsonb_array_length(new.risposte) <> jsonb_array_length(v_scheda.domande)
    or exists (
      select 1 from jsonb_array_elements(new.risposte) r
      where jsonb_typeof(r) <> 'string' or char_length(r #>> '{}') > 1000
    )
  then
    raise exception 'Una risposta per domanda, al massimo 1000 caratteri';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_risposte_obiettivi_salva on public.risposte_obiettivi;
create trigger trg_risposte_obiettivi_salva
before insert or update on public.risposte_obiettivi
for each row execute function public.risposta_obiettivi_prima_di_salvare();

-- ------------------------------------------------------------
-- Avvisi: la scheda nuova agli atleti, la risposta agli allenatori e
-- agli assistenti (tutto il club), il ritorno all'atleta.
-- ------------------------------------------------------------

alter table public.notifiche drop constraint notifiche_tipo_check;
alter table public.notifiche add constraint notifiche_tipo_check check (
  tipo in (
    'atleta_registrato',
    'convocazione_gara',
    'convocazione_partita',
    'visita_medica',
    'benessere',
    'video_partita',
    'allenamento_modificato',
    'segnalazione',
    'segnalazione_risposta',
    'scheda_obiettivi',
    'obiettivi_risposta',
    'obiettivi_ritorno'
  )
);

create or replace function public.scheda_obiettivi_avvisa()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifiche (club_id, tipo, messaggio, user_id, atleta_id, chiave)
  select
    new.club_id,
    'scheda_obiettivi',
    format('C''è una scheda da compilare: %s', new.titolo),
    a.user_id,
    a.id,
    'scheda_obiettivi:' || new.id || ':' || a.id
  from public.atleti a
  where a.club_id = new.club_id
    and a.user_id is not null
    and coalesce(a.attivo, true)
    and (new.gruppo_id is null
      or a.gruppo_id = new.gruppo_id
      or a.altro_gruppo_id = new.gruppo_id)
  on conflict (chiave) do nothing;
  return null;
end;
$$;

drop trigger if exists trg_schede_obiettivi_avvisa on public.schede_obiettivi;
create trigger trg_schede_obiettivi_avvisa
after insert on public.schede_obiettivi
for each row execute function public.scheda_obiettivi_avvisa();

create or replace function public.risposta_obiettivi_avvisa()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_titolo text;
  v_nome text;
  v_user uuid;
begin
  select titolo into v_titolo from public.schede_obiettivi where id = new.scheda_id;
  select trim(nome || ' ' || cognome), user_id into v_nome, v_user
    from public.atleti where id = new.atleta_id;
  if tg_op = 'INSERT' then
    insert into public.notifiche (club_id, tipo, messaggio, atleta_id, chiave)
    values (
      new.club_id,
      'obiettivi_risposta',
      format('%s ha risposto a «%s»', v_nome, v_titolo),
      new.atleta_id,
      'obiettivi_risposta:' || new.id
    )
    on conflict (chiave) do nothing;
  elsif new.ritorno is not null
    and new.ritorno is distinct from old.ritorno
    and v_user is not null
  then
    insert into public.notifiche (club_id, tipo, messaggio, user_id, atleta_id)
    values (
      new.club_id,
      'obiettivi_ritorno',
      format('L''allenatore ti ha scritto su «%s»: %s', v_titolo, left(new.ritorno, 120)),
      v_user,
      new.atleta_id
    );
  end if;
  return null;
end;
$$;

drop trigger if exists trg_risposte_obiettivi_avvisa on public.risposte_obiettivi;
create trigger trg_risposte_obiettivi_avvisa
after insert or update on public.risposte_obiettivi
for each row execute function public.risposta_obiettivi_avvisa();
