-- ============================================================
-- PERSONAL BEST: l'allenatore può anche inserire/modificare/eliminare i
-- PB dei propri atleti, non solo vederli come prima (FASE 10) — restava
-- solo la lettura per il coach, la scrittura era riservata all'atleta
-- collegato. L'atleta collegato continua a poter scrivere i propri.
-- ============================================================

drop policy if exists personal_best_insert on public.personal_best;
create policy personal_best_insert on public.personal_best
  for insert with check (
    atleta_id = public.mia_atleta_id() or public.is_membro_club(club_id)
  );

drop policy if exists personal_best_update on public.personal_best;
create policy personal_best_update on public.personal_best
  for update using (
    atleta_id = public.mia_atleta_id() or public.is_membro_club(club_id)
  )
  with check (
    atleta_id = public.mia_atleta_id() or public.is_membro_club(club_id)
  );

drop policy if exists personal_best_delete on public.personal_best;
create policy personal_best_delete on public.personal_best
  for delete using (
    atleta_id = public.mia_atleta_id() or public.is_membro_club(club_id)
  );
