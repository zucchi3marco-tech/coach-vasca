# SwimCoach FIN — Roadmap & Note di Progetto

App di coaching Nuoto + Pallanuoto — Flutter · Supabase · Cursor · Claude Code

## Stack tecnico
- **Flutter** (mobile + web/desktop)
- **Supabase** (region EU/Frankfurt) — database, auth, backend
- **Drift** — database locale per offline-first
- **Riverpod** — state management
- **Cursor** — editor quotidiano
- **Claude Code** — sviluppo assistito da AI per i task più corposi

## Ambiente di sviluppo
- Flutter SDK: `D:\src\flutter`
- Android SDK: `D:\AndroidSdk`
- Cartella progetto: `D:\Dev\coach-vasca`
- Repository GitHub privato: github.com/zucchi3marco-tech/coach-vasca

## Decisioni chiave di sicurezza e privacy
- Gli atleti sono spesso minorenni: serve informativa privacy + consenso di un genitore/tutore alla raccolta dati
- Supabase in region **EU (Frankfurt)** per residenza dati in Europa
- **Row Level Security (RLS) attiva da subito** su ogni tabella (isolamento per club/coach) — senza RLS chiunque abbia la anon key legge i dati di tutti i club
- Solo la **anon key** nell'app; la **service_role key** non deve mai finire nel client
- Chiavi segrete sempre in file `.env`, mai nel codice, mai su Git — `.gitignore` corretto fin dal primo commit
- Repository GitHub **privato**, non pubblico
- Strategia di conflitto per la sync offline: **last-write-wins su campo `updated_at`** + log delle modifiche
- Strategia branch: `main` sempre funzionante + un branch per ogni feature
- ⚠️ **TEMPORANEO**: "Confirm email" disattivato su Supabase Auth (nessun dominio ancora disponibile per un SMTP proprio, il servizio email di default di Supabase ha un rate limit troppo basso per far testare l'app a più persone). Chiunque può registrarsi con un'email non sua, nessuna verifica di possesso. Da **riattivare** insieme a un provider SMTP con dominio verificato (es. Resend) prima di un uso più ampio o pubblico.

## Fuori scope per la V1
Wearable, OCR referti, computer vision, Banister completo, pubblicazione sugli store.

---

## FASE 0 — Preparazione PC ✅ QUASI COMPLETATA
- [x] Git, Cursor, Flutter, Android Studio installati e funzionanti
- [x] Config Git (nome, email, SSH) fatta
- [x] Account GitHub (repo privato) creato
- [x] Claude Code installato
- [x] Account Supabase (region EU) creato — progetto "Coach-vasca"
- [x] Primo `flutter create` fatto dentro questa cartella — progetto `coach_vasca` (Android/iOS/Web/Linux/macOS/Windows)

## FASE 1 — Fondazione prodotto (~1 settimana)
- [x] Schema DB V1: Club, Atleti, Test_BVS_T30, Tabelle_Passi, Stagione/Macro/Meso/Micro, Allenamenti, Serie, Presenze — migrazioni SQL in `supabase/migrations/`, applicate al progetto reale e verificate (12 tabelle, RLS attiva, 4 policy ciascuna), vedi `supabase/README.md`
- [x] RLS attiva su ogni tabella Supabase da subito (isolamento per club/coach) — multi-coach per club con ruoli owner/coach/assistente
- [x] `.env` con chiavi Supabase, escluso da Git — `.env.example` come template versionato, `.env` reale creato e verificato ignorato
- [x] Bozza informativa privacy + consenso genitori (atleti minorenni) — `docs/privacy/`, da far rivedere da un consulente prima dell'uso reale
- [x] Wireframe 6 schermate: login, lista atleti, test→passi, calendario stagione, scheda bordo vasca, placeholder "Genera con AI" — vedi `docs/wireframes/README.md`

## FASE 2 — MVP Nuoto usabile (~2-4 settimane)
- [x] Auth coach (Supabase email) — Riverpod + client Supabase (`lib/core/supabase/`), login/logout/reset password/registrazione self-service (`lib/features/auth/`)
- [x] CRUD Atleti — bootstrap club (`lib/features/club/`, funzione RPC `create_club` per il bug RLS su INSERT...RETURNING), lista/crea/modifica/archivia atleti (`lib/features/atleti/`)
- [x] Inserimento BVS o T30 — storico test per atleta, passo medio calcolato dal DB (`lib/features/test/`)
- [x] Motore tabelle passi (A1…D) per atleta — percentuali di partenza generiche modificabili dal coach prima di ogni generazione (`lib/features/tabelle_passi/`), indicatore "generata" nella lista test
- [x] Scheda allenamento manuale (serie, distanza, regime, ripartenza, note) — `lib/features/allenamenti/`, con stile (libero/dorso/rana/delfino/misti), esecuzione (nuoto/gambe/braccia/pull/tecnica) e ripartenza distinta dal recupero, per poter in futuro costruire un report per atleta su volumi e presenze
- [x] Presenze sessione — `lib/features/presenze/`, presente/assente/giustificato per atleta e allenamento, salvataggio immediato al tocco (nessun filtro per gruppo: campo testo libero, troppo fragile per un confronto esatto)
- [x] UI pool-first, alto contrasto, bottoni grandi, landscape tablet — "vista bordo vasca" (`scheda_bordo_vasca_screen.dart`) sola lettura, sfondo nero/testo grande, orientamento forzato landscape, accesso rapido a "Segna presenze"
- [ ] Checklist di test manuale prima di chiudere la fase
- [ ] Test su Chrome + telefono Android reale
- [ ] Commit frequenti su branch feature, merge su main solo quando funziona

**Criterio di fine fase:** un coach usa l'app in vasca per una sessione reale, senza AI.

## FASE 3 — Offline-first (~1-2 settimane)
- [x] Drift come DB locale (al posto di SQLite puro) — `lib/core/db/`, schema locale per tutte le 7 entità operative, UUID generati lato client per atleti/test/allenamenti/serie, lettura sempre da cache locale (`StreamProvider` reattivi) con refresh remoto in background best-effort
- [x] Scrittura resiliente in impianto — ogni creazione/modifica prova subito verso Supabase (come sempre); se la rete manca, invece di un errore va in coda locale (`lib/core/sync/`) e riparte da sola alla riconnessione. Scelto invece del local-first puro per non dover replicare in Dart la logica di derivazione club_id oggi nei trigger DB
- [x] Regola di conflitto documentata (last-write-wins su updated_at) — nessun confronto di timestamp lato client: le operazioni in coda vengono rigiocate in ordine verso il server, l'ultima che arriva vince (vedi doc in `sync_engine.dart`)
- [x] Sync verso Supabase a rete disponibile — motore di sync (`lib/core/sync/sync_engine.dart`) attivato da `connectivity_plus` al ritorno della connessione e all'avvio dell'app
- [x] Indicatore "sincronizzato / in coda" — icona nell'AppBar (`HomeScreen`), tocco per ritentare subito
- [x] Test in modalità aereo — verificato su Chrome (DevTools → Network → Offline): creazione/modifica funziona offline, va in coda, si sincronizza da sola al ritorno della rete

## FASE 4 — Programmazione di stagione (~2-3 settimane)
- [x] Creare Stagione (date, obiettivo, gruppo) — `lib/features/stagioni/`, validazione data fine ≥ data inizio lato client, nuove tabelle Drift per l'intera gerarchia (stagioni/macro/meso/micro) anche se per ora solo stagioni ha una UI
- [x] Suddivisione macro/meso/micro (anche solo settimane, in V1) — gerarchia di dettaglio Stagione → Macrocicli → Mesocicli → Microcicli, stesso pattern CRUD resiliente delle altre feature
- [x] Assegnare allenamenti alle date — dettaglio microciclo (`microciclo_detail_screen.dart`) mostra/crea gli allenamenti della settimana, collegati tramite `microciclo_id`; il form generico allenamento preserva il collegamento esistente invece di sganciarlo
- [x] Vista settimanale e mensile — selettore Elenco/Settimana/Mese nella scheda Allenamenti (calendario a griglia con puntino sui giorni con allenamento), tocco su un giorno apre la scheda del giorno (`giorno_allenamenti_screen.dart`)
- [x] Duplica settimana / sposta scheda — "sposta" collega una scheda a un altro microciclo (o la scollega) da `sposta_allenamento_screen.dart`; "duplica" (`duplicazione_settimana_service.dart`) crea la settimana successiva con stessa durata e copia allenamenti + serie, passando dagli stessi repository resilienti online/coda-offline. Fase 4 chiusa.

**Criterio di fine fase:** il coach vede il piano della settimana e apre la scheda del giorno.

## FASE 5 — Modulo AI "Genera allenamento" (~2-3 settimane)
Modulo indipendente, ispirato a funzionalità pubbliche viste online, non al codice di terzi.
- [x] Form input: gruppo/livello, volume, focus, regimi ammessi, vincoli — `lib/features/ai_genera/`, raggiungibile dal nuovo FAB "Genera con AI" nella tab Allenamenti; per ora raccoglie e valida i parametri (`ParametriGenerazione`), la chiamata API è il prossimo punto
- [x] Chiamata API con limite di spesa mensile impostato sul provider — Edge Function Supabase `supabase/functions/genera-allenamento/` (Gemini, chiave server-side via secret `GEMINI_API_KEY`), chiamata da `generazione_ai_repository.dart`; provider isolato dietro la function così è sostituibile senza toccare l'app. Budget/alert mensile impostato lato Google AI Studio (fuori dal codice)
- [x] Output sempre in JSON strutturato e validato (metri, tempi, regimi noti) — Gemini chiamato con `responseSchema` fisso (`SchedaGenerata`/`SerieGenerata`), la Edge Function rivalida comunque ogni campo lato server contro i valori noti (blocco/stile/esecuzione/zona, numeri positivi) prima di rispondere, rifiutando con errore esplicito se il JSON non è conforme; il dialog "Genera" ora mostra la scheda formattata invece del testo grezzo
- [x] Anteprima scheda generata + conferma manuale del coach prima del salvataggio — il dialog "Scheda generata" ora ha data modificabile e pulsanti Annulla/Salva: nulla viene scritto su Supabase/Drift finché il coach non conferma; "Salva" crea l'allenamento e le sue serie tramite i repository esistenti e apre il dettaglio appena creato
- [x] "Aggiungi al calendario" → collega alla stagione — il dialog "Scheda generata" ha un menu per scegliere la settimana (microciclo) a cui collegare l'allenamento; il dettaglio di un microciclo ha anche un FAB "Genera con AI" che pre-compila settimana e data
- [x] Storico prompt/output per migliorare i prompt nel tempo — tabella `generazioni_ai` (migrazione `20260901000100_generazioni_ai.sql`), registrata da `generazioni_ai_repository.dart` ad ogni generazione (successo/errore, parametri, scheda, e se poi salvata come allenamento); consultabile dalla nuova schermata "Storico generazioni AI" (icona nell'AppBar di "Genera con AI")
- [ ] (Opzionale, dopo) dettatura vocale → stesso parser JSON

**Criterio di fine fase:** generi una scheda, la correggi, la metti in una data della stagione.

## FASE 6 — Polish e uso reale (~2 settimane)
- [ ] 2-3 sessioni vere in piscina
- [x] Export PDF/CSV scheda o settimana — `lib/features/export/` (pacchetti `pdf`/`printing`), icona "Esporta" nel dettaglio allenamento e "Esporta settimana" nel dettaglio microciclo; PDF apre la stampa/salvataggio nativa del browser/OS, CSV apre una schermata di testo da copiare (nessun download nativo cross-platform senza altre dipendenze)
- [x] Messaggi di errore chiari — `lib/core/utils/error_messages.dart` (`messaggioErrore`) traduce le eccezioni tecniche (rete, Postgrest, Auth, Edge Function) in messaggi in italiano comprensibili; usato ovunque un errore raggiunga l'utente (liste/dettagli, form di salvataggio, login/registrazione, generazione AI, export) al posto del testo grezzo dell'eccezione
- [x] Backup manuale del DB Supabase se ancora su piano Free — `scripts/backup_db.ps1` (`pg_dump` sullo schema `public`, richiede `SUPABASE_DB_URL` in una variabile d'ambiente) e guida passo-passo in `docs/backup.md`; i file generati vanno in `backups/` (escluso da git, contiene dati personali)
- [ ] Valutare Cursor Pro se i limiti free iniziano a bloccare il lavoro

## FASE 7 — Pallanuoto V2 (~3-5 settimane)
- [x] Distinta FIN (13/15, portieri, capitani, fuoriquota) — tab "Partite" nella home: partite (data/ora/luogo/campionato/colore calottina, tetto 13/15), distinta con selezione atleti pallanuoto, numero calottina, capitano/vice capitano univoci, portiere, fuoriquota (validati anche a DB), export PDF della convocazione
- [x] Partita + eventi base (tiro, fallo, uomo ±) — schermata "Eventi partita" (icona timeline nella distinta): tiro (di un convocato, esito semplice o dettagliato), espulsione (solo espulsioni, non falli ordinari), superiorità numerica nostra/avversaria (esito subito o inizio/fine); impostazioni di dettaglio scelte per partita e precompilate dall'ultima partita della squadra
- [x] Plus/minus semplice — icona "Statistiche" nella distinta: per ogni convocato gol/tiri, percentuale realizzativa ed espulsioni subite, più riepilogo di squadra, calcolati dagli eventi già registrati (nessuna nuova tabella)
- [ ] ~~(Dopo) digitalizzazione referto solo con fogli reali di esempio~~ — accorpato al punto "Referti" della Fase 8 (vedi sotto), stessa cosa

## FASE 8 — Avanzato V3
- [ ] Parsing file .cl2 / .sd3 / risultati FIN
- [x] Banister / tapering su storico carichi — icona "Carico" nella lista atleti: curva fitness/fatica/forma (modello Banister, costanti 42/7 giorni) calcolata da ripetute×distanza×peso-zona delle serie, contata solo nei giorni in cui l'atleta risulta "presente"; possibile miglioramento futuro: carico manuale (RPE×durata) invece che automatico da volume, e/o calcolo a livello di gruppo/allenamento invece che per singolo atleta
- [x] Referti: invio foto a un modello con visione invece di OCR dedicato — tab "Partite", icona fotocamera: carica/scatta la foto di un referto FIN compilato, Edge Function `leggi-referto` (Gemini vision, stesso schema di `genera-allenamento`) estrae squadre/punteggio/parziali/giocatori (reti, espulsioni); tutti i campi restano modificabili in schermata per correggere errori di lettura (soprattutto nomi); messaggi di errore chiari con pulsante "Riprova" se il servizio non risponde. Salvataggio: dopo la correzione, "Salva referto" chiede di collegare il referto a una partita esistente o di crearne una nuova al volo (solo data, squadre già prese dal referto); un solo referto per partita (nuovo salvataggio sovrascrive), archiviato in una tabella dedicata `referti_partita` (non negli eventi_partita usati per il tracking live). Consultazione: dalla schermata di una partita (dove c'è la Distinta), icona "Referto" mostra risultato finale, parziali e rose complete salvate
- [x] Statistiche stagionali di squadra e per atleta — campo "La mia squadra: Casa/Trasferta" sulla partita (form partita + scelta partita nel salvataggio referto), per sapere quali giocatori contano nelle statistiche; nel salvataggio di un referto, dialog "Collega i giocatori agli atleti" per la nostra squadra (auto-collegamento per numero di calottina se esiste già una distinta per quella partita, poi per cognome se corrisponde a un solo atleta, altrimenti scelta manuale; avviso non bloccante se qualcuno resta senza collegamento, le sue reti/espulsioni non verrebbero conteggiate per nessun atleta). Due statistiche stagionali separate (filtrate per Stagione, date inizio/fine) più una terza di confronto: icona "Statistiche stagione" nella tab Partite per la squadra e icona "Statistiche" nella lista atleti per il singolo atleta — sezione "Da referti" (partite/V-P-S/gol, media gol/partita, reti/espulsioni/media per atleta; non conta i tiri sbagliati), sezione "Da eventi live" (gol/tiri/percentuale/media gol partita, scomposti per contesto azione/superiorità/rigore — nuovo campo `contesto_tiro` sull'evento tiro; solo per le partite seguite dal vivo) e sezione "Confronto" che affianca (senza sommarle) le due fonti per ogni atleta
- [x] Computer vision stroke rate (elaborazione locale sul device) [da testare su un device reale] — icona fotocamera nella lista atleti (solo app nativa Android/iOS, nascosta sul web): registra 15s di fotogrammi dalla fotocamera ed elabora localmente (Google ML Kit Pose Detection, nessun video salvato/caricato), traccia il polso e conta i picchi del movimento verticale per stimare le bracciate/min; nessun salvataggio dati, stima sperimentale non ancora validata in acqua
- [ ] Supabase Pro (backup automatici)
- [ ] Pubblicazione store (Play/App Store) se necessario

## FASE 9 — Area atleta e raffinamenti allenamento
- [x] Account atleta — pagina personale in cui l'atleta inserisce i propri PB, condivisi con l'account allenatore. Collegamento tramite invito: per singolo atleta (codice monouso dalla sua scheda) o per gruppo intero (codice riutilizzabile, l'atleta compila da solo la propria anagrafica ed entra già nel gruppo giusto — pensato per onboarding di tante persone insieme, es. una squadra U14/U16)
- [x] Permessi atleta — RLS dedicata: l'atleta collegato vede solo il proprio carico, le proprie presenze (numero e % mensile/totale) e i propri PB, non la rubrica né i dati degli altri atleti. Il consenso privacy resta da confermare a mano dal coach anche per gli atleti auto-registrati col codice di gruppo
- [x] Ricerca e ordinamento (cognome/data di nascita) nella lista atleti — aggiunto durante il test della Fase 9
- [x] Scadenza visita medica in anagrafica, con avviso in elenco quando scaduta o in scadenza entro 30 giorni — aggiunto durante il test della Fase 9
- [ ] Allenamenti: sezione "materiale utilizzato"
- [ ] Nuovi codici zona/tipo lavoro: split di C in C1/C2/C3 (oltre ad A1, A2, B1, B2, D) più "tecnica", "gambe", "braccia", "remate"
- [ ] Pagina Carico: mostrare il volume totale e il volume per ogni codice/tipo lavoro (gambe, braccia, ecc.)
- [ ] Eventi partita pallanuoto: campo disegnato tipo lavagnetta — chi registra un tiro tocca il punto della porta/campo da cui è partito, poi sceglie gol/parato/fuori (sostituisce o affianca l'attuale selezione atleta+esito senza posizione); la posizione toccata va salvata insieme all'evento, per poi avere una statistica/mappa di calore di dove la squadra segna di più

## Restyling DESIGN.md (2026-09-06)

Tutte le schermate dell'app sono state riportate a DESIGN.md, una alla volta: restyle di sola presentazione, `flutter analyze` pulito e commit dedicato per ciascuna (nessuna modifica a logica, dati, database, migrazioni o cartella `supabase/`). Fatte, in ordine: le tre schermate da bordo vasca (segna presenze, allenamento in corso, eventi partita), poi login/registrazione/crea club, le quattro liste della home (atleti, allenamenti + viste calendario, stagioni, partite), l'intera gerarchia stagione → macrociclo → mesociclo → microciclo (elenco e form a ogni livello), test (elenco e form), carico atleta, statistiche (selettore stagione, per atleta, per squadra), bracciate, pallanuoto (distinta, form partita, statistiche partita, referto, leggi referto), tabella passi, le due schermate AI genera, home e anteprima/esportazione CSV. Nessuna schermata è rimasta esclusa dall'elenco originale.

Nel farlo sono stati aggiunti due componenti condivisi non previsti in DESIGN.md sezione 14 — `OrdineBadge` (numero cerchiato) e le estensioni opzionali di `AppTextField` (obscureText/autofillHints/onFieldSubmitted) e `AppListRow` (onLongPress) — e un'eccezione mirata alla regola "massimo tre azioni" a bordo vasca per varianti binarie imprevedibili (sezione 9), tutti già documentati direttamente in DESIGN.md.

Punti lasciati aperti, per scelta deliberata o perché DESIGN.md non li copre ancora:
- **Selezione atleta nei dialog "Registra tiro/espulsione" di Eventi partita**: usa ancora un menu a tendina, che è un "form" vietato a bordo vasca (sezione 9); la regola alternativa (bottom sheet max 3 scelte) non copre una scelta fra un'intera rosa (spesso 13+ persone). Serve un pattern nuovo (es. griglia di bersagli grandi con calottina/nome) da aggiungere a DESIGN.md prima di poterlo sistemare.
- **Colore calottina per riga in Distinta**: `Partita.coloreCalottina` è testo libero (non un enum), quindi non è mappabile in sicurezza sui tre `CapColore` di `CapBadge`; il colore reale resta visibile solo in testo nell'intestazione, non per singolo convocato (eccetto il portiere, sempre rosso).
- **Palette per i grafici a linee** (schermata Carico): DESIGN.md non ne definisce una; per ora Fitness/Fatica/Forma usano blu/attenzione/ok (mai rosso, riservato a "in corso"/errori).
- **IBM Plex Sans Condensed** (colonne strette di distinta/tabella passi/referto): il pacchetto `google_fonts` in uso non la include; `AppTypography.condensata()` ripiega su IBM Plex Sans normale finché non si trova un'alternativa (font incluso come asset?).
- **Chiaro o scuro a bordo vasca** (DESIGN.md sezione 16): decisione esplicitamente rimandata a una vera sessione in impianto, non presa qui.

---

## Ordine di dipendenze (non invertire)
PC pronto → Atleti + Passi + Scheda manuale → Offline → Calendario stagione → AI genera scheda → importa in stagione → (voce, opzionale) → Pallanuoto / referti / CV

*Senza atleti, passi e calendario, una scheda generata dall'AI non ha dove finire.*

## Costi nel tempo (indicativi)
| Momento | Spesa mensile tipica |
| --- | --- |
| Setup + MVP in sviluppo | 0 € |
| Uso quotidiano intenso di Cursor | ~20 $/mese (Cursor Pro) |
| + Refactor pesanti / task lunghi | ~37-40 $/mese (+ Claude Pro) |
| + App in uso reale | ~62-65 $/mese (+ Supabase Pro) |
| Modulo AI genera-allenamento | pochi €/mese (API a consumo, con tetto di spesa) |
