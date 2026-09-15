-- ============================================================
-- Il numero massimo di convocati selezionabile era 13 o 15;
-- il coach ha chiesto di sostituire 13 con 14 (13 non e' piu'
-- un valore valido). Nessuna partita esistente ha 13 (verificato
-- prima di applicare), quindi il vincolo puo' stringersi subito.
-- ============================================================

alter table public.partite drop constraint partite_numero_max_convocati_check;

alter table public.partite
  add constraint partite_numero_max_convocati_check
  check (numero_max_convocati in (14, 15));
