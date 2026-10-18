-- ============================================================
-- Il club: responsabile, allenatori e assistenti (richiesta del coach
-- 2026-10-17: "l'iscrizione è del club dopodiché ci saranno le divisioni
-- tra capo allenatore, assistenti, poi atleti"). Primo pezzo: i ruoli e
-- gli inviti.
--
-- I ruoli c'erano già (`ruolo_club`: owner, coach, assistente) ma nessuno
-- li guardava: ogni membro poteva fare tutto. Scelte del coach:
-- - il responsabile (owner, chi ha creato il club) invita e toglie
--   allenatori e assistenti, con un codice come per gli atleti (7 giorni,
--   una volta sola);
-- - tutti vedono e modificano le programmazioni di tutte le squadre;
-- - gli assistenti scrivono allenamenti, segnano presenze, preparano
--   partite e convocazioni e fanno i test, ma non aggiungono o tolgono
--   atleti e squadre e non cambiano il club.
-- Ogni membro ha un nome (`club_membri.nome`), per "Modificato da …".
-- ============================================================

alter table public.club_membri
  add column nome text check (nome is null or length(trim(nome)) between 1 and 60);

-- Responsabile o allenatore: chi può aggiungere e togliere atleti e
-- squadre (non un assistente).
create or replace function public.e_allenatore_club(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.club_membri
    where club_id = p_club_id
      and user_id = auth.uid()
      and ruolo in ('owner', 'coach')
  );
$$;

grant execute on function public.e_allenatore_club(uuid) to authenticated;

-- ------------------------------------------------------------
-- Atleti e squadre: aggiungerli e toglierli solo responsabile e
-- allenatori. Modificare un atleta (ruolo, numero, note) resta di tutti.
-- ------------------------------------------------------------

drop policy atleti_insert on public.atleti;
create policy atleti_insert on public.atleti
  for insert with check (public.e_allenatore_club(club_id));

drop policy atleti_delete on public.atleti;
create policy atleti_delete on public.atleti
  for delete using (public.e_allenatore_club(club_id));

drop policy gruppi_insert on public.gruppi;
create policy gruppi_insert on public.gruppi
  for insert with check (public.e_allenatore_club(club_id));

drop policy gruppi_update on public.gruppi;
create policy gruppi_update on public.gruppi
  for update using (public.e_allenatore_club(club_id))
  with check (public.e_allenatore_club(club_id));

drop policy gruppi_delete on public.gruppi;
create policy gruppi_delete on public.gruppi
  for delete using (public.e_allenatore_club(club_id));

-- I codici per far entrare gli atleti sono un modo di aggiungerli.
drop policy inviti_atleta_insert on public.inviti_atleta;
create policy inviti_atleta_insert on public.inviti_atleta
  for insert with check (public.e_allenatore_club(club_id));

drop policy codici_gruppo_insert on public.codici_gruppo;
create policy codici_gruppo_insert on public.codici_gruppo
  for insert with check (public.e_allenatore_club(club_id));

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
  if not public.e_allenatore_club(v_club_id) then
    raise exception 'Non autorizzato';
  end if;

  v_codice := upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 10));

  insert into public.inviti_atleta (atleta_id, club_id, codice, creato_da)
  values (p_atleta_id, v_club_id, v_codice, auth.uid());

  return v_codice;
end;
$$;

