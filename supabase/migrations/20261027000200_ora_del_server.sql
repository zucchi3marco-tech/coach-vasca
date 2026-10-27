-- ============================================================
-- LE MODIFICHE FATTE SENZA RETE («Piano di WaterTactics», periodo 2,
-- problema 6, passo 2, 2026-10-27). Quando la rete torna, ogni modifica
-- in coda guarda se intanto qualcun altro ha cambiato la stessa riga
-- (updated_at più recente del momento in cui è stata fatta): se sì non la
-- sovrascrive (scelta del coach: resta la versione del collega) e la spia
-- dice cosa rifare.
--
-- L'orologio del telefono può essere avanti o indietro: l'app chiede
-- l'ora al server e conta quanto tempo fa è stata fatta la modifica.
-- ============================================================

create or replace function public.ora_del_server()
returns timestamptz
language sql
stable
as $$
  select now();
$$;

revoke all on function public.ora_del_server() from public, anon;
grant execute on function public.ora_del_server() to authenticated;
