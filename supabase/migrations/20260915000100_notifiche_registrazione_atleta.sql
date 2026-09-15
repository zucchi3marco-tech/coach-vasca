-- ============================================================
-- NOTIFICHE (FASE 13, punto 1): avvisa il coach quando un atleta
-- completa la registrazione (con codice personale o di gruppo).
-- Nessuna infrastruttura push/email nell'app: notifica in-app,
-- letta dal coach nell'AppBar della Home (stesso schema
-- dell'indicatore di sincronizzazione gia' esistente).
-- Le righe si creano solo dalle funzioni SECURITY DEFINER di
-- registrazione atleta, mai da un insert diretto del client.
-- ============================================================

create table public.notifiche (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  tipo text not null check (tipo in ('atleta_registrato')),
  messaggio text not null,
  letta boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifiche_club on public.notifiche(club_id);

alter table public.notifiche enable row level security;

create policy notifiche_select on public.notifiche
  for select using (public.is_membro_club(club_id));

-- Solo per segnare come letta.
create policy notifiche_update on public.notifiche
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy notifiche_delete on public.notifiche
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- registra_atleta_da_codice_gruppo: aggiunge la notifica dopo
-- aver creato il nuovo atleta. Corpo invariato per il resto
-- (stessa versione con default su p_sesso/p_sport del
-- 2026-09-14).
-- ------------------------------------------------------------

create or replace function public.registra_atleta_da_codice_gruppo(
  p_codice text,
  p_nome text,
  p_cognome text,
  p_data_nascita date,
  p_sesso text default null,
  p_sport text default null
)
returns public.atleti
language plpgsql
security definer
set search_path = public
as $$
declare
  v_codice public.codici_gruppo;
  v_atleta public.atleti;
  v_gruppo_nome text;
begin
  if exists (select 1 from public.atleti where user_id = auth.uid()) then
    raise exception 'Questo account e'' gia'' collegato a un atleta';
  end if;

  select * into v_codice
  from public.codici_gruppo
  where codice = upper(p_codice)
    and scade_il > now();

  if v_codice is null then
    raise exception 'Codice non valido o scaduto';
  end if;

  if p_nome is null or length(trim(p_nome)) = 0
    or p_cognome is null or length(trim(p_cognome)) = 0
    or p_data_nascita is null then
    raise exception 'Nome, cognome e data di nascita sono obbligatori';
  end if;

  insert into public.atleti (
    club_id, nome, cognome, data_nascita, sesso, sport, gruppo_id, user_id
  )
  values (
    v_codice.club_id, trim(p_nome), trim(p_cognome), p_data_nascita,
    p_sesso, coalesce(p_sport, 'nuoto')::public.sport, v_codice.gruppo_id, auth.uid()
  )
  returning * into v_atleta;

  select nome into v_gruppo_nome from public.gruppi where id = v_codice.gruppo_id;

  insert into public.notifiche (club_id, tipo, messaggio)
  values (
    v_codice.club_id,
    'atleta_registrato',
    v_atleta.nome || ' ' || v_atleta.cognome || ' si e'' registrato/a nel gruppo ' ||
      coalesce(v_gruppo_nome, '?')
  );

  return v_atleta;
end;
$$;

grant execute on function public.registra_atleta_da_codice_gruppo(
  text, text, text, date, text, text
) to authenticated;

-- ------------------------------------------------------------
-- collega_atleta_da_invito: aggiunge la notifica dopo aver
-- collegato l'atleta gia' esistente. Corpo invariato per il
-- resto.
-- ------------------------------------------------------------

create or replace function public.collega_atleta_da_invito(p_codice text)
returns public.atleti
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invito public.inviti_atleta;
  v_atleta public.atleti;
  v_gruppo_nome text;
begin
  if exists (select 1 from public.atleti where user_id = auth.uid()) then
    raise exception 'Questo account e'' gia'' collegato a un atleta';
  end if;

  select * into v_invito
  from public.inviti_atleta
  where codice = upper(p_codice)
    and usato_il is null
    and scade_il > now()
  for update;

  if v_invito is null then
    raise exception 'Codice invito non valido o scaduto';
  end if;

  update public.atleti
  set user_id = auth.uid()
  where id = v_invito.atleta_id
  returning * into v_atleta;

  update public.inviti_atleta
  set usato_il = now(), usato_da = auth.uid()
  where id = v_invito.id;

  select nome into v_gruppo_nome from public.gruppi where id = v_atleta.gruppo_id;

  insert into public.notifiche (club_id, tipo, messaggio)
  values (
    v_atleta.club_id,
    'atleta_registrato',
    v_atleta.nome || ' ' || v_atleta.cognome || ' ha completato la registrazione' ||
      case when v_gruppo_nome is null then '' else ' (gruppo ' || v_gruppo_nome || ')' end
  );

  return v_atleta;
end;
$$;

grant execute on function public.collega_atleta_da_invito(text) to authenticated;
