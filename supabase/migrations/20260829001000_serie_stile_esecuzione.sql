-- ============================================================
-- SERIE: aggiunge stile, esecuzione e ripartenza (interval).
--
-- Permette di distinguere, per ogni serie:
-- - lo stile (libero/dorso/rana/delfino/misti)
-- - l'esecuzione (nuoto completo/gambe/braccia/pull/tecnica)
-- - la ripartenza (interval: "riparti ogni X"), distinta dal
--   recupero_s gia' esistente (riposo fisso dopo ogni ripetuta)
--
-- Dati necessari per costruire in futuro un report per atleta sui
-- volumi per stile/esecuzione/zona nel tempo.
-- ============================================================

create type public.stile_nuoto as enum ('libero', 'dorso', 'rana', 'delfino', 'misti');

create type public.esecuzione_serie as enum ('nuoto', 'gambe', 'braccia', 'pull', 'tecnica');

alter table public.serie
  add column stile public.stile_nuoto not null default 'libero',
  add column esecuzione public.esecuzione_serie not null default 'nuoto',
  add column ripartenza_s numeric(6, 2) check (ripartenza_s >= 0);
