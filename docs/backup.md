# Backup manuale del database

Il piano Free di Supabase non offre un modo semplice per scaricare in
autonomia i backup automatici né il point-in-time recovery. Questo backup
manuale è una rete di sicurezza aggiuntiva: da fare prima di migrazioni
rischiose e periodicamente durante l'uso reale (es. una volta al mese).

## 1. Setup una tantum: installare pg_dump

Su Windows:

```
winget install PostgreSQL.PostgreSQL.17
```

(oppure scarica l'installer da postgresql.org e, durante l'installazione,
seleziona solo il componente "Command Line Tools" — non serve installare
il server PostgreSQL).

Apri un nuovo terminale (per aggiornare il PATH) e verifica:

```
pg_dump --version
```

## 2. Recuperare la connection string

Nella Dashboard Supabase: **Project Settings → Database → Connection
string**, scegli formato **URI**, modalità **Session** (porta `5432`, non
la modalità "Transaction"/pooler sulla porta `6543`: pg_dump richiede la
connessione diretta).

Sostituisci `[YOUR-PASSWORD]` con la password del database (quella
impostata alla creazione del progetto, non le chiavi `anon`/`service_role`).

Impostala come variabile d'ambiente solo per la sessione corrente del
terminale — **non salvarla mai in un file del repository**:

```
$env:SUPABASE_DB_URL = "postgresql://postgres:LA-TUA-PASSWORD@db.xxxxxxxx.supabase.co:5432/postgres"
```

## 3. Eseguire il backup

Dalla cartella del progetto:

```
.\scripts\backup_db.ps1
```

Crea un file `backups/coach-vasca_AAAAMMGG_HHMMSS.sql` (la cartella
`backups/` è esclusa da git: contiene dati personali di atleti e genitori
e non va mai committata).

## 4. Dove conservarlo

Sposta il file su un drive esterno o cloud personale (es. Google Drive),
non lasciarlo solo sul PC. Se contiene dati sensibili di minori, valuta di
conservarlo in una cartella cifrata.

## 5. Come ripristinare (solo in caso di emergenza)

1. Crea un nuovo progetto Supabase.
2. Applica le migrazioni in `supabase/migrations/` come al solito (stesso
   procedimento della prima configurazione).
3. Importa i dati con:

```
psql $env:SUPABASE_DB_URL -f backups\coach-vasca_AAAAMMGG_HHMMSS.sql
```

Da fare con attenzione: se alcune tabelle sono già popolate (es. da
trigger di setup), l'import può dare errori di chiave duplicata su quelle
righe — in tal caso importa manualmente solo le tabelle mancanti.
