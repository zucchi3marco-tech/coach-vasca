-- ============================================================
-- COLORE CALOTTINA (chiusura punto aperto DESIGN.md sezione 4): il campo
-- era testo libero, quindi non mappabile in sicurezza sui due CapColore
-- disponibili (bianca/blu) per colorare la tessera di ogni convocato in
-- Distinta. Diventa una scelta vincolata a due soli valori.
--
-- Le partite gia' salvate con un valore libero diverso da bianca/blu
-- vengono azzerate (null): l'app tratta gia' null come "bianca" di
-- default, lo stesso comportamento visivo che avevano prima di questa
-- modifica (nessun colore per riga).
-- ============================================================

update public.partite
set colore_calottina = null
where colore_calottina is not null
  and colore_calottina not in ('bianca', 'blu');

alter table public.partite
  add constraint partite_colore_calottina_check
  check (colore_calottina in ('bianca', 'blu'));