create or replace function public.genera_codice_gruppo(p_club_id uuid, p_gruppo_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_codice text;
begin
  if not public.e_allenatore_club(p_club_id) then
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

-- ------------------------------------------------------------
-- Gli inviti per allenatori e assistenti.
-- ------------------------------------------------------------

create table public.inviti_staff (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  codice text not null unique,
  ruolo public.ruolo_club not null check (ruolo in ('coach', 'assistente')),
  creato_da uuid references auth.users(id) on delete set null,
  scade_at timestamptz not null default now() + interval '7 days',
  usato_da uuid references auth.users(id) on delete set null,
  usato_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_inviti_staff_club on public.inviti_staff(club_id);

alter table public.inviti_staff enable row level security;

-- Li vede il responsabile; si creano e si usano solo con le funzioni.
create policy inviti_staff_select on public.inviti_staff
  for select using (public.is_owner_club(club_id));

-- Un codice nuovo per un allenatore o un assistente (solo il responsabile).
create or replace function public.genera_invito_staff(p_club_id uuid, p_ruolo text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_codice text;
begin
  if not public.is_owner_club(p_club_id) then
    raise exception 'Solo il responsabile del club invita allenatori e assistenti';
  end if;
  if p_ruolo not in ('coach', 'assistente') then
    raise exception 'Ruolo non valido';
  end if;

  v_codice := upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 10));

  insert into public.inviti_staff (club_id, codice, ruolo, creato_da)
  values (p_club_id, v_codice, p_ruolo::public.ruolo_club, auth.uid());

  return v_codice;
end;
$$;

revoke all on function public.genera_invito_staff(uuid, text) from public, anon;
grant execute on function public.genera_invito_staff(uuid, text) to authenticated;

-- Prima di entrare: di che club è il codice e con che ruolo (null se non
-- vale più).
create or replace function public.valida_invito_staff(p_codice text)
returns table (club_nome text, ruolo text)
language sql
stable
security definer
set search_path = public
as $$
  select c.nome, i.ruolo::text
  from public.inviti_staff i
  join public.club c on c.id = i.club_id
  where i.codice = upper(trim(p_codice))
    and i.usato_at is null
    and i.scade_at > now();
$$;

revoke all on function public.valida_invito_staff(text) from public, anon;
grant execute on function public.valida_invito_staff(text) to authenticated;

-- Entrare nel club con il codice, con il proprio nome. Torna il club.
create or replace function public.entra_con_invito_staff(p_codice text, p_nome text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invito public.inviti_staff%rowtype;
  v_nome text := trim(coalesce(p_nome, ''));
begin
  if auth.uid() is null then
    raise exception 'Serve un utente collegato';
  end if;
  if length(v_nome) not between 1 and 60 then
    raise exception 'Scrivi il tuo nome';
  end if;
  select * into v_invito
  from public.inviti_staff
  where codice = upper(trim(p_codice))
  for update;
  if v_invito.id is null then
    raise exception 'Codice non trovato';
  end if;
  if v_invito.usato_at is not null then
    raise exception 'Questo codice è già stato usato';
  end if;
  if v_invito.scade_at <= now() then
    raise exception 'Questo codice è scaduto: chiedine uno nuovo';
  end if;
  if exists (select 1 from public.atleti where user_id = auth.uid()) then
    raise exception 'Questo account è di un atleta: per entrare come allenatore serve un altro account';
  end if;
  if exists (select 1 from public.club_membri where user_id = auth.uid()) then
    raise exception 'Questo account è già in un club';
  end if;

  insert into public.club_membri (club_id, user_id, ruolo, nome)
  values (v_invito.club_id, auth.uid(), v_invito.ruolo, v_nome);

  update public.inviti_staff
  set usato_da = auth.uid(), usato_at = now()
  where id = v_invito.id;

  return v_invito.club_id;
end;
$$;

revoke all on function public.entra_con_invito_staff(text, text) from public, anon;
grant execute on function public.entra_con_invito_staff(text, text) to authenticated;

-- Chi c'è nel club: per tutti i membri il nome e il ruolo, per il
-- responsabile anche l'email (per riconoscere chi non ha ancora un nome).
create or replace function public.membri_del_club(p_club_id uuid)
returns table (user_id uuid, nome text, ruolo text, email text, sono_io boolean)
language sql
stable
security definer
set search_path = public
as $$
  select
    m.user_id,
    m.nome,
    m.ruolo::text,
    case when public.is_owner_club(p_club_id) then u.email::text end,
    m.user_id = auth.uid()
  from public.club_membri m
  left join auth.users u on u.id = m.user_id
  where m.club_id = p_club_id
    and public.is_membro_club(p_club_id)
  order by
    case m.ruolo when 'owner' then 0 when 'coach' then 1 else 2 end,
    lower(coalesce(m.nome, u.email::text));
$$;

revoke all on function public.membri_del_club(uuid) from public, anon;
grant execute on function public.membri_del_club(uuid) to authenticated;

-- Il responsabile cambia il ruolo di un altro (allenatore o assistente).
create or replace function public.cambia_ruolo_membro(
  p_club_id uuid,
  p_user_id uuid,
  p_ruolo text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_owner_club(p_club_id) then
    raise exception 'Solo il responsabile del club cambia i ruoli';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'Il tuo ruolo non si cambia da qui';
  end if;
  if p_ruolo not in ('coach', 'assistente') then
    raise exception 'Ruolo non valido';
  end if;
  update public.club_membri
  set ruolo = p_ruolo::public.ruolo_club
  where club_id = p_club_id and user_id = p_user_id and ruolo <> 'owner';
  if not found then
    raise exception 'Membro non trovato';
  end if;
end;
$$;

revoke all on function public.cambia_ruolo_membro(uuid, uuid, text) from public, anon;
grant execute on function public.cambia_ruolo_membro(uuid, uuid, text) to authenticated;

-- Il responsabile toglie un allenatore o un assistente dal club.
create or replace function public.togli_membro(p_club_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_owner_club(p_club_id) then
    raise exception 'Solo il responsabile del club toglie allenatori e assistenti';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'Non puoi toglierti dal club';
  end if;
  delete from public.club_membri
  where club_id = p_club_id and user_id = p_user_id and ruolo <> 'owner';
  if not found then
    raise exception 'Membro non trovato';
  end if;
end;
$$;

revoke all on function public.togli_membro(uuid, uuid) from public, anon;
grant execute on function public.togli_membro(uuid, uuid) to authenticated;

-- Ognuno scrive il proprio nome (chi c'era prima di questi inviti non ce
-- l'ha).
create or replace function public.mio_nome_nel_club(p_club_id uuid, p_nome text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nome text := trim(coalesce(p_nome, ''));
begin
  if length(v_nome) not between 1 and 60 then
    raise exception 'Scrivi il tuo nome';
  end if;
  update public.club_membri
  set nome = v_nome
  where club_id = p_club_id and user_id = auth.uid();
  if not found then
    raise exception 'Non sei in questo club';
  end if;
end;
$$;

revoke all on function public.mio_nome_nel_club(uuid, text) from public, anon;
grant execute on function public.mio_nome_nel_club(uuid, text) to authenticated;
