-- ============================================================
-- TEST SEGNATI DAGLI ATLETI (proposta 13, «Piano di WaterTactics»
-- periodo 2, 2026-10-26). Scelte del coach: l'allenatore apre un test con
-- «Lo segnano anche gli atleti» (spento all'inizio); il risultato
-- dell'atleta entra subito in classifica con l'etichetta «segnato
-- dall'atleta» e l'allenatore lo può togliere; l'atleta corregge o toglie
-- solo i suoi, mai quelli scritti dall'allenatore.
-- ============================================================

alter table public.test_club
  add column if not exists aperto_atleti boolean not null default false;

alter table public.test_risultati
  add column if not exists dall_atleta boolean not null default false;

-- Chi ha scritto il risultato lo dice il database, non l'app: un
-- allenatore del club → false, l'atleta → true. Senza utente (una
-- correzione fatta a mano sul database) resta com'era.
create or replace function public.segna_autore_risultato_test()
returns trigger
language plpgsql
as $$
declare
  v_club uuid;
begin
  if auth.uid() is null then
    return new;
  end if;
  select club_id into v_club from public.atleti where id = new.atleta_id;
  new.dall_atleta := not public.is_membro_club(v_club);
  return new;
end;
$$;

drop trigger if exists trg_test_risultati_autore on public.test_risultati;
create trigger trg_test_risultati_autore
before insert or update of valori, carico_kg, ripetizioni, data, note
on public.test_risultati
for each row execute function public.segna_autore_risultato_test();

-- Il test è aperto agli atleti (e non archiviato).
create or replace function public.test_aperto_atleti(p_test_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.test_club t
    where t.id = p_test_id and t.aperto_atleti and not t.archiviato
      and t.club_id = public.mio_club_atleta()
  );
$$;

grant execute on function public.test_aperto_atleti(uuid) to authenticated;

-- L'atleta scrive i suoi risultati nei test aperti; corregge e toglie
-- solo quelli scritti da lui. Le regole dell'allenatore restano.
drop policy if exists test_risultati_insert_atleta on public.test_risultati;
create policy test_risultati_insert_atleta on public.test_risultati
  for insert with check (
    atleta_id = public.mia_atleta_id() and public.test_aperto_atleti(test_id)
  );

drop policy if exists test_risultati_update_atleta on public.test_risultati;
create policy test_risultati_update_atleta on public.test_risultati
  for update using (atleta_id = public.mia_atleta_id() and dall_atleta)
  with check (
    atleta_id = public.mia_atleta_id() and public.test_aperto_atleti(test_id)
  );

drop policy if exists test_risultati_delete_atleta on public.test_risultati;
create policy test_risultati_delete_atleta on public.test_risultati
  for delete using (atleta_id = public.mia_atleta_id() and dall_atleta);
