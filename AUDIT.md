# Controllo completo del codice — 2026-09-19

Rapporto di sola lettura: **nessuna correzione è stata applicata**. Ogni punto
qui sotto è una cosa trovata, non ancora sistemata — decidiamo insieme cosa
affrontare e quando.

> **Nota**: esisteva già un controllo precedente, del 12/09/2026
> (`AUDIT_2026-09-12.md`) — quasi tutti i suoi punti sono già stati
> sistemati (commit del 12/09, "Sistema i problemi dell'audit"). Ne resta
> aperto solo uno, il limite di righe nelle query al database, che ritrovi
> anche qui sotto (punto 1.2) perché riguarda ancora file nuovi aggiunti da
> allora. Questo è un controllo da zero sullo stato attuale del codice, non
> una correzione di quello vecchio.

Metodo: `flutter analyze` e `dart fix --dry-run` (strumenti automatici che
controllano tutto il codice in pochi secondi) più una lettura a occhio delle
parti più delicate — gestione degli errori, chiamate al database (Supabase),
regole di sicurezza dei dati (RLS), e punti che potrebbero rallentare l'app
man mano che i dati crescono.

Tutto è ordinato dal più grave al meno grave. Non c'è nessun punto
"bloccante" (cioè: niente che rischi di far crashare l'app o perdere dati in
modo grave e frequente) — il più serio trovato è in categoria "da sistemare
presto".

---

## 1. Da sistemare presto

### 1.1 — Se due dispositivi modificano lo stesso allenamento offline, uno dei due perde le modifiche senza avviso
**Dove**: `lib/core/sync/sync_engine.dart` (tutta la funzione `processQueue`, righe 40-96)
**Gravità**: da sistemare presto

In pratica: se tu e un altro allenatore (o tu su due dispositivi) modificate
lo stesso allenamento mentre siete entrambi offline, quando tornate online
l'app non se ne accorge — vince semplicemente chi si sincronizza per
ultimo, e le modifiche dell'altro vengono sovrascritte senza nessun
messaggio d'avviso. Il controllo del 12/09 aveva già ridotto il danno per
allenamenti/atleti (ora si manda solo il campo davvero cambiato, non tutto
il modulo), ma il meccanismo di fondo — nessun confronto reale tra chi ha
modificato cosa e quando — resta questo per tutte le tabelle. È una scelta
esistente e documentata nel codice, non un errore di distrazione: succede
solo se più persone lavorano sullo stesso club offline nello stesso
momento, oggi un caso raro ma non impossibile.

