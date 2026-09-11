-- ============================================================
-- RIMOZIONE GERARCHIA STAGIONE (FASE 11, punto 6): macrocicli,
-- mesocicli e microcicli vengono eliminati — la stagione resta solo
-- nome + periodo (+ obiettivo/gruppo/campionato, invariati) e gli
-- allenamenti smettono di collegarsi a un microciclo. Al loro posto,
-- la scheda stagione mostra statistiche (pallanuoto) o record (nuoto),
-- gestiti lato app senza bisogno di nuove tabelle.
-- ============================================================

drop trigger if exists trg_allenamenti_valida_microciclo on public.allenamenti;
drop function if exists public.valida_club_microciclo();

alter table public.allenamenti drop column if exists microciclo_id;

drop table if exists public.microcicli;
drop table if exists public.mesocicli;
drop table if exists public.macrocicli;

drop function if exists public.imposta_club_da_macrociclo();
drop function if exists public.imposta_club_da_mesociclo();
drop function if exists public.imposta_club_da_stagione();
