# Backup manuale del database Supabase (schema "public": le tabelle
# dell'app, non auth/storage interni). Setup una tantum e procedura
# completa in docs/backup.md.

if (-not $env:SUPABASE_DB_URL) {
    Write-Error "Variabile SUPABASE_DB_URL non impostata. Vedi docs/backup.md."
    exit 1
}

if (-not (Get-Command pg_dump -ErrorAction SilentlyContinue)) {
    Write-Error "pg_dump non trovato nel PATH. Vedi docs/backup.md per installarlo."
    exit 1
}

$backupDir = Join-Path $PSScriptRoot "..\backups"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outFile = Join-Path $backupDir "coach-vasca_$timestamp.sql"

pg_dump $env:SUPABASE_DB_URL --schema=public --no-owner --no-privileges --format=plain --file=$outFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Backup completato: $outFile"
} else {
    Write-Error "pg_dump ha restituito un errore (codice $LASTEXITCODE)."
}
