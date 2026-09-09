-- ============================================================
-- GRUPPI: tabella formale per club (FASE 10, ultimo punto), al posto del
-- campo "gruppo" testo libero su atleti/allenamenti/stagioni/codici_gruppo.
-- Il backfill crea i gruppi giusti dai valori testo gia' esistenti PRIMA
-- di eliminare le vecchie colonne, cosi' nessun raggruppamento si perde.
-- ============================================================

create table public.gruppi (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  nome text not null,
  ordine integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (club_id, nome)
);

create index idx_gruppi_club on public.gruppi(club_id);

create trigger trg_gruppi_updated_at
before update on public.gruppi
for each row execute function public.set_updated_at();

alter table public.gruppi enable row level security;

create policy gruppi_select on public.gruppi
  for select using (public.is_membro_club(club_id));

create policy gruppi_insert on public.gruppi
  for insert with check (public.is_membro_club(club_id));

create policy gruppi_update on public.gruppi
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy gruppi_delete on public.gruppi
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- Backfill: un gruppo per ogni valore testo distinto gia' in uso.
-- ------------------------------------------------------------

insert into public.gruppi (club_id, nome)
select distinct club_id, gruppo from public.atleti
where gruppo is not null and length(trim(gruppo)) > 0
on conflict (club_id, nome) do nothing;

insert into public.gruppi (club_id, nome)
select distinct club_id, gruppo from public.allenamenti
where gruppo is not null and length(trim(gruppo)) > 0
on conflict (club_id, nome) do nothing;

insert into public.gruppi (club_id, nome)
select distinct club_id, gruppo from public.stagioni
where gruppo is not null and length(trim(gruppo)) > 0
on conflict (club_id, nome) do nothing;

insert into public.gruppi (club_id, nome)
select distinct club_id, gruppo from public.codici_gruppo
where gruppo is not null and length(trim(gruppo)) > 0
on conflict (club_id, nome) do nothing;

-- ------------------------------------------------------------
-- Atleti: gruppo_id al posto di gruppo.
-- ------------------------------------------------------------

alter table public.atleti add column gruppo_id uuid references public.gruppi(id) on delete set null;

update public.atleti a
set gruppo_id = g.id
from public.gruppi g
where g.club_id = a.club_id and g.nome = a.gruppo;

alter table public.atleti drop column gruppo;

-- ------------------------------------------------------------
-- Allenamenti: gruppo_id al posto di gruppo.
-- ------------------------------------------------------------

alter table public.allenamenti add column gruppo_id uuid references public.gruppi(id) on delete set null;

update public.allenamenti a
set gruppo_id = g.id
from public.gruppi g
where g.club_id = a.club_id and g.nome = a.gruppo;

alter table public.allenamenti drop column gruppo;

-- ------------------------------------------------------------
-- Stagioni: gruppo_id al posto di gruppo.
-- ------------------------------------------------------------

alter table public.stagioni add column gruppo_id uuid references public.gruppi(id) on delete set null;

update public.stagioni a
set gruppo_id = g.id
from public.gruppi g
where g.club_id = a.club_id and g.nome = a.gruppo;

alter table public.stagioni drop column gruppo;

-- ------------------------------------------------------------
-- Codici gruppo: gruppo_id al posto di gruppo (qui not null: un codice
-- invito senza il suo gruppo non ha senso, e va eliminato con lui).
-- ------------------------------------------------------------

alter table public.codici_gruppo add column gruppo_id uuid references public.gruppi(id) on delete cascade;

update public.codici_gruppo c
set gruppo_id = g.id
from public.gruppi g
where g.club_id = c.club_id and g.nome = c.gruppo;

alter table public.codici_gruppo alter column gruppo_id set not null;
alter table public.codici_gruppo drop column gruppo;

-- ------------------------------------------------------------
-- genera_codice_gruppo: ora prende l'id del gruppo, non il nome.
-- ------------------------------------------------------------

drop function if exists public.genera_codice_gruppo(uuid, text);

create or replace function public.genera_codice_gruppo(p_club_id uuid, p_gruppo_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_codice text;
begin
  if not public.is_membro_club(p_club_id) then
    raise exception 'Non autorizzato';
  end if;
  if not exists (
    select 1 from public.gruppi where id = p_gruppo_id and club_id = p_club_id
  ) then
    raise exception 'Gruppo non valido per questo club';
  end if;

  v_codice := upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 10));

  insert into public.codici_gruppo (club_id, gruppo_id, creato_da, codice)
  values (p_club_id, p_gruppo_id, auth.uid(), v_codice);

  return v_codice;
end;
$$;

grant execute on function public.genera_codice_gruppo(uuid, uuid) to authenticated;

-- ------------------------------------------------------------
-- valida_codice_gruppo: ritorna il nome del gruppo (join), non piu' un
-- campo testo diretto.
-- ------------------------------------------------------------

drop function if exists public.valida_codice_gruppo(text);

create or replace function public.valida_codice_gruppo(p_codice text)
returns table (gruppo_nome text, club_nome text)
language sql
stable
security definer
set search_path = public
as $$
  select g.nome, cl.nome
  from public.codici_gruppo c
  join public.club cl on cl.id = c.club_id
  join public.gruppi g on g.id = c.gruppo_id
  where c.codice = upper(p_codice)
    and c.scade_il > now();
$$;

grant execute on function public.valida_codice_gruppo(text) to anon, authenticated;

-- ------------------------------------------------------------
-- registra_atleta_da_codice_gruppo: assegna gruppo_id direttamente dal
-- codice, invece di copiare testo libero.
-- ------------------------------------------------------------

create or replace function public.registra_atleta_da_codice_gruppo(
  p_codice text,
  p_nome text,
  p_cognome text,
  p_data_nascita date,
  p_sesso text,
  p_sport text
)
returns public.atleti
language plpgsql
security definer
set search_path = public
as $$
declare
  v_codice public.codici_gruppo;
  v_atleta public.atleti;
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

  return v_atleta;
end;
$$;

grant execute on function public.registra_atleta_da_codice_gruppo(
  text, text, text, date, text, text
) to authenticated;
