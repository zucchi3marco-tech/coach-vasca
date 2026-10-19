# Cose da fare (le fa solo il coach)

Lista dei passi che dall'app non si possono fare: pannelli esterni, password, acquisti, il telefono. Si spunta quando è fatto.

## 0. Il club, il calendario e la configurazione guidata (pubblicati il 2026-10-18)

- [ ] Menu ☰ → **Il mio club** → **Scrivi il nome**: lo vedono gli altri quando modifichi un allenamento.
- [ ] Sempre in "Il mio club" → **Capi allenatori**: tocca ogni squadra e scegli il capo (per ora tu).
- [ ] Per ogni allenatore o assistente: **Invita un allenatore** → Allenatore o Assistente → **Condividi** il codice. Lui si registra come allenatore e in "Crea il tuo club" tocca **Ho un codice da allenatore**.
- [ ] Menu ☰ → **Partite nel calendario** → collegalo sul tuo telefono. Con Android e Google Calendar: **Condividi l'indirizzo** e mandatelo; dal computer **calendar.google.com** → accanto ad **Altri calendari** il **+** → **Da URL** → incolla → **Aggiungi calendario**; poi sul telefono app Google Calendar → **☰** → **Impostazioni** → **Partite · Canottieri Milano** → accendi **Sincronizzazione**. Torna nella pagina: in cima deve dire **Collegato: l'ha letto Google Calendar…**.
- [ ] Dal computer: menu ☰ → **Il mio club** → in fondo **Scarica i dati del club** → **Scarica il file Excel**. Apri il file in Excel e guarda "Leggimi", "Atleti" e "Presenze": dimmi se manca qualcosa o se una colonna non si capisce.
- [ ] In **Oggi** guarda la scheda **Per cominciare**: le spunte devono corrispondere a quello che hai già fatto. Tocca un passo da fare e prova i passi fino a **Fine**; oppure menu ☰ → **Il mio club** → **Configurazione guidata**. Se alleni da solo, tocca **Alleno da solo**; se la scheda non ti serve, **Nascondi**.

## 0bis. Scrivimi, Novità e la guida (pubblicati il 2026-10-19)

- [ ] Alla prima apertura parte la guida nuova: scorrila e guarda che dietro cambia la scheda. La rivedi da menu ☰ → **Rivedi la guida**.
- [ ] Prova **Scrivimi**: apri una pagina qualsiasi (per esempio un allenamento), poi menu ☰ → **Scrivimi**. Controlla che l'anteprima mostri quella pagina, scrivi «Prova» e tocca **Invia**.
- [ ] Menu ☰ → **Segnalazioni** → tocca la tua prova → scrivi una risposta, accendi **Risolta**, **Salva**. In ☰ → **Scrivimi**, sotto, deve comparire la risposta. (Per le tue segnalazioni non ti arriva la notifica: arriva quando scrive un altro allenatore.)
- [ ] Ogni volta che in vasca o in partita qualcosa non va, usa **Scrivimi** subito, dalla pagina dove è successo.

## 0ter. Il tetto di spesa dell'AI, sui siti dei fornitori

Nell'app l'AI ora ha già un tetto: 30 richieste a settimana a persona e 300 al mese per il club. Questi passi mettono un secondo tetto, in euro, dove si paga: se un giorno qualcosa sfuggisse all'app, la spesa si ferma lo stesso. Con l'uso di oggi (poche richieste al mese) si spende meno di 1 € al mese.

- [ ] **OpenAI** (scrive gli allenamenti e risponde nell'assistente): entra in **platform.openai.com** → in alto a destra l'ingranaggio **Settings** → **Billing**. Se c'è la ricarica automatica (**Auto recharge** o **Auto-reload**), **spegnila**: così non si spende più del credito che hai caricato. Se il credito è sotto i 5 $, **Add to credit balance** → 10 $.
- [ ] Sempre in **Settings** → **Limits** (o, dentro il progetto, **Project** → **Limits**): se c'è un **budget mensile**, mettilo a **10 $** con la tua email per l'avviso. Se c'è anche un limite "duro" (*hard limit*), mettilo a 10 $.
- [ ] **Google Gemini** (legge le foto dei referti e dei tempi): entra in **aistudio.google.com** → **Dashboard** → scheda **Spend** (Spesa). Se la chiave è sul piano gratuito non c'è niente da pagare e niente da fare. Se c'è una fatturazione collegata: **Monthly spend cap** → **Edit spend cap** → **5 $**.

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
