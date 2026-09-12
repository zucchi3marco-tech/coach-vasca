-- ============================================================
-- Audit 12/09: le policy allenamenti_select_self/serie_select_self
-- (20260906000200_atleta_account.sql) davano all'atleta collegato
-- accesso all'INTERA riga di ogni allenamento/serie del club (incluse
-- note/titolo/attrezzatura), non solo ai campi che gli servono per
-- calcolare il proprio carico (CaricoRepository). Un allenatore che
-- scrive appunti su un atleta nel campo "note" di un allenamento o di
-- una serie li rendeva leggibili anche a qualsiasi altro atleta
-- collegato dello stesso club.
--
-- Sostituiamo quelle due policy con due funzioni SECURITY DEFINER che
-- restituiscono solo le colonne che il calcolo del carico usa davvero
-- (mai note/titolo/attrezzatura). Il coach continua a leggere le
-- tabelle intere come sempre (le policy esistenti basate su
-- is_membro_club() non vengono toccate): qui aggiungiamo solo un
-- percorso più stretto per l'atleta.
-- ============================================================

drop policy if exists allenamenti_select_self on public.allenamenti;
drop policy if exists serie_select_self on public.serie;

create or replace function public.allenamenti_per_carico(p_club_id uuid)
returns table (id uuid, data date)
language sql
stable
security definer
set search_path = public
as $$
  select a.id, a.data
  from public.allenamenti a
  where a.club_id = p_club_id
    and (
      public.is_membro_club(p_club_id)
      or p_club_id = public.mio_club_atleta()
    );
$$;

create or replace function public.serie_per_carico(p_club_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  ripetute integer,
  distanza_m integer,
  zona text,
  esecuzione text
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.ripetute, s.distanza_m,
         s.zona::text, s.esecuzione::text
  from public.serie s
  where s.club_id = p_club_id
    and (
      public.is_membro_club(p_club_id)
      or p_club_id = public.mio_club_atleta()
    );
$$;

grant execute on function public.allenamenti_per_carico(uuid) to authenticated;
grant execute on function public.serie_per_carico(uuid) to authenticated;
