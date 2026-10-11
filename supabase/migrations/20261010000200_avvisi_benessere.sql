-- ============================================================
-- AVVISI DEL BENESSERE (analisi "Il Mako della pallanuoto", fase 1):
-- quando un atleta salva una scheda benessere "da sentire" (semaforo
-- rosso) o molto sotto il suo solito, gli allenatori del club ricevono
-- una notifica nella campanella e sul telefono.
--
-- Sta nel database e non nell'app perche' la scheda puo' arrivare dalla
-- coda offline del telefono dell'atleta: il trigger scatta comunque. Il
-- punteggio e' lo stesso di `calcolaPunteggio` nell'app
-- (lib/features/benessere/domain/scheda_benessere.dart): se cambiano le
-- regole li', vanno cambiate anche qui.
--
-- Il messaggio non dice il motivo (dolore, febbre...): la notifica
-- compare anche a schermo bloccato. Il dettaglio si legge nell'app.
-- ============================================================

alter table public.notifiche drop constraint notifiche_tipo_check;
alter table public.notifiche add constraint notifiche_tipo_check check (
  tipo in (
    'atleta_registrato',
    'convocazione_gara',
    'convocazione_partita',
    'visita_medica',
    'benessere'
  )
);

-- Prontezza 0-100 di una scheda e se c'e' un motivo critico (dolore da
-- 7/10, febbre, meno di 5 ore di sonno, una voce al minimo), senza il
-- confronto con lo storico.
create or replace function public.prontezza_scheda_benessere(
  s public.schede_benessere,
  p_nascita date
) returns table (valore integer, critico boolean)
language plpgsql
stable
set search_path = public
as $$
declare
  v_voci integer[] := array_remove(
    array[s.qualita_sonno, s.energia, s.muscoli, s.stress, s.umore]::integer[],
    null
  );
  v_valore numeric;
  v_critico boolean := false;
  v_obiettivo numeric;
  v_intensita integer;
  v_sintomo text;
begin
  if cardinality(v_voci) > 0 then
    v_valore := round((select avg(v * 20) from unnest(v_voci) v));
    v_critico := 1 = any(v_voci);
  else
    v_valore := 80;
  end if;

  -- 8 ore sotto i 18 anni (o senza data di nascita), 7 da adulti.
  v_obiettivo := case
    when p_nascita is not null and age(s.data, p_nascita) >= interval '18 years'
      then 7
    else 8
  end;
  if s.ore_sonno < v_obiettivo then
    v_valore := v_valore
      - least(25, ceil((v_obiettivo - s.ore_sonno) / 0.5) * 5);
    v_critico := v_critico or s.ore_sonno < 5;
  end if;

  if s.dolori then
    v_intensita := coalesce(s.intensita_dolore, 5);
    v_valore := v_valore - round(
      v_intensita * 3 * (case when 'spalla' = any(s.zone_dolore) then 1.2 else 1 end)
    );
    v_critico := v_critico or v_intensita >= 7;
  end if;

  foreach v_sintomo in array s.sintomi loop
    v_valore := v_valore - (case when v_sintomo = 'febbre' then 30 else 10 end);
    v_critico := v_critico or v_sintomo = 'febbre';
  end loop;

  valore := greatest(0, least(100, round(v_valore)))::integer;
  critico := v_critico;
  return next;
end;
$$;

create or replace function public.avvisa_benessere()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nome text;
  v_cognome text;
  v_nascita date;
  v_valore integer;
  v_critico boolean;
  v_livello integer;
  v_precedenti integer[];
  v_media numeric;
  v_ds numeric;
  v_sotto boolean := false;
begin
  -- Solo le schede di oggi o di ieri: una correzione vecchia non avvisa.
  if new.data < (now() at time zone 'Europe/Rome')::date - 1 then
    return new;
  end if;

  select nome, cognome, data_nascita into v_nome, v_cognome, v_nascita
    from public.atleti where id = new.atleta_id;

  select p.valore, p.critico into v_valore, v_critico
    from public.prontezza_scheda_benessere(new, v_nascita) p;
  v_livello := case when v_valore >= 60 then 0 when v_valore >= 40 then 1 else 2 end;
  if v_critico then
    v_livello := 2;
  end if;

  -- Il suo solito: le schede delle 4 settimane prima, se sono almeno 5.
  select array_agg(p.valore) into v_precedenti
    from public.schede_benessere x
    cross join lateral public.prontezza_scheda_benessere(x, v_nascita) p
    where x.atleta_id = new.atleta_id
      and x.data < new.data
      and x.data >= new.data - 28;
  if cardinality(v_precedenti) >= 5 then
    select avg(v), stddev_pop(v) into v_media, v_ds from unnest(v_precedenti) v;
    if v_valore - v_media <= -10 and v_valore - v_media < -1.5 * greatest(v_ds, 4) then
      v_sotto := true;
      v_livello := least(2, v_livello + 1);
    end if;
  end if;

  if v_livello < 2 and not v_sotto then
    return new;
  end if;

  insert into public.notifiche (club_id, tipo, messaggio, atleta_id, chiave)
  values (
    new.club_id,
    'benessere',
    case
      when v_livello = 2 then format(
        '%s %s è da sentire prima di entrare in acqua: guarda la sua scheda benessere.',
        v_nome, v_cognome
      )
      else format(
        '%s %s ha una scheda benessere molto sotto il suo solito.',
        v_nome, v_cognome
      )
    end,
    new.atleta_id,
    'benessere:' || new.id
  )
  on conflict (chiave) do nothing;
  return new;
end;
$$;

create trigger trg_schede_benessere_avviso
after insert or update on public.schede_benessere
for each row execute function public.avvisa_benessere();
