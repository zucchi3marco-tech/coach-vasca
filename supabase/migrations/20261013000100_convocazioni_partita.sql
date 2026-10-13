-- ============================================================
-- CONVOCAZIONI E MESSAGGI ALLE FAMIGLIE (Fase 3 del "Mako della
-- pallanuoto", proposta 7)
--
-- Dalla distinta nasce la convocazione: accanto a ora, piscina e
-- calottina che la partita aveva gia', il ritrovo (ora e luogo), il
-- rientro previsto, cosa portare e una nota per le famiglie. Sono dati di
-- squadra come il resto della partita: l'atleta li legge gia' con
-- `partite_select_atleta`.
--
-- Scelta del coach: l'avviso all'atleta non parte piu' a ogni convocato
-- aggiunto in distinta (arrivava subito, senza ritrovo ne' orari, anche a
-- chi poi veniva tolto). Parte quando l'allenatore tocca "Invia ai
-- convocati", che scrive `convocazione_inviata_at`: un avviso completo a
-- ogni convocato con l'account collegato. Chi viene aggiunto dopo l'invio
-- lo riceve subito; un nuovo invio manda "Convocazione aggiornata".
-- Tutto nel database, come prima: l'invio puo' arrivare dalla coda
-- offline e il trigger scatta comunque una volta sola per invio (chiave).
-- ============================================================

alter table public.partite
  add column if not exists ritrovo_ora text,
  add column if not exists ritrovo_luogo text,
  add column if not exists rientro_ora text,
  add column if not exists da_portare text,
  add column if not exists note_convocazione text,
  add column if not exists convocazione_inviata_at timestamptz;

alter table public.partite drop constraint if exists partite_convocazione_check;
alter table public.partite add constraint partite_convocazione_check check (
  (ritrovo_ora is null or ritrovo_ora ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
  and (rientro_ora is null or rientro_ora ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
  and coalesce(char_length(ritrovo_luogo), 0) <= 200
  and coalesce(char_length(da_portare), 0) <= 500
  and coalesce(char_length(note_convocazione), 0) <= 1000
);

-- Il testo dell'avviso (anche sul telefono, con `invia-push`): chi,
-- quando e il ritrovo.
-- "Sei convocato/a per la partita A - B del 18/10/2026 alle 16:00.
--  Ritrovo alle 15:00, piscina del club."
create or replace function public.messaggio_convocazione(
  p_partita_id uuid,
  p_aggiornata boolean
)
returns text
language sql
stable
set search_path = public
as $$
  select format(
    '%s per la partita %s - %s del %s%s.%s',
    case when p_aggiornata then 'Convocazione aggiornata' else 'Sei convocato/a' end,
    p.squadra_casa,
    p.squadra_trasferta,
    to_char(p.data, 'DD/MM/YYYY'),
    coalesce(' alle ' || nullif(trim(p.ora), ''), ''),
    case
      when p.ritrovo_ora is not null then
        ' Ritrovo alle ' || p.ritrovo_ora
          || coalesce(', ' || nullif(trim(p.ritrovo_luogo), ''), '') || '.'
      when nullif(trim(p.ritrovo_luogo), '') is not null then
        ' Ritrovo: ' || trim(p.ritrovo_luogo) || '.'
      else ''
    end
  )
  from public.partite p
  where p.id = p_partita_id;
$$;

-- "Invia ai convocati": un avviso a ogni convocato con l'account. A chi
-- aveva gia' avuto la convocazione di questa partita (anche il vecchio
-- avviso "Sei stato convocato/a") arriva "Convocazione aggiornata".
create or replace function public.notifica_invio_convocazione()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invio text := floor(extract(epoch from new.convocazione_inviata_at))::bigint::text;
begin
  insert into public.notifiche (club_id, tipo, messaggio, user_id, atleta_id, chiave)
  select
    new.club_id,
    'convocazione_partita',
    public.messaggio_convocazione(
      new.id,
      exists (
        select 1 from public.notifiche n
        where n.chiave = 'partita:' || new.id || ':' || a.id
           or n.chiave like 'convocazione:' || new.id || ':' || a.id || ':%'
      )
    ),
    a.user_id,
    a.id,
    'convocazione:' || new.id || ':' || a.id || ':' || v_invio
  from public.distinta_giocatori d
  join public.atleti a on a.id = d.atleta_id
  where d.partita_id = new.id and a.user_id is not null
  on conflict (chiave) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_partite_convocazione on public.partite;
create trigger trg_partite_convocazione
after update of convocazione_inviata_at on public.partite
for each row
when (
  new.convocazione_inviata_at is not null
  and new.convocazione_inviata_at is distinct from old.convocazione_inviata_at
)
execute function public.notifica_invio_convocazione();

-- Un convocato aggiunto in distinta: finche' la convocazione non e'
-- inviata nessun avviso; dopo l'invio, il suo avviso completo subito
-- (stessa chiave dell'invio: tolto e rimesso non lo riceve due volte).
-- Mai per una partita gia' giocata (la distinta sistemata dopo).
create or replace function public.notifica_convocazione_partita()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid;
  v_club uuid;
  v_data date;
  v_inviata timestamptz;
begin
  select user_id into v_user from public.atleti where id = new.atleta_id;
  if v_user is null then
    return new;
  end if;
  select club_id, data, convocazione_inviata_at
    into v_club, v_data, v_inviata
    from public.partite where id = new.partita_id;
  if v_inviata is null or v_data < current_date then
    return new;
  end if;
  insert into public.notifiche (club_id, tipo, messaggio, user_id, atleta_id, chiave)
  values (
    v_club,
    'convocazione_partita',
    public.messaggio_convocazione(new.partita_id, false),
    v_user,
    new.atleta_id,
    'convocazione:' || new.partita_id || ':' || new.atleta_id || ':'
      || floor(extract(epoch from v_inviata))::bigint::text
  )
  on conflict (chiave) do nothing;
  return new;
end;
$$;
