# Backup e anti-pausa del database

## Automatico (GitHub Actions)

Il file `.github/workflows/manutenzione.yml` fa due cose da solo:

- **Anti-pausa** (lunedi e giovedi): il piano gratuito di Supabase mette il
  progetto in pausa dopo 7 giorni senza attivita. Il lavoro fa una richiesta
  al database e, se non risponde, GitHub ti manda una email di errore.
- **Backup** (ogni domenica notte): salva le tabelle dell'app **e gli
  account** (`auth.users`, senza i quali un ripristino perde i login), lo
  cifra e lo conserva su GitHub per 90 giorni.

### Setup una tantum: 4 segreti

Su GitHub apri il repository, poi **Settings → Secrets and variables →
Actions → New repository secret**, e crea questi quattro (nome esatto):

| Nome | Valore |
| --- | --- |
| `SUPABASE_URL` | l'indirizzo del progetto, `https://kinkwzciqtegtblieash.supabase.co` |
| `SUPABASE_ANON_KEY` | la stessa chiave `anon` che hai messo in Vercel (Supabase: Project Settings → API Keys) |
| `SUPABASE_DB_URL` | Supabase: pulsante **Connect** in alto → **Session pooler** → copia l'URI e sostituisci `[YOUR-PASSWORD]` con la password del database. Deve essere il *Session pooler*, non la connessione diretta: GitHub non raggiunge quella diretta |
| `BACKUP_PASSPHRASE` | una frase lunga e casuale inventata da te. **Salvala nel tuo gestore di password**: senza, i backup non si aprono piu |

Poi provalo: **Actions → Manutenzione → Run workflow → tutto → Run
workflow**. Dopo un paio di minuti i due lavori devono essere verdi. Nel
backup, in fondo alla pagina del lavoro, compare l'allegato `backup-…`.

### Scaricare e aprire un backup

1. GitHub → **Actions → Manutenzione** → clicca l'esecuzione che vuoi → in
   fondo, sezione **Artifacts**, scarica `backup-…` (e un file zip).
2. Estrailo: dentro c'e `coach-vasca_….tar.gz.gpg`.
3. In Git Bash, nella cartella del file:

```
gpg --decrypt coach-vasca_AAAAMMGG_HHMMSS.tar.gz.gpg > backup.tar.gz
tar xzf backup.tar.gz
```

(ti chiede la passphrase). Nella cartella `backup/` trovi due file `.sql`:
le tabelle dell'app e gli account. Non metterli mai in una cartella del
repository (dati di minori).

Se una domenica il backup fallisce, GitHub ti scrive una email. Se cambi la
password del database, aggiorna `SUPABASE_DB_URL`.

## Manuale dal PC (in aggiunta)

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

Gli account stanno nell'altro file del backup automatico
(`coach-vasca_auth_….sql`): importalo **prima**, sul nuovo progetto,
perche le tabelle dell'app puntano agli utenti (`auth.users`). Il backup
manuale con `backup_db.ps1` non li contiene.

Da fare con attenzione: se alcune tabelle sono già popolate (es. da
trigger di setup), l'import può dare errori di chiave duplicata su quelle
righe — in tal caso importa manualmente solo le tabelle mancanti.
