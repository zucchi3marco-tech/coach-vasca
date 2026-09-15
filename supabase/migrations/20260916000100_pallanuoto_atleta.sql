-- ============================================================
-- FASE 13, punto 4: un atleta di pallanuoto puo' vedere il risultato
-- delle partite in elenco, e per quelle gia' giocate consultare il
-- referto (se analizzato) e le statistiche di squadra della partita.
-- Stessa cautela delle migrazioni precedenti: solo dati di squadra
-- (eventi, distinta, referto — nessun campo libero sensibile in
-- nessuna di queste tre tabelle), mai un'altra tabella che esponga
-- dati individuali di un altro atleta.
-- ============================================================

create policy eventi_partita_select_atleta on public.eventi_partita
  for select using (club_id = public.mio_club_atleta());

create policy distinta_giocatori_select_atleta on public.distinta_giocatori
  for select using (club_id = public.mio_club_atleta());

create policy referti_partita_select_atleta on public.referti_partita
  for select using (club_id = public.mio_club_atleta());

-- Le statistiche di partita mostrano il nome di OGNI convocato (non solo
-- il proprio): niente accesso diretto alla tabella atleti (che resta
-- riservata al proprio record per l'atleta), solo nome e cognome tramite
-- questa funzione, mai data di nascita/certificato medico/altro.
create or replace function public.nomi_atleti_squadra(p_club_id uuid)
returns table (id uuid, nome_completo text)
language sql
stable
security definer
set search_path = public
as $$
  select a.id, a.cognome || ' ' || a.nome
  from public.atleti a
  where a.club_id = p_club_id
    and (public.is_membro_club(p_club_id) or p_club_id = public.mio_club_atleta());
$$;

grant execute on function public.nomi_atleti_squadra(uuid) to authenticated;
