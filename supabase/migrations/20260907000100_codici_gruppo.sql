-- ============================================================
-- CODICI DI GRUPPO: un solo codice, generato dal coach per un intero
-- gruppo (es. "U14"), condiviso una volta sola con tutta la squadra.
-- A differenza di inviti_atleta (uso singolo, atleta gia' esistente),
-- qui il record atleti NON esiste ancora: chi usa il codice compila la
-- propria anagrafica e viene creato da zero, gia' assegnato al gruppo.
-- ============================================================

alter table public.atleti
  add column visita_medica_scadenza date;

create table public.codici_gruppo (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  gruppo text not null,
  codice text not null unique,
  creato_da uuid not null references auth.users(id),
  creato_il timestamptz not null default now(),
  scade_il timestamptz not null default (now() + interval '30 days')
);

create index idx_codici_gruppo_club on public.codici_gruppo(club_id);
create index idx_codici_gruppo_codice on public.codici_gruppo(codice);

alter table public.codici_gruppo enable row level security;

create policy codici_gruppo_select on public.codici_gruppo
  for select using (public.is_membro_club(club_id));

create policy codici_gruppo_insert on public.codici_gruppo
  for insert with check (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- genera_codice_gruppo: chiamata dal coach.
-- ------------------------------------------------------------

create or replace function public.genera_codice_gruppo(p_club_id uuid, p_gruppo text)
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
  if p_gruppo is null or length(trim(p_gruppo)) = 0 then
    raise exception 'Indica il nome del gruppo';
  end if;

  v_codice := upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 10));

  insert into public.codici_gruppo (club_id, gruppo, creato_da, codice)
  values (p_club_id, trim(p_gruppo), auth.uid(), v_codice);

  return v_codice;
end;
$$;

grant execute on function public.genera_codice_gruppo(uuid, text) to authenticated;

-- ------------------------------------------------------------
-- valida_codice_gruppo: chiamata PRIMA della registrazione (anche
-- anon). Nessun controllo di "usato": il codice serve a tutta la
-- squadra finche' non scade.
-- ------------------------------------------------------------

create or replace function public.valida_codice_gruppo(p_codice text)
returns table (gruppo text, club_nome text)
language sql
stable
security definer
set search_path = public
as $$
  select c.gruppo, cl.nome
  from public.codici_gruppo c
  join public.club cl on cl.id = c.club_id
  where c.codice = upper(p_codice)
    and c.scade_il > now();
$$;

grant execute on function public.valida_codice_gruppo(text) to anon, authenticated;

-- ------------------------------------------------------------
-- registra_atleta_da_codice_gruppo: chiamata subito dopo la signUp().
-- A differenza di collega_atleta_da_invito, QUI si crea il record
-- atleti (non esiste ancora).
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
    club_id, nome, cognome, data_nascita, sesso, sport, gruppo, user_id
  )
  values (
    v_codice.club_id, trim(p_nome), trim(p_cognome), p_data_nascita,
    p_sesso, coalesce(p_sport, 'nuoto')::public.sport, v_codice.gruppo, auth.uid()
  )
  returning * into v_atleta;

  return v_atleta;
end;
$$;

grant execute on function public.registra_atleta_da_codice_gruppo(
  text, text, text, date, text, text
) to authenticated;
