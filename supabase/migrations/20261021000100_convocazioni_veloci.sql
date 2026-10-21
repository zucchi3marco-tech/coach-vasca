-- ============================================================
-- CONVOCAZIONI VELOCI (richiesta del coach 2026-10-21): tutti i
-- convocati insieme, i numeri come nell'ultima partita e riordinabili,
-- capitano e vice in cima alla distinta, il modulo FIN in Excel con lo
-- staff della squadra.
-- ============================================================

-- ------------------------------------------------------------
-- Lo staff del modulo (tecnico, vice tecnico, accompagnatore,
-- dirigente, medico, con la tessera FIN): si scrive una volta nella
-- squadra e vale per ogni partita; una partita può avere il suo
-- (null = come la squadra).
-- Forma: {"tecnico": {"nome": "...", "tessera": "..."}, ...}
-- ------------------------------------------------------------
alter table public.gruppi
  add column if not exists staff_distinta jsonb not null default '{}'::jsonb;

alter table public.partite
  add column if not exists staff_distinta jsonb;

-- ------------------------------------------------------------
-- Nuovi numeri a più convocati in un colpo solo. Il vincolo
-- "un numero per partita" non permette di scambiarli una riga alla
-- volta (per un istante due avrebbero lo stesso numero): prima si
-- spostano tutti oltre il 1000, poi si mettono quelli giusti, nella
-- stessa transazione.
-- p_numeri: [{"id": "<riga della distinta>", "numero": 7}, ...]
-- Con i permessi di chi la chiama: valgono le stesse regole della
-- tabella.
-- ------------------------------------------------------------
create or replace function public.rinumera_distinta(
  p_partita_id uuid,
  p_numeri jsonb
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_attese integer;
  v_fatte integer;
begin
  select count(*) into v_attese from jsonb_array_elements(p_numeri);
  if v_attese = 0 then
    return;
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_numeri) e
    where (e->>'numero')::integer is null or (e->>'numero')::integer <= 0
  ) then
    raise exception 'Numero di calottina non valido';
  end if;

  update public.distinta_giocatori d
  set numero_calottina = d.numero_calottina + 1000
  where d.partita_id = p_partita_id
    and d.id in (select (e->>'id')::uuid from jsonb_array_elements(p_numeri) e);
  get diagnostics v_fatte = row_count;
  if v_fatte <> v_attese then
    raise exception 'Alcuni convocati non sono in questa distinta';
  end if;

  update public.distinta_giocatori d
  set numero_calottina = (e->>'numero')::integer
  from jsonb_array_elements(p_numeri) e
  where d.partita_id = p_partita_id
    and d.id = (e->>'id')::uuid;
end;
$$;

grant execute on function public.rinumera_distinta(uuid, jsonb) to authenticated;

-- ------------------------------------------------------------
-- Capitano e vice della partita in un colpo solo: chi lo era torna
-- giocatore, poi si segnano i nuovi (null = nessuno). Prima l'app li
-- segnava uno alla volta e il secondo capitano veniva rifiutato.
-- ------------------------------------------------------------
create or replace function public.scegli_capitani(
  p_partita_id uuid,
  p_capitano_id uuid,
  p_vice_id uuid
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_fatte integer;
begin
  if p_capitano_id is not null and p_capitano_id = p_vice_id then
    raise exception 'Capitano e vice devono essere due atleti diversi';
  end if;

  update public.distinta_giocatori
  set capitano = false, vice_capitano = false
  where partita_id = p_partita_id
    and (capitano or vice_capitano);

  if p_capitano_id is not null then
    update public.distinta_giocatori
    set capitano = true
    where id = p_capitano_id and partita_id = p_partita_id;
    get diagnostics v_fatte = row_count;
    if v_fatte = 0 then
      raise exception 'Il capitano non è in questa distinta';
    end if;
  end if;

  if p_vice_id is not null then
    update public.distinta_giocatori
    set vice_capitano = true
    where id = p_vice_id and partita_id = p_partita_id;
    get diagnostics v_fatte = row_count;
    if v_fatte = 0 then
      raise exception 'Il vice non è in questa distinta';
    end if;
  end if;
end;
$$;

grant execute on function public.scegli_capitani(uuid, uuid, uuid) to authenticated;
