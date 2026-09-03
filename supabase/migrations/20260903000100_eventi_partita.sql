-- ============================================================
-- PALLANUOTO V2 (FASE 7, punto 2): EVENTI PARTITA
-- Log base degli eventi di una partita: tiro (di un nostro atleta),
-- espulsione (di un nostro atleta) e superiorita' numerica (nostra o
-- avversaria). Punteggio completo e plus/minus sono un punto successivo
-- della roadmap.
--
-- Le impostazioni di dettaglio (dettaglio_tiro, traccia_tempo,
-- modalita_superiorita) vivono sulla partita, non su una tabella di
-- default separata: in UI vengono precompilate copiando l'ultima
-- partita del club, ma restano sempre modificabili per la singola
-- partita.
-- ============================================================

alter table public.partite add column dettaglio_tiro text not null default 'semplice' check (dettaglio_tiro in ('semplice', 'dettagliato'));
alter table public.partite add column traccia_tempo boolean not null default true;
alter table public.partite add column modalita_superiorita text not null default 'singolo' check (modalita_superiorita in ('singolo', 'inizio_fine'));

create table public.eventi_partita (
  id uuid primary key default gen_random_uuid(),
  partita_id uuid not null references public.partite(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  tipo text not null check (tipo in ('tiro', 'espulsione', 'superiorita')),
  squadra text not null default 'nostra' check (squadra in ('nostra', 'avversaria')),
  atleta_id uuid references public.atleti(id) on delete set null,
  periodo integer check (periodo between 1 and 6),
  esito text check (esito in ('gol', 'non_gol', 'parato', 'palo_fuori')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (tipo in ('tiro', 'espulsione') and atleta_id is not null)
    or (tipo = 'superiorita' and atleta_id is null)
  )
);

create index idx_eventi_partita_partita on public.eventi_partita(partita_id);
create index idx_eventi_partita_club on public.eventi_partita(club_id);

create trigger trg_eventi_partita_updated_at
before update on public.eventi_partita
for each row execute function public.set_updated_at();

-- club_id derivato dalla partita, con validazione incrociata che l'atleta
-- (quando presente) appartenga allo stesso club (stesso schema usato per
-- distinta_giocatori).
create or replace function public.imposta_e_valida_evento_partita()
returns trigger
language plpgsql
as $$
declare
  v_club_partita uuid;
  v_club_atleta uuid;
begin
  select club_id into v_club_partita from public.partite where id = new.partita_id;
  if v_club_partita is null then
    raise exception 'Partita % non trovata', new.partita_id;
  end if;

  if new.atleta_id is not null then
    select club_id into v_club_atleta from public.atleti where id = new.atleta_id;
    if v_club_atleta is null then
      raise exception 'Atleta % non trovato', new.atleta_id;
    end if;
    if v_club_atleta <> v_club_partita then
      raise exception 'Atleta e partita appartengono a club diversi';
    end if;
  end if;

  new.club_id := v_club_partita;
  return new;
end;
$$;

create trigger trg_eventi_partita_club
before insert or update of partita_id, atleta_id on public.eventi_partita
for each row execute function public.imposta_e_valida_evento_partita();

alter table public.eventi_partita enable row level security;

create policy eventi_partita_select on public.eventi_partita
  for select using (public.is_membro_club(club_id));

create policy eventi_partita_insert on public.eventi_partita
  for insert with check (public.is_membro_club(club_id));

create policy eventi_partita_update on public.eventi_partita
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy eventi_partita_delete on public.eventi_partita
  for delete using (public.is_membro_club(club_id));
