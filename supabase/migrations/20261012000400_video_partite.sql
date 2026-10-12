-- ============================================================
-- VIDEO DELLA PARTITA COLLEGATO AGLI EVENTI (fase 3 del "Mako della
-- pallanuoto", proposta 6): il link al video YouTube (non in elenco)
-- della partita, allineato agli eventi registrati dal vivo, cosi' ogni
-- tiro, espulsione o palla persa diventa una clip ("tutte le
-- superiorita'", "tutti i tiri di Rossi"). Sul fotogramma fermo
-- l'allenatore disegna frecce e cerchi e scrive una nota, per tutta la
-- squadra o per un giocatore.
-- Nessun file caricato: il video resta su YouTube.
-- Lo vedono gli allenatori del club e gli atleti convocati in quella
-- partita; le note per un giocatore solo lui (e gli allenatori).
-- ============================================================

-- Un atleta collegato all'account e' convocato in questa partita.
create or replace function public.convocato_in_partita(p_partita_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.distinta_giocatori
    where partita_id = p_partita_id and atleta_id = public.mia_atleta_id()
  );
$$;

grant execute on function public.convocato_in_partita(uuid) to authenticated;

-- Il video di una partita (uno solo: tutta la partita, anche tagliata
-- fra un tempo e l'altro).
create table public.video_partite (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  partita_id uuid not null unique references public.partite(id) on delete cascade,
  youtube_id text not null check (youtube_id ~ '^[A-Za-z0-9_-]{11}$'),
  -- I punti di allineamento: [{"secondo": 125.4, "momento":
  -- "2026-10-12T15:03:22Z", "periodo": 1, "evento_id": "..."}] — nel
  -- video, al secondo `secondo`, succede l'evento registrato al
  -- `momento`. Un evento si cerca nel video con il punto del suo stesso
  -- tempo piu' vicino (se no il piu' vicino prima): con un video unico ne
  -- basta uno, dopo un taglio se ne aggiunge un altro.
  allineamenti jsonb not null default '[]'::jsonb
    check (jsonb_typeof(allineamenti) = 'array'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_video_partite_club on public.video_partite(club_id);

create trigger trg_video_partite_updated_at
before update on public.video_partite
for each row execute function public.set_updated_at();

-- club_id dalla partita.
create or replace function public.imposta_club_video_partita()
returns trigger
language plpgsql
as $$
begin
  select club_id into new.club_id from public.partite where id = new.partita_id;
  if new.club_id is null then
    raise exception 'Partita % non trovata', new.partita_id;
  end if;
  return new;
end;
$$;

create trigger trg_video_partite_club
before insert or update of partita_id on public.video_partite
for each row execute function public.imposta_club_video_partita();

alter table public.video_partite enable row level security;

create policy video_partite_select on public.video_partite
  for select using (
    public.is_membro_club(club_id) or public.convocato_in_partita(partita_id)
  );

create policy video_partite_insert on public.video_partite
  for insert with check (public.is_membro_club(club_id));

create policy video_partite_update on public.video_partite
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy video_partite_delete on public.video_partite
  for delete using (public.is_membro_club(club_id));

-- Le note sul video: un fotogramma (il secondo), il disegno sopra
-- (frecce e cerchi in coordinate 0-1 sul riquadro del video) e un testo,
-- per tutta la squadra (atleta_id nullo) o per un convocato.
create table public.note_video (
  id uuid primary key default gen_random_uuid(),
  video_id uuid not null references public.video_partite(id) on delete cascade,
  partita_id uuid not null references public.partite(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  secondo numeric(8, 2) not null check (secondo >= 0),
  -- La clip da cui e' nata, se c'e'.
  evento_id uuid references public.eventi_partita(id) on delete set null,
  atleta_id uuid references public.atleti(id) on delete cascade,
  testo text check (testo is null or length(testo) <= 1000),
  -- [{"forma": "freccia" | "cerchio", "colore": "rosso", "da": [x, y],
  --   "a": [x, y]}]
  disegno jsonb not null default '[]'::jsonb
    check (jsonb_typeof(disegno) = 'array' and jsonb_array_length(disegno) <= 40),
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Una nota vuota non serve.
  check (
    (testo is not null and length(trim(testo)) > 0)
    or jsonb_array_length(disegno) > 0
  )
);

create index idx_note_video_video on public.note_video(video_id, secondo);
create index idx_note_video_club on public.note_video(club_id);

create trigger trg_note_video_updated_at
before update on public.note_video
for each row execute function public.set_updated_at();

-- partita e club dal video; il giocatore deve essere convocato in quella
-- partita (gli altri non la vedrebbero) e la clip della stessa partita.
create or replace function public.valida_nota_video()
returns trigger
language plpgsql
as $$
begin
  select partita_id, club_id into new.partita_id, new.club_id
  from public.video_partite where id = new.video_id;
  if new.club_id is null then
    raise exception 'Video % non trovato', new.video_id;
  end if;
  if new.atleta_id is not null and not exists (
    select 1 from public.distinta_giocatori
    where partita_id = new.partita_id and atleta_id = new.atleta_id
  ) then
    raise exception 'L''atleta % non e'' convocato in questa partita', new.atleta_id;
  end if;
  if new.evento_id is not null and not exists (
    select 1 from public.eventi_partita
    where id = new.evento_id and partita_id = new.partita_id
  ) then
    raise exception 'L''evento % non e'' di questa partita', new.evento_id;
  end if;
  return new;
end;
$$;

create trigger trg_note_video_valida
before insert or update of video_id, atleta_id, evento_id on public.note_video
for each row execute function public.valida_nota_video();

alter table public.note_video enable row level security;

create policy note_video_select on public.note_video
  for select using (
    public.is_membro_club(club_id)
    or (
      public.convocato_in_partita(partita_id)
      and (atleta_id is null or atleta_id = public.mia_atleta_id())
    )
  );

create policy note_video_insert on public.note_video
  for insert with check (public.is_membro_club(club_id));

create policy note_video_update on public.note_video
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy note_video_delete on public.note_video
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- Notifiche: ai convocati con l'account quando arriva il video, e a un
-- giocatore quando c'e' una nota per lui (una sola per partita: dieci
-- note di fila non mandano dieci avvisi).
-- ------------------------------------------------------------

alter table public.notifiche drop constraint notifiche_tipo_check;
alter table public.notifiche add constraint notifiche_tipo_check check (
  tipo in (
    'atleta_registrato',
    'convocazione_gara',
    'convocazione_partita',
    'visita_medica',
    'benessere',
    'video_partita'
  )
);

create or replace function public.notifica_video_partita()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_casa text;
  v_trasferta text;
  v_data date;
begin
  select squadra_casa, squadra_trasferta, data
    into v_casa, v_trasferta, v_data
    from public.partite where id = new.partita_id;
  insert into public.notifiche (club_id, tipo, messaggio, user_id, atleta_id, chiave)
  select
    new.club_id,
    'video_partita',
    format('C''e'' il video della partita %s - %s del %s', v_casa, v_trasferta, to_char(v_data, 'DD/MM/YYYY')),
    a.user_id,
    a.id,
    'video:' || new.partita_id || ':' || a.id
  from public.distinta_giocatori d
  join public.atleti a on a.id = d.atleta_id
  where d.partita_id = new.partita_id and a.user_id is not null
  on conflict (chiave) do nothing;
  return new;
end;
$$;

create trigger trg_video_partite_notifica
after insert on public.video_partite
for each row execute function public.notifica_video_partita();

create or replace function public.notifica_nota_video()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid;
  v_casa text;
  v_trasferta text;
begin
  if new.atleta_id is null then
    return new;
  end if;
  select user_id into v_user from public.atleti where id = new.atleta_id;
  if v_user is null then
    return new;
  end if;
  select squadra_casa, squadra_trasferta into v_casa, v_trasferta
    from public.partite where id = new.partita_id;
  insert into public.notifiche (club_id, tipo, messaggio, user_id, atleta_id, chiave)
  values (
    new.club_id,
    'video_partita',
    format('C''e'' una nota per te nel video della partita %s - %s', v_casa, v_trasferta),
    v_user,
    new.atleta_id,
    'nota_video:' || new.partita_id || ':' || new.atleta_id
  )
  on conflict (chiave) do nothing;
  return new;
end;
$$;

create trigger trg_note_video_notifica
after insert on public.note_video
for each row execute function public.notifica_nota_video();
