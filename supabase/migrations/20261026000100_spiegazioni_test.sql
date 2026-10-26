-- ============================================================
-- SPIEGAZIONI DEI TEST (2026-10-26): ogni test ha la sua scheda "come si
-- fa" (a cosa serve, cosa serve, come si fa, come si misura, errori da
-- evitare), che l'allenatore può cambiare.
--
-- 1. La descrizione di un test del club diventa la spiegazione: fino a
--    4000 caratteri invece di 500.
-- 2. I test di nuoto BVS e T30 non sono test del club (sono tipi fissi
--    di `test_ingresso`): la loro spiegazione, se l'allenatore la cambia,
--    sta in `spiegazioni_test`, una riga per club e tipo. Senza riga
--    l'app mostra quella originale.
-- ============================================================

alter table public.test_club drop constraint if exists test_club_descrizione_check;
alter table public.test_club add constraint test_club_descrizione_check check (
  descrizione is null or length(descrizione) <= 4000
);

create table if not exists public.spiegazioni_test (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.club(id) on delete cascade,
  tipo text not null check (tipo in ('BVS', 'T30')),
  testo text not null check (length(trim(testo)) between 1 and 4000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (club_id, tipo)
);

drop trigger if exists trg_spiegazioni_test_updated_at on public.spiegazioni_test;
create trigger trg_spiegazioni_test_updated_at
before update on public.spiegazioni_test
for each row execute function public.set_updated_at();

alter table public.spiegazioni_test enable row level security;

-- La leggono allenatori e atleti del club; la scrivono gli allenatori.
drop policy if exists spiegazioni_test_select on public.spiegazioni_test;
create policy spiegazioni_test_select on public.spiegazioni_test
  for select using (
    public.is_membro_club(club_id) or club_id = public.mio_club_atleta()
  );

drop policy if exists spiegazioni_test_insert on public.spiegazioni_test;
create policy spiegazioni_test_insert on public.spiegazioni_test
  for insert with check (public.is_membro_club(club_id));

drop policy if exists spiegazioni_test_update on public.spiegazioni_test;
create policy spiegazioni_test_update on public.spiegazioni_test
  for update using (public.is_membro_club(club_id))
  with check (public.is_membro_club(club_id));

drop policy if exists spiegazioni_test_delete on public.spiegazioni_test;
create policy spiegazioni_test_delete on public.spiegazioni_test
  for delete using (public.is_membro_club(club_id));
