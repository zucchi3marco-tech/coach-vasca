-- ============================================================
-- NOTIFICHE DI CONVOCAZIONE (fase C2): quando il coach iscrive un atleta
-- a una gara o lo convoca in una partita, l'atleta (se ha un account
-- collegato) riceve una notifica personale, che poi la funzione
-- `invia-push` manda anche sul telefono.
-- Sta nel database e non nell'app perche' le insert possono arrivare
-- dalla coda offline: il trigger scatta comunque una volta sola.
-- Una sola notifica per atleta e per evento (chiave): togliere e
-- rimettere lo stesso atleta non lo avvisa di nuovo.
-- ============================================================

create or replace function public.notifica_convocazione_gara()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid;
  v_nome text;
  v_data date;
begin
  select user_id into v_user from public.atleti where id = new.atleta_id;
  if v_user is null then
    return new;
  end if;
  select nome, data into v_nome, v_data from public.gare where id = new.gara_id;
  insert into public.notifiche (club_id, tipo, messaggio, user_id, atleta_id, chiave)
  values (
    new.club_id,
    'convocazione_gara',
    format('Sei stato iscritto/a alla gara %s del %s', v_nome, to_char(v_data, 'DD/MM/YYYY')),
    v_user,
    new.atleta_id,
    'gara:' || new.gara_id || ':' || new.atleta_id
  )
  on conflict (chiave) do nothing;
  return new;
end;
$$;

create trigger trg_gara_iscritti_notifica
after insert on public.gara_iscritti
for each row execute function public.notifica_convocazione_gara();

create or replace function public.notifica_convocazione_partita()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid;
  v_club uuid;
  v_casa text;
  v_trasferta text;
  v_data date;
begin
  select user_id into v_user from public.atleti where id = new.atleta_id;
  if v_user is null then
    return new;
  end if;
  select club_id, squadra_casa, squadra_trasferta, data
    into v_club, v_casa, v_trasferta, v_data
    from public.partite where id = new.partita_id;
  insert into public.notifiche (club_id, tipo, messaggio, user_id, atleta_id, chiave)
  values (
    v_club,
    'convocazione_partita',
    format('Sei stato convocato/a per la partita %s - %s del %s', v_casa, v_trasferta, to_char(v_data, 'DD/MM/YYYY')),
    v_user,
    new.atleta_id,
    'partita:' || new.partita_id || ':' || new.atleta_id
  )
  on conflict (chiave) do nothing;
  return new;
end;
$$;

create trigger trg_distinta_giocatori_notifica
after insert on public.distinta_giocatori
for each row execute function public.notifica_convocazione_partita();
