# SwimCoach FIN — analisi del video di test (12/09/2026, 7'15")

Analisi ricostruita frame per frame. I riferimenti temporali servono a ritrovare il punto nel video.

---

## 1. Percorso mostrato nel video

| Tempo | Schermata |
|---|---|
| 0:00–0:25 | Login, errore "Email o password non corretti" |
| 0:25–0:58 | Crea account coach, errore ripetuto "Le password non coincidono" |
| 0:58–1:06 | Crea il tuo club (nome, città, sport Pallanuoto, categorie U14/U16) |
| 1:08–1:16 | "Con chi lavori oggi?" → lista atleti vuota |
| 1:18–1:55 | Nuovo atleta (anagrafica, attività, contatti e consenso) |
| 1:57–2:20 | Nuovo allenamento "Aerobicone" + due Nuova serie |
| 3:18–3:34 | Dettaglio allenamento, modalità lavagna scura, Presenze |
| 3:42–4:20 | Genera con AI (singola seduta) e Genera settimana con AI |
| 4:20–4:50 | Viste Settimana e Mese |
| 4:30–4:54 | Nuova stagione, Statistiche stagione |
| 5:02–6:20 | Partite: nuova partita, convocati, tracciamento live con shot chart |
| 6:22–7:15 | Statistiche partita e statistiche stagione |

---

## 2. Bug veri e propri

### 2.1 Snackbar "Evento registrato" bloccata — grave — ✅ risolto (2026-09-12)
Causa reale diversa dall'ipotesi sotto: eventi registrati in rapida successione accodavano ciascuno un nuovo SnackBar (4s), dando l'impressione di uno bloccato per decine di secondi. Fix applicato: ogni nuovo evento svuota la coda (`clearSnackBars`) prima di mostrarsi, e uscendo dalla schermata partita si ripulisce ogni residuo.

Dal minuto 6:22 fino alla fine del video (oltre 50 secondi) la barra verde "Evento registrato / Annulla" resta fissa in fondo allo schermo mentre navighi tra statistiche partita, menu contestuale, elenco partite, statistiche stagione e perfino la schermata "Con chi lavori oggi?". Non scompare mai e copre i controlli sottostanti.

**Cosa succede.** Lo `SnackBar` viene mostrato su uno `ScaffoldMessenger` che sopravvive al cambio di rotta, e il timer di dismissione non parte o viene resettato a ogni rebuild. Il rischio peggiore è che l'azione "Annulla" resti agganciata a un evento ormai vecchio: se la tocchi dopo cinque schermate, cancelli qualcosa che non ti aspetti.

**Fix.** Chiamare `ScaffoldMessenger.of(context).hideCurrentSnackBar()` nel `dispose` della pagina partita e impostare una `duration` esplicita (3–4 secondi). L'azione "Annulla" deve catturare l'id dell'evento al momento della creazione e disattivarsi allo scadere del timer.

### 2.2 Le statistiche stagione non vedono gli eventi live — grave — ✅ risolto (2026-09-12)
Causa reale diversa dall'ipotesi sotto: l'aggregazione per data era già corretta, ma i tre provider Riverpod erano senza `autoDispose` — il risultato (spesso vuoto) restava in cache per l'intera sessione se la schermata veniva aperta prima di registrare la partita. Aggiunto `autoDispose`. Aggiunto anche il secondo intervento suggerito: messaggio azionabile "Crea una stagione per questa data" nel form partita.

Nel video registri una partita completa dal vivo: risultato 2‑2, due gol su tre tiri, un'espulsione, tiri posizionati sullo shot chart. Le statistiche della singola partita li mostrano correttamente (Gol 2/3, 67%, Espulsioni 1). Le statistiche stagione con il filtro "Da eventi live" invece riportano Gol 0/0, Espulsioni 0, "Nessun evento registrato in questa stagione" e in fondo la frase "0 partite seguite dal vivo con Eventi partita".

**Cosa succede.** Le due query leggono da chiavi diverse. Molto probabilmente la partita creata non è associata a nessuna stagione: nella schermata Nuova partita compare l'avviso "Nessun campionato: questa data non rientra in una stagione con campionato impostato", e la stagione "U16 anno 2026‑27" è stata creata dopo la partita.

