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

flutter build web --release
