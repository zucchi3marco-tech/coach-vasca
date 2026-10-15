# Cose da fare (le fa solo il coach)

Lista dei passi che dall'app non si possono fare: pannelli esterni, password, acquisti, il telefono. Si spunta quando è fatto.

## 1. Email con il codice (dopo l'unione del ramo "fase 2" con main)

Serve solo quando il lavoro della proposta 11 sarà pubblicato. Prima, non toccare "Confirm email".

- [ ] Comprare un dominio (es. `watertactics.it`).
- [ ] Resend → **Domains** → **Add Domain**, poi i record DNS che mostra, dal pannello di chi vende il dominio.
- [ ] Resend → **API Keys** → **Create API Key** (Sending access). La chiave la scrivi tu su Supabase, non a me.
- [ ] Supabase → **Authentication** → **SMTP Settings**: host `smtp.resend.com`, porta `465`, utente `resend`, password la chiave di Resend, mittente `noreply@` il tuo dominio, nome `WaterTactics`.
- [ ] Supabase → **Authentication** → **Email Templates**: "Confirm signup" e "Reset password" in italiano, con il codice `{{ .Token }}` e senza link.
- [ ] Supabase → **Authentication** → **Sign In / Providers** → **Email**: accendere "Confirm email", lunghezza del codice 6, scadenza 3600.

## 2. Privacy

- [ ] Far rivedere a un consulente privacy esterno cosa l'app raccoglie (atleti minorenni, dati di benessere e dolori) prima di aprirla a un altro club.

## 3. Login con Google

Il pulsante c'è già; senza questi passi non funziona.

- [ ] Google Cloud Console: credenziali OAuth 2.0 per un'app web, con l'URL di callback che Supabase mostra in Authentication → Providers → Google.
- [ ] Supabase → Authentication → Providers → **Google**: attivarlo e incollare client ID e secret.
- [ ] Supabase → Authentication → **URL Configuration** → Redirect URLs: aggiungere `io.supabase.coachvasca://login-callback/`.

## 4. AI sul telefono (in pausa)

- [ ] Accettare le licenze Android: `flutter doctor --android-licenses`, rispondere `y`.
- [ ] Sul telefono: Opzioni sviluppatore (tocca 7 volte "Numero build") e Debug USB; collegare il cavo e toccare "Consenti".
- [ ] Creare la chiave di firma (il comando è nel piano "AI locale") e salvare file e password in due posti fuori dal PC. La password non va scritta a me.
- [ ] Scrivere 20 frasi vere per "Scrivi il tuo allenamento".