**Fix.** Due interventi separati. Primo, all'aggregazione stagionale associa le partite per intervallo di date oltre che per chiave esplicita, così una partita dentro le date della stagione entra nel conteggio anche se creata prima. Secondo, quando crei una partita che non ricade in nessuna stagione, il messaggio deve essere un'azione ("Nessuna stagione copre questa data — creane una") e non una nota grigia.

### 2.3 Date picker in inglese — ✅ risolto (2026-09-12)
A 1:36, aprendo "Data di nascita", compare il calendario Material in inglese: "Select date", "Sat, Jan 1", "January 2011", intestazioni S M T W T F S, pulsanti "Cancel" e "OK", tooltip "Next month". Tutto il resto dell'app è in italiano.

**Fix.** Aggiungere in `MaterialApp` le `localizationsDelegates` (`GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate`) e `supportedLocales: [Locale('it')]`, con `locale: Locale('it')` forzato. È una modifica di cinque righe che sistema tutti i picker dell'app in un colpo solo.

### 2.4 Il date picker si apre su gennaio 2011 — ✅ risolto (2026-09-12)
Parte in modalità anno (`initialDatePickerMode: DatePickerMode.year`); se l'atleta ha già un gruppo tipo "U14"/"U16" selezionato l'anno di partenza si deduce da lì.
Sempre a 1:36 il calendario parte da gennaio 2011 e per arrivare alla data giusta devi navigare a mano. Per una data di nascita di un atleta U16 il punto di partenza sensato è l'anno di nascita tipico della categoria.

**Fix.** Passare `initialDate` calcolata dalla categoria selezionata, e `initialDatePickerMode: DatePickerMode.year` così il primo tocco sceglie l'anno invece del giorno.

