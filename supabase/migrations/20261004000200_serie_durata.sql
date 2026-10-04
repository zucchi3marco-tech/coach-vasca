-- ============================================================
-- RIPROGETTAZIONE AI, FASE 1: campo "durata in secondi" sulla serie
-- vera, accanto a "distanza in metri" gia' esistente — una serie usa
-- l'uno o l'altro, mai entrambi (stesso principio della libreria di
-- blocchi che arriva in questa stessa fase: 67 parti su 389 sono a
-- tempo, soprattutto pallanuoto). Le serie gia' salvate hanno sempre
-- una distanza, quindi la colonna resta nullable solo per permettere
-- la nuova alternativa, non toglie nulla a chi c'e' gia'.
-- ============================================================

alter table public.serie
  alter column distanza_m drop not null;

alter table public.serie
  add column durata_s integer check (durata_s > 0);

alter table public.serie
  add constraint serie_distanza_o_durata check (
    (distanza_m is not null and durata_s is null)
    or (distanza_m is null and durata_s is not null)
  );

-- La funzione per l'atleta collegato (dashboard "Prossimo allenamento")
-- deve restituire anche la nuova colonna, altrimenti una serie a tempo
-- gli arriverebbe senza durata ne' distanza.
create or replace function public.serie_allenamento_atleta(p_allenamento_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  club_id uuid,
  ordine integer,
  blocco text,
  ripetute integer,
  distanza_m integer,
  durata_s integer,
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
         s.ripetute, s.distanza_m, s.durata_s, s.stile::text, s.esecuzione::text,
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
