-- ============================================================
-- SCHEDA BENESSERE, seconda versione: le cinque voci del questionario
-- di McLean et al. (2010) — qualita' del sonno, energia (inverso della
-- fatica), indolenzimento muscolare, stress, umore — su scala 1-5 dove
-- 5 e' sempre "meglio", piu' i sintomi di malattia. Facoltative per le
-- schede gia' esistenti (restano null). Il punteggio "Prontezza" si
-- calcola nell'app da questi campi, non si salva.
-- ============================================================

alter table public.schede_benessere
  add column qualita_sonno smallint check (qualita_sonno between 1 and 5),
  add column energia smallint check (energia between 1 and 5),
  add column muscoli smallint check (muscoli between 1 and 5),
  add column stress smallint check (stress between 1 and 5),
  add column umore smallint check (umore between 1 and 5),
  -- febbre | raffreddore | gola | stomaco | altro
  add column sintomi text[] not null default '{}';
