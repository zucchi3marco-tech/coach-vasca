#!/usr/bin/env bash
# Build della versione web per Vercel: scarica Flutter (non preinstallato
# nell'ambiente di build di Vercel), scrive .env dalle Environment
# Variables del progetto Vercel (SUPABASE_URL/SUPABASE_ANON_KEY, mai
# committate) e compila. Non toccare nulla di questo file dall'app: e'
# usato solo da Vercel, il flusso di sviluppo locale resta invariato.
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --enable-web --no-analytics
flutter pub get

: "${SUPABASE_URL:?Imposta SUPABASE_URL nelle Environment Variables del progetto Vercel}"
: "${SUPABASE_ANON_KEY:?Imposta SUPABASE_ANON_KEY nelle Environment Variables del progetto Vercel}"

cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
EOF

# La versione che l'app mostra in "Novità" e allega alle segnalazioni: il
# giorno della build (ora italiana) e il commit (Vercel lo da' in
# VERCEL_GIT_COMMIT_SHA; se manca, quello del clone).
VERSIONE_COMMIT="${VERCEL_GIT_COMMIT_SHA:-$(git rev-parse HEAD 2>/dev/null || true)}"
VERSIONE_DATA="$(TZ=Europe/Rome date +%Y-%m-%d)"

flutter build web --release \
  --dart-define=VERSIONE_COMMIT="${VERSIONE_COMMIT:0:7}" \
  --dart-define=VERSIONE_DATA="${VERSIONE_DATA}"
