-- ============================================================
-- RIPROGETTAZIONE AI, FASE 3: "importanza" (bassa/media/alta, default
-- media) su gare e partite — lo scarico pre-gara del generatore
-- settimanale scatta solo per le "alta". Impostabile dallo stesso form
-- dove oggi si crea una gara/partita, nessun impatto su quelle gia'
-- esistenti (restano "media").
-- ============================================================

alter table public.gare
  add column importanza text not null default 'media'
  check (importanza in ('bassa', 'media', 'alta'));

alter table public.partite
  add column importanza text not null default 'media'
  check (importanza in ('bassa', 'media', 'alta'));
