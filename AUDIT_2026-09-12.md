# Audit del codice — SwimCoach FIN (12/09/2026)

Controllo completo in tre parti: bug, codice inutile, colli di bottiglia. Nessuna correzione applicata — solo un rapporto, da discutere insieme prima di decidere cosa sistemare.

**Metodo**: `flutter analyze` e `dart fix --dry-run` (entrambi puliti, 0 segnalazioni automatiche), più una revisione manuale approfondita fatta leggendo il codice riga per riga in tre aree separate: sicurezza/database, bug a runtime, codice morto e prestazioni.

**Riassunto**: nessun problema bloccante. L'app è in buono stato — l'isolamento dei dati tra club (la cosa più delicata, dato che più allenatori/club condividono lo stesso database) risulta corretto ovunque. I problemi trovati sono per lo più cose da sistemare con calma o rifiniture, non urgenze.

---

## 🔴 Bloccante

Nessuno. In particolare: **tutte le tabelle del database hanno l'isolamento per club correttamente attivo** — un allenatore di un club non può in nessun modo leggere o scrivere dati di un altro club, nemmeno forzando le richieste dell'app. Controllate una per una tutte le tabelle, tutte le funzioni che girano con permessi elevati, e tutti i punti del codice dell'app dove viene deciso "di quale club sono questi dati".

---

## 🟡 Da sistemare presto

### 1. Se due dispositivi modificano lo stesso allenamento (o atleta) mentre uno è senza rete, si può perdere una modifica dell'altro
**Dove**: `lib/features/allenamenti/data/allenamenti_repository.dart` (metodo `updateAllenamento`), `lib/features/atleti/data/atleti_repository.dart` (metodo `updateAtleta`)
**Cosa significa in pratica**: quando salvi una modifica mentre sei offline, l'app la mette in una coda e la rimanda al server quando torna la rete — ma la rimanda con **tutti** i campi del form, non solo quello che hai cambiato tu. Esempio concreto: sei offline e cambi solo la data di un allenamento; nel frattempo un collega online cambia solo il titolo dello stesso allenamento; quando torni online, la tua modifica arriva dopo e **riporta indietro anche il titolo che aveva cambiato il collega**, anche se tu non l'avevi mai toccato. Non è un crash né una perdita di dati eclatante, ma è un comportamento che nessuno si aspetterebbe vedendo l'app. Altre parti dell'app (presenze, eventi partita) già evitano questo problema mandando solo il campo davvero cambiato — andrebbe fatto lo stesso qui.

