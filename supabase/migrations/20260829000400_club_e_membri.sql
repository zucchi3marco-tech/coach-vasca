-- ============================================================
-- CLUB e CLUB_MEMBRI: radice del multi-tenant.
-- Ogni tabella applicativa porta un club_id e la RLS isola i dati
-- per club tramite le funzioni is_membro_club()/is_owner_club().
-- ============================================================

create table public.club (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  citta text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_club_updated_at
before update on public.club
for each row execute function public.set_updated_at();

-- Un utente puo' essere membro di piu' club, con un ruolo per club.
-- Un coach puo' avere colleghi/assistenti sullo stesso club fin da subito.
create table public.club_membri (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  ruolo public.ruolo_club not null default 'coach',
  created_at timestamptz not null default now(),
  unique (club_id, user_id)
);

create index idx_club_membri_user on public.club_membri(user_id);
create index idx_club_membri_club on public.club_membri(club_id);

-- ------------------------------------------------------------
-- Funzioni helper per la RLS (SECURITY DEFINER: bypassano la RLS
-- di club_membri al loro interno, altrimenti si avrebbe una
-- valutazione ricorsiva delle policy sulla stessa tabella).
-- ------------------------------------------------------------

create or replace function public.is_membro_club(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.club_membri
    where club_id = p_club_id and user_id = auth.uid()
  );
$$;

create or replace function public.is_owner_club(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.club_membri
    where club_id = p_club_id and user_id = auth.uid() and ruolo = 'owner'
  );
$$;

grant execute on function public.is_membro_club(uuid) to authenticated;
grant execute on function public.is_owner_club(uuid) to authenticated;

-- Chi crea un club ne diventa automaticamente owner.
create or replace function public.gestisci_nuovo_club()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.club_membri (club_id, user_id, ruolo)
  values (new.id, auth.uid(), 'owner');
  return new;
end;
$$;

create trigger trg_nuovo_club_owner
after insert on public.club
for each row execute function public.gestisci_nuovo_club();

-- ------------------------------------------------------------
-- Row Level Security
-- ------------------------------------------------------------

alter table public.club enable row level security;

create policy club_select on public.club
  for select using (public.is_membro_club(id));

-- Chiunque sia autenticato puo' creare un nuovo club (ne diventa owner via trigger).
create policy club_insert on public.club
  for insert with check (auth.uid() is not null);

create policy club_update on public.club
  for update using (public.is_owner_club(id))
  with check (public.is_owner_club(id));

create policy club_delete on public.club
  for delete using (public.is_owner_club(id));

alter table public.club_membri enable row level security;

create policy club_membri_select on public.club_membri
  for select using (public.is_membro_club(club_id));

-- Solo l'owner del club puo' aggiungere/rimuovere collaboratori.
create policy club_membri_insert on public.club_membri
  for insert with check (public.is_owner_club(club_id));

create policy club_membri_update on public.club_membri
  for update using (public.is_owner_club(club_id))
  with check (public.is_owner_club(club_id));

create policy club_membri_delete on public.club_membri
  for delete using (public.is_owner_club(club_id));
