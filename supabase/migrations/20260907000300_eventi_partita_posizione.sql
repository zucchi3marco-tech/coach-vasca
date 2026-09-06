-- ============================================================
-- POSIZIONE DEL TIRO ED ESPULSIONI AVVERSARIE (FASE 9): il campo
-- disegnato tipo lavagnetta sostituisce il vecchio dialog "Tiro"; le
-- espulsioni si possono ora registrare anche per un giocatore
-- avversario (identificato solo dal numero di calottina, non abbiamo
-- la sua rubrica) e portano un flag "a fallo da rigore" usato in app
-- per bloccare un giocatore dopo la terza volta nella stessa partita
-- (calcolato al volo dagli eventi gia' caricati, nessun campo dedicato).
-- ============================================================

alter table public.eventi_partita
  add column pos_x numeric(5, 2) check (pos_x is null or (pos_x >= 0 and pos_x <= 100)),
  add column pos_y numeric(5, 2) check (pos_y is null or (pos_y >= 0 and pos_y <= 100)),
  add column numero_calottina_avversario integer,
  add column espulsione_da_rigore boolean not null default false;

-- Il vecchio vincolo imponeva atleta_id obbligatorio per tiro/espulsione:
-- va sostituito per permettere un'espulsione con solo il numero di
-- calottina avversario al posto dell'atleta_id.
alter table public.eventi_partita drop constraint if exists eventi_partita_check;

alter table public.eventi_partita add constraint eventi_partita_check check (
  (tipo = 'tiro' and atleta_id is not null and numero_calottina_avversario is null)
  or (tipo = 'espulsione' and (
        (atleta_id is not null and numero_calottina_avversario is null)
        or (atleta_id is null and numero_calottina_avversario is not null)
      ))
  or (tipo = 'superiorita' and atleta_id is null and numero_calottina_avversario is null)
);
