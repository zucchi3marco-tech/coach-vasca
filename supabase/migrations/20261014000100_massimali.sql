-- ============================================================
-- MASSIMALI (fase 4 del "Mako della pallanuoto", proposta 10, ultimo
-- passo del secco). Il massimale di un atleta in un esercizio di forza
-- (squat, panca...) e' un test del club legato a quell'esercizio: si
-- segna come gli altri test, a raffica, e ha la sua classifica. Nessun
-- ragazzo deve sollevare il suo massimo vero: l'allenatore scrive i
-- chili sollevati e le ripetizioni fatte (fino a 10) e l'app stima il
-- massimale (formula di Brzycki); con 1 ripetizione e' quello provato.
-- Nelle sedute a secco un carico scritto "70%" diventa, per ogni atleta,
-- i chili dal suo ultimo massimale in quell'esercizio.
-- ============================================================

-- L'esercizio di cui il test e' il massimale; null per gli altri test.
-- Un esercizio con un massimale non si elimina (l'app lo archivia), come
-- quelli usati nelle sedute.
alter table public.test_club
  add column if not exists esercizio_id uuid references public.esercizi_secco(id);

-- Un massimale si misura in chili, vince il piu' alto, una prova.
alter table public.test_club drop constraint if exists test_club_massimale_check;
alter table public.test_club add constraint test_club_massimale_check check (
  esercizio_id is null
  or (unita = 'chili' and migliore = 'maggiore' and prove = 1)
);

-- Un solo massimale per esercizio: da li' si calcolano le percentuali.
create unique index if not exists idx_test_club_massimale
  on public.test_club(esercizio_id) where esercizio_id is not null;

-- L'esercizio dev'essere dello stesso club del test.
create or replace function public.valida_test_club()
returns trigger
language plpgsql
as $$
declare
  v_club_esercizio uuid;
begin
  if new.esercizio_id is null then
    return new;
  end if;
  select club_id into v_club_esercizio
  from public.esercizi_secco where id = new.esercizio_id;
  if v_club_esercizio is null then
    raise exception 'Esercizio % non trovato', new.esercizio_id;
  end if;
  if v_club_esercizio <> new.club_id then
    raise exception 'Test ed esercizio appartengono a club diversi';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_test_club_valida on public.test_club;
create trigger trg_test_club_valida
before insert or update of club_id, esercizio_id on public.test_club
for each row execute function public.valida_test_club();

-- Il risultato di un massimale: i chili sollevati e quante ripetizioni;
-- in valori c'e' il massimale stimato (mai meno dei chili sollevati).
alter table public.test_risultati
  add column if not exists carico_kg numeric,
  add column if not exists ripetizioni smallint;

alter table public.test_risultati drop constraint if exists test_risultati_massimale_check;
alter table public.test_risultati add constraint test_risultati_massimale_check check (
  (carico_kg is null and ripetizioni is null)
  or (
    carico_kg > 0 and carico_kg <= 500
    and ripetizioni between 1 and 10
    and cardinality(valori) = 1
    and valori[1] >= carico_kg
  )
);

-- Come prima (club dall'atleta, test dello stesso club, non piu' prove di
-- quelle del test) e in piu': un massimale vuole chili e ripetizioni, gli
-- altri test no.
create or replace function public.valida_risultato_test()
returns trigger
language plpgsql
as $$
declare
  v_club_test uuid;
  v_prove smallint;
  v_esercizio uuid;
begin
  select club_id into new.club_id from public.atleti where id = new.atleta_id;
  if new.club_id is null then
    raise exception 'Atleta % non trovato', new.atleta_id;
  end if;
  select club_id, prove, esercizio_id into v_club_test, v_prove, v_esercizio
  from public.test_club where id = new.test_id;
  if v_club_test is null then
    raise exception 'Test % non trovato', new.test_id;
  end if;
  if v_club_test <> new.club_id then
    raise exception 'Atleta e test appartengono a club diversi';
  end if;
  if cardinality(new.valori) > v_prove then
    raise exception 'Il test ha % prove, non %', v_prove, cardinality(new.valori);
  end if;
  if v_esercizio is not null and (new.carico_kg is null or new.ripetizioni is null) then
    raise exception 'Un massimale vuole i chili sollevati e le ripetizioni';
  end if;
  if v_esercizio is null and (new.carico_kg is not null or new.ripetizioni is not null) then
    raise exception 'Chili e ripetizioni valgono solo per un massimale';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_test_risultati_valida on public.test_risultati;
create trigger trg_test_risultati_valida
before insert or update of atleta_id, test_id, valori, carico_kg, ripetizioni
on public.test_risultati
for each row execute function public.valida_risultato_test();
