# Schema database — SwimCoach FIN

Migrazioni SQL in `migrations/`, pensate per Supabase CLI (`supabase db push`)
o per essere incollate in ordine nel SQL Editor del progetto Supabase.

## Come applicarle

1. Crea il progetto Supabase in region **EU (Frankfurt)** (FASE 0).
2. Se usi la CLI:
   ```
   supabase init        # se non gia' fatto in questa cartella
   supabase link --project-ref <ref-del-progetto>
   supabase db push
   ```
3. In alternativa, incolla i file di `migrations/` nel SQL Editor, **in ordine
   di nome file** (i timestamp nel nome garantiscono l'ordine corretto).

## Struttura

- `club`, `club_membri` — radice multi-tenant. Un club puo' avere piu'
  coach/collaboratori (ruoli `owner`/`coach`/`assistente`). Chi crea un club
  ne diventa automaticamente `owner`.
- `atleti` — anagrafica atleti, con campi di consenso privacy (dato che sono
  spesso minorenni).
- `gruppi` — gruppi di allenamento del club, referenziati da `atleti`,
  `allenamenti`, `stagioni` e `codici_gruppo` (`gruppo_id`).
- `test_ingresso`, `tabelle_passi` — test BVS/T30 e le zone di passo (A1, A2,
  B1, B2, C, D) derivate da ciascun test.
- `stagioni` → `macrocicli` → `mesocicli` → `microcicli` — gerarchia di
  programmazione della stagione.
- `allenamenti` → `serie`, e `presenze` — la scheda di un allenamento e le
  presenze degli atleti a quella sessione.

## Isolamento per club (RLS)

Ogni tabella applicativa ha una colonna `club_id` e la Row Level Security e'
**attiva su tutte le tabelle**. L'accesso e' concesso solo a chi risulta
membro del club tramite le funzioni helper `is_membro_club()` /
`is_owner_club()` (definite in `20260829000400_club_e_membri.sql`), che
interrogano `club_membri`.

Per le tabelle "figlie" (es. `test_ingresso`, `serie`, `presenze`, l'intera
gerarchia di stagione) `club_id` **non viene mai preso per buono dal
client**: un trigger `BEFORE INSERT/UPDATE` lo ricalcola sempre a partire dal
genitore (atleta, test, allenamento, ecc.). Questo evita che un client possa
scrivere una riga con un `club_id` diverso da quello reale, anche in caso di
bug applicativo — l'isolamento tra club dipende comunque, in ultima analisi,
solo dalla RLS.

## Cosa manca ancora (fuori da questa migrazione)

- Policy piu' granulari per ruolo (es. `assistente` in sola lettura) — per
  ora chiunque sia membro del club ha CRUD completo sui dati applicativi;
  solo la gestione di `club` e `club_membri` e' riservata all'`owner`.
- Vincoli di coerenza date tra stagione/macro/meso/micro (es. un microciclo
  interamente contenuto nel suo mesociclo) — lasciati alla validazione
  applicativa in V1.
