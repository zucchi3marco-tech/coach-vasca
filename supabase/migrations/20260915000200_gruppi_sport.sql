-- ============================================================
-- FASE 13, punto 2: lo sport di un atleta che si registra con un
-- codice di gruppo si deduce dal gruppo stesso (mai da club.sport,
-- che per un club "nuoto e pallanuoto" resterebbe ambiguo). Ogni
-- gruppo porta ora il proprio sport, valorizzato:
-- - in automatico quando nasce da una categoria scelta in fase di
--   creazione club (gia' specifica di un solo sport)
-- - in automatico anche per i gruppi creati a mano, quando il club
--   pratica un solo sport (nessuna ambiguita' possibile)
-- - lasciato null per i gruppi gia' esistenti di un club "nuoto e
--   pallanuoto" (o senza sport impostato): la registrazione via
--   codice continua a chiedere lo sport per questi, come oggi.
-- ============================================================

alter table public.gruppi
  add column sport text
  check (sport is null or sport in ('nuoto', 'pallanuoto'));

update public.gruppi g
set sport = c.sport
from public.club c
where c.id = g.club_id
  and c.sport in ('nuoto', 'pallanuoto');

-- valida_codice_gruppo: ritorna anche lo sport del gruppo (drop
-- necessario perche' cambia l'elenco delle colonne di ritorno).
drop function if exists public.valida_codice_gruppo(text);

create or replace function public.valida_codice_gruppo(p_codice text)
returns table (gruppo_nome text, club_nome text, gruppo_sport text)
language sql
stable
security definer
set search_path = public
as $$
  select g.nome, cl.nome, g.sport
  from public.codici_gruppo c
  join public.club cl on cl.id = c.club_id
  join public.gruppi g on g.id = c.gruppo_id
  where c.codice = upper(p_codice)
    and c.scade_il > now();
$$;

grant execute on function public.valida_codice_gruppo(text) to anon, authenticated;
