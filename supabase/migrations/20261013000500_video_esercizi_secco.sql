-- ============================================================
-- VIDEO DEGLI ESERCIZI A SECCO (Fase 4 del "Mako della pallanuoto",
-- proposta 10)
--
-- Scelte del coach: a un esercizio dell'elenco del club si attacca un
-- video di YouTube (un link, anche "non in elenco"), che si guarda dentro
-- l'app con lo stesso lettore delle partite; lo vedono anche gli atleti,
-- nella loro seduta a secco. Si salva l'id del video e, se il link lo
-- dice, il secondo da cui parte.
-- ============================================================

alter table public.esercizi_secco
  add column if not exists video_youtube text,
  add column if not exists video_da_s integer;

alter table public.esercizi_secco drop constraint if exists esercizi_secco_video_youtube_check;
alter table public.esercizi_secco add constraint esercizi_secco_video_youtube_check
  check (video_youtube is null or video_youtube ~ '^[A-Za-z0-9_-]{11}$');

alter table public.esercizi_secco drop constraint if exists esercizi_secco_video_da_s_check;
alter table public.esercizi_secco add constraint esercizi_secco_video_da_s_check
  check (video_da_s is null or video_da_s between 0 and 86400);

-- Gli esercizi di una seduta per l'atleta collegato: anche il video
-- (cambia cosa restituisce: si ricrea). Stessa regola di prima.
drop function if exists public.esercizi_seduta_atleta(uuid);
create function public.esercizi_seduta_atleta(p_allenamento_id uuid)
returns table (
  id uuid,
  allenamento_id uuid,
  esercizio_id uuid,
  ordine integer,
  nome text,
  categoria text,
  misura text,
  attrezzo text,
  descrizione text,
  video_youtube text,
  video_da_s integer,
  serie smallint,
  ripetizioni smallint,
  durata_s integer,
  carico text,
  recupero_s integer
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.allenamento_id, s.esercizio_id, s.ordine, e.nome,
         e.categoria, e.misura, e.attrezzo, e.descrizione, e.video_youtube,
         e.video_da_s, s.serie, s.ripetizioni, s.durata_s, s.carico,
         s.recupero_s
  from public.esercizi_seduta s
  join public.esercizi_secco e on e.id = s.esercizio_id
  join public.allenamenti a on a.id = s.allenamento_id
  join public.atleti at on at.user_id = auth.uid() and at.club_id = a.club_id
  where s.allenamento_id = p_allenamento_id
    and (a.gruppo_id is null or at.gruppo_id is null or a.gruppo_id = at.gruppo_id)
  order by s.ordine;
$$;

grant execute on function public.esercizi_seduta_atleta(uuid) to authenticated;
