-- ============================================================
-- PARTITE PIU' RICCHE (Fase 2 del "Mako della pallanuoto", proposta 5)
--
-- Ogni partita ha la sua modalita' degli eventi dal vivo:
--   'essenziale' — com'era: tiri, espulsioni, rigori, tiri avversari;
--   'completa'   — anche palle perse e recuperate, l'assist di un gol,
--                  il gol in controfuga, chi ha guadagnato l'espulsione
--                  o il rigore.
-- Le partite gia' create restano essenziali.
-- ============================================================

alter table public.partite
  add column if not exists eventi_live text not null default 'essenziale';

alter table public.partite drop constraint if exists partite_eventi_live_check;
alter table public.partite add constraint partite_eventi_live_check
  check (eventi_live in ('essenziale', 'completa'));

-- Palla persa e palla recuperata: di un nostro giocatore, o della squadra
-- senza un giocatore (per esempio i 30 secondi scaduti).
alter table public.eventi_partita drop constraint if exists eventi_partita_tipo_check;
alter table public.eventi_partita add constraint eventi_partita_tipo_check
  check (tipo in ('tiro', 'espulsione', 'superiorita', 'palla_persa', 'palla_recuperata'));

-- Il gol in controfuga e' un contesto del tiro, come superiorita' e rigore.
alter table public.eventi_partita drop constraint if exists eventi_partita_contesto_tiro_check;
alter table public.eventi_partita add constraint eventi_partita_contesto_tiro_check
  check (contesto_tiro in ('azione', 'superiorita', 'rigore', 'controfuga'));

-- assist_di: chi ha passato la palla del gol (un nostro tiro).
-- guadagnata_da: chi dei nostri ha guadagnato l'espulsione o il rigore di
-- un avversario.
alter table public.eventi_partita
  add column if not exists assist_di uuid references public.atleti(id) on delete set null,
  add column if not exists guadagnata_da uuid references public.atleti(id) on delete set null;

alter table public.eventi_partita drop constraint if exists eventi_partita_check;
alter table public.eventi_partita add constraint eventi_partita_check check (
  (tipo = 'tiro' and squadra = 'nostra' and atleta_id is not null and numero_calottina_avversario is null)
  or (tipo = 'tiro' and squadra = 'avversaria' and atleta_id is null and numero_calottina_avversario is null)
  or (tipo = 'espulsione' and (
        (atleta_id is not null and numero_calottina_avversario is null)
        or (atleta_id is null and numero_calottina_avversario is not null)
      ))
  or (tipo = 'superiorita' and atleta_id is null and numero_calottina_avversario is null)
  or (tipo in ('palla_persa', 'palla_recuperata') and squadra = 'nostra' and numero_calottina_avversario is null)
);

alter table public.eventi_partita drop constraint if exists eventi_partita_assist_check;
alter table public.eventi_partita add constraint eventi_partita_assist_check check (
  assist_di is null
  or (tipo = 'tiro' and squadra = 'nostra' and assist_di is distinct from atleta_id)
);

alter table public.eventi_partita drop constraint if exists eventi_partita_guadagnata_check;
alter table public.eventi_partita add constraint eventi_partita_guadagnata_check check (
  guadagnata_da is null or (tipo = 'espulsione' and squadra = 'avversaria')
);

-- Anche chi fa l'assist e chi guadagna l'espulsione devono essere del club
-- della partita.
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

  foreach v_atleta in array array[new.atleta_id, new.assist_di, new.guadagnata_da] loop
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
before insert or update of partita_id, atleta_id, assist_di, guadagnata_da on public.eventi_partita
for each row execute function public.imposta_e_valida_evento_partita();
