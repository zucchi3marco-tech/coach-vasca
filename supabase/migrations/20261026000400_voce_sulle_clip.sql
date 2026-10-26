-- ============================================================
-- LA VOCE SULLE CLIP (proposta 15, «Piano di WaterTactics» periodo 2,
-- 2026-10-26). Sulla nota di una clip l'allenatore registra un commento a
-- voce mentre la clip scorre (fino a 3 minuti); chi vede la nota lo
-- riascolta con il video. Sotto la nota il giocatore scrive una risposta:
-- una sola, che può correggere; la leggono lui e lo staff del club (anche
-- quando la nota è per tutta la squadra).
-- ============================================================

-- ------------------------------------------------------------
-- Il commento a voce sulla nota
-- ------------------------------------------------------------

alter table public.note_video
  add column if not exists audio_path text,
  add column if not exists audio_secondi numeric(6, 2)
    check (audio_secondi is null or (audio_secondi > 0 and audio_secondi <= 185));

-- Una nota ora può avere solo la voce.
do $$
declare
  v_nome text;
begin
  for v_nome in
    select conname from pg_constraint
    where conrelid = 'public.note_video'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%jsonb_array_length(disegno) > 0%'
  loop
    execute format('alter table public.note_video drop constraint %I', v_nome);
  end loop;
end $$;

alter table public.note_video drop constraint if exists note_video_non_vuota;
alter table public.note_video add constraint note_video_non_vuota check (
  (testo is not null and length(trim(testo)) > 0)
  or jsonb_array_length(disegno) > 0
  or audio_path is not null
);

-- Il file sta nella cartella del club della nota.
alter table public.note_video drop constraint if exists note_video_audio_del_club;
alter table public.note_video add constraint note_video_audio_del_club check (
  audio_path is null or audio_path like club_id::text || '/%'
);

-- Chi vede la nota (lo staff, o il convocato a cui è rivolta) sente la
-- voce: la stessa regola di `note_video_select`, per i file.
create or replace function public.nota_video_mia(p_nota_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.note_video n
    where n.id = p_nota_id
      and public.convocato_in_partita(n.partita_id)
      and (n.atleta_id is null or n.atleta_id = public.mia_atleta_id())
  );
$$;

create or replace function public.audio_nota_visibile(p_path text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.note_video n
    where n.audio_path = p_path
      and (
        public.is_membro_club(n.club_id)
        or public.nota_video_mia(n.id)
      )
  );
$$;

grant execute on function public.nota_video_mia(uuid) to authenticated;
grant execute on function public.audio_nota_visibile(text) to authenticated;

-- Spazio privato per i commenti a voce: fino a 6 MB (3 minuti stanno in
-- molto meno), solo audio. Scrive lo staff nella cartella del club;
-- ascolta chi vede la nota.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'note_vocali',
  'note_vocali',
  false,
  6291456,
  array['audio/webm', 'audio/mp4', 'audio/ogg', 'audio/mpeg', 'audio/aac']
)
on conflict (id) do nothing;

drop policy if exists note_vocali_insert on storage.objects;
create policy note_vocali_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'note_vocali'
    and public.is_membro_club(((storage.foldername(name))[1])::uuid)
  );

drop policy if exists note_vocali_update on storage.objects;
create policy note_vocali_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'note_vocali'
    and public.is_membro_club(((storage.foldername(name))[1])::uuid)
  );

drop policy if exists note_vocali_delete on storage.objects;
create policy note_vocali_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'note_vocali'
    and public.is_membro_club(((storage.foldername(name))[1])::uuid)
  );

drop policy if exists note_vocali_select on storage.objects;
create policy note_vocali_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'note_vocali'
    and (
      public.is_membro_club(((storage.foldername(name))[1])::uuid)
      or public.audio_nota_visibile(name)
    )
  );

-- ------------------------------------------------------------
-- La risposta scritta del giocatore
-- ------------------------------------------------------------

create table if not exists public.risposte_note_video (
  id uuid primary key default gen_random_uuid(),
  nota_id uuid not null references public.note_video(id) on delete cascade,
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  partita_id uuid not null references public.partite(id) on delete cascade,
  testo text not null
    check (char_length(trim(testo)) between 1 and 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (nota_id, atleta_id)
);

create index if not exists idx_risposte_note_video_partita
  on public.risposte_note_video(partita_id);

-- Club e partita dalla nota; chi e su quale nota non cambiano.
create or replace function public.risposta_nota_prima_di_salvare()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' then
    new.nota_id := old.nota_id;
    new.atleta_id := old.atleta_id;
    new.created_at := old.created_at;
  end if;
  select club_id, partita_id into new.club_id, new.partita_id
    from public.note_video where id = new.nota_id;
  new.testo := trim(new.testo);
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_risposte_note_video_salva on public.risposte_note_video;
create trigger trg_risposte_note_video_salva
before insert or update on public.risposte_note_video
for each row execute function public.risposta_nota_prima_di_salvare();

alter table public.risposte_note_video enable row level security;

drop policy if exists risposte_note_video_select on public.risposte_note_video;
create policy risposte_note_video_select on public.risposte_note_video
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

drop policy if exists risposte_note_video_insert on public.risposte_note_video;
create policy risposte_note_video_insert on public.risposte_note_video
  for insert with check (
    atleta_id = public.mia_atleta_id() and public.nota_video_mia(nota_id)
  );

drop policy if exists risposte_note_video_update on public.risposte_note_video;
create policy risposte_note_video_update on public.risposte_note_video
  for update using (
    atleta_id = public.mia_atleta_id() and public.nota_video_mia(nota_id)
  ) with check (
    atleta_id = public.mia_atleta_id() and public.nota_video_mia(nota_id)
  );

drop policy if exists risposte_note_video_delete on public.risposte_note_video;
create policy risposte_note_video_delete on public.risposte_note_video
  for delete using (
    atleta_id = public.mia_atleta_id() or public.is_membro_club(club_id)
  );

-- Avviso allo staff (tutto il club) alla prima risposta.
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
    'obiettivi_ritorno',
    'nota_video_risposta'
  )
);

create or replace function public.risposta_nota_avvisa()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nome text;
  v_casa text;
  v_trasferta text;
begin
  select trim(nome || ' ' || cognome) into v_nome
    from public.atleti where id = new.atleta_id;
  select squadra_casa, squadra_trasferta into v_casa, v_trasferta
    from public.partite where id = new.partita_id;
  insert into public.notifiche (club_id, tipo, messaggio, atleta_id, chiave)
  values (
    new.club_id,
    'nota_video_risposta',
    format(
      '%s ha risposto a una nota del video %s - %s: %s',
      v_nome, v_casa, v_trasferta, left(new.testo, 100)
    ),
    new.atleta_id,
    'nota_video_risposta:' || new.id
  )
  on conflict (chiave) do nothing;
  return null;
end;
$$;

drop trigger if exists trg_risposte_note_video_avvisa on public.risposte_note_video;
create trigger trg_risposte_note_video_avvisa
after insert on public.risposte_note_video
for each row execute function public.risposta_nota_avvisa();
