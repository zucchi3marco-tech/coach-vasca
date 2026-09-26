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

## Notifiche push (Web Push)

Oltre alla campanella, le notifiche arrivano sul telefono ad app chiusa.
Pezzi: tabella `push_subscriptions` e colonne nuove di `notifiche`
(migrazione `20260926000100_notifiche_push.sql`), Edge Function
`invia-push`, service worker `web/push/sw.js`, chiave pubblica in
`lib/core/push/vapid.dart`.

Setup una tantum:

1. **Migrazione**: incolla `migrations/20260926000100_notifiche_push.sql`
   nel SQL Editor ed eseguila.
2. **Chiavi VAPID**: nel terminale `npx web-push generate-vapid-keys`.
   Danno una chiave pubblica e una privata. La privata non va mai nel
   repository.
3. **Segreti**: Supabase → Edge Functions → Secrets → aggiungi
   `VAPID_PUBLIC_KEY` (la pubblica), `VAPID_PRIVATE_KEY` (la privata) e
   `VAPID_SUBJECT` (un indirizzo `https://` o `mailto:` di contatto).
4. **Chiave pubblica nel codice**: incollala in `lib/core/push/vapid.dart`.
5. **Deploy**: `supabase functions deploy invia-push --project-ref <ref>`.
6. **Database Webhook**: Supabase → Database → Webhooks → Create a new
   hook: nome `notifiche_push`, tabella `public.notifiche`, evento
   **Insert**, tipo **Supabase Edge Functions**, funzione `invia-push`,
   metodo POST. (Non si puo' mettere in una migrazione senza incorporare la
   chiave di servizio.)
7. **Prova**: sul telefono apri l'app → menu ☰ → "Attiva le notifiche sul
   telefono" → consenti. Poi dal SQL Editor:
   ```sql
   insert into public.notifiche (club_id, tipo, messaggio)
   select id, 'atleta_registrato', 'Prova notifica push' from public.club limit 1;
   ```
   Deve comparire la notifica sul telefono.

Su iPhone/iPad il push funziona solo con l'app aggiunta alla Home da Safari
(iOS 16.4 o successivo).
