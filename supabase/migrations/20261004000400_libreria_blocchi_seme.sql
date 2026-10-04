-- ============================================================
-- Libreria blocchi "di fabbrica" (club modello), rigenerata da
-- libreria_blocchi_nuoto_pallanuoto.xlsx con tool/genera_seed_libreria.dart.
-- 350 blocchi, 389 parti.
--
-- Sostituisce la copia precedente: i club già esistenti non sono
-- toccati (si aggiornano con "Importa da Excel" nell'app), solo i
-- club creati DOPO questa migrazione partiranno dal contenuto nuovo.
-- ============================================================

delete from public.training_block_parti where club_id = '00000000-0000-0000-0000-000000000001';
delete from public.training_blocks where club_id = '00000000-0000-0000-0000-000000000001';

with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-001', 'entrambi',
    'Riscaldamento', 'Recupero', 'A1',
    '400 misto sciolto', '200 SL sciolto [A1] + 100 DO sciolto [A1] + 100 RA sciolto [A1]', 'Vari',
    'Ragazzi, Assoluti, Master', null, 400,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'Stile libero', 'sciolto', 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, 100, null, 'Dorso', 'sciolto', 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 1, 100, null, 'Rana', 'sciolto', 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-002', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    '300 SL respirazione 3-5-7', '3x100 SL respirazione ogni 3-5-7 bracciate per 25 [A1] rec 10"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 300,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 100, null, 'Stile libero', 'respirazione ogni 3-5-7 bracciate per 25', 'A1', 'braccia', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-003', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    '8x50 misti ordine inverso', '8x50 MX 25 stile + 25 stile successivo, ordine inverso [A1] rec 15"', 'Misti',
    'Ragazzi, Assoluti', null, 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Misti', '25 stile + 25 stile successivo, ordine inverso', 'A1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-004', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    '3x200 variato', '200 SL [A1] rec 20" + 200 DO [A1] rec 20" + 200 MX sciolto [A1]', 'Vari',
    'Ragazzi, Assoluti', null, 600,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'Stile libero', null, 'A1', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, 200, null, 'Dorso', null, 'A1', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 1, 200, null, 'Misti', 'sciolto', 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-005', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    '400 SL progressivo per 100', '4x100 SL progressivo per 100 (da A1 ad A2) [A1] rec 10"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 400,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 100, null, 'Stile libero', 'progressivo per 100 (da A1 ad A2)', 'A1', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-006', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    '600 variato gambe/braccia', '200 SL [A1] rec 20" + 4x50 scelta gambe [A1] rec 15" (Tavoletta) + 4x50 SL braccia [A1] rec 15" (Pull buoy)', 'Vari',
    'Ragazzi, Assoluti', 'Pull buoy, Tavoletta', 600,
    13, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'Stile libero', null, 'A1', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 4, 50, null, 'A scelta', 'gambe', 'A1', 'gambe', 15, 'Tavoletta', null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 4, 50, null, 'Stile libero', 'braccia', 'A1', 'braccia', 15, 'Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-007', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    'Riscaldamento esordienti 300', '100 SL [A1] rec 20" + 100 DO [A1] rec 20" + 4x25 scelta tecnica a scelta [A1] rec 20"', 'Vari',
    'Esordienti', null, 300,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 100, null, 'Stile libero', null, 'A1', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, 100, null, 'Dorso', null, 'A1', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 4, 25, null, 'A scelta', 'tecnica a scelta', 'A1', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-008', 'nuoto',
    'Riscaldamento', 'Aerobico', 'A1',
    '4x50 dorso/SL esordienti', '4x50 MX 25 dorso + 25 SL [A1] rec 20"', 'Misti',
    'Esordienti', null, 200,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Misti', '25 dorso + 25 SL', 'A1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-009', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    'Riscaldamento master 500', '300 scelta sciolto [A1] rec 30" + 4x50 MX sciolto [A1] rec 20"', 'Vari',
    'Master', null, 500,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 300, null, 'A scelta', 'sciolto', 'A1', 'nuoto', 30, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 4, 50, null, 'Misti', 'sciolto', 'A1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-010', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    '4x100 SL + stile del giorno', '4x100 MX 50 SL + 50 stile del giorno [A1] rec 15"', 'Misti',
    'Ragazzi, Assoluti, Master', null, 400,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 100, null, 'Misti', '50 SL + 50 stile del giorno', 'A1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-011', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    '800 continuo variato', '200 SL [A1] + 200 DO [A1] + 200 scelta gambe [A1] (Pinne) + 200 SL [A1]', 'Vari',
    'Assoluti', 'Pinne', 800,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'Stile libero', null, 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, 200, null, 'Dorso', null, 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 1, 200, null, 'A scelta', 'gambe', 'A1', 'gambe', null, 'Pinne', null from b
union all select id, '00000000-0000-0000-0000-000000000001', 4, 1, 1, 200, null, 'Stile libero', null, 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-012', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    '6x100 SL/DO progressivo', '6x100 MX dispari SL, pari dorso, progressivo per serie [A1] rec 15"', 'Misti',
    'Ragazzi, Assoluti', null, 600,
    13, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 100, null, 'Misti', 'dispari SL, pari dorso, progressivo per serie', 'A1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-013', 'nuoto',
    'Riscaldamento', 'Tecnica', 'A1',
    'Riscaldamento rana', '200 SL [A1] rec 20" + 4x50 RA 2 gambate 1 bracciata [A1] rec 15" + 4x50 RA nuotato [A1] rec 15"', 'Vari',
    'Ragazzi, Assoluti, Master', null, 600,
    13, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'Stile libero', null, 'A1', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 4, 50, null, 'Rana', '2 gambate 1 bracciata', 'A1', 'braccia', 15, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 4, 50, null, 'Rana', 'nuotato', 'A1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-014', 'nuoto',
    'Riscaldamento', 'Tecnica', 'A1',
    'Riscaldamento delfino', '300 SL [A1] rec 20" + 6x25 DF braccio singolo dx/sx [A1] rec 15" (Pinne) + 4x25 DF nuotato [A1] rec 20"', 'Vari',
    'Ragazzi, Assoluti', 'Pinne', 550,
    13, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 300, null, 'Stile libero', null, 'A1', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 6, 25, null, 'Delfino', 'braccio singolo dx/sx', 'A1', 'nuoto', 15, 'Pinne', null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 4, 25, null, 'Delfino', 'nuotato', 'A1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-015', 'nuoto',
    'Riscaldamento', 'Tecnica', 'A1',
    'Riscaldamento dorso', '200 SL [A1] rec 20" + 4x50 DO braccio singolo / doppio braccio [A1] rec 15" + 4x50 DO nuotato [A1] rec 15"', 'Vari',
    'Ragazzi, Assoluti, Master', null, 600,
    13, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'Stile libero', null, 'A1', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 4, 50, null, 'Dorso', 'braccio singolo / doppio braccio', 'A1', 'nuoto', 15, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 4, 50, null, 'Dorso', 'nuotato', 'A1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-016', 'nuoto',
    'Riscaldamento', 'Velocità', 'A1 / A2 / RG / V',
    'Riscaldamento pre-gara', '400 scelta sciolto [A1] rec 30" + 4x50 SL progressivi [A2] rec 20" + 4x25 scelta ritmo gara [RG] rec 40" + 2x15 scelta sprint dal blocco [V] rec 1''', 'Vari',
    'Ragazzi, Assoluti', null, 730,
    20, 'Da usare il giorno della gara o nella seduta di rifinitura.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 400, null, 'A scelta', 'sciolto', 'A1', 'nuoto', 30, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 4, 50, null, 'Stile libero', 'progressivi', 'A2', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 4, 25, null, 'A scelta', 'ritmo gara', 'RG', 'nuoto', 40, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 4, 1, 2, 15, null, 'A scelta', 'sprint dal blocco', 'V', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-017', 'entrambi',
    'Riscaldamento', 'Aerobico', 'A1',
    '400 con pinne', '400 MX 100 SL + 100 dorso + 100 delfino-ondulazioni + 100 SL [A1] (Pinne)', 'Misti',
    'Ragazzi, Assoluti, Master', 'Pinne', 400,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 400, null, 'Misti', '100 SL + 100 dorso + 100 delfino-ondulazioni + 100 SL', 'A1', 'nuoto', null, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-018', 'entrambi',
    'Attivazione', 'Velocità', 'B1',
    '6x25 SL progressivi', '6x25 SL progressivi nella serie [B1] rec 20"', 'Stile libero',
    'Esordienti, Ragazzi, Assoluti, Master', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', 'progressivi nella serie', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-019', 'nuoto',
    'Attivazione', 'Velocità', 'B1',
    '6x25 DO progressivi', '6x25 DO progressivi nella serie [B1] rec 20"', 'Dorso',
    'Esordienti, Ragazzi, Assoluti, Master', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Dorso', 'progressivi nella serie', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-020', 'nuoto',
    'Attivazione', 'Velocità', 'B1',
    '6x25 RA progressivi', '6x25 RA progressivi nella serie [B1] rec 20"', 'Rana',
    'Esordienti, Ragazzi, Assoluti, Master', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Rana', 'progressivi nella serie', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-021', 'nuoto',
    'Attivazione', 'Velocità', 'B1',
    '6x25 DF progressivi', '6x25 DF progressivi nella serie [B1] rec 20"', 'Delfino',
    'Esordienti, Ragazzi, Assoluti, Master', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Delfino', 'progressivi nella serie', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-022', 'entrambi',
    'Attivazione', 'Velocità', 'B1',
    '6x25 MX progressivi', '6x25 MX progressivi nella serie [B1] rec 20"', 'Misti',
    'Esordienti, Ragazzi, Assoluti, Master', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Misti', 'progressivi nella serie', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-023', 'entrambi',
    'Attivazione', 'Velocità', 'B1',
    '4x50 SL build-up', '4x50 SL crescente nella vasca [B1] rec 20"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 200,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Stile libero', 'crescente nella vasca', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-024', 'nuoto',
    'Attivazione', 'Velocità', 'B1',
    '4x50 stile principale build-up', '4x50 scelta stile principale, crescente nella vasca [B1] rec 20"', 'A scelta',
    'Ragazzi, Assoluti', null, 200,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'A scelta', 'stile principale, crescente nella vasca', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-025', 'entrambi',
    'Attivazione', 'Velocità', 'V',
    '8x25 12,5 veloce + 12,5 facile', '8x25 scelta 12,5 m veloce + 12,5 m facile [V] rec 20"', 'A scelta',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'A scelta', '12,5 m veloce + 12,5 m facile', 'V', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-026', 'entrambi',
    'Attivazione', 'Velocità', 'B2',
    '4x(25 veloce + 25 facile)', '4x50 scelta 25 veloce + 25 facile [B2] rec 15"', 'A scelta',
    'Ragazzi, Assoluti, Master', null, 200,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'A scelta', '25 veloce + 25 facile', 'B2', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-027', 'nuoto',
    'Attivazione', 'Velocità', 'V',
    '6x15 partenza dal blocco', '6x15 scelta partenza dal blocco, uscita e prime bracciate [V] rec 45"', 'A scelta',
    'Ragazzi, Assoluti', null, 90,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 15, null, 'A scelta', 'partenza dal blocco, uscita e prime bracciate', 'V', 'braccia', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-028', 'nuoto',
    'Attivazione', 'Velocità', 'V',
    '6x15 uscite subacquee', '6x15 DF ondulazioni subacquee fino a 10-15 m [V] rec 40"', 'Delfino',
    'Ragazzi, Assoluti', null, 90,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 15, null, 'Delfino', 'ondulazioni subacquee fino a 10-15 m', 'V', 'nuoto', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-029', 'nuoto',
    'Attivazione', 'Velocità', 'RG',
    '4x25 ritmo gara', '4x25 scelta ritmo gara della distanza obiettivo [RG] rec 40"', 'A scelta',
    'Ragazzi, Assoluti', null, 100,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 25, null, 'A scelta', 'ritmo gara della distanza obiettivo', 'RG', 'nuoto', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-030', 'entrambi',
    'Tecnica', 'Tecnica', 'T',
    'SL: catch-up (presa davanti)', '6x50 SL 25 catch-up (presa davanti) + 25 nuotato [T] rec 15"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', '25 catch-up (presa davanti) + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-031', 'entrambi',
    'Tecnica', 'Tecnica', 'T',
    'SL esordienti: catch-up (presa davanti)', '6x25 SL catch-up (presa davanti) [T] rec 20"', 'Stile libero',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', 'catch-up (presa davanti)', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-032', 'entrambi',
    'Tecnica', 'Tecnica', 'T',
    'SL: braccio singolo, l''altro avanti', '6x50 SL 25 braccio singolo, l''altro avanti + 25 nuotato [T] rec 15"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', '25 braccio singolo, l''altro avanti + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-033', 'entrambi',
    'Tecnica', 'Tecnica', 'T',
    'SL esordienti: braccio singolo, l''altro avanti', '6x25 SL braccio singolo, l''altro avanti [T] rec 20"', 'Stile libero',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', 'braccio singolo, l''altro avanti', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-034', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL: 6 battute di lato + bracciata (rotazione)', '6x50 SL 25 6 battute di lato + bracciata (rotazione) + 25 nuotato [T] rec 15" (Pinne)', 'Stile libero',
    'Ragazzi, Assoluti, Master', 'Pinne', 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', '25 6 battute di lato + bracciata (rotazione) + 25 nuotato', 'T', 'tecnica', 15, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-035', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL esordienti: 6 battute di lato + bracciata (rotazione)', '6x25 SL 6 battute di lato + bracciata (rotazione) [T] rec 20" (Pinne)', 'Stile libero',
    'Esordienti', 'Pinne', 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', '6 battute di lato + bracciata (rotazione)', 'T', 'tecnica', 20, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-036', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL: zip: dita che sfiorano il fianco', '6x50 SL 25 zip: dita che sfiorano il fianco + 25 nuotato [T] rec 15"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', '25 zip: dita che sfiorano il fianco + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-037', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL esordienti: zip: dita che sfiorano il fianco', '6x25 SL zip: dita che sfiorano il fianco [T] rec 20"', 'Stile libero',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', 'zip: dita che sfiorano il fianco', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-038', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL: pugni chiusi', '6x50 SL 25 pugni chiusi + 25 nuotato [T] rec 15"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', '25 pugni chiusi + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-039', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL esordienti: pugni chiusi', '6x25 SL pugni chiusi [T] rec 20"', 'Stile libero',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', 'pugni chiusi', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-040', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL: respirazione bilaterale ogni 3', '6x50 SL 25 respirazione bilaterale ogni 3 + 25 nuotato [T] rec 15"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', '25 respirazione bilaterale ogni 3 + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-041', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL esordienti: respirazione bilaterale ogni 3', '6x25 SL respirazione bilaterale ogni 3 [T] rec 20"', 'Stile libero',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', 'respirazione bilaterale ogni 3', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-042', 'entrambi',
    'Tecnica', 'Tecnica', 'T',
    'SL: testa alta (stile pallanuoto)', '6x50 SL 25 testa alta (stile pallanuoto) + 25 nuotato [T] rec 15"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', '25 testa alta (stile pallanuoto) + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-043', 'entrambi',
    'Tecnica', 'Tecnica', 'T',
    'SL esordienti: testa alta (stile pallanuoto)', '6x25 SL testa alta (stile pallanuoto) [T] rec 20"', 'Stile libero',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', 'testa alta (stile pallanuoto)', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-044', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL: conta bracciate e riducile', '6x50 SL 25 conta bracciate e riducile + 25 nuotato [T] rec 15"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', '25 conta bracciate e riducile + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-045', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'SL esordienti: conta bracciate e riducile', '6x25 SL conta bracciate e riducile [T] rec 20"', 'Stile libero',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', 'conta bracciate e riducile', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-046', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO: braccio singolo', '6x50 DO 25 braccio singolo + 25 nuotato [T] rec 15"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Dorso', '25 braccio singolo + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-047', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO esordienti: braccio singolo', '6x25 DO braccio singolo [T] rec 20"', 'Dorso',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Dorso', 'braccio singolo', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-048', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO: doppio braccio', '6x50 DO 25 doppio braccio + 25 nuotato [T] rec 15"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Dorso', '25 doppio braccio + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-049', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO esordienti: doppio braccio', '6x25 DO doppio braccio [T] rec 20"', 'Dorso',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Dorso', 'doppio braccio', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-050', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO: 6 battute con spalla fuori', '6x50 DO 25 6 battute con spalla fuori + 25 nuotato [T] rec 15"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Dorso', '25 6 battute con spalla fuori + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-051', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO esordienti: 6 battute con spalla fuori', '6x25 DO 6 battute con spalla fuori [T] rec 20"', 'Dorso',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Dorso', '6 battute con spalla fuori', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-052', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO: bottiglia/bicchiere sulla fronte', '6x50 DO 25 bottiglia/bicchiere sulla fronte + 25 nuotato [T] rec 15"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Dorso', '25 bottiglia/bicchiere sulla fronte + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-053', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO esordienti: bottiglia/bicchiere sulla fronte', '6x25 DO bottiglia/bicchiere sulla fronte [T] rec 20"', 'Dorso',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Dorso', 'bottiglia/bicchiere sulla fronte', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-054', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO: 3 bracciate dx, 3 sx, 3 complete', '6x50 DO 25 3 bracciate dx, 3 sx, 3 complete + 25 nuotato [T] rec 15"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Dorso', '25 3 bracciate dx, 3 sx, 3 complete + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-055', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO esordienti: 3 bracciate dx, 3 sx, 3 complete', '6x25 DO 3 bracciate dx, 3 sx, 3 complete [T] rec 20"', 'Dorso',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Dorso', '3 bracciate dx, 3 sx, 3 complete', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-056', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO: rotazione con pausa a braccio alto', '6x50 DO 25 rotazione con pausa a braccio alto + 25 nuotato [T] rec 15"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Dorso', '25 rotazione con pausa a braccio alto + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-057', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DO esordienti: rotazione con pausa a braccio alto', '6x25 DO rotazione con pausa a braccio alto [T] rec 20"', 'Dorso',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Dorso', 'rotazione con pausa a braccio alto', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-058', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA: 2 gambate e 1 bracciata', '6x50 RA 25 2 gambate e 1 bracciata + 25 nuotato [T] rec 15"', 'Rana',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Rana', '25 2 gambate e 1 bracciata + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-059', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA esordienti: 2 gambate e 1 bracciata', '6x25 RA 2 gambate e 1 bracciata [T] rec 20"', 'Rana',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Rana', '2 gambate e 1 bracciata', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-060', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA: braccia rana + gambe delfino', '6x50 RA 25 braccia rana + gambe delfino + 25 nuotato [T] rec 15"', 'Rana',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Rana', '25 braccia rana + gambe delfino + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-061', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA esordienti: braccia rana + gambe delfino', '6x25 RA braccia rana + gambe delfino [T] rec 20"', 'Rana',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Rana', 'braccia rana + gambe delfino', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-062', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA: gambe rana sul dorso', '6x50 RA 25 gambe rana sul dorso + 25 nuotato [T] rec 15"', 'Rana',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Rana', '25 gambe rana sul dorso + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-063', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA esordienti: gambe rana sul dorso', '6x25 RA gambe rana sul dorso [T] rec 20"', 'Rana',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Rana', 'gambe rana sul dorso', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-064', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA: scivolata lunga (conta 2)', '6x50 RA 25 scivolata lunga (conta 2) + 25 nuotato [T] rec 15"', 'Rana',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Rana', '25 scivolata lunga (conta 2) + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-065', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA esordienti: scivolata lunga (conta 2)', '6x25 RA scivolata lunga (conta 2) [T] rec 20"', 'Rana',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Rana', 'scivolata lunga (conta 2)', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-066', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA: braccia rana con pull buoy', '6x50 RA 25 braccia rana con pull buoy + 25 nuotato [T] rec 15" (Pull buoy)', 'Rana',
    'Ragazzi, Assoluti, Master', 'Pull buoy', 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Rana', '25 braccia rana con pull buoy + 25 nuotato', 'T', 'tecnica', 15, 'Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-067', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA esordienti: braccia rana con pull buoy', '6x25 RA braccia rana con pull buoy [T] rec 20" (Pull buoy)', 'Rana',
    'Esordienti', 'Pull buoy', 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Rana', 'braccia rana con pull buoy', 'T', 'tecnica', 20, 'Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-068', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA: bracciata stretta e veloce, ritorno rapido', '6x50 RA 25 bracciata stretta e veloce, ritorno rapido + 25 nuotato [T] rec 15"', 'Rana',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Rana', '25 bracciata stretta e veloce, ritorno rapido + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-069', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'RA esordienti: bracciata stretta e veloce, ritorno rapido', '6x25 RA bracciata stretta e veloce, ritorno rapido [T] rec 20"', 'Rana',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Rana', 'bracciata stretta e veloce, ritorno rapido', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-070', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF: braccio singolo dx/sx', '6x50 DF 25 braccio singolo dx/sx + 25 nuotato [T] rec 15" (Pinne)', 'Delfino',
    'Ragazzi, Assoluti, Master', 'Pinne', 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', '25 braccio singolo dx/sx + 25 nuotato', 'T', 'tecnica', 15, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-071', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF esordienti: braccio singolo dx/sx', '6x25 DF braccio singolo dx/sx [T] rec 20" (Pinne)', 'Delfino',
    'Esordienti', 'Pinne', 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Delfino', 'braccio singolo dx/sx', 'T', 'tecnica', 20, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-072', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF: 3-3-3 (dx, sx, completo)', '6x50 DF 25 3-3-3 (dx, sx, completo) + 25 nuotato [T] rec 15" (Pinne)', 'Delfino',
    'Ragazzi, Assoluti, Master', 'Pinne', 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', '25 3-3-3 (dx, sx, completo) + 25 nuotato', 'T', 'tecnica', 15, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-073', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF esordienti: 3-3-3 (dx, sx, completo)', '6x25 DF 3-3-3 (dx, sx, completo) [T] rec 20" (Pinne)', 'Delfino',
    'Esordienti', 'Pinne', 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Delfino', '3-3-3 (dx, sx, completo)', 'T', 'tecnica', 20, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-074', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF: ondulazioni con braccia avanti', '6x50 DF 25 ondulazioni con braccia avanti + 25 nuotato [T] rec 15"', 'Delfino',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', '25 ondulazioni con braccia avanti + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-075', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF esordienti: ondulazioni con braccia avanti', '6x25 DF ondulazioni con braccia avanti [T] rec 20"', 'Delfino',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Delfino', 'ondulazioni con braccia avanti', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-076', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF: braccia delfino + gambe stile', '6x50 DF 25 braccia delfino + gambe stile + 25 nuotato [T] rec 15"', 'Delfino',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', '25 braccia delfino + gambe stile + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-077', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF esordienti: braccia delfino + gambe stile', '6x25 DF braccia delfino + gambe stile [T] rec 20"', 'Delfino',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Delfino', 'braccia delfino + gambe stile', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-078', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF: 2 gambate per bracciata accentuate', '6x50 DF 25 2 gambate per bracciata accentuate + 25 nuotato [T] rec 15"', 'Delfino',
    'Ragazzi, Assoluti, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', '25 2 gambate per bracciata accentuate + 25 nuotato', 'T', 'tecnica', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-079', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF esordienti: 2 gambate per bracciata accentuate', '6x25 DF 2 gambate per bracciata accentuate [T] rec 20"', 'Delfino',
    'Esordienti', null, 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Delfino', '2 gambate per bracciata accentuate', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-080', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF: ondulazioni sul fianco', '6x50 DF 25 ondulazioni sul fianco + 25 nuotato [T] rec 15" (Pinne)', 'Delfino',
    'Ragazzi, Assoluti, Master', 'Pinne', 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', '25 ondulazioni sul fianco + 25 nuotato', 'T', 'tecnica', 15, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-081', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'DF esordienti: ondulazioni sul fianco', '6x25 DF ondulazioni sul fianco [T] rec 20" (Pinne)', 'Delfino',
    'Esordienti', 'Pinne', 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Delfino', 'ondulazioni sul fianco', 'T', 'tecnica', 20, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-082', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'Virate SL da metà vasca', '8x25 SL partenza a 7 m dal muro, virata e uscita fino a 10 m [T] rec 20"', 'Stile libero',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Stile libero', 'partenza a 7 m dal muro, virata e uscita fino a 10 m', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-083', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'Virate dorso', '8x25 DO conta bracciate dalle bandierine, virata e subacquea [T] rec 20"', 'Dorso',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Dorso', 'conta bracciate dalle bandierine, virata e subacquea', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-084', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'Virate rana/delfino (tocco a 2 mani)', '8x25 MX alterna rana e delfino, tocco a due mani e uscita [T] rec 20"', 'Misti',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Misti', 'alterna rana e delfino, tocco a due mani e uscita', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-085', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'Cambi dei misti', '8x50 MX cambi DF-DO, DO-RA, RA-SL (2 per tipo) [T] rec 20"', 'Misti',
    'Ragazzi, Assoluti', null, 400,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Misti', 'cambi DF-DO, DO-RA, RA-SL (2 per tipo)', 'T', 'tecnica', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-086', 'nuoto',
    'Tecnica', 'Tecnica', 'V',
    'Partenze dal blocco', '6x15 scelta partenza dal blocco, tempo ai 15 m [V] rec 1''', 'A scelta',
    'Ragazzi, Assoluti', null, 90,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 15, null, 'A scelta', 'partenza dal blocco, tempo ai 15 m', 'V', 'tecnica', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-087', 'nuoto',
    'Tecnica', 'Tecnica', 'V',
    'Partenze dorso', '6x15 DO partenza dorso dal muro, subacquea [V] rec 1''', 'Dorso',
    'Ragazzi, Assoluti', null, 90,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 15, null, 'Dorso', 'partenza dorso dal muro, subacquea', 'V', 'tecnica', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-088', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'Subacquee a delfino', '8x15 DF ondulazioni subacquee dal muro [T] rec 30" (Pinne)', 'Delfino',
    'Ragazzi, Assoluti', 'Pinne', 120,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 15, null, 'Delfino', 'ondulazioni subacquee dal muro', 'T', 'tecnica', 30, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-089', 'nuoto',
    'Tecnica', 'Tecnica', 'V',
    'Arrivi al tocco', '6x10 scelta arrivo senza respirare, tocco in allungo [V] rec 30"', 'A scelta',
    'Esordienti, Ragazzi, Assoluti, Master', null, 60,
    4, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 10, null, 'A scelta', 'arrivo senza respirare, tocco in allungo', 'V', 'tecnica', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-090', 'nuoto',
    'Tecnica', 'Tecnica', 'T',
    'Cambi staffetta', '8x25 scelta cambio staffetta a coppie dal blocco [T] rec 40"', 'A scelta',
    'Ragazzi, Assoluti', null, 200,
    9, 'Serve il blocco di partenza.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'A scelta', 'cambio staffetta a coppie dal blocco', 'T', 'tecnica', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-091', 'entrambi',
    'Tecnica', 'Tecnica', 'A1',
    'Conta bracciate (efficienza)', '8x50 SL conta le bracciate, riduci di 1 ogni 2 ripetizioni [A1] rec 20"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 400,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Stile libero', 'conta le bracciate, riduci di 1 ogni 2 ripetizioni', 'A1', 'braccia', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-092', 'entrambi',
    'Gambe', 'Aerobico', 'A2',
    '8x50 gambe SL', '8x50 SL gambe [A2] rec 15" (Tavoletta)', 'Stile libero',
    'Ragazzi, Assoluti, Master', 'Tavoletta', 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Stile libero', 'gambe', 'A2', 'gambe', 15, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-093', 'entrambi',
    'Gambe', 'Soglia', 'B2',
    '6x50 gambe SL veloci', '6x50 SL gambe veloci [B2] rec 30" (Tavoletta)', 'Stile libero',
    'Ragazzi, Assoluti', 'Tavoletta', 300,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', 'gambe veloci', 'B2', 'gambe', 30, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-094', 'entrambi',
    'Gambe', 'Velocità', 'V',
    '10x25 gambe SL max', '10x25 SL gambe massimali [V] rec 40"', 'Stile libero',
    'Ragazzi, Assoluti', null, 250,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 25, null, 'Stile libero', 'gambe massimali', 'V', 'gambe', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-095', 'nuoto',
    'Gambe', 'Aerobico', 'A2',
    '8x50 gambe DO', '8x50 DO gambe [A2] rec 15" (Tavoletta)', 'Dorso',
    'Ragazzi, Assoluti, Master', 'Tavoletta', 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Dorso', 'gambe', 'A2', 'gambe', 15, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-096', 'nuoto',
    'Gambe', 'Soglia', 'B2',
    '6x50 gambe DO veloci', '6x50 DO gambe veloci [B2] rec 30" (Tavoletta)', 'Dorso',
    'Ragazzi, Assoluti', 'Tavoletta', 300,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Dorso', 'gambe veloci', 'B2', 'gambe', 30, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-097', 'nuoto',
    'Gambe', 'Velocità', 'V',
    '10x25 gambe DO max', '10x25 DO gambe massimali [V] rec 40"', 'Dorso',
    'Ragazzi, Assoluti', null, 250,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 25, null, 'Dorso', 'gambe massimali', 'V', 'gambe', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-098', 'nuoto',
    'Gambe', 'Aerobico', 'A2',
    '8x50 gambe RA', '8x50 RA gambe [A2] rec 15" (Tavoletta)', 'Rana',
    'Ragazzi, Assoluti, Master', 'Tavoletta', 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Rana', 'gambe', 'A2', 'gambe', 15, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-099', 'nuoto',
    'Gambe', 'Soglia', 'B2',
    '6x50 gambe RA veloci', '6x50 RA gambe veloci [B2] rec 30" (Tavoletta)', 'Rana',
    'Ragazzi, Assoluti', 'Tavoletta', 300,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Rana', 'gambe veloci', 'B2', 'gambe', 30, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-100', 'nuoto',
    'Gambe', 'Velocità', 'V',
    '10x25 gambe RA max', '10x25 RA gambe massimali [V] rec 40"', 'Rana',
    'Ragazzi, Assoluti', null, 250,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 25, null, 'Rana', 'gambe massimali', 'V', 'gambe', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-101', 'nuoto',
    'Gambe', 'Aerobico', 'A2',
    '8x50 gambe DF', '8x50 DF gambe [A2] rec 15" (Tavoletta)', 'Delfino',
    'Ragazzi, Assoluti, Master', 'Tavoletta', 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Delfino', 'gambe', 'A2', 'gambe', 15, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-102', 'nuoto',
    'Gambe', 'Soglia', 'B2',
    '6x50 gambe DF veloci', '6x50 DF gambe veloci [B2] rec 30" (Tavoletta)', 'Delfino',
    'Ragazzi, Assoluti', 'Tavoletta', 300,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', 'gambe veloci', 'B2', 'gambe', 30, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-103', 'nuoto',
    'Gambe', 'Velocità', 'V',
    '10x25 gambe DF max', '10x25 DF gambe massimali [V] rec 40"', 'Delfino',
    'Ragazzi, Assoluti', null, 250,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 25, null, 'Delfino', 'gambe massimali', 'V', 'gambe', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-104', 'nuoto',
    'Gambe', 'Aerobico', 'A1',
    '300 gambe misti con pinne', '300 MX gambe a stili ogni 25 [A1] (Pinne)', 'Misti',
    'Ragazzi, Assoluti, Master', 'Pinne', 300,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 300, null, 'Misti', 'gambe a stili ogni 25', 'A1', 'gambe', null, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-105', 'nuoto',
    'Gambe', 'Velocità', 'B2',
    '6x50 gambe subacquee', '6x50 DF 25 ondulazioni subacquee + 25 facile [B2] rec 30" (Pinne)', 'Delfino',
    'Ragazzi, Assoluti', 'Pinne', 300,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', '25 ondulazioni subacquee + 25 facile', 'B2', 'gambe', 30, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-106', 'nuoto',
    'Gambe', 'Aerobico', 'A2',
    '4x100 gambe progressive', '4x100 scelta gambe progressive per 25 [A2] rec 20" (Tavoletta)', 'A scelta',
    'Ragazzi, Assoluti, Master', 'Tavoletta', 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 100, null, 'A scelta', 'gambe progressive per 25', 'A2', 'gambe', 20, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-107', 'nuoto',
    'Gambe', 'Tecnica', 'A1',
    'Gambe esordienti 6x25', '6x25 scelta gambe (alterna stile e dorso) [A1] rec 20" (Tavoletta)', 'A scelta',
    'Esordienti', 'Tavoletta', 150,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'A scelta', 'gambe (alterna stile e dorso)', 'A1', 'gambe', 20, 'Tavoletta', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-108', 'entrambi',
    'Gambe', 'Forza', 'B2',
    'Gambe verticali', '6x30" gambe in verticale braccia incrociate al petto [B2] rec 30"', null,
    'Ragazzi, Assoluti', null, 0,
    6, 'Lavoro a tempo, senza spostamento.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, null, 30, null, 'gambe in verticale braccia incrociate al petto', 'B2', 'gambe', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-109', 'entrambi',
    'Braccia', 'Aerobico', 'A2',
    '4x200 pull buoy', '4x200 SL braccia [A2] rec 20" (Pull buoy)', 'Stile libero',
    'Ragazzi, Assoluti', 'Pull buoy', 800,
    16, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 200, null, 'Stile libero', 'braccia', 'A2', 'braccia', 20, 'Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-110', 'entrambi',
    'Braccia', 'Soglia', 'B1',
    '6x100 palette + pull', '6x100 SL braccia [B1] rec 15" (Palette, Pull buoy)', 'Stile libero',
    'Ragazzi, Assoluti', 'Palette, Pull buoy', 600,
    13, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 100, null, 'Stile libero', 'braccia', 'B1', 'braccia', 15, 'Palette, Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-111', 'nuoto',
    'Braccia', 'Tecnica', 'A2',
    '8x50 braccia rana', '8x50 RA braccia con pull buoy [A2] rec 15" (Pull buoy)', 'Rana',
    'Ragazzi, Assoluti, Master', 'Pull buoy', 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Rana', 'braccia con pull buoy', 'A2', 'pull', 15, 'Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-112', 'entrambi',
    'Braccia', 'Aerobico', 'A2',
    '400 pull respirazione 5', '400 SL braccia, respirazione ogni 5 [A2] (Pull buoy)', 'Stile libero',
    'Ragazzi, Assoluti, Master', 'Pull buoy', 400,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 400, null, 'Stile libero', 'braccia, respirazione ogni 5', 'A2', 'braccia', null, 'Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-113', 'entrambi',
    'Braccia', 'Forza', 'A2',
    '3x300 palette', '3x300 SL braccia, presa lunga [A2] rec 30" (Palette, Pull buoy)', 'Stile libero',
    'Assoluti', 'Palette, Pull buoy', 900,
    18, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 300, null, 'Stile libero', 'braccia, presa lunga', 'A2', 'braccia', 30, 'Palette, Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-114', 'nuoto',
    'Braccia', 'Aerobico', 'A2',
    '10x50 braccia dorso', '10x50 DO braccia [A2] rec 15" (Pull buoy)', 'Dorso',
    'Ragazzi, Assoluti, Master', 'Pull buoy', 500,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 50, null, 'Dorso', 'braccia', 'A2', 'braccia', 15, 'Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-115', 'entrambi',
    'Braccia', 'Forza', 'B1',
    '8x50 trascinamento', '8x50 SL braccia con elastico alle caviglie [B1] rec 30" (Pull buoy, Elastico)', 'Stile libero',
    'Ragazzi, Assoluti', 'Elastico, Pull buoy', 400,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Stile libero', 'braccia con elastico alle caviglie', 'B1', 'braccia', 30, 'Pull buoy, Elastico', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-116', 'entrambi',
    'Braccia', 'Forza', 'C2',
    '6x25 paracadute', '6x25 scelta con paracadute/freno [C2] rec 1'' (Paracadute)', 'A scelta',
    'Ragazzi, Assoluti', 'Paracadute', 150,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'A scelta', 'con paracadute/freno', 'C2', 'pull', 60, 'Paracadute', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-117', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '3x400 SL A2', '3x400 SL ritmo costante [A2] rec 30"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 1200,
    24, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 400, null, 'Stile libero', 'ritmo costante', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-118', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '3x400 DO A2', '3x400 DO ritmo costante [A2] rec 30"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 1200,
    24, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 400, null, 'Dorso', 'ritmo costante', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-119', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '3x400 RA A2', '3x400 RA ritmo costante [A2] rec 30"', 'Rana',
    'Ragazzi, Assoluti, Master', null, 1200,
    24, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 400, null, 'Rana', 'ritmo costante', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-120', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '3x200 DF A2', '3x200 DF ritmo costante [A2] rec 30"', 'Delfino',
    'Ragazzi, Assoluti, Master', null, 600,
    13, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 200, null, 'Delfino', 'ritmo costante', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-121', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '3x400 MX A2', '3x400 MX ritmo costante [A2] rec 30"', 'Misti',
    'Ragazzi, Assoluti, Master', null, 1200,
    24, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 400, null, 'Misti', 'ritmo costante', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-122', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '8x200 SL A2', '8x200 SL ritmo costante [A2] rec 20"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 1600,
    32, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 200, null, 'Stile libero', 'ritmo costante', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-123', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '8x200 DO A2', '8x200 DO ritmo costante [A2] rec 20"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 1600,
    32, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 200, null, 'Dorso', 'ritmo costante', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-124', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '8x200 RA A2', '8x200 RA ritmo costante [A2] rec 20"', 'Rana',
    'Ragazzi, Assoluti, Master', null, 1600,
    32, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 200, null, 'Rana', 'ritmo costante', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-125', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '8x100 DF A2', '8x100 DF ritmo costante [A2] rec 20"', 'Delfino',
    'Ragazzi, Assoluti, Master', null, 800,
    17, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 100, null, 'Delfino', 'ritmo costante', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-126', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '8x200 MX A2', '8x200 MX ritmo costante [A2] rec 20"', 'Misti',
    'Ragazzi, Assoluti, Master', null, 1600,
    32, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 200, null, 'Misti', 'ritmo costante', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-127', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '10x100 SL A2', '10x100 SL negative split [A2] rec 15"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 1000,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 100, null, 'Stile libero', 'negative split', 'A2', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-128', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '10x100 DO A2', '10x100 DO negative split [A2] rec 15"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 1000,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 100, null, 'Dorso', 'negative split', 'A2', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-129', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '10x100 RA A2', '10x100 RA negative split [A2] rec 15"', 'Rana',
    'Ragazzi, Assoluti, Master', null, 1000,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 100, null, 'Rana', 'negative split', 'A2', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-130', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '10x50 DF A2', '10x50 DF negative split [A2] rec 15"', 'Delfino',
    'Ragazzi, Assoluti, Master', null, 500,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 50, null, 'Delfino', 'negative split', 'A2', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-131', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '10x100 MX A2', '10x100 MX negative split [A2] rec 15"', 'Misti',
    'Ragazzi, Assoluti, Master', null, 1000,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 100, null, 'Misti', 'negative split', 'A2', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-132', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '16x50 SL A2', '16x50 SL ritmo costante [A2] rec 10"', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 800,
    17, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 16, 50, null, 'Stile libero', 'ritmo costante', 'A2', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-133', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '16x50 DO A2', '16x50 DO ritmo costante [A2] rec 10"', 'Dorso',
    'Ragazzi, Assoluti, Master', null, 800,
    17, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 16, 50, null, 'Dorso', 'ritmo costante', 'A2', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-134', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '16x50 RA A2', '16x50 RA ritmo costante [A2] rec 10"', 'Rana',
    'Ragazzi, Assoluti, Master', null, 800,
    17, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 16, 50, null, 'Rana', 'ritmo costante', 'A2', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-135', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '8x50 DF A2', '8x50 DF ritmo costante [A2] rec 10"', 'Delfino',
    'Ragazzi, Assoluti, Master', null, 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Delfino', 'ritmo costante', 'A2', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-136', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '10x100 SL B1', '10x100 SL ritmo soglia costante [B1] rec 15"', 'Stile libero',
    'Ragazzi, Assoluti', null, 1000,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 100, null, 'Stile libero', 'ritmo soglia costante', 'B1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-137', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '10x100 DO B1', '10x100 DO ritmo soglia costante [B1] rec 15"', 'Dorso',
    'Ragazzi, Assoluti', null, 1000,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 100, null, 'Dorso', 'ritmo soglia costante', 'B1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-138', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '10x100 RA B1', '10x100 RA ritmo soglia costante [B1] rec 15"', 'Rana',
    'Ragazzi, Assoluti', null, 1000,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 100, null, 'Rana', 'ritmo soglia costante', 'B1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-139', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '10x50 DF B1', '10x50 DF ritmo soglia costante [B1] rec 15"', 'Delfino',
    'Ragazzi, Assoluti', null, 500,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 50, null, 'Delfino', 'ritmo soglia costante', 'B1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-140', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '10x100 MX B1', '10x100 MX ritmo soglia costante [B1] rec 15"', 'Misti',
    'Ragazzi, Assoluti', null, 1000,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 100, null, 'Misti', 'ritmo soglia costante', 'B1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-141', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '5x200 SL B1', '5x200 SL ritmo soglia [B1] rec 20"', 'Stile libero',
    'Ragazzi, Assoluti', null, 1000,
    20, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 5, 200, null, 'Stile libero', 'ritmo soglia', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-142', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '5x200 DO B1', '5x200 DO ritmo soglia [B1] rec 20"', 'Dorso',
    'Ragazzi, Assoluti', null, 1000,
    20, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 5, 200, null, 'Dorso', 'ritmo soglia', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-143', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '5x200 RA B1', '5x200 RA ritmo soglia [B1] rec 20"', 'Rana',
    'Ragazzi, Assoluti', null, 1000,
    20, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 5, 200, null, 'Rana', 'ritmo soglia', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-144', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '5x100 DF B1', '5x100 DF ritmo soglia [B1] rec 20"', 'Delfino',
    'Ragazzi, Assoluti', null, 500,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 5, 100, null, 'Delfino', 'ritmo soglia', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-145', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '5x200 MX B1', '5x200 MX ritmo soglia [B1] rec 20"', 'Misti',
    'Ragazzi, Assoluti', null, 1000,
    20, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 5, 200, null, 'Misti', 'ritmo soglia', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-146', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '3x400 SL B1', '3x400 SL ritmo soglia [B1] rec 30"', 'Stile libero',
    'Assoluti', null, 1200,
    24, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 400, null, 'Stile libero', 'ritmo soglia', 'B1', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-147', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '3x400 DO B1', '3x400 DO ritmo soglia [B1] rec 30"', 'Dorso',
    'Assoluti', null, 1200,
    24, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 400, null, 'Dorso', 'ritmo soglia', 'B1', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-148', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '3x400 RA B1', '3x400 RA ritmo soglia [B1] rec 30"', 'Rana',
    'Assoluti', null, 1200,
    24, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 400, null, 'Rana', 'ritmo soglia', 'B1', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-149', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '3x200 DF B1', '3x200 DF ritmo soglia [B1] rec 30"', 'Delfino',
    'Assoluti', null, 600,
    13, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 200, null, 'Delfino', 'ritmo soglia', 'B1', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-150', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '3x400 MX B1', '3x400 MX ritmo soglia [B1] rec 30"', 'Misti',
    'Assoluti', null, 1200,
    24, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 400, null, 'Misti', 'ritmo soglia', 'B1', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-151', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '20x50 SL B1', '20x50 SL ritmo soglia [B1] rec 10"', 'Stile libero',
    'Ragazzi, Assoluti', null, 1000,
    22, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 20, 50, null, 'Stile libero', 'ritmo soglia', 'B1', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-152', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '20x50 DO B1', '20x50 DO ritmo soglia [B1] rec 10"', 'Dorso',
    'Ragazzi, Assoluti', null, 1000,
    22, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 20, 50, null, 'Dorso', 'ritmo soglia', 'B1', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-153', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '20x50 RA B1', '20x50 RA ritmo soglia [B1] rec 10"', 'Rana',
    'Ragazzi, Assoluti', null, 1000,
    22, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 20, 50, null, 'Rana', 'ritmo soglia', 'B1', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-154', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '10x50 DF B1', '10x50 DF ritmo soglia [B1] rec 10"', 'Delfino',
    'Ragazzi, Assoluti', null, 500,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 50, null, 'Delfino', 'ritmo soglia', 'B1', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-155', 'entrambi',
    'Serie principale', 'VO2max', 'B2',
    '8x100 SL B2', '8x100 SL forte, tempi costanti [B2] rec 30"', 'Stile libero',
    'Ragazzi, Assoluti', null, 800,
    19, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 100, null, 'Stile libero', 'forte, tempi costanti', 'B2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-156', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '8x100 DO B2', '8x100 DO forte, tempi costanti [B2] rec 30"', 'Dorso',
    'Ragazzi, Assoluti', null, 800,
    19, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 100, null, 'Dorso', 'forte, tempi costanti', 'B2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-157', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '8x100 RA B2', '8x100 RA forte, tempi costanti [B2] rec 30"', 'Rana',
    'Ragazzi, Assoluti', null, 800,
    19, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 100, null, 'Rana', 'forte, tempi costanti', 'B2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-158', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '8x50 DF B2', '8x50 DF forte, tempi costanti [B2] rec 30"', 'Delfino',
    'Ragazzi, Assoluti', null, 400,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Delfino', 'forte, tempi costanti', 'B2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-159', 'entrambi',
    'Serie principale', 'VO2max', 'B2',
    '8x100 MX B2', '8x100 MX forte, tempi costanti [B2] rec 30"', 'Misti',
    'Ragazzi, Assoluti', null, 800,
    19, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 100, null, 'Misti', 'forte, tempi costanti', 'B2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-160', 'entrambi',
    'Serie principale', 'VO2max', 'B2',
    '6x200 SL B2', '6x200 SL forte [B2] rec 45"', 'Stile libero',
    'Assoluti', null, 1200,
    27, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 200, null, 'Stile libero', 'forte', 'B2', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-161', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '6x200 DO B2', '6x200 DO forte [B2] rec 45"', 'Dorso',
    'Assoluti', null, 1200,
    27, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 200, null, 'Dorso', 'forte', 'B2', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-162', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '6x200 RA B2', '6x200 RA forte [B2] rec 45"', 'Rana',
    'Assoluti', null, 1200,
    27, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 200, null, 'Rana', 'forte', 'B2', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-163', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '6x100 DF B2', '6x100 DF forte [B2] rec 45"', 'Delfino',
    'Assoluti', null, 600,
    16, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 100, null, 'Delfino', 'forte', 'B2', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-164', 'entrambi',
    'Serie principale', 'VO2max', 'B2',
    '6x200 MX B2', '6x200 MX forte [B2] rec 45"', 'Misti',
    'Assoluti', null, 1200,
    27, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 200, null, 'Misti', 'forte', 'B2', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-165', 'entrambi',
    'Serie principale', 'VO2max', 'B2',
    '12x50 SL B2', '12x50 SL forte [B2] rec 20"', 'Stile libero',
    'Ragazzi, Assoluti', null, 600,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 12, 50, null, 'Stile libero', 'forte', 'B2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-166', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '12x50 DO B2', '12x50 DO forte [B2] rec 20"', 'Dorso',
    'Ragazzi, Assoluti', null, 600,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 12, 50, null, 'Dorso', 'forte', 'B2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-167', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '12x50 RA B2', '12x50 RA forte [B2] rec 20"', 'Rana',
    'Ragazzi, Assoluti', null, 600,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 12, 50, null, 'Rana', 'forte', 'B2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-168', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '6x50 DF B2', '6x50 DF forte [B2] rec 20"', 'Delfino',
    'Ragazzi, Assoluti', null, 300,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', 'forte', 'B2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-169', 'entrambi',
    'Serie principale', 'Lattacido', 'C1',
    '6x100 SL C1', '6x100 SL tolleranza, tempi vicini al ritmo gara [C1] rec 1''30"', 'Stile libero',
    'Ragazzi, Assoluti', null, 600,
    20, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 100, null, 'Stile libero', 'tolleranza, tempi vicini al ritmo gara', 'C1', 'nuoto', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-170', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '6x100 DO C1', '6x100 DO tolleranza, tempi vicini al ritmo gara [C1] rec 1''30"', 'Dorso',
    'Ragazzi, Assoluti', null, 600,
    20, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 100, null, 'Dorso', 'tolleranza, tempi vicini al ritmo gara', 'C1', 'nuoto', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-171', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '6x100 RA C1', '6x100 RA tolleranza, tempi vicini al ritmo gara [C1] rec 1''30"', 'Rana',
    'Ragazzi, Assoluti', null, 600,
    20, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 100, null, 'Rana', 'tolleranza, tempi vicini al ritmo gara', 'C1', 'nuoto', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-172', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '6x50 DF C1', '6x50 DF tolleranza, tempi vicini al ritmo gara [C1] rec 1''30"', 'Delfino',
    'Ragazzi, Assoluti', null, 300,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', 'tolleranza, tempi vicini al ritmo gara', 'C1', 'nuoto', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-173', 'entrambi',
    'Serie principale', 'Lattacido', 'C1',
    '6x100 MX C1', '6x100 MX tolleranza, tempi vicini al ritmo gara [C1] rec 1''30"', 'Misti',
    'Ragazzi, Assoluti', null, 600,
    20, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 100, null, 'Misti', 'tolleranza, tempi vicini al ritmo gara', 'C1', 'nuoto', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-174', 'entrambi',
    'Serie principale', 'Lattacido', 'C1',
    '8x50 SL C1', '8x50 SL tolleranza [C1] rec 1''', 'Stile libero',
    'Ragazzi, Assoluti', null, 400,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Stile libero', 'tolleranza', 'C1', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-175', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '8x50 DO C1', '8x50 DO tolleranza [C1] rec 1''', 'Dorso',
    'Ragazzi, Assoluti', null, 400,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Dorso', 'tolleranza', 'C1', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-176', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '8x50 RA C1', '8x50 RA tolleranza [C1] rec 1''', 'Rana',
    'Ragazzi, Assoluti', null, 400,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Rana', 'tolleranza', 'C1', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-177', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '8x50 DF C1', '8x50 DF tolleranza [C1] rec 1''', 'Delfino',
    'Ragazzi, Assoluti', null, 400,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Delfino', 'tolleranza', 'C1', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-178', 'entrambi',
    'Serie principale', 'Lattacido', 'C1',
    '4x75 SL C1', '4x75 SL tolleranza [C1] rec 1''30"', 'Stile libero',
    'Ragazzi, Assoluti', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 75, null, 'Stile libero', 'tolleranza', 'C1', 'nuoto', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-179', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '4x75 DO C1', '4x75 DO tolleranza [C1] rec 1''30"', 'Dorso',
    'Ragazzi, Assoluti', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 75, null, 'Dorso', 'tolleranza', 'C1', 'nuoto', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-180', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '4x75 RA C1', '4x75 RA tolleranza [C1] rec 1''30"', 'Rana',
    'Ragazzi, Assoluti', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 75, null, 'Rana', 'tolleranza', 'C1', 'nuoto', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-181', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '4x75 DF C1', '4x75 DF tolleranza [C1] rec 1''30"', 'Delfino',
    'Ragazzi, Assoluti', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 75, null, 'Delfino', 'tolleranza', 'C1', 'nuoto', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-182', 'entrambi',
    'Serie principale', 'Lattacido', 'C2',
    '4x50 SL C2', '4x50 SL massimale [C2] rec 3''', 'Stile libero',
    'Ragazzi, Assoluti', null, 200,
    16, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Stile libero', 'massimale', 'C2', 'nuoto', 180, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-183', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '4x50 DO C2', '4x50 DO massimale [C2] rec 3''', 'Dorso',
    'Ragazzi, Assoluti', null, 200,
    16, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Dorso', 'massimale', 'C2', 'nuoto', 180, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-184', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '4x50 RA C2', '4x50 RA massimale [C2] rec 3''', 'Rana',
    'Ragazzi, Assoluti', null, 200,
    16, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Rana', 'massimale', 'C2', 'nuoto', 180, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-185', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '4x50 DF C2', '4x50 DF massimale [C2] rec 3''', 'Delfino',
    'Ragazzi, Assoluti', null, 200,
    16, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Delfino', 'massimale', 'C2', 'nuoto', 180, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-186', 'entrambi',
    'Serie principale', 'Lattacido', 'C2',
    '3x100 SL C2', '3x100 SL massimale [C2] rec 5''', 'Stile libero',
    'Assoluti', null, 300,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 100, null, 'Stile libero', 'massimale', 'C2', 'nuoto', 300, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-187', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '3x100 DO C2', '3x100 DO massimale [C2] rec 5''', 'Dorso',
    'Assoluti', null, 300,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 100, null, 'Dorso', 'massimale', 'C2', 'nuoto', 300, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-188', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '3x100 RA C2', '3x100 RA massimale [C2] rec 5''', 'Rana',
    'Assoluti', null, 300,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 100, null, 'Rana', 'massimale', 'C2', 'nuoto', 300, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-189', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '3x50 DF C2', '3x50 DF massimale [C2] rec 5''', 'Delfino',
    'Assoluti', null, 150,
    18, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 50, null, 'Delfino', 'massimale', 'C2', 'nuoto', 300, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-190', 'entrambi',
    'Serie principale', 'Lattacido', 'C2',
    '3x100 MX C2', '3x100 MX massimale [C2] rec 5''', 'Misti',
    'Assoluti', null, 300,
    21, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 100, null, 'Misti', 'massimale', 'C2', 'nuoto', 300, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-191', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '6x25 SL C2', '6x25 SL massimale dal blocco [C2] rec 2''', 'Stile libero',
    'Ragazzi, Assoluti', null, 150,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Stile libero', 'massimale dal blocco', 'C2', 'nuoto', 120, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-192', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '6x25 DO C2', '6x25 DO massimale dal blocco [C2] rec 2''', 'Dorso',
    'Ragazzi, Assoluti', null, 150,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Dorso', 'massimale dal blocco', 'C2', 'nuoto', 120, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-193', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '6x25 RA C2', '6x25 RA massimale dal blocco [C2] rec 2''', 'Rana',
    'Ragazzi, Assoluti', null, 150,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Rana', 'massimale dal blocco', 'C2', 'nuoto', 120, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-194', 'nuoto',
    'Serie principale', 'Lattacido', 'C2',
    '6x25 DF C2', '6x25 DF massimale dal blocco [C2] rec 2''', 'Delfino',
    'Ragazzi, Assoluti', null, 150,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 25, null, 'Delfino', 'massimale dal blocco', 'C2', 'nuoto', 120, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-195', 'entrambi',
    'Serie principale', 'Velocità', 'V',
    '8x25 SL V', '8x25 SL massimale [V] rec 1''', 'Stile libero',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Stile libero', 'massimale', 'V', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-196', 'nuoto',
    'Serie principale', 'Velocità', 'V',
    '8x25 DO V', '8x25 DO massimale [V] rec 1''', 'Dorso',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Dorso', 'massimale', 'V', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-197', 'nuoto',
    'Serie principale', 'Velocità', 'V',
    '8x25 RA V', '8x25 RA massimale [V] rec 1''', 'Rana',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Rana', 'massimale', 'V', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-198', 'nuoto',
    'Serie principale', 'Velocità', 'V',
    '8x25 DF V', '8x25 DF massimale [V] rec 1''', 'Delfino',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Delfino', 'massimale', 'V', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-199', 'entrambi',
    'Serie principale', 'Velocità', 'V',
    '8x25 a scelta V', '8x25 scelta massimale, stile a scelta [V] rec 1''', 'A scelta',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'A scelta', 'massimale, stile a scelta', 'V', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-200', 'entrambi',
    'Serie principale', 'Velocità', 'V',
    '6x15 SL V', '6x15 SL sprint dal muro [V] rec 45"', 'Stile libero',
    'Esordienti, Ragazzi, Assoluti, Master', null, 90,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 15, null, 'Stile libero', 'sprint dal muro', 'V', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-201', 'nuoto',
    'Serie principale', 'Velocità', 'V',
    '6x15 DO V', '6x15 DO sprint dal muro [V] rec 45"', 'Dorso',
    'Esordienti, Ragazzi, Assoluti, Master', null, 90,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 15, null, 'Dorso', 'sprint dal muro', 'V', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-202', 'nuoto',
    'Serie principale', 'Velocità', 'V',
    '6x15 RA V', '6x15 RA sprint dal muro [V] rec 45"', 'Rana',
    'Esordienti, Ragazzi, Assoluti, Master', null, 90,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 15, null, 'Rana', 'sprint dal muro', 'V', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-203', 'nuoto',
    'Serie principale', 'Velocità', 'V',
    '6x15 DF V', '6x15 DF sprint dal muro [V] rec 45"', 'Delfino',
    'Esordienti, Ragazzi, Assoluti, Master', null, 90,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 15, null, 'Delfino', 'sprint dal muro', 'V', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-204', 'entrambi',
    'Serie principale', 'Velocità', 'V',
    '10x12,5 SL V', '10x12,5 SL sprint [V] rec 30"', 'Stile libero',
    'Esordienti, Ragazzi, Assoluti, Master', null, 130,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 13, null, 'Stile libero', 'sprint', 'V', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-205', 'nuoto',
    'Serie principale', 'Velocità', 'V',
    '10x12,5 DO V', '10x12,5 DO sprint [V] rec 30"', 'Dorso',
    'Esordienti, Ragazzi, Assoluti, Master', null, 130,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 13, null, 'Dorso', 'sprint', 'V', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-206', 'nuoto',
    'Serie principale', 'Velocità', 'V',
    '10x12,5 RA V', '10x12,5 RA sprint [V] rec 30"', 'Rana',
    'Esordienti, Ragazzi, Assoluti, Master', null, 130,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 13, null, 'Rana', 'sprint', 'V', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-207', 'nuoto',
    'Serie principale', 'Velocità', 'V',
    '10x12,5 DF V', '10x12,5 DF sprint [V] rec 30"', 'Delfino',
    'Esordienti, Ragazzi, Assoluti, Master', null, 130,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 13, null, 'Delfino', 'sprint', 'V', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-208', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '4x(3x100) soglia', '4x( 3x100 SL ritmo soglia [B1] rec 10" )', 'Stile libero',
    'Assoluti', null, 1200,
    24, '1'' di recupero tra un giro e l''altro.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 4, 3, 100, null, 'Stile libero', 'ritmo soglia', 'B1', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-209', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '2x(4x50) tolleranza', '2x( 4x50 scelta stile principale, tolleranza [C1] rec 45" )', 'A scelta',
    'Ragazzi, Assoluti', null, 400,
    13, '3'' facili tra i due giri.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 2, 4, 50, null, 'A scelta', 'stile principale, tolleranza', 'C1', 'nuoto', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-210', 'entrambi',
    'Serie principale', 'Velocità', 'V',
    '4x(4x25) sprint', '4x( 4x25 scelta sprint [V] rec 30" )', 'A scelta',
    'Ragazzi, Assoluti', null, 400,
    15, '2'' facili tra i giri.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 4, 4, 25, null, 'A scelta', 'sprint', 'V', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-211', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '1500 SL continuo', '1500 SL continuo, ritmo regolare [A2]', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 1500,
    28, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 1500, null, 'Stile libero', 'continuo, ritmo regolare', 'A2', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-212', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '5x300 SL/DO/SL', '5x300 MX 100 SL + 100 dorso + 100 SL [A2] rec 30"', 'Misti',
    'Ragazzi, Assoluti', null, 1500,
    30, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 5, 300, null, 'Misti', '100 SL + 100 dorso + 100 SL', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-213', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '8x50 SL ritmo 200', '8x50 SL ritmo 200 [RG] rec 30"', 'Stile libero',
    'Ragazzi, Assoluti', null, 400,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Stile libero', 'ritmo 200', 'RG', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-214', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '8x50 DO ritmo 200', '8x50 DO ritmo 200 [RG] rec 30"', 'Dorso',
    'Ragazzi, Assoluti', null, 400,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Dorso', 'ritmo 200', 'RG', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-215', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '8x50 RA ritmo 200', '8x50 RA ritmo 200 [RG] rec 30"', 'Rana',
    'Ragazzi, Assoluti', null, 400,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Rana', 'ritmo 200', 'RG', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-216', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '8x50 DF ritmo 200', '8x50 DF ritmo 200 [RG] rec 30"', 'Delfino',
    'Ragazzi, Assoluti', null, 400,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Delfino', 'ritmo 200', 'RG', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-217', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '4x100 SL ritmo 400', '4x100 SL ritmo 400 [RG] rec 20"', 'Stile libero',
    'Ragazzi, Assoluti', null, 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 100, null, 'Stile libero', 'ritmo 400', 'RG', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-218', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '4x100 DO ritmo 400', '4x100 DO ritmo 400 [RG] rec 20"', 'Dorso',
    'Ragazzi, Assoluti', null, 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 100, null, 'Dorso', 'ritmo 400', 'RG', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-219', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '4x100 RA ritmo 400', '4x100 RA ritmo 400 [RG] rec 20"', 'Rana',
    'Ragazzi, Assoluti', null, 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 100, null, 'Rana', 'ritmo 400', 'RG', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-220', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '6x50 SL ritmo 100', '6x50 SL ritmo 100 [RG] rec 1''', 'Stile libero',
    'Ragazzi, Assoluti', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', 'ritmo 100', 'RG', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-221', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '6x50 DO ritmo 100', '6x50 DO ritmo 100 [RG] rec 1''', 'Dorso',
    'Ragazzi, Assoluti', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Dorso', 'ritmo 100', 'RG', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-222', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '6x50 RA ritmo 100', '6x50 RA ritmo 100 [RG] rec 1''', 'Rana',
    'Ragazzi, Assoluti', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Rana', 'ritmo 100', 'RG', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-223', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '6x50 DF ritmo 100', '6x50 DF ritmo 100 [RG] rec 1''', 'Delfino',
    'Ragazzi, Assoluti', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Delfino', 'ritmo 100', 'RG', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-224', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '4x50 SL broken 200 (rec 10" ogni 50)', '4x50 SL broken 200 (rec 10" ogni 50) [RG] rec 10"', 'Stile libero',
    'Ragazzi, Assoluti', null, 200,
    4, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Stile libero', 'broken 200 (rec 10" ogni 50)', 'RG', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-225', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '4x50 DO broken 200 (rec 10" ogni 50)', '4x50 DO broken 200 (rec 10" ogni 50) [RG] rec 10"', 'Dorso',
    'Ragazzi, Assoluti', null, 200,
    4, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Dorso', 'broken 200 (rec 10" ogni 50)', 'RG', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-226', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '4x50 RA broken 200 (rec 10" ogni 50)', '4x50 RA broken 200 (rec 10" ogni 50) [RG] rec 10"', 'Rana',
    'Ragazzi, Assoluti', null, 200,
    4, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Rana', 'broken 200 (rec 10" ogni 50)', 'RG', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-227', 'nuoto',
    'Serie principale', 'Ritmo gara', 'RG',
    '4x50 DF broken 200 (rec 10" ogni 50)', '4x50 DF broken 200 (rec 10" ogni 50) [RG] rec 10"', 'Delfino',
    'Ragazzi, Assoluti', null, 200,
    4, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Delfino', 'broken 200 (rec 10" ogni 50)', 'RG', 'nuoto', 10, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-228', 'nuoto',
    'Serie principale', 'Soglia', 'B1',
    '4x100 misti soglia', '4x100 MX ritmo soglia [B1] rec 20"', 'Misti',
    'Ragazzi, Assoluti', null, 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 100, null, 'Misti', 'ritmo soglia', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-229', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '4x200 misti', '4x200 MX ritmo costante [A2] rec 30"', 'Misti',
    'Ragazzi, Assoluti, Master', null, 800,
    17, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 200, null, 'Misti', 'ritmo costante', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-230', 'nuoto',
    'Serie principale', 'VO2max', 'B2',
    '6x100 misti forte', '6x100 MX forte [B2] rec 40"', 'Misti',
    'Ragazzi, Assoluti', null, 600,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 100, null, 'Misti', 'forte', 'B2', 'nuoto', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-231', 'nuoto',
    'Serie principale', 'Lattacido', 'C1',
    '4x100 misti tolleranza', '4x100 MX ritmo gara 200 misti [C1] rec 2''', 'Misti',
    'Ragazzi, Assoluti', null, 400,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 100, null, 'Misti', 'ritmo gara 200 misti', 'C1', 'nuoto', 120, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-232', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '3x(4x50) misti', '3x( 4x50 MX 1 per stile, poi giro successivo più veloce [A2] rec 15" )', 'Misti',
    'Ragazzi, Assoluti, Master', null, 600,
    14, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 3, 4, 50, null, 'Misti', '1 per stile, poi giro successivo più veloce', 'A2', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-233', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '6x50 SL esordienti', '6x50 SL ritmo costante [A2] rec 20"', 'Stile libero',
    'Esordienti', null, 300,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Stile libero', 'ritmo costante', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-234', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '4x100 SL esordienti', '4x100 SL ritmo costante [A2] rec 30"', 'Stile libero',
    'Esordienti', null, 400,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 100, null, 'Stile libero', 'ritmo costante', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-235', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '8x25 esordienti a stili', '8x25 MX 2 per stile [A2] rec 20"', 'Misti',
    'Esordienti', null, 200,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Misti', '2 per stile', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-236', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '4x50 dorso esordienti', '4x50 DO ritmo costante [A2] rec 20"', 'Dorso',
    'Esordienti', null, 200,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Dorso', 'ritmo costante', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-237', 'nuoto',
    'Serie principale', 'Aerobico', 'A2',
    '4x50 rana esordienti', '4x50 RA ritmo costante, scivolata [A2] rec 20"', 'Rana',
    'Esordienti', null, 200,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Rana', 'ritmo costante, scivolata', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-238', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '6x50 esordienti forte', '6x50 scelta forte, tempi costanti [B1] rec 30"', 'A scelta',
    'Esordienti', null, 300,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'A scelta', 'forte, tempi costanti', 'B1', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-239', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '200 misti esordienti', '2x100 MX 25 per stile [A2] rec 30"', 'Misti',
    'Esordienti', null, 200,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 2, 100, null, 'Misti', '25 per stile', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-240', 'entrambi',
    'Serie principale', 'Velocità', 'V',
    'Staffetta a squadre esordienti', '4x25 scelta staffetta a squadre, gioco [V] rec 1''', 'A scelta',
    'Esordienti', null, 100,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 25, null, 'A scelta', 'staffetta a squadre, gioco', 'V', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-241', 'entrambi',
    'Serie principale', 'Aerobico', 'A2',
    '10x100 master', '10x100 SL ritmo costante, partenza a tempo [A2] rec 20"', 'Stile libero',
    'Master', null, 1000,
    22, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 100, null, 'Stile libero', 'ritmo costante, partenza a tempo', 'A2', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-242', 'entrambi',
    'Serie principale', 'Soglia', 'B1',
    '6x200 master soglia', '6x200 scelta ritmo soglia [B1] rec 30"', 'A scelta',
    'Master', null, 1200,
    25, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 200, null, 'A scelta', 'ritmo soglia', 'B1', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-243', 'entrambi',
    'Serie principale', 'Velocità', 'V',
    '8x25 master veloci', '8x25 scelta veloci, tecnica pulita [V] rec 45"', 'A scelta',
    'Master', null, 200,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'A scelta', 'veloci, tecnica pulita', 'V', 'tecnica', 45, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-244', 'entrambi',
    'Defaticamento', 'Recupero', 'A1',
    '200 sciolto', '200 scelta sciolto [A1]', 'A scelta',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    4, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'A scelta', 'sciolto', 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-245', 'entrambi',
    'Defaticamento', 'Recupero', 'A1',
    '300 misti facile', '300 MX molto facile [A1]', 'Misti',
    'Ragazzi, Assoluti, Master', null, 300,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 300, null, 'Misti', 'molto facile', 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-246', 'entrambi',
    'Defaticamento', 'Recupero', 'A1',
    '4x50 dorso sciolto', '4x50 DO sciolto [A1] rec 15"', 'Dorso',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, 50, null, 'Dorso', 'sciolto', 'A1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-247', 'entrambi',
    'Defaticamento', 'Recupero', 'A1',
    '100 SL + 100 DO facile', '100 SL [A1] + 100 DO [A1]', 'Vari',
    'Esordienti, Ragazzi, Assoluti, Master', null, 200,
    4, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 100, null, 'Stile libero', null, 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, 100, null, 'Dorso', null, 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-248', 'entrambi',
    'Defaticamento', 'Recupero', 'A1',
    '400 pull respirazione 5', '400 SL braccia lente, respirazione 5 [A1] (Pull buoy)', 'Stile libero',
    'Assoluti, Master', 'Pull buoy', 400,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 400, null, 'Stile libero', 'braccia lente, respirazione 5', 'A1', 'braccia', null, 'Pull buoy', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-249', 'entrambi',
    'Defaticamento', 'Recupero', 'A1',
    '200 gambe pinne facile', '200 scelta gambe facili [A1] (Pinne)', 'A scelta',
    'Ragazzi, Assoluti, Master', 'Pinne', 200,
    4, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'A scelta', 'gambe facili', 'A1', 'gambe', null, 'Pinne', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-250', 'entrambi',
    'Defaticamento', 'Recupero', 'A1',
    '200 sciolto + allungamento', '200 scelta sciolto [A1] + 5'' allungamento in acqua [A1]', 'A scelta',
    'Ragazzi, Assoluti, Master', null, 200,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'A scelta', 'sciolto', 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, null, 300, null, 'allungamento in acqua', 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-251', 'entrambi',
    'Defaticamento', 'Recupero', 'A1',
    'Esordienti 100 + gioco', '100 scelta sciolto [A1] + 5'' gioco libero in acqua [A1]', 'A scelta',
    'Esordienti', null, 100,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 100, null, 'A scelta', 'sciolto', 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, null, 300, null, 'gioco libero in acqua', 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-252', 'nuoto',
    'Test', 'Test', 'TEST',
    'Test 400 SL', '400 SL massimale, prendi tempo e passaggi ai 100 [TEST]', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 400,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 400, null, 'Stile libero', 'massimale, prendi tempo e passaggi ai 100', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-253', 'entrambi',
    'Test', 'Test', 'TEST',
    'Test CSS (400 + 200)', '400 SL massimale [TEST] rec 10'' + 200 SL massimale [TEST]', 'Stile libero',
    'Ragazzi, Assoluti, Master', null, 600,
    21, 'CSS = 200 / (tempo 400 - tempo 200) in m/s. Base per calcolare le ripartenze.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 400, null, 'Stile libero', 'massimale', 'TEST', 'nuoto', 600, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, 200, null, 'Stile libero', 'massimale', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-254', 'nuoto',
    'Test', 'Test', 'TEST',
    'Test T30', '30'' 30 minuti continui, registra i metri percorsi [TEST]', 'Stile libero',
    'Assoluti, Master', null, 0,
    30, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 1800, 'Stile libero', '30 minuti continui, registra i metri percorsi', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-255', 'nuoto',
    'Test', 'Test', 'TEST',
    'Test 100 SL', '100 SL massimale dal blocco [TEST]', 'Stile libero',
    'Esordienti, Ragazzi, Assoluti, Master', null, 100,
    2, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 100, null, 'Stile libero', 'massimale dal blocco', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-256', 'nuoto',
    'Test', 'Test', 'TEST',
    'Test 100 DO', '100 DO massimale dal blocco [TEST]', 'Dorso',
    'Esordienti, Ragazzi, Assoluti, Master', null, 100,
    2, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 100, null, 'Dorso', 'massimale dal blocco', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-257', 'nuoto',
    'Test', 'Test', 'TEST',
    'Test 100 RA', '100 RA massimale dal blocco [TEST]', 'Rana',
    'Esordienti, Ragazzi, Assoluti, Master', null, 100,
    2, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 100, null, 'Rana', 'massimale dal blocco', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-258', 'nuoto',
    'Test', 'Test', 'TEST',
    'Test 100 DF', '100 DF massimale dal blocco [TEST]', 'Delfino',
    'Esordienti, Ragazzi, Assoluti, Master', null, 100,
    2, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 100, null, 'Delfino', 'massimale dal blocco', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-259', 'entrambi',
    'Test', 'Test', 'TEST',
    'Test 50 max', '2x50 scelta massimale, vale il migliore [TEST] rec 5''', 'A scelta',
    'Esordienti, Ragazzi, Assoluti, Master', null, 100,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 2, 50, null, 'A scelta', 'massimale, vale il migliore', 'TEST', 'nuoto', 300, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-260', 'nuoto',
    'Test', 'Test', 'TEST',
    'Step test 7x200', '7x200 SL progressivo a gradini, tempo e FC a ogni 200 [TEST] rec 30"', 'Stile libero',
    'Assoluti', null, 1400,
    29, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 7, 200, null, 'Stile libero', 'progressivo a gradini, tempo e FC a ogni 200', 'TEST', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-261', 'nuoto',
    'Test', 'Test', 'TEST',
    'Test 6x50 ritmo', '6x50 scelta ritmo gara 200, registra i tempi [TEST] rec 1''', 'A scelta',
    'Ragazzi, Assoluti', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'A scelta', 'ritmo gara 200, registra i tempi', 'TEST', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-262', 'nuoto',
    'Test', 'Test', 'TEST',
    'Test 200 stile principale', '200 scelta massimale, stile principale [TEST]', 'A scelta',
    'Ragazzi, Assoluti', null, 200,
    4, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'A scelta', 'massimale, stile principale', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'N-263', 'nuoto',
    'Test', 'Test', 'TEST',
    'Test 2000 SL', '2000 SL massimale, passaggi ai 500 [TEST]', 'Stile libero',
    'Assoluti, Master', null, 2000,
    37, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 2000, null, 'Stile libero', 'massimale, passaggi ai 500', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-001', 'pallanuoto',
    'Riscaldamento', 'Aerobico', 'A1',
    '400 misto + 200 testa alta', '400 MX sciolto [A1] + 200 SL testa alta [A1]', 'Vari',
    'Under 14, Under 16, Under 18, Senior', null, 600,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 400, null, 'Misti', 'sciolto', 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, 200, null, 'Testa alta', null, 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-002', 'pallanuoto',
    'Riscaldamento', 'Aerobico', 'A1',
    '300 SL + 4x50 testa alta', '300 SL [A1] rec 30" + 4x50 MX 25 testa alta + 25 SL [A1] rec 15"', 'Vari',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 500,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 300, null, 'Stile libero', null, 'A1', 'nuoto', 30, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 4, 50, null, 'Misti', '25 testa alta + 25 SL', 'A1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-003', 'pallanuoto',
    'Riscaldamento', 'Tecnica', 'A1',
    'Palleggio a coppie in movimento', '10'' passaggi a coppie spostandosi con gambe a rana pallanuoto [A1] (Palloni)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'passaggi a coppie spostandosi con gambe a rana pallanuoto', 'A1', 'gambe', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-004', 'pallanuoto',
    'Riscaldamento', 'Aerobico', 'A1 / V',
    '200 SL + 200 gambe + 4x25 sprint', '200 SL [A1] + 200 gambe rana pallanuoto in verticale e spostamento [A1] + 4x25 SL testa alta sprint [V] rec 30"', 'Vari',
    'Under 14, Under 16, Under 18, Senior', null, 500,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'Stile libero', null, 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, 200, null, null, 'gambe rana pallanuoto in verticale e spostamento', 'A1', 'gambe', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 4, 25, null, 'Testa alta', 'sprint', 'V', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-005', 'pallanuoto',
    'Riscaldamento', 'Aerobico', 'A1',
    'Riscaldamento Under 12 con gioco', '200 SL [A1] rec 30" + 5'' gioco con la palla (ruba-palla, passaggi liberi) [A1] (Palloni)', 'Stile libero',
    'Under 12', 'Palloni', 200,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'Stile libero', null, 'A1', 'nuoto', 30, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, null, 300, null, 'gioco con la palla (ruba-palla, passaggi liberi)', 'A1', 'nuoto', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-006', 'pallanuoto',
    'Riscaldamento', 'Aerobico', 'A1',
    '6x50 variati', '6x50 MX SL testa alta / dorso polo / rana alternati [A1] rec 15"', 'Misti',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 300,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Misti', 'SL testa alta / dorso polo / rana alternati', 'A1', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-007', 'pallanuoto',
    'Riscaldamento', 'Velocità', 'A1 / V / T',
    'Riscaldamento pre-partita', '300 scelta sciolto [A1] + 4x15 SL testa alta sprint [V] rec 30" + 5'' passaggi a coppie [T] (Palloni) + 5'' tiri al portiere progressivi [T] (Palloni, Porte)', 'Vari',
    'Under 16, Under 18, Senior', 'Palloni, Porte', 360,
    19, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 300, null, 'A scelta', 'sciolto', 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 4, 15, null, 'Testa alta', 'sprint', 'V', 'nuoto', 30, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 1, null, 300, null, 'passaggi a coppie', 'T', 'tecnica', null, 'Palloni', null from b
union all select id, '00000000-0000-0000-0000-000000000001', 4, 1, 1, null, 300, null, 'tiri al portiere progressivi', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-008', 'pallanuoto',
    'Riscaldamento', 'Aerobico', 'A1',
    'Riscaldamento master', '300 scelta sciolto [A1] rec 30" + 5'' passaggi a coppie da fermi [A1] (Palloni)', 'A scelta',
    'Master', 'Palloni', 300,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 300, null, 'A scelta', 'sciolto', 'A1', 'nuoto', 30, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, null, 300, null, 'passaggi a coppie da fermi', 'A1', 'nuoto', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-009', 'pallanuoto',
    'Nuoto specifico', 'Velocità', 'B2',
    '10x25 testa alta', '10x25 SL testa alta veloce [B2] rec 15"', 'Testa alta',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 250,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 25, null, 'Testa alta', 'veloce', 'B2', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-010', 'pallanuoto',
    'Nuoto specifico', 'Velocità', 'V',
    '8x15 sprint da fermo', '8x15 SL testa alta partenza dalla posizione verticale al fischio [V] rec 30"', 'Testa alta',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 120,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 15, null, 'Testa alta', 'partenza dalla posizione verticale al fischio', 'V', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-011', 'pallanuoto',
    'Nuoto specifico', 'Velocità', 'V',
    'Sprint con cambio di direzione', '6x20 SL testa alta 10 m sprint, giro di 180° al fischio, 10 m sprint [V] rec 30"', 'Testa alta',
    'Under 14, Under 16, Under 18, Senior', null, 120,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 20, null, 'Testa alta', '10 m sprint, giro di 180° al fischio, 10 m sprint', 'V', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-012', 'pallanuoto',
    'Nuoto specifico', 'Tecnica', 'A2',
    '8x25 SL testa alta + dorso polo', '8x25 MX 12,5 testa alta + 12,5 dorso polo [A2] rec 15"', 'Misti',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 200,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Misti', '12,5 testa alta + 12,5 dorso polo', 'A2', 'nuoto', 15, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-013', 'pallanuoto',
    'Nuoto specifico', 'Velocità', 'V',
    '10x15 conduzione palla sprint', '10x15 SL testa alta conduzione palla [V] rec 30" (Palloni)', 'Testa alta',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni', 150,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 15, null, 'Testa alta', 'conduzione palla', 'V', 'nuoto', 30, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-014', 'pallanuoto',
    'Nuoto specifico', 'Aerobico', 'A2',
    '6x50 conduzione palla', '6x50 SL testa alta conduzione palla, ritmo costante [A2] rec 20" (Palloni)', 'Testa alta',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni', 300,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Testa alta', 'conduzione palla, ritmo costante', 'A2', 'nuoto', 20, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-015', 'pallanuoto',
    'Nuoto specifico', 'Velocità', 'V',
    '4x(4x25) sprint con giro', '4x( 4x25 SL testa alta sprint con giro di 180° a metà vasca [V] rec 20" )', 'Testa alta',
    'Under 14, Under 16, Under 18, Senior', null, 400,
    13, '1'' facile tra i giri.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 4, 4, 25, null, 'Testa alta', 'sprint con giro di 180° a metà vasca', 'V', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-016', 'pallanuoto',
    'Nuoto specifico', 'Velocità', 'V',
    '20x15 sprint contropiede', '20x15 SL testa alta partenza al fischio, come in contropiede [V] rec 30"', 'Testa alta',
    'Under 16, Under 18, Senior', null, 300,
    16, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 20, 15, null, 'Testa alta', 'partenza al fischio, come in contropiede', 'V', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-017', 'pallanuoto',
    'Nuoto specifico', 'VO2max', 'B2',
    '8x50 testa alta forte', '8x50 SL testa alta forte [B2] rec 30"', 'Testa alta',
    'Under 14, Under 16, Under 18, Senior', null, 400,
    11, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 50, null, 'Testa alta', 'forte', 'B2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-018', 'pallanuoto',
    'Nuoto specifico', 'Aerobico', 'A2',
    '3x200 testa alta', '3x200 SL testa alta ritmo costante [A2] rec 30"', 'Testa alta',
    'Under 14, Under 16, Under 18, Senior', null, 600,
    13, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 200, null, 'Testa alta', 'ritmo costante', 'A2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-019', 'pallanuoto',
    'Nuoto specifico', 'Velocità', 'V',
    'Piramide di sprint', '10 SL testa alta [V] rec 20" + 15 SL testa alta [V] rec 25" + 20 SL testa alta [V] rec 30" + 15 SL testa alta [V] rec 25" + 10 SL testa alta [V]', 'Testa alta',
    'Under 16, Under 18, Senior', null, 70,
    3, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 10, null, 'Testa alta', null, 'V', 'nuoto', 20, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, 15, null, 'Testa alta', null, 'V', 'nuoto', 25, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 3, 1, 1, 20, null, 'Testa alta', null, 'V', 'nuoto', 30, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 4, 1, 1, 15, null, 'Testa alta', null, 'V', 'nuoto', 25, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 5, 1, 1, 10, null, 'Testa alta', null, 'V', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-020', 'pallanuoto',
    'Gambe', 'Forza', 'B2',
    '6x1'' elevazione braccia fuori', '6x1'' gambe rana pallanuoto, braccia fuori dall''acqua [B2] rec 30"', null,
    'Under 14, Under 16, Under 18, Senior', null, 0,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, null, 60, null, 'gambe rana pallanuoto, braccia fuori dall''acqua', 'B2', 'gambe', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-021', 'pallanuoto',
    'Gambe', 'Forza', 'C1',
    '8x30" gambe con peso', '8x30" gambe in verticale tenendo un peso sopra la testa [C1] rec 30" (Peso/cintura zavorrata)', null,
    'Under 16, Under 18, Senior', 'Peso/cintura zavorrata', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, null, 30, null, 'gambe in verticale tenendo un peso sopra la testa', 'C1', 'gambe', 30, 'Peso/cintura zavorrata', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-022', 'pallanuoto',
    'Gambe', 'Tecnica', 'A2',
    'Spostamenti laterali in verticale', '5'' spostamenti laterali dx/sx in verticale, busto alto [A2]', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 0,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 300, null, 'spostamenti laterali dx/sx in verticale, busto alto', 'A2', 'gambe', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-023', 'pallanuoto',
    'Gambe', 'Forza', 'V',
    '10x20" esplosioni verticali', '10x20" salti/esplosioni fuori dall''acqua dalla verticale [V] rec 40"', null,
    'Under 14, Under 16, Under 18, Senior', null, 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, null, 20, null, 'salti/esplosioni fuori dall''acqua dalla verticale', 'V', 'gambe', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-024', 'pallanuoto',
    'Gambe', 'Aerobico', 'A2',
    '4x2'' gambe mani fuori', '4x2'' gambe rana pallanuoto, mani fuori [A2] rec 30"', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, null, 120, null, 'gambe rana pallanuoto, mani fuori', 'A2', 'gambe', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-025', 'pallanuoto',
    'Gambe', 'Forza', 'B2',
    '8x25 gambe verticale in avanti', '8x25 avanzamento in verticale con gambe, braccia fuori [B2] rec 30"', null,
    'Under 14, Under 16, Under 18, Senior', null, 200,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, null, 'avanzamento in verticale con gambe, braccia fuori', 'B2', 'gambe', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-026', 'pallanuoto',
    'Gambe', 'Forza', 'C1',
    '6x30" lotta a coppie', '6x30" spinta frontale a coppie in verticale [C1] rec 30"', null,
    'Under 16, Under 18, Senior', null, 0,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, null, 30, null, 'spinta frontale a coppie in verticale', 'C1', 'gambe', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-027', 'pallanuoto',
    'Gambe', 'Velocità', 'V',
    '10x15" scatti dalla verticale', '10x15" dalla verticale scatto orizzontale di 5 m [V] rec 30"', null,
    'Under 14, Under 16, Under 18, Senior', null, 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, null, 15, null, 'dalla verticale scatto orizzontale di 5 m', 'V', 'gambe', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-028', 'pallanuoto',
    'Gambe', 'Tecnica', 'A2',
    'Gioco ''chi sta più alto''', '5x30" gambe con mani sopra la testa, a gara [A2] rec 30"', null,
    'Under 12', null, 0,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 5, null, 30, null, 'gambe con mani sopra la testa, a gara', 'A2', 'gambe', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-029', 'pallanuoto',
    'Gambe', 'Forza', 'B1',
    'Gambe con palla sopra la testa', '6x45" gambe in verticale con palla tenuta in alto con una mano [B1] rec 30" (Palloni)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, null, 45, null, 'gambe in verticale con palla tenuta in alto con una mano', 'B1', 'gambe', 30, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-030', 'pallanuoto',
    'Passaggi', 'Tecnica', 'T',
    'Passaggi a coppie 5-8 m', '10'' passaggi a coppie, alterna mano dx e sx [T] (Palloni)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'passaggi a coppie, alterna mano dx e sx', 'T', 'tecnica', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-031', 'pallanuoto',
    'Passaggi', 'Tecnica', 'T',
    'Passaggi a terne in movimento', '10'' terne che avanzano lungo la vasca passandosi la palla [T] (Palloni)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'terne che avanzano lungo la vasca passandosi la palla', 'T', 'tecnica', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-032', 'pallanuoto',
    'Passaggi', 'Tecnica', 'T',
    'Passaggio + palleggio', '8'' ricezione, palleggio sul posto, passaggio [T] (Palloni)', null,
    'Under 12, Under 14', 'Palloni', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'ricezione, palleggio sul posto, passaggio', 'T', 'tecnica', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-033', 'pallanuoto',
    'Passaggi', 'Tecnica', 'T',
    'Dai e vai a coppie', '10'' passaggio e scatto in avanti, ricezione in movimento [T] (Palloni)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'passaggio e scatto in avanti, ricezione in movimento', 'T', 'tecnica', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-034', 'pallanuoto',
    'Passaggi', 'Tattica', 'TT',
    'Passaggi sotto pressione 2vs1', '10'' due attaccanti si passano la palla con un difensore in mezzo [TT] (Palloni)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'due attaccanti si passano la palla con un difensore in mezzo', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-035', 'pallanuoto',
    'Passaggi', 'Tecnica', 'T',
    'Passaggi asciutti e bagnati', '8'' alterna passaggi in aria (asciutti) e sull''acqua (bagnati) [T] (Palloni)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'alterna passaggi in aria (asciutti) e sull''acqua (bagnati)', 'T', 'tecnica', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-036', 'pallanuoto',
    'Passaggi', 'Tattica', 'TT',
    'Circolazione palla sull''arco', '10'' 6 giocatori in posizione d''attacco, circolazione veloce [TT] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, '6 giocatori in posizione d''attacco, circolazione veloce', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-037', 'pallanuoto',
    'Passaggi', 'Tecnica', 'T',
    'Lanci lunghi del portiere', '8'' lanci lunghi del portiere a giocatori in contropiede [T] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'lanci lunghi del portiere a giocatori in contropiede', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-038', 'pallanuoto',
    'Tiro', 'Tecnica', 'T',
    'Tiri da fermo 5 m', '10'' tiri da 5 m mirando agli angoli alti e bassi [T] (Palloni, Porte)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'tiri da 5 m mirando agli angoli alti e bassi', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-039', 'pallanuoto',
    'Tiro', 'Tecnica', 'T',
    'Tiro dopo conduzione', '10'' conduzione palla 10 m e tiro in movimento [T] (Palloni, Porte)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'conduzione palla 10 m e tiro in movimento', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-040', 'pallanuoto',
    'Tiro', 'Tecnica', 'T',
    'Tiro a palombella', '8'' tiro a pallonetto sopra il portiere [T] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'tiro a pallonetto sopra il portiere', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-041', 'pallanuoto',
    'Tiro', 'Tecnica', 'T',
    'Tiro a rimbalzo', '8'' tiro che rimbalza sull''acqua davanti al portiere [T] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'tiro che rimbalza sull''acqua davanti al portiere', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-042', 'pallanuoto',
    'Tiro', 'Tecnica', 'T',
    'Tiro di potenza da fuori', '10'' tiri dai 7-8 m con elevazione [T] (Palloni, Porte)', null,
    'Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'tiri dai 7-8 m con elevazione', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-043', 'pallanuoto',
    'Tiro', 'Tecnica', 'T',
    'Tiro di girata del centroboa', '8'' ricezione spalle alla porta e tiro di girata [T] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'ricezione spalle alla porta e tiro di girata', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-044', 'pallanuoto',
    'Tiro', 'Lattacido', 'C1',
    'Sprint + tiro sotto fatica', '10x15 SL testa alta sprint 15 m e tiro immediato [C1] rec 45" (Palloni, Porte)', 'Testa alta',
    'Under 16, Under 18, Senior', 'Palloni, Porte', 150,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 15, null, 'Testa alta', 'sprint 15 m e tiro immediato', 'C1', 'pallanuoto tecnico-tattico', 45, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-045', 'pallanuoto',
    'Tiro', 'Tecnica', 'T',
    'Rigori 5 m', '8'' rigori a rotazione, il portiere cambia [T] (Palloni, Porte)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni, Porte', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'rigori a rotazione, il portiere cambia', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-046', 'pallanuoto',
    'Tiro', 'Tattica', 'TT',
    'Tiro dopo 1vs1', '10'' attaccante contro difensore, conclusione a rete [TT] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'attaccante contro difensore, conclusione a rete', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-047', 'pallanuoto',
    'Portiere', 'Forza', 'C1',
    'Elevazione portiere', '6x30" elevazione massima con braccia fuori [C1] rec 30"', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 0,
    6, 'Lavoro specifico portieri.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, null, 30, null, 'elevazione massima con braccia fuori', 'C1', 'braccia', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-048', 'pallanuoto',
    'Portiere', 'Velocità', 'V',
    'Spostamenti laterali sulla linea', '8x15" spostamenti laterali palo-palo [V] rec 30"', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 0,
    6, 'Lavoro specifico portieri.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, null, 15, null, 'spostamenti laterali palo-palo', 'V', 'pallanuoto tecnico-tattico', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-049', 'pallanuoto',
    'Portiere', 'Tecnica', 'T',
    'Parate su tiri piazzati', '10'' parate su tiri dell''allenatore da varie posizioni [T] (Palloni, Porte)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni, Porte', 0,
    10, 'Lavoro specifico portieri.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'parate su tiri dell''allenatore da varie posizioni', 'T', 'tecnica', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-050', 'pallanuoto',
    'Portiere', 'Velocità', 'V',
    'Riflessi a distanza ravvicinata', '8'' tiri ravvicinati rapidi da 2-3 m [V] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    8, 'Lavoro specifico portieri.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'tiri ravvicinati rapidi da 2-3 m', 'V', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-051', 'pallanuoto',
    'Portiere', 'Tecnica', 'T',
    'Rinvii lunghi di precisione', '8'' rinvii verso un compagno in movimento [T] (Palloni)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni', 0,
    8, 'Lavoro specifico portieri.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'rinvii verso un compagno in movimento', 'T', 'tecnica', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-052', 'pallanuoto',
    'Portiere', 'Tattica', 'TT',
    'Uscite sul contropiede', '8'' uscita su attaccante solo in contropiede [TT] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    8, 'Lavoro specifico portieri.', 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 480, null, 'uscita su attaccante solo in contropiede', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-053', 'pallanuoto',
    'Difesa', 'Tattica', 'TT',
    'Marcatura individuale 1vs1', '10'' difensore in pressing sul portatore [TT] (Palloni)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'difensore in pressing sul portatore', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-054', 'pallanuoto',
    'Difesa', 'Tattica', 'TT',
    'Difesa sul centroboa', '10'' anticipo, difesa davanti e dietro il centroboa [TT] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'anticipo, difesa davanti e dietro il centroboa', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-055', 'pallanuoto',
    'Difesa', 'Tattica', 'TT',
    'Difesa a zona', '10'' difesa a zona con raddoppio sul centroboa [TT] (Palloni, Porte)', null,
    'Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'difesa a zona con raddoppio sul centroboa', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-056', 'pallanuoto',
    'Difesa', 'Velocità', 'V',
    'Rientri difensivi', '8x25 SL testa alta dopo il tiro, rientro veloce in difesa [V] rec 40"', 'Testa alta',
    'Under 14, Under 16, Under 18, Senior', null, 200,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 25, null, 'Testa alta', 'dopo il tiro, rientro veloce in difesa', 'V', 'pallanuoto tecnico-tattico', 40, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-057', 'pallanuoto',
    'Difesa', 'Tattica', 'TT',
    'Inferiorità 5vs6', '10'' difesa in inferiorità numerica [TT] (Palloni, Porte)', null,
    'Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'difesa in inferiorità numerica', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-058', 'pallanuoto',
    'Attacco', 'Tattica', 'TT',
    'Attacco 3-3', '10'' circolazione e tagli in attacco 3-3 [TT] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'circolazione e tagli in attacco 3-3', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-059', 'pallanuoto',
    'Attacco', 'Tattica', 'TT',
    'Attacco 4-2', '10'' attacco con due giocatori in zona 2 metri [TT] (Palloni, Porte)', null,
    'Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'attacco con due giocatori in zona 2 metri', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-060', 'pallanuoto',
    'Attacco', 'Tecnica', 'C1',
    'Centroboa: lotta per la posizione', '6x30" centroboa contro difensore, conquista della posizione [C1] rec 30"', null,
    'Under 14, Under 16, Under 18, Senior', null, 0,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, null, 30, null, 'centroboa contro difensore, conquista della posizione', 'C1', 'pallanuoto tecnico-tattico', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-061', 'pallanuoto',
    'Attacco', 'Tattica', 'TT',
    'Superiorità 6vs5 (4-2)', '10'' schema di superiorità 4-2 [TT] (Palloni, Porte)', null,
    'Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'schema di superiorità 4-2', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-062', 'pallanuoto',
    'Attacco', 'Tattica', 'TT',
    'Superiorità 6vs5 (3-3)', '10'' schema di superiorità 3-3 [TT] (Palloni, Porte)', null,
    'Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'schema di superiorità 3-3', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-063', 'pallanuoto',
    'Attacco', 'Tattica', 'TT',
    'Contropiede 2vs1', '10'' due attaccanti contro un difensore fino al tiro [TT] (Palloni, Porte)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'due attaccanti contro un difensore fino al tiro', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-064', 'pallanuoto',
    'Attacco', 'Tattica', 'TT',
    'Contropiede 3vs2', '10'' tre attaccanti contro due difensori [TT] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'tre attaccanti contro due difensori', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-065', 'pallanuoto',
    'Partita a tema', 'Tattica', 'TT',
    'Partitella metà campo 4vs4', '15'' partitella a metà campo [TT] (Palloni, Porte)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni, Porte', 0,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 900, null, 'partitella a metà campo', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-066', 'pallanuoto',
    'Partita a tema', 'Tattica', 'TT',
    'Partita: solo passaggi asciutti', '15'' vietati i passaggi bagnati [TT] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 900, null, 'vietati i passaggi bagnati', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-067', 'pallanuoto',
    'Partita a tema', 'Tattica', 'TT',
    'Partita: max 3 passaggi', '15'' tiro obbligatorio entro 3 passaggi [TT] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 900, null, 'tiro obbligatorio entro 3 passaggi', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-068', 'pallanuoto',
    'Partita a tema', 'Tattica', 'TT',
    'Partita: gol doppio in contropiede', '15'' i gol in contropiede valgono doppio [TT] (Palloni, Porte)', null,
    'Under 14, Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    15, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 900, null, 'i gol in contropiede valgono doppio', 'TT', 'pallanuoto tecnico-tattico', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-069', 'pallanuoto',
    'Partita a tema', 'Tattica', 'TT',
    'Partita simulata 4x6''', '4x6'' partita con regole ufficiali [TT] rec 2'' (Palloni, Porte)', null,
    'Under 16, Under 18, Senior', 'Palloni, Porte', 0,
    32, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 4, null, 360, null, 'partita con regole ufficiali', 'TT', 'pallanuoto tecnico-tattico', 120, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-070', 'pallanuoto',
    'Partita a tema', 'Tattica', 'TT',
    'Partita Under 12', '2x8'' partita libera con regole semplificate [TT] rec 2'' (Palloni, Porte)', null,
    'Under 12', 'Palloni, Porte', 0,
    20, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 2, null, 480, null, 'partita libera con regole semplificate', 'TT', 'pallanuoto tecnico-tattico', 120, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-071', 'pallanuoto',
    'Condizionamento', 'Velocità', 'V',
    '10x15 m sprint + gambe alte', '10x15 SL testa alta sprint e 10" di gambe con braccia fuori [V] rec 30"', 'Testa alta',
    'Under 14, Under 16, Under 18, Senior', null, 150,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 15, null, 'Testa alta', 'sprint e 10" di gambe con braccia fuori', 'V', 'gambe', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-072', 'pallanuoto',
    'Condizionamento', 'VO2max', 'B2',
    'Circuito in acqua 6 stazioni', '6x1'' stazioni: sprint, gambe con peso, lotta, tiri, salti, dorso polo [B2] rec 20" (Palloni, Peso/cintura zavorrata)', null,
    'Under 16, Under 18, Senior', 'Palloni, Peso/cintura zavorrata', 0,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, null, 60, null, 'stazioni: sprint, gambe con peso, lotta, tiri, salti, dorso polo', 'B2', 'gambe', 20, 'Palloni, Peso/cintura zavorrata', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-073', 'pallanuoto',
    'Condizionamento', 'Soglia', 'B1',
    '8x100 testa alta', '8x100 SL testa alta ritmo soglia [B1] rec 20"', 'Testa alta',
    'Under 16, Under 18, Senior', null, 800,
    17, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 8, 100, null, 'Testa alta', 'ritmo soglia', 'B1', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-074', 'pallanuoto',
    'Condizionamento', 'Lattacido', 'C1',
    '6x50 testa alta tolleranza', '6x50 SL testa alta forte [C1] rec 1''', 'Testa alta',
    'Under 16, Under 18, Senior', null, 300,
    12, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 6, 50, null, 'Testa alta', 'forte', 'C1', 'nuoto', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-075', 'pallanuoto',
    'Condizionamento', 'VO2max', 'B2',
    'Intermittente 30"-30"', '10x30" nuoto forte [B2] rec 30"', 'Testa alta',
    'Under 14, Under 16, Under 18, Senior', null, 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, null, 30, 'Testa alta', 'nuoto forte', 'B2', 'nuoto', 30, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-076', 'pallanuoto',
    'Defaticamento', 'Recupero', 'A1',
    '200 sciolto + allungamento', '200 scelta sciolto [A1] + 5'' allungamento in acqua [A1]', 'A scelta',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 200,
    9, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 200, null, 'A scelta', 'sciolto', 'A1', 'nuoto', null, null, null from b
union all select id, '00000000-0000-0000-0000-000000000001', 2, 1, 1, null, 300, null, 'allungamento in acqua', 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-077', 'pallanuoto',
    'Defaticamento', 'Recupero', 'A1',
    '300 misto facile', '300 MX molto facile [A1]', 'Misti',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 300,
    6, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 300, null, 'Misti', 'molto facile', 'A1', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-078', 'pallanuoto',
    'Test', 'Test', 'TEST',
    'Test sprint 15 m', '3x15 SL testa alta dalla verticale, vale il migliore [TEST] rec 2''', 'Testa alta',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 45,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, 15, null, 'Testa alta', 'dalla verticale, vale il migliore', 'TEST', 'nuoto', 120, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-079', 'pallanuoto',
    'Test', 'Test', 'TEST',
    'Test 400 SL', '400 SL massimale [TEST]', 'Stile libero',
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', null, 400,
    7, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, 400, null, 'Stile libero', 'massimale', 'TEST', 'nuoto', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-080', 'pallanuoto',
    'Test', 'Test', 'TEST',
    'Test elevazione', '1'' tempo di mantenimento con braccia fuori sopra la testa [TEST]', null,
    'Under 14, Under 16, Under 18, Senior', null, 0,
    1, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 60, null, 'tempo di mantenimento con braccia fuori sopra la testa', 'TEST', 'braccia', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-081', 'pallanuoto',
    'Test', 'Test', 'TEST',
    'Test sprint ripetuti 10x25', '10x25 SL testa alta registra tutti i tempi (calo di prestazione) [TEST] rec 20"', 'Testa alta',
    'Under 16, Under 18, Senior', null, 250,
    8, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 10, 25, null, 'Testa alta', 'registra tutti i tempi (calo di prestazione)', 'TEST', 'nuoto', 20, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'P-082', 'pallanuoto',
    'Test', 'Test', 'TEST',
    'Test precisione tiro', '5'' 10 tiri nei 4 angoli, conta i centri [TEST] (Palloni, Porte)', null,
    'Under 12, Under 14, Under 16, Under 18, Senior, Master', 'Palloni, Porte', 0,
    5, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 300, null, '10 tiri nei 4 angoli, conta i centri', 'TEST', 'nuoto', null, 'Palloni, Porte', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'S-001', 'entrambi',
    'A secco', 'Attivazione', 'T',
    'Attivazione spalle con elastici', '10'' rotazioni interne/esterne, tirate, Y-T-W [T] (Elastici)', null,
    'Tutti i livelli', 'Elastici', 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'rotazioni interne/esterne, tirate, Y-T-W', 'T', 'tecnica', null, 'Elastici', null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'S-002', 'entrambi',
    'A secco', 'Recupero', 'A1',
    'Mobilità generale', '10'' mobilità di spalle, anche, caviglie e colonna [A1]', null,
    'Tutti i livelli', null, 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'mobilità di spalle, anche, caviglie e colonna', 'A1', 'a secco', null, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'S-003', 'entrambi',
    'A secco', 'Forza', 'B1',
    'Core stability', '3x5'' plank, plank laterale, dead bug, superman [B1] rec 1''', null,
    'Tutti i livelli', null, 0,
    18, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, null, 300, null, 'plank, plank laterale, dead bug, superman', 'B1', 'a secco', 60, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'S-004', 'entrambi',
    'A secco', 'Forza', 'B2',
    'Circuito a corpo libero', '3x8'' squat, affondi, piegamenti, trazioni assistite, salti [B2] rec 1''30"', null,
    'Tutti i livelli', null, 0,
    29, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 3, null, 480, null, 'squat, affondi, piegamenti, trazioni assistite, salti', 'B2', 'a secco', 90, null, null from b
;


with b as (
  insert into public.training_blocks (
    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,
    descrizione, stile_principale, livelli, attrezzi, metri_totali,
    durata_stimata_min, note, stato, fonte, importato_il
  )
  values (
    '00000000-0000-0000-0000-000000000001', 'S-005', 'entrambi',
    'A secco', 'Recupero', 'A1',
    'Allungamento finale', '10'' allungamento statico dei principali gruppi [A1]', null,
    'Tutti i livelli', null, 0,
    10, null, 'approvato',
    'Libreria base', now()
  )
  returning id
)
insert into public.training_block_parti (
  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,
  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note
)
select id, '00000000-0000-0000-0000-000000000001', 1, 1, 1, null, 600, null, 'allungamento statico dei principali gruppi', 'A1', 'a secco', null, null, null from b
;


