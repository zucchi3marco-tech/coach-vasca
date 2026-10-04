-- ============================================================
-- RIPROGETTAZIONE AI, FASE 1: libreria di blocchi di allenamento
-- approvati dal coach, per club (stesso isolamento di ogni altra
-- tabella: RLS via is_membro_club()). Un "blocco" (es. "8x100 soglia")
-- e' fatto di "parti" (le sue serie), stesso schema allenamento->serie.
--
-- codice e' la chiave di business usata dall'importatore Excel (id
-- dell'Excel, es. "N-001"): unico per club, non globalmente — club
-- diversi possono avere blocchi con lo stesso codice senza conflitto.
--
-- modificato_in_app + importato_il: l'importatore non sovrascrive mai
-- un blocco che il coach ha modificato a mano nell'app dopo l'ultimo
-- import (vedi piano FASE 1).
-- ============================================================

create table public.training_blocks (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  codice text not null,
  sport text not null check (sport in ('nuoto', 'pallanuoto', 'entrambi')),
  fase text not null,
  obiettivo text not null,
  zone_coinvolte text not null,
  titolo text not null,
  descrizione text not null,
  stile_principale text,
  livelli text not null default '',
  attrezzi text,
  metri_totali integer not null default 0 check (metri_totali >= 0),
  durata_stimata_min integer not null default 0 check (durata_stimata_min >= 0),
  note text,
  stato text not null default 'bozza' check (stato in ('approvato', 'bozza')),
  fonte text not null default 'Allenatore',
  importato_il timestamptz,
  modificato_in_app boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (club_id, codice)
);

create index idx_training_blocks_club on public.training_blocks(club_id);

create trigger trg_training_blocks_updated_at
before update on public.training_blocks
for each row execute function public.set_updated_at();

alter table public.training_blocks enable row level security;

create policy training_blocks_select on public.training_blocks
  for select using (public.is_membro_club(club_id));

create policy training_blocks_insert on public.training_blocks
  for insert with check (public.is_membro_club(club_id));

create policy training_blocks_update on public.training_blocks
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy training_blocks_delete on public.training_blocks
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- TRAINING_BLOCK_PARTI: le serie di un blocco.
-- club_id derivato dal blocco (stesso schema di imposta_club_da_allenamento).
-- zona resta nel vocabolario esteso dell'Excel (A1/A2/B1/B2/C1/C2/V/RG/
-- T/TT/TEST), non ancora tradotto in zona_intensita: la traduzione
-- (V->C3, RG->D, T/TT/TEST fuori dalla zona) avviene quando una parte
-- diventa una serie vera (FASE 3).
-- ------------------------------------------------------------

create table public.training_block_parti (
  id uuid primary key default gen_random_uuid(),
  blocco_id uuid not null references public.training_blocks(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  ordine integer not null default 1,
  giri integer not null default 1 check (giri > 0),
  ripetizioni integer not null default 1 check (ripetizioni > 0),
  distanza_m integer check (distanza_m > 0),
  durata_s integer check (durata_s > 0),
  stile text,
  esercizio text,
  zona text not null,
  esecuzione text not null,
  recupero_s integer check (recupero_s >= 0),
  attrezzi text,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint training_block_parti_distanza_o_durata check (
    (distanza_m is not null and durata_s is null)
    or (distanza_m is null and durata_s is not null)
  )
);

create index idx_training_block_parti_blocco on public.training_block_parti(blocco_id, ordine);
create index idx_training_block_parti_club on public.training_block_parti(club_id);

create trigger trg_training_block_parti_updated_at
before update on public.training_block_parti
for each row execute function public.set_updated_at();

create or replace function public.imposta_club_da_blocco()
returns trigger
language plpgsql
as $$
begin
  select club_id into new.club_id from public.training_blocks where id = new.blocco_id;
  if new.club_id is null then
    raise exception 'Blocco % non trovato', new.blocco_id;
  end if;
  return new;
end;
$$;

create trigger trg_training_block_parti_club
before insert or update of blocco_id on public.training_block_parti
for each row execute function public.imposta_club_da_blocco();

alter table public.training_block_parti enable row level security;

create policy training_block_parti_select on public.training_block_parti
  for select using (public.is_membro_club(club_id));

create policy training_block_parti_insert on public.training_block_parti
  for insert with check (public.is_membro_club(club_id));

create policy training_block_parti_update on public.training_block_parti
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

create policy training_block_parti_delete on public.training_block_parti
  for delete using (public.is_membro_club(club_id));

-- ------------------------------------------------------------
-- Semina automatica per i nuovi club: un club "modello" (mai membro di
-- nessun utente, invisibile via RLS normale) tiene la libreria base di
-- fabbrica; create_club ne copia blocchi+parti nel club appena creato.
-- Popolato dalla migrazione successiva (generata dal file Excel).
-- ------------------------------------------------------------

-- Il trigger normale assegnerebbe come owner chi esegue la migrazione
-- (auth.uid() e' null in questo contesto, il che violerebbe il not null
-- di user_id): va disattivato per questo solo insert. Il club modello
-- non deve avere membri, cosi' resta invisibile a chiunque tranne alla
-- funzione SECURITY DEFINER che lo copia.
alter table public.club disable trigger trg_nuovo_club_owner;

insert into public.club (id, nome, citta)
values ('00000000-0000-0000-0000-000000000001', 'Libreria base (modello)', null)
on conflict (id) do nothing;

alter table public.club enable trigger trg_nuovo_club_owner;

drop function if exists public.create_club(text, text, text, text[]);

create or replace function public.create_club(
  p_nome text,
  p_citta text default null,
  p_sport text default null,
  p_categorie text[] default '{}'
)
returns public.club
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club public.club;
begin
  insert into public.club (nome, citta, sport, categorie)
  values (p_nome, p_citta, p_sport, coalesce(p_categorie, '{}'))
  returning * into v_club;

  with blocchi_copiati as (
    insert into public.training_blocks (
      club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
      descrizione, stile_principale, livelli, attrezzi, metri_totali,
      durata_stimata_min, note, stato, fonte, importato_il
    )
    select
      v_club.id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
      descrizione, stile_principale, livelli, attrezzi, metri_totali,
      durata_stimata_min, note, stato, fonte, now()
    from public.training_blocks
    where club_id = '00000000-0000-0000-0000-000000000001'
    returning id, codice
  )
  insert into public.training_block_parti (
    blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
    stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
  )
  select
    nuovo.id, v_club.id, p.ordine, p.giri, p.ripetizioni, p.distanza_m,
    p.durata_s, p.stile, p.esercizio, p.zona, p.esecuzione, p.recupero_s,
    p.attrezzi, p.note
  from public.training_block_parti p
  join public.training_blocks originale on originale.id = p.blocco_id
    and originale.club_id = '00000000-0000-0000-0000-000000000001'
  join blocchi_copiati nuovo on nuovo.codice = originale.codice;

  return v_club;
end;
$$;

grant execute on function public.create_club(text, text, text, text[]) to authenticated;