### 2.5 Accenti mancanti in tutta l'app — ✅ risolto (2026-09-12)
Nella vista Settimana i giorni erano "Lunedi", "Martedi", "Mercoledi", "Venerdi" (risultavano già corretti nel codice attuale, probabilmente sistemati in una sessione precedente). Nel menu a tendina del focus seduta compariva "Velocita": corretto (valore interno invariato, solo l'etichetta mostrata ora è "Velocità"). Passata al setaccio l'intera codebase per altre parole tronche in testo utente: nessun altro caso trovato.

**Fix.** Sono stringhe hardcoded. Vale la pena centralizzarle ora in un unico file di costanti: se domani vuoi l'app anche in inglese, il lavoro è già impostato.

### 2.6 Percorso interno del repository visibile all'utente — ✅ risolto (2026-09-12)
Nella schermata Nuovo atleta, sotto "Consenso privacy firmato", si legge "Vedi docs/privacy/ per il modulo da far firmare al genitore". È il percorso di una cartella del progetto, non qualcosa che un allenatore possa aprire.

**Fix.** Sostituire con un pulsante "Scarica il modulo di consenso" che apre il PDF, oppure togliere la riga.

*Come risolto:* nessun PDF del modulo esiste ancora nel progetto (solo markdown in `docs/privacy/`), quindi niente pulsante di download per ora — la riga tecnica è stata sostituita con un promemoria neutro ("Fai firmare il modulo di consenso al genitore prima di attivare questo interruttore"), senza riferimenti a percorsi interni. Costruire il download del PDF resta un'opzione per dopo, se si genera un PDF vero dal markdown esistente.

### 2.7 Generazione AI senza esito visibile
Compili il form "Genera con AI" (gruppo U16, volume 3000 m, focus Aerobico, regimi A1 e A2) e subito dopo l'elenco allenamenti contiene ancora solo "Aerobicone". Stessa cosa con "Genera settimana con AI": imposti 4 sedute, 14000 m, focus Aerobico/Soglia/Tecnica/Velocità, e la vista Settimana resta con sei giorni su sette a "Nessun allenamento".

Dal video non si capisce se hai premuto "Genera" e non è successo niente, o se sei uscito prima. In entrambi i casi il problema è lo stesso: **non c'è nessun feedback**. Non si vede uno stato di caricamento, né un errore, né una conferma.

**Fix.** Il pulsante deve entrare in stato di attesa con testo esplicito ("Sto generando la settimana…"), la chiamata deve avere un timeout, e in caso di fallimento serve un messaggio che dica cosa è andato storto e offra "Riprova". Se la generazione riesce, porta l'utente direttamente all'anteprima del risultato invece di tornare alla lista.

*✅ risolto (2026-09-12):* verificato che la navigazione diretta all'anteprima e l'indicatore di caricamento sul pulsante esistevano già (probabilmente il video è stato registrato contro una build precedente, o l'attesa senza timeout dava l'impressione di nulla che succedesse); mancavano davvero timeout e "Riprova". Aggiunto un timeout di 60s su entrambe le chiamate AI (`GenerazioneAiRepository`, con messaggio dedicato in `messaggioErrore` per `TimeoutException`), un'azione "Riprova" sullo snackbar di errore in entrambi i generatori, e il testo del pulsante del generatore a seduta singola ora cambia in "Sto generando..." durante l'attesa (quello della settimana aveva già un testo di fase più dettagliato, "Pianificazione della settimana..."/"Dettaglio seduta X di Y...", lasciato invariato). **Non affrontati in questo passaggio** (sezione 5, elenco "cosa manca"): scelta dei giorni della settimana, rigenerazione di una singola seduta senza rifare tutta la settimana, "duplica settimana precedente" — sono funzionalità nuove, non fix di feedback, da valutare come punti separati.

### 2.8 Il pulsante resta attivo con il form non valido
In "Crea account coach" appare "Le password non coincidono" ma "Crea account" resta scuro e premibile. Stessa logica altrove: la validazione avvisa ma non blocca.

**Fix.** Disabilitare il pulsante finché il form non è valido, oppure lasciarlo attivo ma far comparire l'errore sul campo al tocco. La via di mezzo attuale è la peggiore delle due.

---

## 3. Problemi di flusso e di interfaccia

### 3.1 Due minuti su sette per entrare nell'app
Il 28% del video è login, registrazione, password sbagliate, creazione club. Parte è dovuta a errori di battitura tuoi, ma il flusso non aiuta: l'errore "Email o password non corretti" non distingue tra utente inesistente e password sbagliata, e dopo aver fallito il login non c'è un collegamento diretto a "Crea un account con questa email".

**Fix.** Riportare l'email già digitata nella schermata di registrazione, e nel messaggio di errore aggiungere l'azione "Non hai un account? Registrati".

### 3.2 Lo skeleton loader sembra una lista vuota — ✅ risolto (2026-09-12)
A 1:12 la lista atleti mostra sei rettangoli grigi vuoti per circa due secondi. Senza animazione di shimmer sembrano schede di atleti rotte, non un caricamento.

**Fix.** Aggiungere l'effetto shimmer, oppure mostrare direttamente lo stato vuoto se il caricamento dura meno di 300 ms.

*Come risolto:* `LoadingSkeleton` (usato ovunque nell'app) ora pulsa continuamente tra il 50% e il 100% di opacità finché il caricamento dura — una pulsazione invece di un vero shimmer a gradiente in movimento, più semplice da implementare in modo affidabile e sufficiente a comunicare "sta caricando" invece di "lista vuota o rotta".

### 3.3 Tre pulsanti flottanti impilati senza etichette — ✅ risolto (2026-09-12)
Nella sezione Allenamenti ci sono tre FAB uno sopra l'altro: un'icona libro, una stella AI, un più. Il tooltip esiste ("Genera settimana con AI") ma appare solo al passaggio del mouse, quindi su tablet non lo vedi mai. Stessa cosa nella sezione Partite con tre FAB diversi.

**Fix.** Un solo FAB primario "+" e le altre azioni in un menu che si apre, con etichette testuali sempre visibili. Tre bersagli identici in colonna sono anche facili da sbagliare con le dita bagnate.

*Come risolto:* nuovo componente condiviso `FabAzioni` (documentato in DESIGN.md sezione 14): con una sola azione si comporta come un FAB normale, con più azioni il tocco apre un elenco a comparsa dal basso con icona ed etichetta sempre visibili per ciascuna. Sostituiti i FAB impilati sia in Allenamenti (Nuovo allenamento/Genera con AI/Genera settimana con AI) sia in Partite (Nuova partita/Leggi referto/Statistiche stagione).

### 3.4 Il campo "Ordine" è compilato a mano — ✅ risolto (2026-09-12)
In Nuova serie il primo campo di Volume è "Ordine", e nel video lo scrivi tu: 1 per la prima serie, 2 per la seconda.

**Fix.** L'ordine è la posizione nella lista. Toglilo dal form e rendi la lista riordinabile con trascinamento (`ReorderableListView`). È il campo che non dovrebbe esistere.

*Come risolto:* il campo "Ordine" è sparito dal form completo della serie (già non serviva più nemmeno nella riga rapida, che lo calcola da sola). L'elenco serie nel dettaglio allenamento è ora un `ReorderableListView` (tenendo premuto si trascina una serie in una nuova posizione), che rinumera automaticamente l'ordine di tutte le serie coinvolte.

### 3.5 L'app è a colonna unica anche su desktop — ✅ risolto (2026-09-12)
Il video è registrato su Edge e i campi si allargano per tutta la larghezza della finestra. Su un monitor da 1920 px avrai caselle di testo lunghe un metro e la navigazione principale in fondo allo schermo, che su desktop è il posto più lontano dal mouse.

**Fix.** Mettere il contenuto in un contenitore con larghezza massima intorno ai 700–800 px e centrarlo. Sopra una certa larghezza, sostituire la barra inferiore con una `NavigationRail` laterale. È il cambiamento che da solo farà sembrare l'app più curata.

*Come risolto:* `AppScaffold` (usato da ogni schermata) centra ora il contenuto in un `ConstrainedBox` largo al massimo 760px — sotto quella soglia (telefono/tablet) non cambia nulla. In `HomeScreen`, oltre 900px la barra inferiore (`NavigationBar`) è sostituita da una `NavigationRail` laterale con le stesse 4 destinazioni (Atleti/Allenamenti/Stagioni/Partite).

### 3.6 Nessuna normalizzazione dei nomi — ✅ già risolto
L'atleta viene salvato come Cognome "Genah", Nome "gabriel". In lista compare "Genah Gabriel", quindi la visualizzazione corregge, ma il dato salvato resta minuscolo.

**Fix.** Normalizzare al salvataggio, non alla visualizzazione, altrimenti ricerca e ordinamento si comportano in modo imprevedibile.

*Verificato (2026-09-12):* `capitalizzaNome` viene già chiamato al salvataggio (creazione e modifica) in `atleta_form_screen.dart`, non solo in visualizzazione — il video risulta registrato contro una build precedente a questo fix (fatto in FASE 10). Nessuna modifica necessaria.

### 3.7 "Tipo di settimana (facoltativo)" non si capisce
Nel generatore settimanale c'è un menu "Tipo di settimana" impostato su "Nessuno". Non è chiaro cosa cambi scegliendo qualcos'altro.

**Fix.** Una riga di spiegazione sotto il campo, o rinominarlo con qualcosa di autoesplicativo (per esempio "Fase del mesociclo: carico / scarico / gara").

---

## 4. Costruzione allenamenti: SwimCoach a confronto con Corsia Pro

### Come funziona in SwimCoach
Nuovo allenamento è un form leggero: Data, Titolo (facoltativo), Gruppo (facoltativo), Note (facoltativo), Salva. Le serie si aggiungono dopo, una alla volta, ognuna su una schermata a sé che contiene:

- **Tipo di serie**: Blocco (Riscaldamento / Principale), Stile, Esecuzione, Zona (facoltativo)
- **Volume**: Ordine, Ripetute, Distanza (m)
- **Ritmo**: Passo obiettivo /100m diviso in Minuti e Secondi, Recupero in secondi, Ripartenza/interval diviso in Minuti e Secondi
- **Altro**: Attrezzatura, Note

### Come funziona in Corsia Pro
Tutto su una schermata sola: Data, Titolo, chip delle categorie destinatarie, poi sezioni con titolo libero (Warm Up, Parte centrale, Sciolto, Tecnica) e dentro ciascuna le serie, dove una serie è **una riga di testo libero** (`4x(1x100 + 2x50)`) più un menu della zona e i metri. In fondo il riepilogo "Volume per specializzazione" si aggiorna mentre scrivi.

### I quattro problemi che emergono dal confronto

**Una schermata per ogni serie è troppo.** Per una seduta da otto serie servono otto passaggi avanti e indietro. Corsia Pro le aggiunge in linea, senza mai cambiare schermata. Una seduta vera ne ha dieci o dodici: con il flusso attuale l'allenatore smette di usarlo dopo la seconda settimana.

*Come risolverlo.* Aggiungi le serie in linea nella pagina dell'allenamento, con il form che si espande sotto l'ultima serie inserita.

**Cinque campi numerici per il ritmo.** Passo minuti, passo secondi, recupero secondi, ripartenza minuti, ripartenza secondi. Un allenatore scrive "1:25 r15" in due secondi.

*Come risolverlo.* Un campo unico con maschera `m:ss` per il passo e uno per la ripartenza, e il recupero accanto. Meglio ancora: **una riga di inserimento rapido**. L'allenatore scrive `10x100 A2 1:25 r15 sl` e tu lo interpreti in ripetute, distanza, zona, passo, recupero, stile. È l'intervento con il rapporto valore/fatica più alto di tutto l'elenco, perché è esattamente la notazione che già scrive sulla lavagna. Il form completo resta disponibile per i casi particolari.

*✅ risolto (2026-09-12):* nuova barra fissa in fondo al dettaglio allenamento (sostituisce il FAB "Nuova serie") con un campo di testo che interpreta esattamente la sintassi `10x100 A2 1:25 r15 sl` (ripetute, distanza, zona, passo, recupero, stile — un'anteprima dal vivo mostra cosa è stato capito mentre si scrive), un selettore compatto del blocco (default "Principale") e un'iconcina per aprire comunque il form completo nei casi particolari (esecuzione, ripartenza, attrezzatura, note, blocco diverso via form). Si aggiunge una serie e si resta sulla stessa schermata, tastiera aperta, pronti per la prossima riga — mai più otto schermate per otto serie. Contestualmente, nel form completo (`SerieFormScreen`) Passo e Ripartenza sono diventati un campo unico `m:ss` ciascuno, con Recupero nella stessa riga (tre campi affiancati invece di cinque impilati).

**Non si vede mai il totale metri.** Né durante la costruzione, né nel dettaglio dell'allenamento, né nella vista settimana. In Corsia Pro il totale della sezione è in alto a destra e il volume per specializzazione in fondo, entrambi aggiornati in tempo reale. Ed è un'incoerenza interna: il generatore AI ti fa impostare "Volume totale: 3000 m" e "Volume settimanale: 14000 m", ma poi non puoi verificare se il risultato rispetta quei numeri.

*✅ risolto (2026-09-12):* aggiunto il totale (e il subtotale per blocco) in testata al dettaglio allenamento — si aggiorna da solo a ogni serie aggiunta con la riga rapida, senza bisogno di ricaricare nulla — il totale per giorno e il totale settimanale nella vista Settimana, e il totale settimanale nella schermata di revisione della settimana generata dall'AI. **Non ancora fatto:** totale nella vista Mese.

*Come risolverlo.* Totale metri in testata all'allenamento, totale per blocco accanto al titolo del blocco, totale per giorno nella vista Settimana e totale settimanale in alto. È la cosa più importante da aggiungere dopo i due bug gravi.

**Il blocco è un attributo della serie, non un contenitore.** Ogni serie porta con sé la propria etichetta Riscaldamento o Principale, quindi devi riselezionarla ogni volta e non puoi spostare un blocco intero. Corsia Pro ha sezioni che contengono serie, con titolo libero.

*Come risolverlo.* Passare a sezioni contenitore con titolo libero. Come effetto secondario ottieni anche il totale per sezione, che è già il punto precedente.

### Dove SwimCoach è invece migliore
Da segnare, perché in Corsia Pro non c'è:

- **Zona come campo strutturato con codici A1–D**, uguale a Corsia Pro ma con un livello in più. Attenzione però: è facoltativa e il default è "Nessuna", quindi le statistiche per zona avranno buchi. Rendila obbligatoria, o preimpostala in base al blocco.
- **Passo obiettivo, recupero e ripartenza come dati strutturati.** Corsia Pro li lascia dentro il testo libero e quindi non può calcolarci niente sopra. Tu potrai fare analisi che lui non farà mai. Vale la pena tenerli, purché l'inserimento diventi veloce.
- **Presenze integrate nell'allenamento** (Presente / Assente / Giustificato direttamente dalla lavagna).
- **Modalità lavagna scura**, equivalente alla Lavagna di Corsia Pro ma con il pulsante "Segna presenze" già dentro.
- **Viste Elenco / Settimana / Mese** nella sezione allenamenti. Corsia Pro ha solo il calendario mensile nella dashboard.

---

## 5. Generazione AI e settimana di allenamenti

È la funzione che Corsia Pro non ha, quindi qui non c'è confronto possibile: o funziona bene e diventa il motivo per cui un allenatore sceglie la tua app, o resta un pulsante che nessuno preme due volte.

**Cosa c'è già di buono.** I parametri sono quelli giusti: gruppo, volume, focus, regimi ammessi, vincoli in linguaggio naturale con esempi utili ("niente pinne, max 75 minuti, vasca 25m"). Il generatore settimanale permette di dare un focus diverso a ogni seduta. Lo "Storico" in alto a destra è un'ottima idea.

**Cosa manca.**

*Non puoi scegliere i giorni.* Imposti "Numero di sedute: 4" e una data di inizio, ma non quali giorni. Le corsie in piscina sono assegnate in giorni fissi: se il generatore mette una seduta di mercoledì e tu il mercoledì non hai la vasca, il risultato è da rifare a mano. Aggiungi una fila di chip con i giorni della settimana.

*Non c'è anteprima né modifica prima del salvataggio.* Una generazione AI va rivista prima di finire nel calendario. Serve una schermata di anteprima con le sedute proposte, i metri di ciascuna, il totale settimanale, e la possibilità di rigenerare una singola seduta senza rifare tutta la settimana.

*Non c'è verifica del risultato.* Chiedi 14000 m settimanali: da nessuna parte poi leggi se ne sono stati generati 14000 o 9000. Collegato al punto sui totali metri della sezione precedente.

*Manca la cosa che l'allenatore fa davvero ogni settimana:* duplicare la settimana precedente e modificarla. Non c'è né in SwimCoach né in Corsia Pro, ed è più utile di qualsiasi generazione da zero. "Duplica settimana" con spostamento automatico delle date è poco codice e molto valore.

---

## 6. Ordine di priorità consigliato

1. Snackbar bloccata (2.1) e statistiche stagione che non vedono gli eventi live (2.2). Sono i due bug che fanno perdere fiducia nei dati.
2. Localizzazione italiana dei picker (2.3, 2.4) e accenti (2.5). Poche righe, effetto immediato sulla percezione di qualità.
3. Totali metri ovunque (sezione 4). È l'informazione che l'allenatore cerca continuamente e oggi non trova mai.
4. Inserimento serie in linea con riga rapida di testo (sezione 4). È l'intervento che decide se l'app verrà usata davvero.
5. Feedback e anteprima sulla generazione AI (2.7, sezione 5).
6. Contenitore a larghezza massima e navigazione laterale su desktop (3.5).
7. Il resto: FAB, ordine, skeleton, normalizzazione nomi, stringa docs/privacy.

---

## 7. Nota sul metodo di test

Due osservazioni sul video in sé, non sull'app.

La prova è fatta su un club appena creato con un solo atleta. Quasi tutte le schermate sono stati vuoti, e i problemi seri di un'app del genere escono con venti atleti, due gruppi e un mese di allenamenti alle spalle: liste lunghe, ricerca, ordinamento, prestazioni, conflitti di date. Vale la pena preparare un set di dati finti e rifare la stessa registrazione.

Nella prima scheda del browser è aperto l'editor SQL di Supabase e nel form compare la tua email personale. Se questi video circolano, conviene registrare con un account di prova e una sola scheda aperta.
