-- ============================================================
-- TIPO MICROCICLO (FASE 10, punto 1): il campo era testo libero con solo
-- un suggerimento in etichetta ("es. carico/scarico"). Diventa una scelta
-- vincolata a un lessico comune di periodizzazione.
--
-- I microcicli gia' salvati con un valore libero fuori da questo elenco
-- vengono azzerati (null): l'app tratta gia' null come "non specificato".
-- ============================================================

update public.microcicli
set tipo = null
where tipo is not null
  and tipo not in ('carico', 'scarico', 'gara', 'recupero', 'test');

alter table public.microcicli
  add constraint microcicli_tipo_check
  check (tipo in ('carico', 'scarico', 'gara', 'recupero', 'test'));
