-- ============================================================
-- SCHEMI TATTICI (pallanuoto): l'allenatore disegna sulla lavagna
-- tattica (giocatori + frecce) e lo salva; gli atleti lo sfogliano in
-- sola lettura. Prima la lavagna (`WaterPoloTacticsBoard`) era solo
-- locale, dentro la dashboard dell'atleta: nulla si salvava né si
-- condivideva con la squadra.
-- ============================================================

create table public.schemi_tattici (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  titolo text not null,
  dati jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_schemi_tattici_club on public.schemi_tattici(club_id);

create trigger trg_schemi_tattici_updated_at
before update on public.schemi_tattici
for each row execute function public.set_updated_at();

alter table public.schemi_tattici enable row level security;

-- Il coach (membro del club) legge e scrive; l'atleta collegato solo
-- legge (stesso schema di pallanuoto_atleta: dati di squadra, non
-- individuali, ma di sola competenza dell'allenatore da creare).
create policy schemi_tattici_select on public.schemi_tattici
  for select using (public.is_membro_club(club_id));

create policy schemi_tattici_select_atleta on public.schemi_tattici
  for select using (club_id = public.mio_club_atleta());

create policy schemi_tattici_insert on public.schemi_tattici
  for insert with check (public.is_membro_club(club_id));

create policy schemi_tattici_update on public.schemi_tattici
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy schemi_tattici_delete on public.schemi_tattici
  for delete using (public.is_membro_club(club_id));
