-- ============================================================
-- INVITI ATLETA (FASE 9): il coach genera un codice monouso dalla
-- scheda di un atleta; l'atleta lo usa per collegare il proprio nuovo
-- account a quel record, prima ancora di essere membro di un club
-- (da qui le funzioni security definer sotto).
-- ============================================================

create table public.inviti_atleta (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  codice text not null unique,
  creato_da uuid not null references auth.users(id),
  creato_il timestamptz not null default now(),
  scade_il timestamptz not null default (now() + interval '7 days'),
  usato_il timestamptz,
  usato_da uuid references auth.users(id)
);

create index idx_inviti_atleta_club on public.inviti_atleta(club_id);
create index idx_inviti_atleta_codice on public.inviti_atleta(codice);

alter table public.inviti_atleta enable row level security;

-- Solo il coach del club vede/crea gli inviti dei propri atleti. Nessuna
-- policy di update/delete: ci pensa solo la RPC sotto (security definer),
-- perche' a usare il codice e' un utente che non e' ancora membro del club.
create policy inviti_atleta_select on public.inviti_atleta
  for select using (public.is_membro_club(club_id));

create policy inviti_atleta_insert on public.inviti_atleta
  for insert with check (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- genera_invito_atleta: chiamata dal coach dalla scheda atleta.
-- ------------------------------------------------------------

create or replace function public.genera_invito_atleta(p_atleta_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club_id uuid;
  v_codice text;
begin
  select club_id into v_club_id from public.atleti where id = p_atleta_id;
  if v_club_id is null then
    raise exception 'Atleta non trovato';
  end if;
  if not public.is_membro_club(v_club_id) then
    raise exception 'Non autorizzato';
  end if;

  v_codice := upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 10));

  insert into public.inviti_atleta (atleta_id, club_id, codice, creato_da)
  values (p_atleta_id, v_club_id, v_codice, auth.uid());

  return v_codice;
end;
$$;

grant execute on function public.genera_invito_atleta(uuid) to authenticated;

-- ------------------------------------------------------------
-- valida_codice_invito: chiamata PRIMA della registrazione, quindi
-- anche da anon. Ritorna solo nome/cognome, mai altri campi
-- dell'atleta (email/telefono genitore, note, ecc.).
-- ------------------------------------------------------------

create or replace function public.valida_codice_invito(p_codice text)
returns table (nome text, cognome text)
language sql
stable
security definer
set search_path = public
as $$
  select a.nome, a.cognome
  from public.inviti_atleta i
  join public.atleti a on a.id = i.atleta_id
  where i.codice = upper(p_codice)
    and i.usato_il is null
    and i.scade_il > now();
$$;

grant execute on function public.valida_codice_invito(text) to anon, authenticated;

-- ------------------------------------------------------------
-- collega_atleta_da_invito: chiamata subito dopo la signUp(), quando
-- auth.uid() e' gia' valorizzato ma l'utente non e' ancora membro di
-- nessun club.
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

  return v_atleta;
end;
$$;

grant execute on function public.collega_atleta_da_invito(text) to authenticated;
