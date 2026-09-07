# DESIGN.md — SwimCoach FIN

Sistema di design dell'app. Questo file è **vincolante**: ogni schermata nuova o rifatta deve rispettarlo.

## 0. Come usare questo file (istruzioni per Claude Code)

- Leggi questo file all'inizio di ogni sessione che tocca l'interfaccia.
- I valori qui dentro vivono in un unico posto nel codice (`lib/theme/`). **Non scrivere mai colori, dimensioni o raggi direttamente dentro le schermate.**
- Se una schermata ha bisogno di qualcosa che qui non è previsto, non inventare: proponi l'aggiunta, aggiorniamo questo file, poi implementa.
- Prima di dire che una schermata è finita, passa la checklist della sezione 15.

---

## 1. Il contesto

**Chi la usa:** allenatori di nuoto e pallanuoto tesserati FIN. Persone che passano quattro ore al giorno a bordo vasca con un tablet in mano, spesso in piedi, con le mani bagnate, mentre venti ragazzi aspettano istruzioni.

**Dove la usano:** due mondi diversi, con esigenze opposte.

1. **A bordo vasca**, durante l'allenamento o la partita: sguardo di due secondi, tap veloce, distanza di lettura di mezzo metro, luce forte, riflessi dell'acqua.
2. **Alla scrivania**, per programmare la stagione, inserire test, leggere statistiche: seduti, con calma, tanti dati sullo schermo.

Questi due contesti hanno regole diverse. Sono descritti separatamente nelle sezioni 9 e 8.

**Cosa non è:** non è un'app di fitness per il pubblico, non è un social. È uno strumento di lavoro. Deve sembrare affidabile e leggibile, non divertente.

---

## 2. La direzione visiva in una frase

**L'orologio da vasca e la piastrella.**

I due oggetti che ogni allenatore di nuoto ha davanti agli occhi tutti i giorni sono il pace clock a bordo vasca (quadrante bianco, numeri neri, una lancetta rossa che gira) e il blu della piastrella. Da lì viene tutto:

- fondo chiaro, freddo, pulito, come una piastrella asciutta;
- **il blu profondo della vasca** per tutto ciò su cui si agisce;
- **il rosso della lancetta** riservato a una cosa sola: quello che sta succedendo adesso.

Il rosso non è decorazione. Sull'orologio da vasca la lancetta rossa è l'unica cosa che si muove, ed è quello che l'allenatore guarda. Nell'app vale la stessa regola.

**Dove spendere l'audacia:** una sola schermata deve essere memorabile, quella dell'**allenamento in corso a bordo vasca** — tipografia enorme, colori ridotti all'osso, zero decorazione. Tutto il resto (elenchi, form, impostazioni) sta zitto e fa il suo lavoro.

---

## 3. Colore

Tutti i valori vivono in `lib/theme/app_colors.dart`. Nomi in italiano, come qui.

### Neutri

| Token | Hex | Uso |
| --- | --- | --- |
| `sfondo` | `#EFF2F4` | fondo dell'app |
| `superficie` | `#FFFFFF` | pannelli, righe di elenco, campi |
| `superficieTenue` | `#F7F9FA` | fondi secondari, righe alternate |
| `linea` | `#D5DBE0` | filetti, bordi, separatori |
| `testo` | `#10222E` | testo principale |
| `testoSecondario` | `#55697A` | metadati, descrizioni |
| `testoTenue` | `#8A9AA8` | placeholder, testo disabilitato |

### Colori d'azione

| Token | Hex | Uso |
| --- | --- | --- |
| `blu` | `#0D5C87` | **azione principale**: pulsanti pieni, elementi selezionati, link |
| `bluPremuto` | `#094866` | stato premuto |
| `bluTenue` | `#E3EEF5` | fondo di chip selezionati, evidenziazioni tenui |

### Segnale

| Token | Hex | Uso |
| --- | --- | --- |
| `rosso` | `#D42D1E` | **in corso / adesso**, ed errori |
| `rossoTenue` | `#FCEAE8` | fondo delle fasce di errore |
| `ok` | `#157F4C` | conferme, dati completi, presente |
| `attenzione` | `#B4690E` | avvisi non bloccanti, dati mancanti |

