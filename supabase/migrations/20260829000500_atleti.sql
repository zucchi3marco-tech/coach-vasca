-- ============================================================
-- ATLETI
-- Gli atleti sono spesso minorenni: consenso privacy tracciato
-- esplicitamente in tabella (vedi decisioni di sicurezza in ROADMAP.md).
-- ============================================================

create table public.atleti (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  nome text not null,
  cognome text not null,
  data_nascita date not null,
  sesso text check (sesso in ('M', 'F')),
  sport public.sport not null default 'nuoto',
  gruppo text,
  email_genitore text,
  telefono_genitore text,
  consenso_privacy_firmato boolean not null default false,
  consenso_privacy_data date,
  note text,
  attivo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_atleti_club_id on public.atleti(club_id);
create index idx_atleti_club_attivo on public.atleti(club_id, attivo);

create trigger trg_atleti_updated_at
before update on public.atleti
for each row execute function public.set_updated_at();

alter table public.atleti enable row level security;

create policy atleti_select on public.atleti
  for select using (public.is_membro_club(club_id));

create policy atleti_insert on public.atleti
  for insert with check (public.is_membro_club(club_id));

create policy atleti_update on public.atleti
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy atleti_delete on public.atleti
  for delete using (public.is_membro_club(club_id));
