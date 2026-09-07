-- ============================================================
-- TIRO AVVERSARIO (Fase 9, campo live): il pulsante "Tiro avversario"
-- registra un tiro subito senza sapere quale giocatore avversario lo ha
-- calciato (un click = gol, doppio click = non gol) — tipo='tiro',
-- squadra='avversaria', nessun atleta_id ne' numero di calottina.
-- ============================================================

alter table public.eventi_partita drop constraint if exists eventi_partita_check;

alter table public.eventi_partita add constraint eventi_partita_check check (
  (tipo = 'tiro' and squadra = 'nostra' and atleta_id is not null and numero_calottina_avversario is null)
  or (tipo = 'tiro' and squadra = 'avversaria' and atleta_id is null and numero_calottina_avversario is null)
  or (tipo = 'espulsione' and (
        (atleta_id is not null and numero_calottina_avversario is null)
        or (atleta_id is null and numero_calottina_avversario is not null)
      ))
  or (tipo = 'superiorita' and atleta_id is null and numero_calottina_avversario is null)
);