**Regola sul rosso.** Il rosso ha due lavori e si distinguono dalla *forma*, non dal colore:

- **In corso** → sempre piccolo: un punto, un filetto sottile, le cifre di un cronometro che scorre. Mai un fondo pieno.
- **Errore** → sempre dentro una fascia con `rossoTenue` come fondo, con un'icona e un testo.
- **Azioni distruttive** (elimina, archivia) → pulsante con **solo bordo** rosso, mai pieno, e sempre con conferma. Un pulsante rosso pieno non esiste in questa app.

### Grafici a linee

Il grafico Banister (pagina Carico: fitness/fatica/forma) è l'unico grafico a
linee dell'app. Non ha una palette dedicata: usa tre token già esistenti,
scelti per restare fuori dalla regola sul rosso (riservato a "in corso" ed
errori) — **mai** una linea rossa in questo grafico.

| Curva | Token |
| --- | --- |
| Fitness | `blu` |
| Fatica | `attenzione` |
| Forma | `ok` |

### Zone di intensità

Le zone sono il vocabolario tecnico dell'allenatore. Hanno un colore fisso in tutta l'app: nelle serie, nel calendario, nelle statistiche, nella tabella passi.

| Zona | Hex |
| --- | --- |
| A1 | `#4FA3D1` |
| A2 | `#2E8B8B` |
| B1 | `#5A9E3F` |
| B2 | `#C79A18` |
| C1 | `#D68A3A` |
| C2 | `#D9741F` |
| C3 | `#C2571A` |
| D | `#8E3B8F` |

`C` (senza numero) è una zona storica, sostituita da C1/C2/C3: non compare più nelle schermate per nuove serie, ma resta un colore valido (`#D9741F`, lo stesso di C2) per le serie salvate prima dello split, mai rimossa dall'enum del database.

**Il colore non basta mai da solo.** La sigla della zona deve sempre essere scritta accanto al colore. Un allenatore daltonico deve poter usare l'app, e comunque un colore senza etichetta va imparato a memoria.

### Calottine (pallanuoto)

Nella distinta e negli eventi partita, il numero dell'atleta sta dentro un cerchio che riprende il colore reale della calottina: bianca `#FFFFFF` con bordo `linea`, blu `#14477D`, rossa `#D42D1E` per i portieri. È l'unica eccezione ammessa alla regola sul rosso, perché il contesto è inequivocabile.

---

## 4. Tipografia

**Un solo carattere: IBM Plex Sans** (pacchetto `google_fonts`).

Scelto perché è disegnato per la leggibilità tecnica: cifre chiare e distinguibili, forme aperte che reggono a distanza e con schermo bagnato, e un carattere "da strumento di lavoro" invece che da app di consumo.

