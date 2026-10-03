-- ============================================================
-- SERIE.PIRAMIDE_ID: una serie "piramidale" (es. 50-100-200-100-50,
-- scritta nella barra rapida) crea più righe in `serie` — una per
-- distanza — che condividono lo stesso piramide_id, così l'app può
-- raggrupparle in un'unica riga visiva, spostarle/duplicarle/
-- eliminarle insieme. Null = riga normale, non fa parte di una
-- piramide. Nessuna FK/vincolo: è solo un'etichetta di raggruppamento,
-- le righe restano coperte dalle policy RLS già esistenti su `serie`.
-- ============================================================

alter table public.serie add column piramide_id uuid;
