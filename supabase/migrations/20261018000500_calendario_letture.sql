-- ============================================================
-- Calendario collegato: quando e da quale app è stato letto l'ultima
-- volta (segnalazione del coach 2026-10-18: collegato il calendario, le
-- partite non comparivano). Il calendario c'era, ma dal telefono Google
-- non aggiunge un calendario da indirizzo: la pagina ora dice se qualche
-- calendario l'ha davvero letto, così si vede subito se il collegamento
-- è riuscito.
--
-- Si tiene solo l'ultima lettura: l'ora e il nome dell'app ("Google
-- Calendar", "iPhone"…) ricavato dalla Edge Function; niente indirizzi IP.
-- ============================================================

alter table public.calendari_collegati
  add column letto_at timestamptz,
  add column letto_da text check (letto_da is null or length(letto_da) <= 40);

-- Solo per la Edge Function `calendario` (chiave di servizio).
create or replace function public.segna_lettura_calendario(p_codice text, p_da text)
returns void
language sql
volatile
security definer
set search_path = public
as $$
  update public.calendari_collegati
  set letto_at = now(), letto_da = left(p_da, 40)
  where codice = p_codice;
$$;

revoke all on function public.segna_lettura_calendario(text, text) from public, anon, authenticated;
grant execute on function public.segna_lettura_calendario(text, text) to service_role;

-- "Cambia indirizzo": il nuovo indirizzo non l'ha ancora letto nessuno.
create or replace function public.mio_calendario(p_nuovo boolean default false)
returns text
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_codice text;
begin
  if auth.uid() is null then
    raise exception 'Serve un utente collegato';
  end if;

  if not p_nuovo then
    select codice into v_codice
    from public.calendari_collegati
    where user_id = auth.uid();
    if v_codice is not null then
      return v_codice;
    end if;
  end if;

  v_codice := encode(extensions.gen_random_bytes(24), 'hex');
  insert into public.calendari_collegati (user_id, codice)
  values (auth.uid(), v_codice)
  on conflict (user_id) do update
    set codice = excluded.codice, created_at = now(),
        letto_at = null, letto_da = null;
  return v_codice;
end;
$$;

revoke all on function public.mio_calendario(boolean) from public, anon;
grant execute on function public.mio_calendario(boolean) to authenticated;