**IBM Plex Sans Condensed** si userebbe solo dove servono davvero colonne strette: i campi numerici di distinta, tabella passi e referto, più il numero dentro `CapBadge` ovunque appaia. Non è nel catalogo del pacchetto `google_fonts` in uso — un font-asset locale (scaricato da github.com/IBM/plex) è stato provato il 2026-09-07 e **rimosso lo stesso giorno**: causava instabilità di rendering diffusa sul web (liste che smettevano di comparire — allenamenti, atleti — e blocchi dell'app), quasi certamente per come il motore di rendering web gestisce quel font specifico. `AppTypography.condensata()` resta quindi un ripiego su IBM Plex Sans normale finché non si trova un'alternativa sicura (magari un formato diverso, o un altro font condensato).

### Cifre tabulari — obbligatorie

Ogni numero che compare in colonna o rappresenta un tempo (passi, ripetute, ripartenze, split, statistiche) usa `FontFeature.tabularFigures()`. Senza, le colonne di tempi ballano e diventano illeggibili. Questa non è un'opzione estetica.

### Scala

| Ruolo | Dimensione / interlinea | Peso | Uso |
| --- | --- | --- | --- |
| `display` | 44 / 48 | 700 | solo schermata bordo vasca |
| `titoloXl` | 28 / 34 | 600 | titolo di una schermata chiave |
| `titolo` | 22 / 28 | 600 | titolo di schermata, AppBar |
| `sezione` | 17 / 24 | 600 | intestazione di un gruppo |
| `corpo` | 16 / 24 | 400 | testo normale |
| `corpoForte` | 16 / 24 | 600 | valore di un campo, nome atleta |
| `piccolo` | 14 / 20 | 400 | metadati, descrizioni sotto un titolo |
| `etichetta` | 13 / 18 | 500 | etichette dei campi |
| `numeroGrande` | 34 / 38 | 700 | valore di una statistica |

Il corpo del testo parte da 16, non da 14. Si legge a mezzo metro di distanza con gli occhiali bagnati.

### Regole

- **Frase normale, non maiuscolo.** Le etichette si scrivono "Data di nascita", non "DATA DI NASCITA". Il maiuscoletto spaziato sopra ogni titolo è il tic più riconoscibile delle interfacce generate in serie.
- Niente etichetta sopra un contenuto che si spiega da solo.
- Massimo due pesi per schermata: regolare e semigrassetto. Il 700 esiste solo per i numeri grandi e la schermata vasca.
- Righe di testo sotto gli 80 caratteri.

---

## 5. Spaziatura

Scala a base 4: **4, 8, 12, 16, 20, 24, 28, 40, 56**. Non esistono valori fuori da questa scala.

| Contesto | Valore |
| --- | --- |
| Margine laterale schermata (telefono) | 16 |
| Margine laterale schermata (tablet) | 24 |
| Padding interno di un pannello | 16 |
| Spazio fra due campi di un form | 16 |
| Spazio fra due gruppi di campi | 28 |
| Spazio fra due pannelli | 12 |
| Altezza minima di una riga di elenco | 56 |
| Spazio fra due bersagli toccabili | 12 |

Lo spazio è il modo principale per raggruppare le cose. Prima di aggiungere un bordo o un fondo colorato per separare due blocchi, prova ad aumentare lo spazio.

---

## 6. Superfici, raggi, bordi, ombre

**Non tutto è una card.** Il raggio dipende dal ruolo dell'elemento, non è lo stesso ovunque.

| Elemento | Raggio |
| --- | --- |
| Pannello, contenitore di gruppo | 12 |
| Pulsante, campo di testo | 8 |
| Chip, badge, pillola | pieno (999) |
| Bottom sheet, dialog | 20 (solo angoli superiori per i sheet) |
| Cerchio numero calottina, avatar | cerchio |
| Separatori a tutta larghezza | nessuno |

**Bordi invece di ombre.** Un pannello si distingue dal fondo con `superficie` bianca su `sfondo` grigio e un bordo di 1px `linea`. L'ombra è ammessa solo per ciò che davvero galleggia sopra il contenuto (bottom sheet, menu, FAB): `0 6 16 rgba(16, 34, 46, 0.12)`.

### Il filetto di corsia

Elemento strutturale distintivo dell'app. Un filetto verticale di 3px sul lato sinistro di un blocco, colorato secondo l'informazione che porta:

- in una scheda di allenamento: colore della zona della serie;
- in un elenco di sessioni: colore che distingue riscaldamento / parte principale / defaticamento;
- nella riga di una partita in corso: `rosso`.

Serve a leggere la struttura con la coda dell'occhio, senza fermarsi a leggere. **Si usa solo quando porta un'informazione reale**, mai come decorazione.

---

## 7. Icone

- Famiglia unica: **Material Symbols Rounded**, peso 400.
- Dimensioni: 20 in linea col testo, 24 per le azioni della barra.
- In navigazione e nelle azioni principali l'icona sta **sempre insieme a un'etichetta di testo**. Un'icona sola è ammessa solo dove il significato è universale (indietro, chiudi, cerca, più).
- Colore: `testoSecondario` a riposo, `blu` se attiva.

---

## 8. Componenti (schermate da scrivania)

### Pulsanti

Tre livelli, mai di più nella stessa schermata:

1. **Principale** — fondo `blu`, testo bianco, raggio 8, altezza 48. Uno solo per schermata.
2. **Secondario** — bordo 1px `linea`, testo `testo`, fondo `superficie`.
3. **Testuale** — solo testo `blu`, per azioni minori.
4. **Distruttivo** — bordo 1px `rosso`, testo `rosso`, fondo trasparente. Sempre con conferma.

Nei form lunghi il pulsante principale sta in fondo, a tutta larghezza, dentro una barra fissa con fondo `superficie` e un filetto superiore, così resta raggiungibile senza scorrere.

L'etichetta dice cosa succede: "Salva atleta", non "Invia". Niente freccia "→" appiccicata al testo.

### Campi di testo

Il difetto più evidente dell'app oggi sono i campi sottolineati impilati a decine. Da sostituire ovunque:

- fondo `superficie`, bordo 1px `linea`, raggio 8, altezza 52, padding orizzontale 12;
- bordo `blu` da 2px quando il campo è a fuoco;
- **etichetta sopra il campo**, stile `etichetta`, non etichetta flottante;
- testo di aiuto sotto, stile `piccolo`, `testoSecondario`;
- errore: bordo `rosso` + messaggio sotto in `rosso`, mai un popup;
- i campi opzionali si segnalano scrivendo "facoltativo" nell'etichetta, non con un asterisco sugli obbligatori.

### Form

**Nessun form mostra più di cinque campi di fila senza un'interruzione.** I form attuali (Nuovo atleta, Nuova serie, Nuova partita) vanno spezzati in gruppi con un'intestazione `sezione`, un filetto sotto, e 28 di spazio fra un gruppo e l'altro.

Esempio per la scheda atleta: *Anagrafica* / *Attività* / *Contatti e consenso* / *Note*.

Un campo che serve solo in casi rari sta dentro un blocco espandibile chiuso di default, non sempre visibile.

### Elenchi

Righe raggruppate dentro un pannello `superficie` con bordo, separate da filetti `linea` di 1px che partono dopo l'eventuale icona. **Niente `ListTile` nudi appoggiati direttamente sul fondo.**

Ogni riga: titolo `corpoForte`, riga di metadati sotto in `piccolo` / `testoSecondario`.

Per i metadati preferisci l'allineamento e il peso del testo alla stringa unita da puntini. Se un separatore serve davvero, al massimo due informazioni per riga.

### Pannelli statistica

Etichetta `etichetta` in `testoSecondario` sopra, valore `numeroGrande` con cifre tabulari sotto, unità o confronto in `piccolo`. Massimo quattro affiancati, poi vanno a capo.

### Chip e badge

Pillola, altezza 28, padding orizzontale 12, testo `piccolo` peso 500. Usati per: zona, sport, categoria, stato presenza, ruolo (capitano, portiere).

### Schermate vuote

**Regola non negoziabile.** Una schermata senza dati non mostra mai una riga di testo grigio. Struttura fissa, centrata:

1. icona 48 in `testoTenue`;
2. titolo `sezione` che dice cosa manca, in frase normale: "Nessun test registrato";
3. una o due righe `piccolo` che spiegano cosa succede quando ci sarà qualcosa: "I passi delle zone si calcolano dal primo test BVS o T30.";
4. un pulsante principale con l'azione: "Aggiungi test".

Se dalla schermata vuota si può fare più di una cosa (es. aggiungi a mano oppure importa da CSV), il secondo pulsante è secondario.

### Caricamento

Niente rotellina sola in mezzo allo schermo (oggi succede nella schermata MESO). Si usano **scheletri**: rettangoli `superficieTenue` con raggio 8 della forma del contenuto che sta arrivando. La rotellina è ammessa solo dentro un pulsante mentre si salva.

### Errori

**Non deve mai comparire un errore tecnico grezzo nell'interfaccia.** Oggi succede: nella schermata "Nuova partita" viene stampato un `SqliteException` completo di query SQL. Da correggere ovunque.

Un errore si presenta come una fascia con fondo `rossoTenue`, filetto sinistro `rosso`, icona, e:

- **cosa è successo**, in linguaggio umano: "Non è stato possibile salvare la partita.";
- **cosa fare**: "Riprova. Se l'errore continua, chiudi e riapri l'app.";
- il dettaglio tecnico solo dentro un "Mostra dettagli" chiuso, utile per segnalare il problema.

L'errore non si scusa e non è vago.

### Conferme

Azione riuscita → snackbar in basso, `ok`, testo al passato che riprende il verbo del pulsante: "Salva atleta" → "Atleta salvato". Dura 3 secondi.

Azione distruttiva → dialog con titolo che nomina l'oggetto ("Archiviare Sara Napoletani?"), una riga sulle conseguenze, pulsante distruttivo a destra.

---

## 9. Schermate da bordo vasca

Sono un'altra cosa. Riguardano: allenamento in esecuzione, segna presenze, eventi partita in diretta.

**Regole specifiche, che prevalgono su tutto il resto:**

- **Altezza minima dei bersagli: 64.** Mani bagnate, movimento, fretta.
- **Massimo tre azioni per schermata.** Tutto il resto sta dietro un menu.
  **Eccezione:** un'azione con una variante binaria imprevedibile che va
  registrata nell'istante in cui succede (es. superiorità numerica nostra
  o avversaria: non si sa in anticipo quale delle due, e un passaggio in
  più per sceglierla costerebbe il momento esatto dell'evento) resta due
  bersagli affiancati invece di un bottone più una scelta successiva.
  Contano come una sola azione ai fini del limite. Non è una scappatoia
  generale: si applica solo quando l'evento è imprevedibile e il ritardo
  di un passaggio in più è il problema reale, non solo scomodo.
- Tipografia `display` per l'informazione centrale (la serie in corso, il punteggio, il tempo). Deve leggersi a mezzo metro senza avvicinare il tablet.
- Layout pensato per **orizzontale su tablet**, con le azioni sui lati raggiungibili col pollice.
- Il rosso `rosso` compare qui, e solo qui, come indicatore di "in corso": un punto pulsante accanto al cronometro o un filetto sul blocco attivo.
  **Eccezione:** il campo disegnato degli eventi partita pallanuoto usa
  rosso e giallo per le linee reali della vasca (2m, 5m, 6m) — un uso
  rappresentativo dei colori del regolamento, non uno stato "in corso".
- **Nessun form.** Se serve inserire un dato, si fa con bottoni grandi o un bottom sheet con al massimo tre scelte.
  **Eccezione:** scegliere una persona dentro un'intera rosa (13+ convocati)
  non ci sta in tre bottoni né in un menu a tendina (vietato a bordo vasca).
  Pattern accettato: una fascia di calottine numerate sui bordi dello
  schermo (bianche a sinistra/casa, blu a destra/trasferta), sempre
  visibili, che diventano toccabili solo quando serve scegliere un
  giocatore — vedi eventi partita pallanuoto.
- Nessuna azione distruttiva raggiungibile con un tap solo.
- Lo schermo non si spegne mentre una sessione è attiva.

### Chiaro o scuro?

**Chiaro di default, ma l'allenatore può passare a scuro.** Non è più una
decisione presa a tavolino per tutti: dipende dall'impianto (luci, riflessi
dell'acqua) e da chi tocca il tablet quel giorno, quindi le tre schermate da
bordo vasca hanno un interruttore (icona sole/luna nell'AppBar) che ricorda
la scelta sul device.

Resta valido il motivo per cui il chiaro è il default: in un impianto
illuminato uno schermo chiaro alla massima luminosità si legge meglio,
perché uno schermo scuro fa da specchio e restituisce i riflessi delle luci
e dell'acqua. Lo scuro serve per l'opposto — poca luce in impianto, o
riflessi fastidiosi sullo specifico tablet — da valutare a occhio, non a
tavolino.

**Implementazione:** `SuperficiTema` (in `lib/theme/superfici_tema.dart`) è
un `ThemeExtension` con le due varianti (chiaro/scuro) dei soli colori
neutri (sfondo, superficie, testo, linea); `AppTheme.scuroBordoVasca` la usa
al posto di `AppTheme.chiaro`. La scelta è letta da
`temaBordoVascaScuroProvider` (salvata con `shared_preferences`, non
sincronizzata su Supabase: è un gusto del device, non un dato del club).
Riguarda solo le tre schermate da bordo vasca — il resto dell'app resta
sempre chiaro, perché `AppTypography`/`AppColors` restano fissi come prima
ovunque quella scelta non venga letta esplicitamente.

---

## 10. Movimento

- Micro-interazioni (pressione di un pulsante, apertura di un menu): 120 ms.
- Transizioni fra schermate, apertura di un pannello: 220 ms.
- Curva: `Curves.easeOutCubic`. Niente rimbalzi.
- **Il movimento risponde a un'azione della persona.** Nessuna animazione d'ingresso sugli elenchi, nessuna dissolvenza a scaglioni al caricamento di una pagina.
- Unica animazione non richiesta ammessa: il punto rosso che pulsa quando una sessione è in corso, perché comunica uno stato reale.
- Rispettare l'impostazione di sistema per la riduzione del movimento.

---

## 11. Accessibilità

- Contrasto minimo 4,5:1 per il testo, 3:1 per gli elementi grafici. Da verificare, non da supporre.
- Bersagli toccabili minimo 48 (64 a bordo vasca).
- L'app deve reggere l'ingrandimento del testo di sistema fino al 130% senza rompere i layout. Niente altezze fisse sui contenitori di testo.
- **Nessuna informazione affidata al solo colore.** Le zone hanno la sigla, gli stati hanno un'icona, gli errori hanno un testo.
- Ogni icona senza etichetta ha un `Semantics` label.
- Ordine di messa a fuoco coerente con la lettura, per chi usa una tastiera esterna sul tablet.

---

## 12. Come si scrive nell'app

Le parole sono contenuto, non decorazione.

- **Voce:** quella di un collega competente. Diretta, senza fronzoli, senza entusiasmo forzato. Niente punti esclamativi.
- **Frase normale** ovunque: titoli, pulsanti, etichette.
- **Verbi attivi.** Il pulsante dice cosa succede: "Segna presenze", "Genera allenamento", "Archivia atleta".
- **Lo stesso verbo per tutto il percorso.** Se il pulsante dice "Archivia", la conferma dice "Archiviare...?" e il messaggio finale dice "Atleta archiviato". Mai tre parole diverse per la stessa azione.
- **Il linguaggio è quello dell'allenatore**, non del database: "ripartenza", "passo", "vasca", "distinta", "convocati". Mai "record", "entità", "sincronizzazione fallita".
- Una schermata vuota è un invito ad agire, non un dispiacere.
- Ogni testo fa un lavoro solo. Se una frase non aiuta a capire o a decidere, si toglie.

---

## 13. Da non fare

Elenco chiuso. Se una schermata contiene una di queste cose, non è finita.

- Etichette in MAIUSCOLO spaziato sopra i contenuti.
- Testo tecnico grezzo (eccezioni, SQL, nomi di tabelle) visibile all'utente.
- Rotellina di caricamento da sola al centro dello schermo.
- Schermata vuota risolta con una riga di testo grigio.
- Più di cinque campi di fila senza intestazione di gruppo.
- Campi di testo sottolineati in stile Material di default.
- `ListTile` appoggiati direttamente sul fondo, senza pannello.
- Tutto chiuso dentro riquadri identici, con lo stesso raggio e la stessa ombra grigia.
- Pulsante rosso pieno.
- Colori scritti a mano dentro il codice di una schermata.
- Più di un pulsante principale nella stessa schermata.
- Freccia "→" attaccata al testo di un pulsante.
- Sfumature usate come decoro.
- Metadati incollati con puntini in mezzo per più di due informazioni.
- Testo sotto i 14 in qualsiasi punto dell'app.

---

## 14. Implementazione in Flutter

### Struttura dei file

```
lib/theme/
  app_colors.dart        # tutti i colori, nessuno altrove
  app_typography.dart    # scala tipografica, cifre tabulari
  app_spacing.dart       # scala 4 e raggi
  app_theme.dart         # ThemeData completo, chiaro
  domain_tokens.dart     # ThemeExtension: colori zone, colori calottina, colore "in corso"
```

`app_theme.dart` configura almeno: `colorScheme`, `textTheme`, `inputDecorationTheme`, `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `cardTheme`, `appBarTheme`, `dividerTheme`, `chipTheme`, `snackBarTheme`, `bottomSheetTheme`, `floatingActionButtonTheme`.

I token di dominio (zone, calottine, "in corso") non stanno in `ColorScheme`: vanno in una `ThemeExtension` dedicata, letta con `Theme.of(context).extension<DomainTokens>()`.

### Widget riutilizzabili

Vivono in `lib/widgets/`. Una schermata nuova si compone con questi, non ricostruisce nulla da zero:

`AppScaffold`, `SectionHeader`, `FormGroup`, `AppTextField`, `AppSelect`, `PrimaryButton`, `SecondaryButton`, `DangerButton`, `AppListPanel`, `AppListRow`, `StatPanel`, `ZoneChip`, `CapBadge`, `LaneRule`, `EmptyState`, `ErrorBanner`, `LoadingSkeleton`, `PoolCard`, `OrdineBadge`.

Se serve un componente nuovo, si aggiunge qui e si documenta in questo file. Non si scrive un widget su misura dentro una singola schermata.

### Regole di codice

- Nessun `Color(0x...)`, `EdgeInsets` con numeri arbitrari o `TextStyle` inline dentro le schermate.
- Nessun `Card` con elevazione di default.
- I numeri passano sempre da uno stile con cifre tabulari.
- Le dimensioni vengono da `AppSpacing`, mai scritte a mano.

### Ordine di lavoro

Non si rifà tutta l'app in una volta. Ordine:

1. `lib/theme/` completo e applicato a `MaterialApp`;
2. i widget riutilizzabili della lista sopra;
3. **una schermata pilota** portata a termine e approvata — proposta: la scheda atleta, perché contiene form, gruppi, azione distruttiva e stato vuoto;
4. tutte le altre, una per volta, partendo da quelle usate a bordo vasca.

---

## 15. Checklist prima di dire "finita"

- [ ] Nessun colore, spazio o stile scritto a mano nel file della schermata
- [ ] Un solo pulsante principale
- [ ] Nessun gruppo di più di cinque campi senza intestazione
- [ ] Stato vuoto con icona, titolo, spiegazione e azione
- [ ] Stato di caricamento a scheletro
- [ ] Stato di errore leggibile, senza testo tecnico
- [ ] Tutti i bersagli almeno 48 (64 a bordo vasca)
- [ ] I numeri usano cifre tabulari
- [ ] Le zone hanno colore **e** sigla
- [ ] Testo delle azioni coerente fra pulsante, conferma e messaggio finale
- [ ] Provata a 130% di ingrandimento testo senza rotture
- [ ] Provata in orizzontale su tablet se è una schermata da vasca
- [ ] Nessuna voce della sezione 13 presente

---

## 16. Decisioni ancora aperte

Da chiudere con l'uso reale, non a tavolino:

1. ~~Chiaro o scuro a bordo vasca~~ (sezione 9) — risolto: ora è una scelta dell'allenatore, non più una decisione unica per tutti.
2. **Densità su tablet.** Se in orizzontale rimane troppo spazio vuoto, valutare un layout a due colonne per le schermate di gestione. Da decidere quando ci saranno dati veri.
3. **Colore delle zone.** Se un allenatore che usa già una convenzione diversa fatica a leggerle, si cambia la palette: sono token, cambia un file.
