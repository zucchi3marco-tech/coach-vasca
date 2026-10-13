-- ============================================================
-- REGISTRAZIONE DELLE SEDUTE A SECCO DAL TELEFONO (Fase 4 del "Mako
-- della pallanuoto", proposta 10)
--
-- Scelte del coach: registra l'atleta dal suo telefono, serie per serie,
-- con il carico. Una riga per ogni serie fatta: quante ripetizioni (o
-- quanti secondi), con che carico e quando. Il carico previsto
-- dall'allenatore in quel momento resta accanto, per sapere la volta
-- dopo se la prescrizione è cambiata (si riparte dal carico dell'atleta
-- solo se non è cambiata).
--
-- Scrive e legge l'atleta (le proprie), legge (e può scrivere)
-- l'allenatore del club. Senza rete l'app la salva sul telefono e la
-- manda dopo, con upsert sulla chiave (atleta, esercizio della seduta,
-- serie).
-- ============================================================

create table if not exists public.serie_secco_fatte (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  allenamento_id uuid not null references public.allenamenti(id) on delete cascade,
  -- L'esercizio della seduta (la riga di `esercizi_seduta`): togliendolo
  -- dalla seduta se ne vanno anche le serie fatte.
  riga_id uuid not null references public.esercizi_seduta(id) on delete cascade,
  -- L'esercizio dell'elenco, per ritrovare "l'ultima volta" in un'altra
  -- seduta (l'atleta non legge `esercizi_seduta`).
  esercizio_id uuid not null references public.esercizi_secco(id) on delete cascade,
  serie smallint not null check (serie between 1 and 20),
  ripetizioni smallint check (ripetizioni is null or ripetizioni between 0 and 500),
  durata_s integer check (durata_s is null or durata_s between 0 and 3600),
  carico text check (carico is null or length(carico) <= 40),
  carico_previsto text check (carico_previsto is null or length(carico_previsto) <= 40),
  fatta_il timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (atleta_id, riga_id, serie)
);

create index if not exists idx_serie_secco_fatte_allenamento
  on public.serie_secco_fatte(allenamento_id);
create index if not exists idx_serie_secco_fatte_atleta_esercizio
  on public.serie_secco_fatte(atleta_id, esercizio_id, fatta_il desc);

drop trigger if exists trg_serie_secco_fatte_updated_at on public.serie_secco_fatte;
create trigger trg_serie_secco_fatte_updated_at
before update on public.serie_secco_fatte
for each row execute function public.set_updated_at();

-- Club, seduta ed esercizio vengono dalla riga della seduta e
-- dall'atleta, non da chi scrive; la seduta dev'essere del suo club e
-- del suo gruppo (la stessa regola di `esercizi_seduta_atleta`).
-- Security definer: l'atleta non legge `esercizi_seduta` né
-- `allenamenti` direttamente.
create or replace function public.valida_serie_secco_fatta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_riga record;
  v_atleta record;
begin
  select s.allenamento_id, s.esercizio_id, s.club_id, a.gruppo_id
    into v_riga
  from public.esercizi_seduta s
  join public.allenamenti a on a.id = s.allenamento_id
  where s.id = new.riga_id;
  if not found then
    raise exception 'Esercizio della seduta non trovato';
  end if;

  select club_id, gruppo_id into v_atleta
  from public.atleti where id = new.atleta_id;
  if not found then
    raise exception 'Atleta non trovato';
  end if;

  if v_riga.club_id <> v_atleta.club_id then
    raise exception 'Seduta di un altro club';
  end if;
  if v_riga.gruppo_id is not null and v_atleta.gruppo_id is not null
     and v_riga.gruppo_id <> v_atleta.gruppo_id then
    raise exception 'Seduta di un altro gruppo';
  end if;

  new.club_id := v_atleta.club_id;
  new.allenamento_id := v_riga.allenamento_id;
  new.esercizio_id := v_riga.esercizio_id;
  return new;
end;
$$;

drop trigger if exists trg_serie_secco_fatte_valida on public.serie_secco_fatte;
create trigger trg_serie_secco_fatte_valida
before insert or update of atleta_id, riga_id, club_id, allenamento_id, esercizio_id
on public.serie_secco_fatte
for each row execute function public.valida_serie_secco_fatta();

alter table public.serie_secco_fatte enable row level security;

drop policy if exists serie_secco_fatte_select on public.serie_secco_fatte;
create policy serie_secco_fatte_select on public.serie_secco_fatte
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

drop policy if exists serie_secco_fatte_insert on public.serie_secco_fatte;
create policy serie_secco_fatte_insert on public.serie_secco_fatte
  for insert with check (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

drop policy if exists serie_secco_fatte_update on public.serie_secco_fatte;
create policy serie_secco_fatte_update on public.serie_secco_fatte
  for update using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  ) with check (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

drop policy if exists serie_secco_fatte_delete on public.serie_secco_fatte;
create policy serie_secco_fatte_delete on public.serie_secco_fatte
  for delete using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );
