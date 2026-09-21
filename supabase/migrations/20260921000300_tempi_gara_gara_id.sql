-- ============================================================
-- RISULTATI DI GARA: un tempo dello storico (tempi_gara) può essere
-- collegato alla gara in cui è stato nuotato. Se la gara viene
-- eliminata il tempo resta nello storico dell'atleta (gara_id nullo):
-- è un dato dell'atleta, non della gara.
-- ============================================================

alter table public.tempi_gara
  add column gara_id uuid references public.gare(id) on delete set null;

create index idx_tempi_gara_gara on public.tempi_gara(gara_id);

-- La gara collegata deve essere dello stesso club dell'atleta.
create or replace function public.valida_tempo_gara_gara()
returns trigger
language plpgsql
as $$
declare
  v_club_gara uuid;
  v_club_atleta uuid;
begin
  if new.gara_id is null then
    return new;
  end if;

  select club_id into v_club_gara from public.gare where id = new.gara_id;
  select club_id into v_club_atleta from public.atleti where id = new.atleta_id;

  if v_club_gara is null or v_club_atleta is null
     or v_club_gara <> v_club_atleta then
    raise exception 'La gara e l''atleta appartengono a club diversi';
  end if;

  return new;
end;
$$;

create trigger trg_tempi_gara_gara_valida
before insert or update of gara_id, atleta_id on public.tempi_gara
for each row execute function public.valida_tempo_gara_gara();
