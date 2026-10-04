-- ============================================================
-- RIPROGETTAZIONE AI, FASE 1: due nuovi valori di "esecuzione" per
-- rappresentare fedelmente i blocchi di pallanuoto della libreria che
-- non sono nuoto puro (tattica/gioco, lavoro a secco). Stessa procedura
-- già usata per "remate" (20260907000200_nuovi_codici_zona.sql).
-- ============================================================

alter type public.esecuzione_serie add value if not exists 'pallanuoto tecnico-tattico';
alter type public.esecuzione_serie add value if not exists 'a secco';
