-- ============================================================
-- RPC per la creazione di un club.
--
-- Perche' serve: un semplice "insert into club(...) returning *"
-- fallisce con "new row violates row-level security policy for
-- table club" quando il client chiede la riga indietro (RETURNING /
-- Prefer: return=representation). Postgres valuta la policy di
-- SELECT (club_select, basata su is_membro_club) sulla riga
-- restituita PRIMA che il trigger AFTER INSERT
-- gestisci_nuovo_club() abbia inserito la membership in
-- club_membri: al momento del controllo l'utente non risulta
-- ancora membro del club appena creato.
--
-- La funzione, essendo SECURITY DEFINER, esegue l'insert e
-- restituisce la riga bypassando del tutto questo controllo di
-- visibilita' (il trigger esistente su public.club continua a
-- occuparsi di creare la membership, invariato).
-- ============================================================

create or replace function public.create_club(p_nome text, p_citta text default null)
returns public.club
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club public.club;
begin
  insert into public.club (nome, citta)
  values (p_nome, p_citta)
  returning * into v_club;

  return v_club;
end;
$$;

grant execute on function public.create_club(text, text) to authenticated;
