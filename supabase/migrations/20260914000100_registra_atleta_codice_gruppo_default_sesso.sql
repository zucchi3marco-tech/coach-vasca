-- ============================================================
-- Fix: registra_atleta_da_codice_gruppo falliva con "Could not
-- find the function" quando il campo Sesso non era compilato.
-- Il client Flutter omette 'p_sesso' dai parametri RPC quando e'
-- null (stesso pattern usato per p_citta/p_sport in create_club),
-- ma qui p_sesso non aveva un default: PostgREST cercava una
-- versione a 5 parametri, inesistente. Aggiungiamo default null
-- a p_sesso (e, per rispettare la regola SQL che i parametri con
-- default devono essere finali, anche a p_sport) senza cambiare
-- il corpo della funzione.
-- ============================================================

create or replace function public.registra_atleta_da_codice_gruppo(
  p_codice text,
  p_nome text,
  p_cognome text,
  p_data_nascita date,
  p_sesso text default null,
  p_sport text default null
)
returns public.atleti
language plpgsql
security definer
set search_path = public
as $$
declare
  v_codice public.codici_gruppo;
  v_atleta public.atleti;
begin
  if exists (select 1 from public.atleti where user_id = auth.uid()) then
    raise exception 'Questo account e'' gia'' collegato a un atleta';
  end if;

  select * into v_codice
  from public.codici_gruppo
  where codice = upper(p_codice)
    and scade_il > now();

  if v_codice is null then
    raise exception 'Codice non valido o scaduto';
  end if;

  if p_nome is null or length(trim(p_nome)) = 0
    or p_cognome is null or length(trim(p_cognome)) = 0
    or p_data_nascita is null then
    raise exception 'Nome, cognome e data di nascita sono obbligatori';
  end if;

  insert into public.atleti (
    club_id, nome, cognome, data_nascita, sesso, sport, gruppo_id, user_id
  )
  values (
    v_codice.club_id, trim(p_nome), trim(p_cognome), p_data_nascita,
    p_sesso, coalesce(p_sport, 'nuoto')::public.sport, v_codice.gruppo_id, auth.uid()
  )
  returning * into v_atleta;

  return v_atleta;
end;
$$;

grant execute on function public.registra_atleta_da_codice_gruppo(
  text, text, text, date, text, text
) to authenticated;