### 1.2 — Le liste di dati (allenamenti, presenze, atleti, tempi, personal best) si scaricano sempre tutte intere, senza un limite
**Dove**: `lib/features/allenamenti/data/allenamenti_repository.dart:104-107`, `lib/features/presenze/data/presenze_repository.dart:73-92`, `lib/features/atleti/data/atleti_repository.dart:66`, `lib/features/atleti/data/personal_best_repository.dart:79-100`, `lib/features/atleti/data/tempi_gara_repository.dart:75-77` (e, meno urgente, `lib/features/pallanuoto/data/eventi_partita_repository.dart` e `lib/features/pallanuoto/data/partite_repository.dart:77`)
**Gravità**: da sistemare presto (stesso punto già aperto dal 12/09 e ancora in `ROADMAP.md` — qui solo l'elenco aggiornato dei file coinvolti, comprese le tabelle più recenti come `tempi_gara` e `personal_best`)

In pratica: ogni volta che l'app scarica i dati di un club per usarli anche
offline, prende sempre **tutta** la tabella in un colpo, senza un tetto
massimo. Con i numeri di oggi non si nota. Se un club crescesse molto (anni
di storico allenamenti/presenze, centinaia di atleti), il primo
caricamento dopo l'installazione diventerebbe via via più lento. Non è un
fix da un'ora: tocca il modo in cui l'app tiene i dati disponibili offline,
va deciso insieme prima di cambiare qualcosa.

### 1.3 — "Segna come letta" su una notifica può fallire senza che l'allenatore se ne accorga
**Dove**: `lib/features/notifiche/data/notifiche_repository.dart:26-28` e `lib/features/notifiche/presentation/notifiche_screen.dart:26-29`
**Gravità**: da sistemare presto

In pratica: quando tocchi l'icona "segna come letta" su una notifica, se in
quel momento non c'è connessione (o il server risponde con un errore),
l'app non mostra nessun messaggio di errore — sembra aver funzionato ma la
notifica potrebbe restare "non letta" alla prossima apertura. Fastidioso,
non pericoloso: non si perdono dati, nessun'altra parte dell'app fa questo
errore (è l'unico punto rimasto scoperto, lo stesso tipo di problema che il
controllo del 12/09 aveva già corretto altrove — logout, annulla evento —
ma non era ancora arrivato qui).

### 1.4 — Alcune schermate si aggiornano più del necessario
**Dove**: `lib/features/home/home_screen.dart:252-262` (e un doppio controllo dei gruppi già fatto anche alla riga 205) e `lib/features/pallanuoto/presentation/partita_live_screen.dart:319-321`
**Gravità**: da sistemare presto

In pratica: alcune schermate "ascoltano" più dati di quelli che mostrano
davvero, quindi ogni piccola modifica a uno qualsiasi di quei dati fa
ridisegnare tutta la schermata anche se solo un dettaglio è cambiato. Il
caso più sensibile è la schermata "partita dal vivo": ogni singolo
evento segnato (un tiro, un'espulsione) potrebbe far ridisegnare più del
dovuto durante la partita, quando la fluidità conta di più. Con i volumi
attuali non è percepibile: è più un'attenzione da avere se in futuro l'app
sembrasse "a scatti" durante una partita live.

---

## 2. Rifinitura

### 2.1 — Il progetto non ha attivato il controllo automatico di uno spreco comune ("const" mancanti)
**Dove**: `analysis_options.yaml` (tutto il file — manca la riga che attiverebbe questo controllo)
**Gravità**: rifinitura

In pratica: Flutter permette di dire "questo pezzo di schermata non cambia
mai, non ridisegnarlo" (si scrive `const` nel codice). Il progetto non ha
attivato il controllo automatico che segnala dove questo manca, quindi non
possiamo sapere con certezza quanti punti dell'app lo stiano già facendo
bene o no — un controllo a campione su un paio di file grandi ha trovato
codice già scritto bene, ma non è stato controllato ovunque per tempo.
Attivare il controllo è un'operazione di un minuto; sistemare quello che
segnalerebbe è lavoro a parte.

### 2.2 — Il logo viene caricato sempre a piena qualità anche quando è mostrato piccolo
**Dove**: `lib/features/home/home_screen.dart` (dove viene mostrato `assets/images/logo.png` nella barra in alto)
**Gravità**: rifinitura

In pratica: il file del logo (153 KB, dimensione già ragionevole) viene
sempre aperto a piena risoluzione anche quando sullo schermo occupa pochi
centimetri quadrati (l'icona nella barra in alto). Uno spreco piccolissimo
con un solo file di queste dimensioni — da tenere d'occhio solo se in
futuro si aggiungono altre immagini più pesanti.

---

## 3. Controllato, nessun problema trovato

Un controllo completo ha anche lo scopo di dire cosa **va bene**, non solo
cosa non va — ecco cosa è stato verificato a fondo e trovato a posto.

- **Chi può vedere i dati di chi (RLS)** — priorità alta di questo
  controllo: verificate tutte le migrazioni del database (regole che
  decidono chi può leggere/scrivere cosa), comprese quelle più recenti
  aggiunte da settembre. Ogni tabella è correttamente riservata al club di
  appartenenza (per l'allenatore) o al proprio profilo (per l'atleta):
  nessuna tabella è risultata apribile da un club diverso da quello giusto,
  e nessuna delle funzioni "speciali" del database (quelle che a volte
  bypassano i controlli normali per motivi tecnici) si è rivelata usabile
  per leggere dati di un altro club. Anche il problema di privacy tra
  atleti dello stesso club, segnalato nel controllo del 12/09 (un atleta
  poteva leggere le note di allenamenti destinate ad altri compagni), è
  confermato corretto oggi.
- **L'app non crasha per uno schermo chiuso troppo in fretta** — controllato
  ogni punto dell'app dove si aspetta una risposta dal server e poi si
  aggiorna lo schermo: se nel frattempo l'utente ha già chiuso quella
  schermata, l'app se ne accorge sempre correttamente prima di provare ad
  aggiornarla (nessun punto dove questo controllo manca).
- **Nessuna "perdita di memoria" da elementi non richiusi** — controllati
  tutti i punti che aprono una fotocamera, un timer, o un campo di testo:
  vengono sempre richiusi correttamente quando la schermata si chiude.
- **`flutter analyze` e `dart fix`** (i due controlli automatici standard di
  Flutter): **0 problemi** su tutto il codice.
- **Nessun file, importazione o libreria inutilizzata**: controllato
  l'intero progetto, nessun file "orfano" lasciato da versioni precedenti,
  nessuna libreria elencata in `pubspec.yaml` che non viene più usata.
- **I dati non vengono scaricati due volte per sbaglio**: il modo in cui
  l'app tiene una copia locale dei dati (per funzionare anche offline) e la
  aggiorna dal server è applicato in modo uniforme in tutta l'app — non
  sono stati trovati punti che richiamano il server ripetutamente ad ogni
  piccolo aggiornamento dello schermo invece di usare la copia locale già
  pronta.

---

## Prossimo passo

Nessuna correzione è stata fatta. Decidiamo insieme quali dei punti sopra
affrontare (e in che ordine) — nessuno di questi è urgente al punto da
richiedere un intervento immediato.
