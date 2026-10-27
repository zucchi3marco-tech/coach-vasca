-- ============================================================
-- NOTE SUGLI AVVERSARI (scheda dell'avversario, passo B, «Piano di
-- WaterTactics» periodo 3, problema 21, 2026-10-27).
-- Una riga per avversario e per squadra: una nota sulla squadra
-- (come gioca, cosa ha funzionato) e le righe dei giocatori da tenere
-- d'occhio (numero, nome, cosa fa), più il nome come lo scrive il sito
-- FIN quando l'app non lo trova da sola.
-- Scelte del coach: le note le vede tutta la squadra, anche chi non è
-- convocato; i precedenti (e quindi le note) sono della squadra.
-- gruppo_id nullo = l'avversario delle partite di tutto il club.
-- chiave: il nome senza maiuscole, punti e sigle, come lo calcola
-- l'app (`chiaveSquadra` in scheda_avversario.dart).
-- Lo staff (membri del club) scrive; l'atleta collegato legge solo
-- quelle della sua squadra, dell'altra squadra con cui si allena e di
-- tutto il club (stessa regola di `nel_gruppo_atleta`).
-- ============================================================

create table if not exists public.note_avversari (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  gruppo_id uuid references public.gruppi(id) on delete cascade,
  chiave text not null check (char_length(chiave) between 1 and 120),
  nome text not null check (char_length(trim(nome)) between 1 and 120),
  nome_fin text check (nome_fin is null or char_length(nome_fin) <= 120),
  nota text check (nota is null or char_length(nota) <= 2000),
  -- [{"numero": 7, "nome": "Rossi", "nota": "tira solo di destro"}]
  giocatori jsonb not null default '[]'::jsonb
    check (
      jsonb_typeof(giocatori) = 'array'
      and jsonb_array_length(giocatori) <= 30
      and octet_length(giocatori::text) <= 20000
    ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (club_id, gruppo_id, chiave)
);

drop trigger if exists trg_note_avversari_updated_at on public.note_avversari;
create trigger trg_note_avversari_updated_at
before update on public.note_avversari
for each row execute function public.set_updated_at();

-- L'atleta collegato del club, se la nota è della sua squadra (o
-- dell'altra con cui si allena, o di tutto il club).
create or replace function public.nota_avversario_visibile(
  p_club_id uuid,
  p_gruppo_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.atleti a
    where a.user_id = auth.uid()
      and a.club_id = p_club_id
      and public.nel_gruppo_atleta(p_gruppo_id, a.gruppo_id, a.altro_gruppo_id)
  );
$$;

grant execute on function public.nota_avversario_visibile(uuid, uuid)
  to authenticated;

alter table public.note_avversari enable row level security;

drop policy if exists note_avversari_select on public.note_avversari;
create policy note_avversari_select on public.note_avversari
  for select using (
    public.is_membro_club(club_id)
    or public.nota_avversario_visibile(club_id, gruppo_id)
  );

drop policy if exists note_avversari_insert on public.note_avversari;
create policy note_avversari_insert on public.note_avversari
  for insert with check (public.is_membro_club(club_id));

drop policy if exists note_avversari_update on public.note_avversari;
create policy note_avversari_update on public.note_avversari
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

drop policy if exists note_avversari_delete on public.note_avversari;
create policy note_avversari_delete on public.note_avversari
  for delete using (public.is_membro_club(club_id));
