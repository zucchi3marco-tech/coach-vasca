-- ============================================================
-- GIRONI_FIN: i gironi dei campionati regionali FIN Lombardia collegati
-- alle squadre del club (richiesta del coach del 13 ottobre 2026).
-- L'allenatore sceglie dal sito FIN campionato, fase e girone di una
-- squadra e tocca la sua squadra nella classifica: classifica e
-- calendario poi li legge l'app dal sito (Edge Function `campionati-fin`).
-- Qui si salva solo il collegamento: niente dati personali.
-- La vedono tutti nel club (allenatori, atleti e famiglie: sono dati
-- pubblici della federazione); la cambiano solo gli allenatori.
-- ============================================================

create table if not exists public.gironi_fin (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  -- null = vale per tutto il club.
  gruppo_id uuid references public.gruppi(id) on delete cascade,
  -- L'identificativo del girone sul sito FIN (CMPid).
  cmp_id integer not null check (cmp_id > 0),
  stagione text not null check (stagione ~ '^\d{4}-\d{4}$'),
  campionato text not null check (length(campionato) between 1 and 200),
  fase text check (length(fase) <= 100),
  girone text check (length(girone) <= 100),
  -- Il nome della squadra del club come lo scrive il sito FIN.
  squadra text not null check (length(squadra) between 1 and 200),
  created_at timestamptz not null default now(),
  unique nulls not distinct (club_id, gruppo_id, cmp_id)
);

create index if not exists idx_gironi_fin_club on public.gironi_fin(club_id);

-- La squadra deve essere dello stesso club.
create or replace function public.valida_girone_fin()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.gruppo_id is not null and not exists (
    select 1 from public.gruppi
    where id = new.gruppo_id and club_id = new.club_id
  ) then
    raise exception 'La squadra non appartiene al club';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_valida_girone_fin on public.gironi_fin;
create trigger trg_valida_girone_fin
before insert or update on public.gironi_fin
for each row execute function public.valida_girone_fin();

alter table public.gironi_fin enable row level security;

drop policy if exists gironi_fin_select on public.gironi_fin;
create policy gironi_fin_select on public.gironi_fin
  for select using (
    public.is_membro_club(club_id) or club_id = public.mio_club_atleta()
  );

drop policy if exists gironi_fin_insert on public.gironi_fin;
create policy gironi_fin_insert on public.gironi_fin
  for insert with check (public.is_membro_club(club_id));

drop policy if exists gironi_fin_update on public.gironi_fin;
create policy gironi_fin_update on public.gironi_fin
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

drop policy if exists gironi_fin_delete on public.gironi_fin;
create policy gironi_fin_delete on public.gironi_fin
  for delete using (public.is_membro_club(club_id));
