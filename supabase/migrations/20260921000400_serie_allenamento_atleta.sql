-- ============================================================
-- Dashboard atleta: «Prossimo allenamento».
--
-- L'atleta non può leggere la tabella `serie` (dall'audit del 12/09 ha
-- solo `serie_per_carico`: ripetute/distanza/zona/esecuzione di TUTTO
-- il club, senza stile, recuperi, attrezzatura). Per mostrargli il
-- prossimo allenamento in modalità vasca servono le serie di UN
-- allenamento con quei dettagli — ma mai il campo libero `note`, dove
-- l'allenatore può scrivere appunti sugli atleti.
--
-- La funzione restituisce le serie solo se l'allenamento è del club
-- dell'atleta e, se l'atleta ha un gruppo, l'allenamento è senza gruppo
-- o del suo stesso gruppo: l'isolamento fra gruppi vale anche lato
-- server, non solo nell'app. Un atleta senza gruppo vede quelli del
-- club, come già fa `allenamenti_atleta`.
-- ============================================================

create or replace function public.serie_allenamento_atleta(p_allenamento_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  club_id uuid,
  ordine integer,
  blocco text,
  ripetute integer,
  distanza_m integer,
  stile text,
  esecuzione text,
  zona text,
  passo_obiettivo_s numeric,
  recupero_s integer,
  ripartenza_s numeric,
  attrezzatura text
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.club_id, s.ordine, s.blocco::text,
         s.ripetute, s.distanza_m, s.stile::text, s.esecuzione::text,
         s.zona::text, s.passo_obiettivo_s, s.recupero_s, s.ripartenza_s,
         s.attrezzatura
  from public.serie s
  join public.allenamenti a on a.id = s.allenamento_id
  join public.atleti at on at.user_id = auth.uid() and at.club_id = a.club_id
  where s.allenamento_id = p_allenamento_id
    and (a.gruppo_id is null or at.gruppo_id is null or a.gruppo_id = at.gruppo_id)
  order by s.ordine;
$$;

grant execute on function public.serie_allenamento_atleta(uuid) to authenticated;
