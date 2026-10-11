-- ============================================================
-- RPE DI SEDUTA (analisi "Il Mako della pallanuoto", proposta 1): a fine
-- allenamento e a fine partita l'atleta dice quanto e' stata dura, da 0
-- a 10 (scala CR-10 di Foster). Il carico della seduta diventa RPE x
-- minuti, contato a parte per acqua, secco e partita: prima una partita
-- valeva zero nel carico.
--
-- Una riga per atleta e per seduta: ridare la risposta la aggiorna.
-- Scrive l'atleta (le proprie) e anche l'allenatore del club, per gli
-- atleti senza account.
-- ============================================================

create table public.rpe_sedute (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atleti(id) on delete cascade,
  club_id uuid not null references public.club(id) on delete cascade,
  evento_tipo text not null check (evento_tipo in ('allenamento', 'partita')),
  -- Id dell'allenamento o della partita: niente chiave esterna perche'
  -- punta a due tabelle; una riga orfana non conta nel carico.
  evento_id uuid not null,
  -- Il giorno della seduta, per il carico giorno per giorno.
  data date not null,
  rpe smallint not null check (rpe between 0 and 10),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (atleta_id, evento_tipo, evento_id)
);

create index idx_rpe_sedute_club_data on public.rpe_sedute(club_id, data desc);
create index idx_rpe_sedute_atleta on public.rpe_sedute(atleta_id);

create trigger trg_rpe_sedute_updated_at
before update on public.rpe_sedute
for each row execute function public.set_updated_at();

-- club_id derivato dall'atleta, come per le schede benessere.
create trigger trg_rpe_sedute_club
before insert or update of atleta_id on public.rpe_sedute
for each row execute function public.imposta_club_da_atleta();

alter table public.rpe_sedute enable row level security;

create policy rpe_sedute_select on public.rpe_sedute
  for select using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

create policy rpe_sedute_insert on public.rpe_sedute
  for insert with check (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

create policy rpe_sedute_update on public.rpe_sedute
  for update using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  ) with check (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

create policy rpe_sedute_delete on public.rpe_sedute
  for delete using (
    public.is_membro_club(club_id) or atleta_id = public.mia_atleta_id()
  );

-- ------------------------------------------------------------
-- serie_per_carico: anche recupero, ripartenza e passo obiettivo, per
-- stimare la durata della seduta (i minuti del carico) come la stima
-- mostrata nel dettaglio dell'allenamento. Il tipo di ritorno cambia:
-- va eliminata prima di ridefinirla (vedi 20261008000400).
-- ------------------------------------------------------------

drop function if exists public.serie_per_carico(uuid);

create or replace function public.serie_per_carico(p_club_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  ripetute integer,
  distanza_m integer,
  durata_s integer,
  zona text,
  esecuzione text,
  recupero_s integer,
  ripartenza_s numeric,
  passo_obiettivo_s numeric
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.ripetute, s.distanza_m, s.durata_s,
         s.zona::text, s.esecuzione::text, s.recupero_s, s.ripartenza_s,
         s.passo_obiettivo_s
  from public.serie s
  where s.club_id = p_club_id
    and s.esito is distinct from 'saltata'
    and (
      public.is_membro_club(p_club_id)
      or p_club_id = public.mio_club_atleta()
    );
$$;

grant execute on function public.serie_per_carico(uuid) to authenticated;