### 2. Un atleta collegato al suo account vede gli allenamenti (e le note) di tutti i gruppi del club, non solo del proprio
**Dove**: regole del database create in `supabase/migrations/20260906000200_atleta_account.sql` (righe 65-69)
**Cosa significa in pratica**: è una scelta fatta apposta (serve per calcolare il carico di allenamento dell'atleta), ma ha un effetto collaterale: se scrivi appunti personali su un atleta nel campo "Note" di un allenamento o di una serie, **qualsiasi altro atleta con un account collegato nello stesso club può leggerli**, anche se l'appunto riguarda un compagno diverso. Non è una falla verso altri club — resta tutto isolato correttamente — ma è un'esposizione più ampia di quanto ci si aspetterebbe all'interno dello stesso club.

### 3. Se la registrazione di un atleta con codice invito si interrompe a metà, l'account resta bloccato
**Dove**: `lib/features/auth/presentation/riscatta_invito_screen.dart` (metodo `_creaAccount`, righe 141-190)
**Cosa significa in pratica**: registrarsi con un codice invito richiede due passaggi di seguito (crea l'account, poi collegalo all'atleta). Se il primo passaggio riesce ma il secondo fallisce per un problema di rete proprio in quel momento, l'account resta creato ma "orfano" — e se la persona riprova, l'app dirà che quell'email è già registrata, senza un modo ovvio per sbloccarsi da sola. Caso raro, ma se capita serve il tuo intervento manuale.

### 4. Il pulsante "Esci" non avvisa se il logout fallisce
**Dove**: `lib/features/home/home_screen.dart` (riga 210)
**Cosa significa in pratica**: se tocchi "Esci" proprio mentre manca la rete, l'app non ti dice che non è riuscita a disconnetterti — resta un'incertezza su se sei uscito davvero o no.

### 5. "Annulla" su un evento partita live non avvisa se la cancellazione fallisce
**Dove**: `lib/features/pallanuoto/presentation/partita_live_screen.dart` (righe 96-100)
**Cosa significa in pratica**: dopo aver registrato un tiro o un'espulsione, compare un tasto "Annulla". Se in quel momento la cancellazione fallisce per un motivo diverso dalla rete assente, l'app non ti avvisa — credi di aver annullato l'evento ma in realtà è ancora lì, registrato.

### 6. Lo "Storico generazioni AI" scarica tutta la cronologia in una volta, senza limite
**Dove**: `lib/features/ai_genera/data/generazioni_ai_repository.dart` (metodo `fetchStorico`, righe 84-91)
**Cosa significa in pratica**: ogni volta che apri questa schermata, l'app scarica tutte le generazioni AI mai fatte per il club, dall'inizio. Oggi con pochi mesi di utilizzo non si nota, ma più userai la generazione AI nel tempo, più questa schermata diventerà lenta ad aprirsi.

### 7. "Duplica settimana" fa tutte le operazioni una alla volta, in fila
**Dove**: `lib/features/allenamenti/data/duplicazione_settimana_service.dart` (righe 32-59)
**Cosa significa in pratica**: quando duplichi una settimana, l'app crea un allenamento, legge le sue serie, poi crea ogni serie una per una — in sequenza, non tutte insieme. Con una settimana piena questo significa decine di operazioni in fila: più lento del necessario, e se la connessione cade a metà rischi di ritrovarti con solo una parte della settimana duplicata.

### 8. Le foto dei referti vengono inviate all'AI a piena risoluzione
**Dove**: `lib/features/referti/presentation/leggi_referto_screen.dart` (righe 42-46), `lib/features/referti/data/referti_repository.dart` (riga 37)
**Cosa significa in pratica**: quando scatti o carichi la foto di un referto, l'app ne riduce la qualità (85%) ma non le dimensioni in pixel. Una foto di un moderno smartphone resta molto più grande di quanto serva per leggere del testo scritto — invii più lenti e probabilmente un costo più alto ad ogni lettura.

---

## ⚪ Rifiniture (nessun impatto reale per ora)

### 9. Tre widget scritti per la vecchia gerarchia delle stagioni non vengono più usati da nessuna parte
**Dove**: `lib/widgets/breadcrumb_bar.dart` (tutto il file), `lib/widgets/ordine_badge.dart` (tutto il file), `lib/widgets/app_list_panel.dart` righe 41-85 (`ReorderableAppListPanel`)
**Cosa significa in pratica**: erano stati costruiti per la gerarchia macrociclo/mesociclo/microciclo, eliminata di recente. Restano nel progetto ma non li richiama più nessuna schermata — codice morto, non fanno danno ma occupano spazio.

### 10. Una dipendenza dichiarata nel progetto non viene mai usata
**Dove**: `pubspec.yaml` (riga 38, `cupertino_icons`)
**Cosa significa in pratica**: pacchetto di icone in stile Apple rimasto dal modello iniziale di Flutter, mai effettivamente usato in nessuna schermata. Si potrebbe togliere senza cambiare nulla nell'app.

### 11. Due tabelle non hanno una regola per "cancellare" righe
**Dove**: tabella `generazioni_ai` e tabella `codici_gruppo`
**Cosa significa in pratica**: non è un rischio di sicurezza (nessuno può leggere/scrivere dati di un altro club), è solo una funzionalità mancante — oggi non si possono eliminare vecchie generazioni AI o vecchi codici gruppo dall'app, se mai un giorno servisse.

### 12. Quasi tutte le richieste al database non hanno un limite di righe
**Dove**: la maggior parte dei file `data/*_repository.dart` (es. allenamenti, serie, partite, presenze)
**Cosa significa in pratica**: l'app scarica sempre tutti i dati di un club in un colpo solo, poi li salva sul telefono e da lì legge velocemente. Oggi non si nota; se un club crescesse molto (centinaia di allenamenti/partite), i primi scaricamenti diventerebbero via via più lenti.

### 13. Qualche `const` mancante, isolato
**Dove**: `lib/features/home/home_screen.dart` (riga 235), `lib/features/stagioni/presentation/stagione_detail_screen.dart` (righe 118 e 128)
**Cosa significa in pratica**: tre icone che potrebbero essere marcate come "non cambiano mai" (`const`) per un minimo risparmio, ma non lo sono. Effetto pratico impercettibile — la disciplina generale sul resto del codice è già buona.

---

## Cosa NON è stato trovato (buone notizie)

- **Nessuna falla di sicurezza tra club**: ogni tabella ha le regole di isolamento attive e corrette, verificate una per una.
- **Nessun controller/risorsa dimenticata aperta** (niente `dispose()` mancanti) in tutto il progetto.
- **Nessun caso trovato** di schermata che usa riferimenti "morti" dopo essere stata chiusa (un problema classico in app Flutter che qui non si presenta).
- **Nessuna vera perdita di reattività**: le schermate con liste/statistiche già calcolano i dati pesanti una sola volta invece che ad ogni ridisegno.
- Tutte le altre dipendenze del progetto (oltre a `cupertino_icons`) sono realmente usate.
