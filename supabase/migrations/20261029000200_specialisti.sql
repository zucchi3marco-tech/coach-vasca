-- ============================================================
-- PROFILO FISICO, passo B: gli specialisti convenzionati del club
-- (scelte del coach del 2026-10-29).
-- Nutrizionista sportivo, fisioterapista, osteopata, massoterapista:
-- ogni club ha i suoi, li scrive il responsabile (owner). Ognuno ha un
-- sito o un numero WhatsApp (o tutti e due). Li legge lo staff e, dal
-- passo C («Chi mi può aiutare?»), gli atleti del club. Non sono dati
-- degli atleti: chi apre un contatto si segna al passo D.
-- ============================================================

create table if not exists public.specialisti (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  tipo text not null check (
    tipo in ('nutrizionista', 'fisioterapista', 'osteopata', 'massoterapista')
  ),
  nome text not null check (char_length(trim(nome)) between 1 and 80),
  descrizione text check (descrizione is null or char_length(descrizione) <= 300),
  sito text check (
    sito is null or (char_length(sito) <= 300 and sito ~ '^https?://[^\s/]+\.[^\s]+$')
  ),
  -- Con il prefisso internazionale, solo cifre: «+393331234567».
  whatsapp text check (whatsapp is null or whatsapp ~ '^\+[0-9]{8,15}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (sito is not null or whatsapp is not null)
);

create index if not exists idx_specialisti_club on public.specialisti(club_id);

drop trigger if exists trg_specialisti_updated_at on public.specialisti;
create trigger trg_specialisti_updated_at
before update on public.specialisti
for each row execute function public.set_updated_at();

alter table public.specialisti enable row level security;

drop policy if exists specialisti_select on public.specialisti;
create policy specialisti_select on public.specialisti
  for select using (
    public.is_membro_club(club_id) or club_id = public.mio_club_atleta()
  );

drop policy if exists specialisti_insert on public.specialisti;
create policy specialisti_insert on public.specialisti
  for insert with check (public.is_owner_club(club_id));

drop policy if exists specialisti_update on public.specialisti;
create policy specialisti_update on public.specialisti
  for update using (public.is_owner_club(club_id))
  with check (public.is_owner_club(club_id));

drop policy if exists specialisti_delete on public.specialisti;
create policy specialisti_delete on public.specialisti
  for delete using (public.is_owner_club(club_id));
