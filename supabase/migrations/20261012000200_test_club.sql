-- ============================================================
-- TEST DEL CLUB CON CLASSIFICHE (fase 2 del "Mako della pallanuoto",
-- proposta 3): i test di oggi (BVS, T30) sono pensati per il nuoto; la
-- condizione di un giocatore si misura anche con la palla, negli sprint
-- ripetuti e nella verticale. L'allenatore si fa i suoi test (o parte da
-- quelli pronti: sprint 10 e 15 m, 6 x 15 m, WIST, verticale, salto,
-- tiro), li segna a raffica a bordo vasca e ne legge le classifiche.
-- ============================================================

-- I test del club: cosa si misura e come si legge.
create table public.test_club (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  nome text not null check (length(trim(nome)) between 1 and 80),
  descrizione text check (descrizione is null or length(descrizione) <= 500),
  -- L'unita' dei valori: secondi, metri, centimetri, chili, km/h, punti,
  -- ripetizioni.
  unita text not null check (
    unita in ('secondi', 'metri', 'centimetri', 'chili', 'kmh', 'punti', 'ripetizioni')
  ),
  -- Quale valore e' migliore: il piu' basso (un tempo) o il piu' alto.
  migliore text not null check (migliore in ('minore', 'maggiore')),
  -- Quante prove fa ogni atleta (6 per un 6 x 15 m).
  prove smallint not null default 1 check (prove between 1 and 20),
  -- Con piu' prove, il valore che va in classifica: la migliore, la
  -- media o la somma.
  punteggio text not null default 'migliore' check (
    punteggio in ('migliore', 'media', 'somma')
  ),
  -- Il test pronto da cui e' nato ('sprint_15_palla'...), null per uno
  -- inventato dall'allenatore.
  modello text,
  archiviato boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_test_club_club on public.test_club(club_id);

create trigger trg_test_club_updated_at
before update on public.test_club
for each row execute function public.set_updated_at();

alter table public.test_club enable row level security;

create policy test_club_select on public.test_club
  for select using (
    public.is_membro_club(club_id) or club_id = public.mio_club_atleta()
  );

create policy test_club_insert on public.test_club
  for insert with check (public.is_membro_club(club_id));

create policy test_club_update on public.test_club
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy test_club_delete on public.test_club
  for delete using (public.is_membro_club(club_id));

-- I risultati: una riga per atleta, test e giorno (rifarlo lo stesso
-- giorno la aggiorna), con il valore di ogni prova nell'unita' del test.
create table public.test_risultati (
  id uuid primary key default gen_random_uuid(),
  test_id uuid not null references public.test_club(id) on delete cascade,
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  data date not null,
  valori numeric[] not null check (
    cardinality(valori) between 1 and 20
    and array_position(valori, null) is null
  ),
  note text check (note is null or length(note) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (test_id, atleta_id, data)
);

create index idx_test_risultati_test on public.test_risultati(test_id, data desc);
create index idx_test_risultati_atleta on public.test_risultati(atleta_id);
create index idx_test_risultati_club on public.test_risultati(club_id);

create trigger trg_test_risultati_updated_at
before update on public.test_risultati
for each row execute function public.set_updated_at();

-- club_id dall'atleta; il test deve essere dello stesso club e le prove
-- non piu' di quelle del test.
create or replace function public.valida_risultato_test()
returns trigger
language plpgsql
as $$
declare
  v_club_test uuid;
  v_prove smallint;
begin
  select club_id into new.club_id from public.atleti where id = new.atleta_id;
  if new.club_id is null then
    raise exception 'Atleta % non trovato', new.atleta_id;
  end if;
  select club_id, prove into v_club_test, v_prove
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
  return new;
end;
$$;

create trigger trg_test_risultati_valida
before insert or update of atleta_id, test_id, valori on public.test_risultati
for each row execute function public.valida_risultato_test();

alter table public.test_risultati enable row level security;

-- L'allenatore legge e scrive tutto; l'atleta legge i suoi.
create policy test_risultati_select on public.test_risultati
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

create policy test_risultati_insert on public.test_risultati
  for insert with check (public.is_membro_club(club_id));

create policy test_risultati_update on public.test_risultati
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy test_risultati_delete on public.test_risultati
  for delete using (public.is_membro_club(club_id));
