-- ============================================================
-- ACCOUNT ATLETA (FASE 9): un atleta puo' avere un proprio login,
-- collegato a UN SOLO record in atleti tramite user_id. Le policy
-- aggiunte qui sono permissive e si sommano a quelle gia' esistenti
-- basate su is_membro_club(): un coach continua a vedere tutto come
-- prima, un atleta collegato vede in piu' anche il proprio record.
-- ============================================================

alter table public.atleti
  add column user_id uuid references auth.users(id);

create unique index idx_atleti_user_id on public.atleti(user_id) where user_id is not null;

-- ------------------------------------------------------------
-- Funzioni helper (stesso pattern di is_membro_club/is_owner_club):
-- security definer per evitare valutazioni ricorsive della RLS su
-- atleti dentro le policy di atleti/presenze/allenamenti/serie.
-- ------------------------------------------------------------

create or replace function public.mia_atleta_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.atleti where user_id = auth.uid();
$$;

create or replace function public.mio_club_atleta()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select club_id from public.atleti where user_id = auth.uid();
$$;

grant execute on function public.mia_atleta_id() to authenticated;
grant execute on function public.mio_club_atleta() to authenticated;

-- ------------------------------------------------------------
-- Policy aggiuntive di sola lettura per l'atleta collegato.
-- ------------------------------------------------------------

create policy atleti_select_self on public.atleti
  for select using (id = public.mia_atleta_id());

-- Serve perche' l'Area atleta mostra il nome del club nell'intestazione:
-- senza questa policy un atleta collegato non potrebbe leggere neppure
-- la propria riga in club (non e' un club_membri).
create policy club_select_self on public.club
  for select using (id = public.mio_club_atleta());

create policy presenze_select_self on public.presenze
  for select using (atleta_id = public.mia_atleta_id());

-- Il carico si calcola client-side da serie+allenamenti+presenze (vedi
-- CaricoRepository): l'atleta deve poter leggere serie/allenamenti del
-- proprio club per farlo, non solo le proprie presenze. Non e' un dato
-- personale/sensibile (contenuto di un allenamento), quindi va bene
-- scoped al club invece che al singolo gruppo (gruppo e' testo libero,
-- non collegabile in modo affidabile via RLS).
create policy allenamenti_select_self on public.allenamenti
  for select using (club_id = public.mio_club_atleta());

create policy serie_select_self on public.serie
  for select using (club_id = public.mio_club_atleta());
