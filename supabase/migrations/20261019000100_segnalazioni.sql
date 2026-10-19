-- ============================================================
-- «Scrivimi»: le segnalazioni degli allenatori (proposta 22 del piano di
-- WaterTactics, 2026-10-19). Scelte del coach: le scrivono allenatori e
-- assistenti (gli atleti segnalano al loro allenatore), le legge dentro
-- l'app chi sviluppa WaterTactics, con la schermata, la versione e la
-- pagina; chi l'ha scritta vede se è risolta e la risposta.
--
-- - `amministratori_app`: chi legge le segnalazioni di tutti i club. Si
--   riempie a mano da SQL, mai dall'app (nessuna regola di accesso).
-- - `segnalazioni`: una riga per segnalazione. Chi scrive, il suo club e
--   il nome li mette il database, non l'app.
-- - Le schermate stanno nello spazio privato `segnalazioni`, in una
--   cartella per utente: `<user_id>/<id della segnalazione>.png`.
-- - Una segnalazione nuova avvisa gli amministratori, una risposta avvisa
--   chi l'ha scritta (notifiche, quindi anche sul telefono).
-- ============================================================

create table public.amministratori_app (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.amministratori_app enable row level security;

create or replace function public.e_amministratore_app()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.amministratori_app where user_id = auth.uid()
  );
$$;

grant execute on function public.e_amministratore_app() to authenticated;

create table public.segnalazioni (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  club_id uuid references public.club(id) on delete set null,
  -- Scritti dal trigger: chi legge non vede i club degli altri.
  autore text,
  club_nome text,
  ruolo text,
  testo text not null check (length(trim(testo)) between 1 and 4000),
  versione text not null check (length(versione) between 1 and 40),
  pagina text check (pagina is null or length(pagina) <= 200),
  dispositivo text check (dispositivo is null or length(dispositivo) <= 300),
  schermo text check (schermo is null or length(schermo) <= 40),
  schermata text check (
    schermata is null
    or schermata ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.png$'
  ),
  stato text not null default 'aperta' check (stato in ('aperta', 'risolta')),
  risposta text check (risposta is null or length(trim(risposta)) between 1 and 2000),
  risolta_at timestamptz
);

create index idx_segnalazioni_user on public.segnalazioni(user_id);
create index idx_segnalazioni_aperte on public.segnalazioni(created_at desc)
  where stato = 'aperta';

alter table public.segnalazioni enable row level security;

-- Scrive solo un membro del club (responsabile, allenatore, assistente),
-- per sé.
create policy segnalazioni_insert on public.segnalazioni
  for insert with check (
    user_id = auth.uid()
    and club_id is not null
    and public.is_membro_club(club_id)
  );

create policy segnalazioni_select on public.segnalazioni
  for select using (user_id = auth.uid() or public.e_amministratore_app());

-- Stato e risposta: solo chi legge.
create policy segnalazioni_update on public.segnalazioni
  for update using (public.e_amministratore_app())
  with check (public.e_amministratore_app());

create policy segnalazioni_delete on public.segnalazioni
  for delete using (public.e_amministratore_app());

-- Chi scrive, con che nome e da quale club: dal database, non dall'app.
-- Una segnalazione nasce sempre aperta e senza risposta.
create or replace function public.segnalazione_prima_di_inserire()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.user_id := auth.uid();
  new.stato := 'aperta';
  new.risposta := null;
  new.risolta_at := null;
  new.created_at := now();
  select
    coalesce(nullif(trim(m.nome), ''), u.email, 'Un allenatore'),
    c.nome,
    m.ruolo::text
  into new.autore, new.club_nome, new.ruolo
  from public.club_membri m
  join public.club c on c.id = m.club_id
  left join auth.users u on u.id = m.user_id
  where m.club_id = new.club_id and m.user_id = new.user_id;
  return new;
end;
$$;

create trigger trg_segnalazione_prima_di_inserire
before insert on public.segnalazioni
for each row execute function public.segnalazione_prima_di_inserire();

-- Chi legge cambia solo stato e risposta; "risolta" porta la data.
create or replace function public.segnalazione_prima_di_aggiornare()
returns trigger
language plpgsql
as $$
begin
  new.id := old.id;
  new.created_at := old.created_at;
  new.user_id := old.user_id;
  new.club_id := old.club_id;
  new.autore := old.autore;
  new.club_nome := old.club_nome;
  new.ruolo := old.ruolo;
  new.testo := old.testo;
  new.versione := old.versione;
  new.pagina := old.pagina;
  new.dispositivo := old.dispositivo;
  new.schermo := old.schermo;
  new.schermata := old.schermata;
  if new.stato = 'risolta' and old.stato <> 'risolta' then
    new.risolta_at := now();
  elsif new.stato = 'aperta' then
    new.risolta_at := null;
  else
    new.risolta_at := old.risolta_at;
  end if;
  return new;
end;
$$;

create trigger trg_segnalazione_prima_di_aggiornare
before update on public.segnalazioni
for each row execute function public.segnalazione_prima_di_aggiornare();

-- Avvisi: una segnalazione nuova a ogni amministratore (nel primo club in
-- cui è membro: le notifiche stanno in un club), una risposta nuova a chi
-- l'ha scritta.
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
    'segnalazione_risposta'
  )
);

create or replace function public.segnalazione_avvisa()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin record;
  v_testo text := left(regexp_replace(trim(new.testo), '\s+', ' ', 'g'), 80);
begin
  if tg_op = 'INSERT' then
    for v_admin in
      select a.user_id,
        (select m.club_id from public.club_membri m
          where m.user_id = a.user_id
          order by m.created_at limit 1) as club_id
      from public.amministratori_app a
      where a.user_id <> new.user_id
    loop
      if v_admin.club_id is not null then
        insert into public.notifiche (club_id, tipo, messaggio, user_id, chiave)
        values (
          v_admin.club_id,
          'segnalazione',
          format(
            'Segnalazione da %s (%s): %s',
            coalesce(new.autore, 'un allenatore'),
            coalesce(new.club_nome, 'club'),
            v_testo
          ),
          v_admin.user_id,
          'segnalazione:' || new.id || ':' || v_admin.user_id
        )
        on conflict (chiave) do nothing;
      end if;
    end loop;
  elsif new.risposta is not null
    and new.risposta is distinct from old.risposta
    and new.club_id is not null
    and new.user_id <> auth.uid()
  then
    insert into public.notifiche (club_id, tipo, messaggio, user_id)
    values (
      new.club_id,
      'segnalazione_risposta',
      format('Risposta alla tua segnalazione: %s', left(new.risposta, 120)),
      new.user_id
    );
  end if;
  return null;
end;
$$;

create trigger trg_segnalazione_avvisa
after insert or update on public.segnalazioni
for each row execute function public.segnalazione_avvisa();

-- ------------------------------------------------------------
-- Le schermate: spazio privato, fino a 2 MB, solo PNG. Ognuno carica
-- nella sua cartella; leggono chi l'ha caricata e gli amministratori.
-- ------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('segnalazioni', 'segnalazioni', false, 2097152, array['image/png'])
on conflict (id) do nothing;

create policy segnalazioni_schermate_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'segnalazioni'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy segnalazioni_schermate_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'segnalazioni'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.e_amministratore_app()
    )
  );

create policy segnalazioni_schermate_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'segnalazioni' and public.e_amministratore_app());
