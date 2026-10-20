-- ============================================================
-- COM'È ANDATA (proposta 23 del «Piano di WaterTactics», scelte del coach
-- 2026-10-20): oggi una serie è fatta o saltata, mai fatta a metà. Ora
-- si segna anche quanto se ne è fatto davvero: 8 dei 10 da 100, 15 dei
-- 20 minuti di partita. Il programma scritto non cambia mai.
--
-- Solo con esito 'fatta': senza numeri è fatta tutta, con i numeri è
-- fatta in parte. metri_fatti per le serie a distanza, secondi_fatti
-- per quelle a tempo (mai tutte e due). Contano nel carico, nei volumi
-- dell'atleta e nello storico per l'AI; nell'app non superano mai il
-- volume scritto.
-- ============================================================

alter table public.serie
  add column if not exists metri_fatti integer,
  add column if not exists secondi_fatti integer;

alter table public.serie drop constraint if exists serie_fatto_check;
alter table public.serie
  add constraint serie_fatto_check check (
    (metri_fatti is null or metri_fatti >= 0)
    and (secondi_fatti is null or secondi_fatti >= 0)
    and (metri_fatti is null or secondi_fatti is null)
    and (
      (metri_fatti is null and secondi_fatti is null)
      or esito = 'fatta'
    )
  );

-- Come esito: segnare quanto si è fatto non è una modifica del programma
-- da far controllare al capo allenatore.
create or replace function public.modifica_da_riga_allenamento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and (to_jsonb(new) - 'updated_at' - 'esito' - 'metri_fatti' - 'secondi_fatti')
       = (to_jsonb(old) - 'updated_at' - 'esito' - 'metri_fatti' - 'secondi_fatti') then
    return new;
  end if;
  perform public.registra_modifica_allenamento(
    case when tg_op = 'DELETE' then old.allenamento_id else new.allenamento_id end
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

-- Il carico: le stesse righe di prima, più quanto si è fatto.
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
  passo_obiettivo_s numeric,
  recupero_dopo_s integer,
  per_ruolo text,
  solo_atleti uuid[],
  tranne_atleti uuid[],
  momento_id uuid,
  metri_fatti integer,
  secondi_fatti integer
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.ripetute, s.distanza_m, s.durata_s,
         s.zona::text, s.esecuzione::text, s.recupero_s, s.ripartenza_s,
         s.passo_obiettivo_s, s.recupero_dopo_s, s.per_ruolo,
         case when public.is_membro_club(p_club_id) then s.solo_atleti end,
         case when public.is_membro_club(p_club_id) then s.tranne_atleti end,
         case when public.is_membro_club(p_club_id) then s.momento_id end,
         s.metri_fatti, s.secondi_fatti
  from public.serie s
  where s.club_id = p_club_id
    and s.esito is distinct from 'saltata'
    and (
      public.is_membro_club(p_club_id)
      or (
        p_club_id = public.mio_club_atleta()
        and exists (
          select 1
          from public.atleti at
          where at.user_id = auth.uid()
            and at.club_id = p_club_id
            and public.serie_fatta_da(s, at.id, at.ruolo)
        )
      )
    );
$$;

grant execute on function public.serie_per_carico(uuid) to authenticated;
