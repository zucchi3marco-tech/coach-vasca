-- ============================================================
-- FASE 8: SALVATAGGIO REFERTI ANALIZZATI
-- Il referto letto (via edge function leggi-referto) e corretto a mano
-- dall'utente viene salvato come archivio legato a una Partita:
-- risultato finale, parziali per tempo e rose complete (reti/espulsioni)
-- di entrambe le squadre. Un solo referto per partita (unique su
-- partita_id): salvare di nuovo sovrascrive quello precedente, stesso
-- schema di upsert su chiave naturale gia' usato per "presenze".
-- ============================================================

create table public.referti_partita (
  id uuid primary key default gen_random_uuid(),
  partita_id uuid not null unique references public.partite(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  squadra_casa text not null,
  squadra_trasferta text not null,
  risultato_casa integer not null check (risultato_casa >= 0),
  risultato_trasferta integer not null check (risultato_trasferta >= 0),
  parziali jsonb not null default '[]'::jsonb,
  giocatori_casa jsonb not null default '[]'::jsonb,
  giocatori_trasferta jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_referti_partita_club on public.referti_partita(club_id);

create trigger trg_referti_partita_updated_at
before update on public.referti_partita
for each row execute function public.set_updated_at();

-- club_id derivato dalla partita, stesso schema usato per distinta_giocatori
-- ed eventi_partita.
create or replace function public.imposta_e_valida_referto_partita()
returns trigger
language plpgsql
as $$
declare
  v_club_partita uuid;
begin
  select club_id into v_club_partita from public.partite where id = new.partita_id;
  if v_club_partita is null then
    raise exception 'Partita % non trovata', new.partita_id;
  end if;

  new.club_id := v_club_partita;
  return new;
end;
$$;

create trigger trg_referti_partita_club
before insert or update of partita_id on public.referti_partita
for each row execute function public.imposta_e_valida_referto_partita();

alter table public.referti_partita enable row level security;

create policy referti_partita_select on public.referti_partita
  for select using (public.is_membro_club(club_id));

create policy referti_partita_insert on public.referti_partita
  for insert with check (public.is_membro_club(club_id));

create policy referti_partita_update on public.referti_partita
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy referti_partita_delete on public.referti_partita
  for delete using (public.is_membro_club(club_id));
