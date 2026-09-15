-- ============================================================
-- FASE 13, punto 3: home page personale dell'atleta (data odierna,
-- percentuale presenze, prossimi allenamenti della settimana,
-- prossimo evento/partita, stagione in corso). Serve concedere
-- all'atleta collegato accesso in lettura a dati oggi riservati al
-- coach (partite, stagioni, allenamenti) — nulla di questo espone
-- dati di UN ALTRO ATLETA (mai note personali, presenze o PB altrui,
-- gia' verificato nell'audit del 12/09): sono tutti dati di squadra
-- o di calendario, condivisi per definizione fra i membri del club.
-- ============================================================

-- partite: calendario/risultati partita sono informazione di squadra,
-- non individuale — nessun campo "per gruppo" esiste su questa
-- tabella (le partite non sono mai state scomposte per gruppo).
create policy partite_select_atleta on public.partite
  for select using (club_id = public.mio_club_atleta());

-- stagioni: nome/periodo/obiettivo, nessun campo sensibile.
create policy stagioni_select_atleta on public.stagioni
  for select using (club_id = public.mio_club_atleta());

-- allenamenti: a differenza di partite/stagioni, ha un campo "note"
-- potenzialmente dettagliato sulla singola seduta — stesso motivo per
-- cui l'audit del 12/09 ha ristretto l'accesso di un atleta a
-- allenamenti/serie con funzioni dedicate invece che con la tabella
-- intera. Qui la stessa cautela: una funzione che espone solo
-- id/data/titolo/gruppo, mai "note".
create or replace function public.allenamenti_atleta()
returns table (id uuid, club_id uuid, data date, titolo text, gruppo_id uuid)
language sql
stable
security definer
set search_path = public
as $$
  select a.id, a.club_id, a.data, a.titolo, a.gruppo_id
  from public.allenamenti a
  join public.atleti at on at.user_id = auth.uid()
  where a.club_id = at.club_id;
$$;

grant execute on function public.allenamenti_atleta() to authenticated;
