-- Portieri: chi era in porta su ogni tiro avversario e in quali tempi.
--
-- portiere_id (eventi_partita): solo su un tiro avversario, il nostro
-- portiere in acqua in quel momento. Da qui parate e gol subiti dal vivo,
-- anche quando il portiere cambia a metà tempo.
--
-- tempi_in_porta (distinta_giocatori): i tempi (1-4, più eventuali
-- supplementari) in cui il convocato è stato in porta. Serve quando la
-- partita ha solo il referto: i gol subiti si ricavano dai parziali di
-- quei tempi. Dal vivo si aggiorna da solo.

alter table public.eventi_partita
  add column if not exists portiere_id uuid references public.atleti(id) on delete set null;

alter table public.eventi_partita drop constraint if exists eventi_partita_portiere_check;
alter table public.eventi_partita add constraint eventi_partita_portiere_check check (
  portiere_id is null or (tipo = 'tiro' and squadra = 'avversaria')
);

create index if not exists idx_eventi_partita_portiere
  on public.eventi_partita(portiere_id) where portiere_id is not null;

alter table public.distinta_giocatori
  add column if not exists tempi_in_porta smallint[] not null default '{}';

-- Anche il portiere dev'essere del club della partita.
create or replace function public.imposta_e_valida_evento_partita()
returns trigger
language plpgsql
as $$
declare
  v_club_partita uuid;
  v_club_atleta uuid;
  v_atleta uuid;
begin
  select club_id into v_club_partita from public.partite where id = new.partita_id;
  if v_club_partita is null then
    raise exception 'Partita % non trovata', new.partita_id;
  end if;

  foreach v_atleta in array array[new.atleta_id, new.assist_di, new.guadagnata_da, new.portiere_id] loop
    continue when v_atleta is null;
    select club_id into v_club_atleta from public.atleti where id = v_atleta;
    if v_club_atleta is null then
      raise exception 'Atleta % non trovato', v_atleta;
    end if;
    if v_club_atleta <> v_club_partita then
      raise exception 'Atleta e partita appartengono a club diversi';
    end if;
  end loop;

  new.club_id := v_club_partita;
  return new;
end;
$$;

drop trigger if exists trg_eventi_partita_club on public.eventi_partita;
create trigger trg_eventi_partita_club
before insert or update of partita_id, atleta_id, assist_di, guadagnata_da, portiere_id on public.eventi_partita
for each row execute function public.imposta_e_valida_evento_partita();
