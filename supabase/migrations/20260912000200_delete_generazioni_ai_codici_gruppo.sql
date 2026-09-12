-- ============================================================
-- Aggiunge la policy DELETE mancante su generazioni_ai e
-- codici_gruppo (audit 12/09, punto 11): nessuna falla di
-- sicurezza (le altre policy isolavano gia' correttamente per
-- club), solo una funzionalita' mancante — oggi non si possono
-- eliminare vecchie righe di queste due tabelle dall'app.
-- ============================================================

create policy generazioni_ai_delete on public.generazioni_ai
  for delete using (public.is_membro_club(club_id));

create policy codici_gruppo_delete on public.codici_gruppo
  for delete using (public.is_membro_club(club_id));
