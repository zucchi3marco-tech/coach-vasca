# DESIGN.md — SwimCoach FIN

Sistema di design dell'app. Questo file è **vincolante**: ogni schermata nuova o rifatta deve rispettarlo.

Versione 2 — riscrittura con tema chiaro e tema scuro su tutta l'app, architettura dei token a tre livelli e sistema di layout esplicito.

## 0. Come usare questo file (istruzioni per Claude Code)

- Leggi questo file all'inizio di ogni sessione che tocca l'interfaccia.
- I valori qui dentro vivono in un unico posto nel codice (`lib/theme/`). **Non scrivere mai colori, dimensioni, raggi o durate direttamente dentro le schermate.**
- Ogni colore che una schermata usa arriva da `Theme.of(context)`. Non esistono più costanti statiche di colore raggiungibili da una schermata: un colore statico non sa in che tema si trova, e a tema scuro attivo diventa un bug visivo.
- Se una schermata ha bisogno di qualcosa che qui non è previsto, non inventare: proponi l'aggiunta, aggiorniamo questo file, poi implementa.
- Prima di dire che una schermata è finita, passa la checklist della sezione 19. La checklist si passa **due volte**, una per tema.

---

## 1. Il contesto

**Chi la usa:** allenatori di nuoto e pallanuoto tesserati FIN. Persone che passano quattro ore al giorno a bordo vasca con un tablet in mano, spesso in piedi, con le mani bagnate, mentre venti ragazzi aspettano istruzioni.

**Dove la usano:** due mondi diversi, con esigenze opposte.

1. **A bordo vasca**, durante l'allenamento o la partita: sguardo di due secondi, tap veloce, distanza di lettura di mezzo metro, luce forte, riflessi dell'acqua.
2. **Alla scrivania**, per programmare la stagione, inserire test, leggere statistiche: seduti, con calma, tanti dati sullo schermo, spesso da browser.

Questi due contesti hanno regole diverse. Sono descritti separatamente nelle sezioni 12 e 13.

**Cosa non è:** non è un'app di fitness per il pubblico, non è un social. È uno strumento di lavoro. Deve sembrare affidabile e leggibile, non divertente.

**Cosa vuol dire "attraente" qui.** Non decorazione. Un'app di lavoro attrae perché è nitida: contrasti puliti, spazio generoso, allineamenti che tornano, colore raro e quindi significativo, numeri che si leggono al volo. La bellezza di questo strumento è la stessa di un cronometro professionale, non quella di una landing page.

---

## 2. La direzione visiva in una frase

**L'orologio da vasca e la piastrella, di giorno. L'acqua illuminata, di notte.**

I due oggetti che ogni allenatore ha davanti agli occhi sono il pace clock a bordo vasca (quadrante bianco, numeri neri, una lancetta rossa che gira) e il blu della piastrella. Da lì viene il tema chiaro:

- fondo chiaro, freddo, pulito, come una piastrella asciutta;
- **il blu profondo della vasca** per tutto ciò su cui si agisce;
- **il rosso della lancetta** riservato a una cosa sola: quello che sta succedendo adesso.

Il tema scuro non è il chiaro rovesciato. Ha una sua immagine: **la vasca di sera, con le luci accese sotto il pelo dell'acqua.** Fondi blu-neri, mai grigi neutri e mai nero pieno; l'azzurro dell'acqua illuminata come colore d'azione al posto del blu profondo, perché su fondo scuro un blu scuro sparisce.

Questo è il motivo per cui i due temi non condividono un solo valore esadecimale, e non devono.

**Dove spendere l'audacia:** una sola schermata deve essere memorabile, quella dell'**allenamento in corso a bordo vasca** — tipografia enorme, colori ridotti all'osso, zero decorazione. Tutto il resto (elenchi, form, impostazioni) sta zitto e fa il suo lavoro.

**Seconda eccezione, la dashboard atleta.** È la schermata-vetrina dell'atleta — il primo (e spesso unico) punto su cui gira tutto il suo account, l'equivalente per lui della pagina bordo vasca per l'allenatore — quindi ha una sua tavolozza dedicata: `TokenDominio.evidenzaCiano`/`evidenzaVerde`/`evidenzaAmbra`, un colore diverso per l'icona di ogni scheda invece del solo `azione`, più lo stesso duo ciano/verde sul grafico Banister ovunque appaia (anche fuori dalla dashboard, es. `CaricoAtletaScreen`). Resta legata al tema chiaro/scuro dell'utente come tutto il resto dell'app — nessuna schermata "sempre scura" a parte. **Delimitata**: sfondi dei pannelli, titoli e i valori degli `StatPanel` restano neutri, il colore arriva solo dalle icone e dal grafico; la tavolozza `evidenza*` non si estende ad altre schermate senza deciderlo di nuovo esplicitamente qui.

**Terza eccezione, la home dell'allenatore.** Estendendo la stessa logica, la sua schermata principale (le 5 tab Atleti/Allenamenti/Schemi tattici/Stagioni/Partite, o 4 per il nuoto: niente Schemi tattici, l'ultima si chiama Gare) riceve lo stesso colpo d'occhio a colori: le icone delle tab usano `evidenzaCiano`/`evidenzaViola`/`evidenzaVerde`/`evidenzaAmbra` quando selezionate (Atleti resta su `azione`, l'ancora neutra — stesso ruolo di "Il tuo club" nella dashboard atleta), e una card di riepilogo sopra l'elenco atleti (`_RiepilogoClub`, `atleti_list_screen.dart`) mostra 3 statistiche rapide del club con la stessa tavolozza. **Delimitata** allo stesso modo: nessun altro sfondo/titolo/testo cambia colore, la card di riepilogo è un `PoolCard` neutro come tutti gli altri, il colore arriva solo dalle icone.

---

## 3. Architettura dei token

Tre livelli. La regola è che ogni livello può leggere solo quello sopra di sé.

| Livello | Cosa contiene | Chi lo legge |
| --- | --- | --- |
| **1. Primitivi** | le scale di colore grezze (`blu600`, `neutro100`…). Nessun significato. | solo il livello 2 |
| **2. Semantici** | il significato (`sfondo`, `superficie`, `azione`, `testo`, `rosso`). Ha **due valori**, uno per tema. | i componenti e le schermate |
| **3. Dominio** | i colori che sono dati, non interfaccia: zone di intensità, calottine, serie dei grafici. Ha due valori. | i componenti di dominio |

**Le schermate usano solo il livello 2 e 3.** Un primitivo dentro una schermata è un errore, sempre: significa che quel colore non cambierà passando al tema scuro.

Nomi dei token in italiano, come in tutto questo file. Nomi dei widget in inglese, come già nel codice.

---

## 4. Colore — primitivi

Vivono in `lib/theme/tokens/palette.dart`. **Nessuna schermata importa questo file.**

### Acqua (la scala d'azione)

| Token | Hex |
| --- | --- |
| `acqua50` | `#EDF6FB` |
| `acqua100` | `#D3E8F4` |
| `acqua200` | `#A9D2E8` |
| `acqua300` | `#71B4D6` |
| `acqua400` | `#4FC3E8` |
| `acqua500` | `#1E76A4` |
| `acqua600` | `#0D5C87` |
| `acqua700` | `#094B6E` |
| `acqua800` | `#073A55` |
| `acqua900` | `#05293C` |

`acqua600` è il blu della piastrella, azione nel tema chiaro. `acqua400` è l'acqua illuminata, azione nel tema scuro.

### Neutri chiari (piastrella)

| Token | Hex |
| --- | --- |
| `chiaro0` | `#FFFFFF` |
| `chiaro50` | `#F7FAFC` |
| `chiaro100` | `#EEF2F5` |
| `chiaro200` | `#DCE3E9` |
| `chiaro300` | `#C3CDD6` |
| `chiaro500` | `#64798A` |
| `chiaro600` | `#4A5F70` |
| `chiaro900` | `#0C1B24` |

### Neutri scuri (acqua di notte)

| Token | Hex |
| --- | --- |
| `scuro900` | `#0B141B` |
| `scuro800` | `#121E27` |
| `scuro700` | `#18262F` |
| `scuro600` | `#1F2F3A` |
| `scuro500` | `#253743` |
| `scuro400` | `#263844` |
| `scuro300` | `#38505F` |
| `scuro200` | `#7A8E9D` |
| `scuro100` | `#A3B5C2` |
| `scuro50` | `#E8EFF4` |

I neutri scuri hanno una punta di blu (circa 205° di tinta, saturazione 25–30%). Un grigio neutro puro, a fianco dell'azzurro d'azione, sembra sporco.

### Segnale

| Ruolo | Variante chiara | Variante scura |
| --- | --- | --- |
| Rosso | `#D42D1E` | `#FF6B5A` |
| Verde | `#157F4C` | `#45D391` |
| Ambra | `#9E5A08` | `#F0A93C` |

---

## 5. Colore — token semantici

Questa è la tabella operativa. Vive in `lib/theme/tokens_chiaro.dart` e `lib/theme/tokens_scuro.dart`, esposta come `ThemeExtension<ColoriApp>`.

### Superfici

| Token | Chiaro | Scuro | Uso |
| --- | --- | --- | --- |
| `sfondo` | `#EEF2F5` | `#0B141B` | fondo dell'app, dietro tutto |
| `superficie` | `#FFFFFF` | `#121E27` | pannelli, righe di elenco, campi, AppBar |
| `superficieAlt` | `#F7FAFC` | `#18262F` | righe alternate, fondi secondari, intestazioni di tabella |
| `superficieAlta` | `#FFFFFF` | `#1F2F3A` | menu, dropdown, snackbar, tooltip |
| `superficieMassima` | `#FFFFFF` | `#253743` | dialog, bottom sheet |
| `scrim` | `rgba(12,27,36,0.48)` | `rgba(3,8,12,0.72)` | velo dietro dialog e sheet |

Nel tema chiaro i livelli si distinguono con **ombra e bordo**, perché la superficie resta bianca. Nel tema scuro si distinguono con **la luminosità della superficie**, perché un'ombra su fondo scuro non si vede. Dettagli in sezione 10.

### Linee

| Token | Chiaro | Scuro | Uso |
| --- | --- | --- | --- |
| `linea` | `#DCE3E9` | `#263844` | bordi dei pannelli, separatori di elenco |
| `lineaForte` | `#C3CDD6` | `#38505F` | bordo di un campo a riposo, divisione fra due aree del layout |

Nel tema scuro i bordi contano più che nel chiaro: senza bordo, un pannello `#121E27` su fondo `#0B141B` è quasi invisibile. **Un pannello senza bordo non esiste in questa app.**

### Testo

| Token | Chiaro | Scuro | Contrasto sul proprio fondo | Uso |
| --- | --- | --- | --- | --- |
| `testo` | `#0C1B24` | `#E8EFF4` | 16:1 / 14,6:1 | testo principale, numeri, titoli |
| `testoSecondario` | `#4A5F70` | `#A3B5C2` | 6,6:1 / 8,0:1 | metadati, descrizioni, icone a riposo |
| `testoTenue` | `#64798A` | `#7A8E9D` | 4,5:1 / 5,0:1 | placeholder, testo disabilitato, unità di misura |

Niente `#000000` nel chiaro e niente `#FFFFFF` nello scuro. Il nero pieno su bianco affatica, il bianco pieno su fondo scuro sfarfalla ai bordi delle lettere.

`testoTenue` sta esattamente sulla soglia 4,5:1. Non abbassarlo oltre, e non usarlo per un'informazione che serve davvero.

### Azione

| Token | Chiaro | Scuro | Uso |
| --- | --- | --- | --- |
| `azione` | `#0D5C87` | `#4FC3E8` | pulsanti pieni, elementi selezionati, link, icone attive |
| `azionePremuta` | `#094B6E` | `#71B4D6` | stato premuto |
| `azioneInk` | `#FFFFFF` | `#072A38` | testo e icone **sopra** `azione` |
| `azioneTenue` | `#E3EEF5` | `rgba(79,195,232,0.14)` | fondo di chip selezionati, riga di elenco selezionata |
| `azioneFuoco` | `rgba(13,92,135,0.40)` | `rgba(79,195,232,0.45)` | anello di messa a fuoco |

Nota sul tema scuro: `azioneInk` è **inchiostro scuro**, non bianco. Testo bianco sopra un azzurro chiaro dà 2,9:1 e non si legge. Con `#072A38` il rapporto è 7,4:1.

I fondi tenui nello scuro sono **il colore d'azione a bassa opacità sopra la superficie**, non una tinta pastello fissa. Una tinta pastello su fondo scuro sembra una macchia.

### Segnale

| Token | Chiaro | Scuro | Uso |
| --- | --- | --- | --- |
| `rosso` | `#D42D1E` | `#FF6B5A` | **in corso / adesso**, ed errori |
| `rossoTenue` | `#FCEAE8` | `rgba(255,107,90,0.14)` | fondo delle fasce di errore |
| `ok` | `#157F4C` | `#45D391` | conferme, dati completi, presente |
| `okTenue` | `#E6F4EC` | `rgba(69,211,145,0.14)` | fondo di una conferma persistente |
| `attenzione` | `#9E5A08` | `#F0A93C` | avvisi non bloccanti, dati mancanti |
| `attenzioneTenue` | `#FBF1E2` | `rgba(240,169,60,0.14)` | fondo di un avviso |

**Regola sul rosso.** Il rosso ha due lavori e si distinguono dalla *forma*, non dal colore:

- **In corso** → sempre piccolo: un punto, un filetto sottile, le cifre di un cronometro che scorre. Mai un fondo pieno.
- **Errore** → sempre dentro una fascia con `rossoTenue` come fondo, con un'icona e un testo.
- **Azioni distruttive** → pulsante con **solo bordo** rosso, mai pieno, e sempre con conferma. Un pulsante rosso pieno non esiste in questa app.

---

## 6. Come il colore attrae

Il colore in questa app ha un solo mestiere: **portare l'occhio dove serve, nell'ordine giusto.** Attrae perché è raro. Se coloro tutto, non attraggo niente.

### Gerarchia dell'attenzione

Quattro livelli. Una schermata li rispetta tutti e quattro, in quest'ordine.

| Livello | Colore | Quanto | Cosa comunica |
| --- | --- | --- | --- |
| 1 | `rosso` | **al massimo un elemento** per schermata, e piccolo | sta succedendo adesso |
| 2 | `azione` | **un solo pieno** per schermata, più i testuali | qui si agisce |
| 3 | dominio (zone, calottine, serie) | quanti ne servono | questo è un dato, non una gerarchia |
| 4 | neutri | tutto il resto | struttura, testo, contenitori |

Il livello 1 vince sempre sul 2: se in una schermata c'è una sessione in corso, il punto rosso deve essere la prima cosa che si vede, anche se accanto c'è il pulsante principale.

Il livello 3 non partecipa alla gerarchia. I colori delle zone sono un'etichetta, come la sigla scritta accanto: non vogliono attirare l'occhio più della zona vicina, vogliono solo essere distinguibili fra loro.

### Il budget del colore

In una schermata da scrivania, i pixel non neutri stanno **sotto il 10% dell'area visibile**. Se superi quella soglia, il pulsante principale smette di essere il punto più forte dello schermo e la schermata diventa rumore.

Modo pratico di verificarlo: guarda la schermata socchiudendo gli occhi. Devi vedere una macchia colorata sola (l'azione), oppure due se c'è qualcosa in corso. Se ne vedi cinque, qualcosa va tolto.

### Cosa non colora mai

- I titoli. Un titolo si distingue per dimensione e peso, non per tinta.
- Le intestazioni di sezione.
- I bordi dei pannelli, che restano `linea` anche quando il pannello è importante.
- I fondi dei pannelli, che restano `superficie` salvo che stiano segnalando uno stato (errore, avviso, selezione).
- Le icone decorative dentro gli stati vuoti, che stanno in `testoTenue`.

### L'unica sfumatura ammessa

Nessuna sfumatura è decorazione. Ne esiste **una sola** in tutta l'app: il blocco principale della schermata di allenamento a bordo vasca, dietro il numero grande.

- Chiaro: verticale da `#0D5C87` a `#073A55`.
- Scuro: verticale da `#0B141B` a `#05293C`.

Serve a dare profondità all'unico punto dell'app che deve farsi guardare da mezzo metro. Fuori da lì, una sfumatura è un difetto da correggere.

### Il colore significa la stessa cosa nei due temi

`rosso` vuol dire "adesso" tanto nel chiaro quanto nello scuro. Cambia l'esadecimale, non il significato. Non esiste un elemento che è blu di giorno e verde di notte: quello non è un tema, è un'altra app.

---

## 7. Colore di dominio

### Zone di intensità

Sono il vocabolario tecnico dell'allenatore. Hanno un colore fisso in tutta l'app: nelle serie, nel calendario, nelle statistiche, nella tabella passi.

| Zona | Chiaro | Scuro |
| --- | --- | --- |
| A1 | `#4FA3D1` | `#6FBDE6` |
| A2 | `#2E8B8B` | `#4FB3B3` |
| B1 | `#5A9E3F` | `#7CC45E` |
| B2 | `#C79A18` | `#E3BA45` |
| C1 | `#D68A3A` | `#EDA75C` |
| C2 | `#D9741F` | `#F09146` |
| C3 | `#C2571A` | `#E37440` |
| D | `#8E3B8F` | `#B769B8` |

`C` (senza numero) è una zona storica, sostituita da C1/C2/C3: non compare più nelle schermate per nuove serie, ma resta un colore valido (gli stessi valori di C2) per le serie salvate prima dello split, mai rimossa dall'enum del database.

**Come si mostra una zona.** Mai come fondo pieno con testo sopra: quattro di questi otto colori non reggono il testo bianco né quello nero. Il pattern unico, in entrambi i temi:

- un **punto pieno di 8px** nel colore della zona, oppure un **filetto verticale di 3px**;
- la **sigla accanto**, in `testo`, stile `etichetta`;
- se serve un chip, fondo = colore della zona al **12%** (chiaro) o al **18%** (scuro) sopra `superficie`, bordo 1px del colore della zona al 40%, testo in `testo`.

Così il contrasto del testo è garantito dai neutri e il colore fa solo il suo lavoro di riconoscimento.

**Il colore non basta mai da solo.** La sigla va sempre scritta. Un allenatore daltonico deve poter usare l'app, e comunque otto colori senza etichetta vanno imparati a memoria.

### Calottine (pallanuoto)

Nella distinta e negli eventi partita, il numero dell'atleta sta dentro un cerchio che riprende il colore reale della calottina.

| Calottina | Fondo chiaro | Fondo scuro | Numero |
| --- | --- | --- | --- |
| Bianca | `#FFFFFF`, bordo `lineaForte` | `#E8EFF4`, bordo `#7A8E9D` | `#0C1B24` |
| Blu | `#14477D` | `#2A6DB0` | `#FFFFFF` |
| Rossa (portiere) | `#D42D1E` | `#E8503F` | `#FFFFFF` |

È l'unica eccezione ammessa alla regola sul rosso, perché il contesto è inequivocabile. Nel tema scuro i tre colori si alzano di luminosità: una calottina blu `#14477D` su fondo `#121E27` non si distingue dal fondo.

### Grafici

Il grafico Banister (pagina Carico: fitness/fatica/forma) è l'unico grafico a linee dell'app. Usa token esistenti, scelti per restare fuori dalla regola sul rosso — **mai** una linea rossa in questo grafico.

| Curva | Token |
| --- | --- |
| Fitness | `azione` |
| Fatica | `attenzione` |
| Forma | `ok` |

Regole di lettura valide per ogni grafico:

- spessore della linea 2px, nessun punto sui vertici salvo quello selezionato;
- griglia orizzontale in `linea`, nessuna griglia verticale;
- asse Y con al massimo 5 tacche, etichette in `testoTenue`, stile `etichetta`, cifre tabulari;
- area sotto la curva solo se c'è una curva sola, riempita con il colore al 10%;
- la legenda sta sopra il grafico, in orizzontale, con un punto pieno e l'etichetta — mai una legenda staccata in basso a destra.

---

## 8. Tipografia

**Un solo carattere: IBM Plex Sans** (pacchetto `google_fonts`).

Scelto perché è disegnato per la leggibilità tecnica: cifre chiare e distinguibili, forme aperte che reggono a distanza e con schermo bagnato, e un carattere "da strumento di lavoro" invece che da app di consumo. Un secondo carattere non serve: la personalità la porta la scala, non la varietà.

**IBM Plex Sans Condensed** si userebbe solo dove servono davvero colonne strette: i campi numerici di distinta, tabella passi e referto, più il numero dentro `CapBadge`. Non è nel catalogo del pacchetto `google_fonts` in uso — un font-asset locale (da github.com/IBM/plex) è stato provato il 2026-09-07 e **rimosso lo stesso giorno**: causava instabilità di rendering diffusa sul web (liste che smettevano di comparire, blocchi dell'app), quasi certamente per come il motore di rendering web gestisce quel font specifico. `AppTypography.condensata()` resta quindi un ripiego su IBM Plex Sans normale finché non si trova un'alternativa sicura.

### Funzioni tipografiche obbligatorie

Ogni numero che compare in colonna o rappresenta un tempo (passi, ripetute, ripartenze, split, statistiche, punteggi, cronometri) usa:

- `FontFeature.tabularFigures()` — senza, le colonne di tempi ballano e diventano illeggibili;
- `FontFeature.slashedZero()` — a mezzo metro di distanza uno zero e una O si confondono.

Questa non è una scelta estetica. Vive in `AppTypography.numerica()` e ogni stile numerico passa da lì.

### Scala

| Ruolo | Dimensione / interlinea | Peso | Spaziatura lettere | Uso |
| --- | --- | --- | --- | --- |
| `display` | 44 / 46 · **64 / 66** su tablet | 700 | −1,0 | solo schermate bordo vasca |
| `titoloXl` | 28 / 34 | 600 | −0,4 | titolo di una schermata chiave |
| `titolo` | 22 / 28 | 600 | −0,2 | titolo di schermata, AppBar |
| `sezione` | 17 / 24 | 600 | 0 | intestazione di un gruppo |
| `corpo` | 16 / 24 | 400 | 0 | testo normale |
| `corpoForte` | 16 / 24 | 600 | 0 | valore di un campo, nome atleta |
| `piccolo` | 14 / 20 | 400 | 0 | metadati, descrizioni sotto un titolo |
| `etichetta` | 13 / 18 | 500 | +0,1 | etichette dei campi, voci di navigazione, assi dei grafici |
| `numeroGrande` | 34 / 38 | 700 | −0,5 | valore di una statistica |
| `numeroMedio` | 22 / 26 | 600 | −0,2 | numeri dentro una riga di tabella o di elenco |

La spaziatura negativa sui corpi grandi non è un vezzo: IBM Plex a 44px con spaziatura zero sembra slegato. Sotto i 17px la spaziatura resta a zero, tranne `etichetta` che guadagna un soffio di aria perché è la dimensione più piccola dell'app.

Il corpo del testo parte da 16, non da 14. Si legge a mezzo metro di distanza con gli occhiali bagnati.

**Dimensione minima assoluta: 13**, e solo per `etichetta`. Non esiste testo a 12 o a 11 da nessuna parte, comprese le voci della barra di navigazione e le etichette degli assi.

### Regole

- **Frase normale, non maiuscolo.** Le etichette si scrivono "Data di nascita", non "DATA DI NASCITA". Il maiuscoletto spaziato sopra ogni titolo è il tic più riconoscibile delle interfacce generate in serie.
- Niente etichetta sopra un contenuto che si spiega da solo.
- Massimo due pesi per schermata: regolare e semigrassetto. Il 700 esiste solo per i numeri grandi e la schermata vasca.
- Righe di testo sotto gli 80 caratteri: su schermo largo il testo lungo sta in una colonna da 640, non a tutta pagina.
- Niente parola singola evidenziata dentro un titolo, né in colore né in grassetto.
- I pesi nel tema scuro scendono di un gradino percepito: il testo chiaro su fondo scuro sembra più grasso. Dove nel chiaro useresti 600, nello scuro valuta 500 per i blocchi lunghi. I titoli restano 600 in entrambi.

---

## 9. Spaziatura e ritmo

Scala a base 4: **4, 8, 12, 16, 20, 24, 28, 32, 40, 48, 56, 64**. Non esistono valori fuori da questa scala.

| Contesto | Valore |
| --- | --- |
| Padding interno di un pannello | 16 (20 da `esteso` in su) |
| Spazio fra due campi di un form | 16 |
| Spazio fra due gruppi di campi | 28 |
| Spazio fra due pannelli | 12 |
| Spazio fra due sezioni di pagina | 32 |
| Spazio sopra un'intestazione di sezione | 28 |
| Spazio sotto un'intestazione di sezione | 12 |
| Altezza minima di una riga di elenco | 56 |
| Spazio fra due bersagli toccabili | 12 |
| Spazio fra icona e testo dentro un elemento | 8 |
| Spazio fra due chip | 8 |

Lo spazio è il modo principale per raggruppare le cose. Prima di aggiungere un bordo o un fondo colorato per separare due blocchi, prova ad aumentare lo spazio.

**Ritmo verticale.** Lo spazio sopra un blocco è sempre maggiore o uguale a quello sotto il blocco precedente, mai il contrario: un'intestazione deve stare attaccata al suo contenuto e staccata da quello prima. Uno spazio di 28 sopra e 12 sotto un'intestazione di sezione è ciò che rende leggibile un form lungo senza disegnare un solo bordo.

---

## 10. Layout

Questa sezione è vincolante quanto i colori. Un'app fatta di componenti giusti disposti male sembra comunque un prototipo.

### Punti di rottura

| Nome | Larghezza logica | Dispositivo tipico |
| --- | --- | --- |
| `compatto` | < 600 | telefono verticale |
| `medio` | 600 – 839 | tablet verticale, telefono orizzontale |
| `esteso` | 840 – 1199 | tablet orizzontale |
| `largo` | ≥ 1200 | browser da scrivania (il build web su Vercel) |

Vivono in `lib/theme/app_layout.dart` come `Breakpoint.of(context)`. **Nessuna schermata scrive `MediaQuery.of(context).size.width > 600` a mano.**

### Griglia e margini

| | `compatto` | `medio` | `esteso` | `largo` |
| --- | --- | --- | --- | --- |
| Margine laterale | 16 | 24 | 32 | 32 |
| Colonne | 4 | 8 | 12 | 12 |
| Gronda fra colonne | 16 | 24 | 24 | 24 |
| Larghezza massima del contenuto | — | — | — | 1200, centrato |

Oltre i 1200 il contenuto **non si allarga**: si centra e ai lati resta `sfondo`. Una riga di elenco larga 1900px è illeggibile e fa sembrare l'app una pagina web mal fatta.

### Larghezze massime per tipo di contenuto

| Contenuto | Larghezza massima |
| --- | --- |
| Colonna di un form | 640 |
| Testo discorsivo (spiegazioni, stati vuoti) | 560 |
| Pannello di dettaglio | 880 |
| Elenco in layout a due pannelli | 360 fisso |
| Cruscotto a più pannelli | 1200 |

### Navigazione

| Punto di rottura | Struttura |
| --- | --- |
| `compatto` | barra in basso, massimo 5 voci, altezza 64 + area sicura |
| `medio`, `esteso` | rail verticale a sinistra, larghezza 88, icona 24 sopra etichetta `etichetta` |
| `largo` | rail estesa, larghezza 240, icona e etichetta in linea, sezioni separate da 1px `linea` |

In tutti i casi: icona **più** etichetta di testo, sempre. La voce attiva ha icona in `azione` con riempimento pieno (Material Symbols `FILL 1`), etichetta in `azione` peso 600, e un indicatore — pillola `azioneTenue` dietro l'icona nel compatto, filetto verticale di 3px `azione` a sinistra nella rail. Le voci a riposo hanno icona `FILL 0` in `testoSecondario`.

La barra in basso non ha ombra: ha un bordo superiore di 1px `linea` e fondo `superficie`.

#### Barra club (in alto)

Sopra il Navigator, fissa su ogni schermata dell'utente autenticato: **logo** (torna alla home) + **nome del club** + selettore del tema + menu ☰ (notifiche, sincronizzazione, installa l'app, cambia gruppo, guida, esci). Ogni schermata tiene sotto la sua AppBar (freccia e titolo).

- Altezza 44 più l'area sicura in alto; fondo `superficie`, nessuna ombra, bordo inferiore di 1px `linea`. Nome del club in `corpoForte`, una riga, con i puntini se troppo lungo.
- Il logo dell'allenatore chiude le schermate aperte e riporta alla prima tab (Atleti, col riepilogo del gruppo); quello dell'atleta alla sua dashboard.
- **Nascosta** su lavagna tattica (editor e visualizzatore), partita dal vivo, eventi partita, segna presenze e scheda bordo vasca: schermate a tutto schermo, da usare in piedi con una mano sola. Una schermata si dichiara così avvolgendosi in `NascondiBarraClub`; la barra torna da sola alla chiusura.
- Sta fuori dal Navigator, quindi non ci vanno `Tooltip`, `PopupMenuButton` né `showDialog` col proprio contesto: menu e dialoghi passano da `navigatorKeyApp` (`showMenu` sull'overlay del Navigator). Un dialogo aperto non copre la barra.

### Archetipi di pagina

Ogni schermata dell'app è uno di questi cinque. Se non lo è, fermati e chiedi.

**A. Pagina elenco**

```
compatto                          esteso / largo
┌────────────────────────┐        ┌──────┬──────────────┬──────────────────────┐
│ ← Atleti          [+]  │        │      │ ← Atleti [+] │  Sara Napoletani     │
├────────────────────────┤        │ rail ├──────────────┤  ──────────────────  │
│ [cerca]                │        │  88  │ [cerca]      │  [contenuto dettaglio│
│ (chip) (chip) (chip)  →│        │      │ (chip)(chip)→│   in pannelli]       │
├────────────────────────┤        │      ├──────────────┤                      │
│ ▌ Sara Napoletani      │        │      │▌Sara N.      │                      │
│   2009 · Ragazze       │        │      │ 2009·Ragazze │                      │
│ ─────────────────────  │        │      │──────────────│                      │
│ ▌ Marco Bertoli        │        │      │ Marco B.     │                      │
└────────────────────────┘        │      │  ← 360 →     │  ← max 880 →         │
 ═══ barra in basso ═══           └──────┴──────────────┴──────────────────────┘
```

Da `esteso` in su l'elenco diventa **a due pannelli**: lista a sinistra larga 360 fissa, dettaglio a destra. La riga selezionata ha fondo `azioneTenue` e filetto sinistro `azione` di 3px. I due pannelli scorrono in modo indipendente e la lista conserva la sua posizione di scorrimento quando cambi elemento. Questo chiude la vecchia decisione aperta sulla densità da tablet.

Il campo di ricerca e la fila di chip restano fissi sopra la lista, non scorrono con essa.

**B. Pagina dettaglio**

```
┌──────────────────────────────────────┐
│ ← Sara Napoletani              ⋮     │  AppBar 56 / 64
├──────────────────────────────────────┤
│ Sara Napoletani            [Modifica]│  intestazione: titoloXl + azione
│ 2009 · Ragazze · 100 SL                  secondaria, mai un pulsante pieno
├──────────────────────────────────────┤  ── 32 ──
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │  fascia statistica, max 4 affiancate
│ │ 1:02 │ │  14  │ │ 82%  │ │  3   │ │
│ └──────┘ └──────┘ └──────┘ └──────┘ │
│  ── 32 ──                            │
│ Test                                 │  sezione
│ ┌──────────────────────────────────┐ │
│ │ riga · riga · riga               │ │  AppListPanel
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

L'azione principale di una pagina di dettaglio non sta nell'intestazione: sta nella barra fissa in basso, o è un `FabAzioni`. Nell'intestazione stanno solo azioni secondarie.

**C. Pagina form**

```
┌──────────────────────────────────────┐
│ ← Nuovo atleta                       │
├──────────────────────────────────────┤
│  ┌────────── max 640 ──────────┐     │  colonna centrata da `medio` in su
│  │ Anagrafica                  │     │  sezione + filetto
│  │ ───────────────────────────  │     │
│  │ Nome                        │     │  etichetta sopra il campo
│  │ [__________________________]│     │  campo 52
│  │            ── 16 ──          │     │
│  │ Data di nascita             │     │
│  │ [__________________________]│     │
│  │            ── 28 ──          │     │  fra due gruppi
│  │ Attività                    │     │
│  │ ...                         │     │
│  └─────────────────────────────┘     │
├──────────────────────────────────────┤
│           [ Salva atleta ]           │  barra fissa 72 + area sicura
└──────────────────────────────────────┘
```

Il form non è mai a tutta larghezza su schermo largo. Da `esteso` in su, un form con più di dieci campi può andare su **due colonne da 320** con gronda 24, ma solo raggruppando: un gruppo non si spezza mai fra due colonne.

**D. Cruscotto**

Pannelli su griglia, mai dentro un'unica colonna scorrevole infinita.

| Punto di rottura | Pannelli per riga |
| --- | --- |
| `compatto` | 1 |
| `medio` | 2 |
| `esteso` | 3 |
| `largo` | 4, con i pannelli chiave a doppia larghezza |

Il pannello più importante della pagina occupa due celle e sta in alto a sinistra. Gli altri hanno tutti la stessa altezza per riga.

**E. Pagina bordo vasca**

Orizzontale, tre bande verticali. Descritta in sezione 13.

### Densità

| Contesto | Altezza riga |
| --- | --- |
| Elenco, `compatto` | 56 |
| Elenco, `medio` e oltre | 64 |
| Riga di tabella dati (passi, referto) da `esteso` in su | 48 |
| Qualunque riga a bordo vasca | 72, minimo 64 |

### Scorrimento

- **Una sola direzione di scorrimento per pannello.** Un elenco verticale non contiene mai un altro elenco verticale: si usano gli slivers.
- Lo scorrimento orizzontale esiste in due posti soli: la fila di chip di filtro e la fascia delle calottine a bordo vasca. In entrambi l'ultimo elemento visibile è tagliato a metà, così si capisce che ce n'è dell'altro.
- La barra di navigazione e le barre di azione non scorrono mai.
- L'AppBar resta piatta a riposo; appena `scrollOffset > 0` guadagna un bordo inferiore 1px `linea` nel tema chiaro e passa a `superficieAlt` nel tema scuro. **Mai un'ombra.**

### Tastiera e aree sicure

- Quando un campo prende il fuoco, la pagina lo porta a 96px dal bordo superiore dell'area visibile.
- La barra fissa di azione sale sopra la tastiera, non ci finisce sotto.
- Ogni schermata rispetta le aree sicure in basso; a bordo vasca anche quelle laterali, perché il tablet si tiene in orizzontale e le mani coprono i bordi.

---

## 11. Superfici, raggi, bordi, profondità

**Non tutto è una card.** Il raggio dipende dal ruolo dell'elemento.

| Elemento | Raggio |
| --- | --- |
| Pulsante, campo di testo, scheletro di caricamento | 8 |
| Pannello, riga di elenco raggruppata, chip rettangolare | 12 |
| Blocco in evidenza, pannello statistica, blocco vasca | 16 |
| Bottom sheet, dialog | 24 (solo angoli superiori per gli sheet) |
| Chip a pillola, badge, punto, avatar, cerchio calottina | pieno |
| Separatori a tutta larghezza | nessuno |

Quattro raggi diversi in una schermata sono troppi. In pratica ne convivono due: 8 per i controlli, 12 per i contenitori.

### I cinque livelli di profondità

Il chiaro usa l'ombra, lo scuro usa la luminosità della superficie. **Il tema scuro non ha ombre** sotto il livello 3, e anche lì servono solo a staccare dal velo, non a creare profondità.

| Livello | Cosa | Chiaro | Scuro |
| --- | --- | --- | --- |
| 0 | fondo pagina | `sfondo`, nessun bordo | `sfondo`, nessun bordo |
| 1 | pannello, riga, campo | `superficie` + bordo 1px `linea` | `superficie` + bordo 1px `linea` |
| 2 | AppBar su scorrimento, barra di azione fissa | `superficie` + bordo + `0 1 2 rgba(12,27,36,0.06)` | `superficieAlt` + bordo `linea` |
| 3 | menu, dropdown, snackbar, tooltip | `superficieAlta` + `0 8 24 rgba(12,27,36,0.12)` e `0 2 6 rgba(12,27,36,0.08)` | `superficieAlta` + bordo 1px `lineaForte` |
| 4 | dialog, bottom sheet | `superficieMassima` + `0 16 40 rgba(12,27,36,0.18)` | `superficieMassima` + bordo 1px `lineaForte` |

Sopra i livelli 3 e 4 c'è sempre lo `scrim`.

Un `Card` con elevazione di default di Material non compare mai: l'ombra grigia uguale sotto ogni riquadro è il segno più riconoscibile di un'interfaccia non disegnata.

### Messa a fuoco

Ogni elemento interattivo ha un anello di messa a fuoco visibile: **2px `azioneFuoco`, staccato di 2px** dal bordo dell'elemento, con lo stesso raggio più 2. Vale per tastiera esterna sul tablet e per il browser. Non si rimuove mai l'outline "perché è brutto": su web è l'unico modo di navigare senza mouse.

### Stati di un elemento interattivo

| Stato | Trattamento |
| --- | --- |
| Riposo | come da componente |
| Sopra (solo web e mouse) | fondo `azioneTenue` se è una riga, schiarita/scurita dell'8% se è un pulsante |
| Premuto | `azionePremuta`, nessun effetto di onda che esce dai bordi |
| A fuoco | anello come sopra |
| Selezionato | fondo `azioneTenue` + filetto sinistro 3px `azione` |
| Disabilitato | opacità 0,38 sul contenuto, fondo invariato, **nessun cambio di colore** |

### Il filetto di corsia

Elemento strutturale distintivo dell'app. Un filetto verticale di 3px sul lato sinistro di un blocco, alto quanto il blocco meno 8 sopra e sotto, con estremità arrotondate, colorato secondo l'informazione che porta:

- in una scheda di allenamento: colore della zona della serie;
- in un elenco di sessioni: colore che distingue riscaldamento / parte principale / defaticamento;
- nella riga di una partita in corso: `rosso`;
- in una riga selezionata: `azione`.

Serve a leggere la struttura con la coda dell'occhio, senza fermarsi a leggere. **Si usa solo quando porta un'informazione reale**, mai come decorazione, e mai più di un significato per schermata.

---

## 12. Icone

- Famiglia unica: **Material Symbols Rounded**.
- Assi: `wght 400`, `opsz` uguale alla dimensione dell'icona, `FILL 0` a riposo e `FILL 1` quando l'elemento è attivo o selezionato. Il passaggio fra i due riempimenti dura 120 ms ed è l'unico momento in cui un'icona si anima.
- Dimensioni: 20 in linea col testo, 24 per le azioni della barra e la navigazione, 48 per l'icona di uno stato vuoto.
- In navigazione e nelle azioni principali l'icona sta **sempre insieme a un'etichetta di testo**. Un'icona sola è ammessa solo dove il significato è universale: indietro, chiudi, cerca, più, altro.
- Colore: `testoSecondario` a riposo, `azione` se attiva, `testoTenue` se disabilitata.
- Nessuna icona colorata di verde, ambra o rosso se non sta dentro una fascia di stato che già spiega cosa sta succedendo.

---

## 13. Componenti

Valgono in entrambi i temi. Dove non è detto il contrario, i colori citati sono token semantici e cambiano da soli.

### Pulsanti

Quattro tipi, mai più di tre nella stessa schermata:

1. **Principale** — fondo `azione`, testo `azioneInk`, raggio 8, altezza 48 (52 da `esteso`), padding orizzontale 24, peso 600. **Uno solo per schermata.**
2. **Secondario** — bordo 1px `lineaForte`, testo `testo`, fondo `superficie`.
3. **Testuale** — solo testo `azione`, padding orizzontale 12, per azioni minori.
4. **Distruttivo** — bordo 1px `rosso`, testo `rosso`, fondo trasparente. Sempre con conferma.

Nei form lunghi il pulsante principale sta in fondo, a tutta larghezza della colonna, dentro una barra fissa di livello 2. Su schermo `largo` non si allarga oltre i 640 della colonna del form.

L'etichetta dice cosa succede: "Salva atleta", non "Invia". Niente freccia "→" appiccicata al testo.

Mentre si salva: la rotellina sostituisce il testo dentro il pulsante, la larghezza non cambia, il pulsante resta disabilitato fino alla risposta.

### Campi di testo

Il difetto più evidente dell'app oggi sono i campi sottolineati impilati a decine. Da sostituire ovunque:

- fondo `superficie`, bordo 1px `lineaForte`, raggio 8, altezza 52, padding orizzontale 12;
- bordo `azione` da 2px quando il campo è a fuoco, più l'anello di messa a fuoco;
- **etichetta sopra il campo**, stile `etichetta`, colore `testoSecondario`, 8 di spazio sotto. Mai etichetta flottante;
- testo di aiuto sotto, stile `piccolo`, `testoTenue`, 6 di spazio;
- errore: bordo `rosso` da 2px + messaggio sotto in `rosso` stile `piccolo`, con icona 16. Mai un popup;
- i campi opzionali si segnalano scrivendo "facoltativo" nell'etichetta, non con un asterisco sugli obbligatori;
- campo numerico: tastiera numerica, stile numerico con cifre tabulari, allineamento a destra se sta in colonna con altri numeri.

Nel tema scuro il campo **non ha fondo più chiaro della superficie**: resta `superficie` con il bordo a fare il lavoro. Un campo più chiaro del pannello che lo contiene inverte la gerarchia di profondità.

### Form

**Nessun form mostra più di cinque campi di fila senza un'interruzione.** I form attuali (Nuovo atleta, Nuova serie, Nuova partita) vanno spezzati in gruppi con un'intestazione `sezione`, un filetto `linea` sotto, e 28 di spazio fra un gruppo e l'altro.

Esempio per la scheda atleta: *Anagrafica* / *Attività* / *Contatti e consenso* / *Note*.

Un campo che serve solo in casi rari sta dentro un blocco espandibile chiuso di default.

### Elenchi

Righe raggruppate dentro un pannello `superficie` con bordo `linea` e raggio 12, separate da filetti `linea` di 1px che partono dopo l'eventuale icona e arrivano al bordo destro interno. **Niente `ListTile` nudi appoggiati direttamente sul fondo.**

Ogni riga: titolo `corpoForte`, riga di metadati sotto in `piccolo` / `testoSecondario`, eventuale valore numerico a destra in `numeroMedio` con cifre tabulari.

Per i metadati preferisci l'allineamento e il peso del testo alla stringa unita da puntini. Se un separatore serve davvero, al massimo due informazioni per riga.

Il primo e l'ultimo elemento del pannello ereditano il raggio 12 sugli angoli esterni: nessun angolo quadrato che sporge dal contenitore arrotondato.

### Pannelli statistica

Etichetta `etichetta` in `testoSecondario` sopra, valore `numeroGrande` con cifre tabulari sotto, unità o confronto in `piccolo` / `testoTenue`. Raggio 16, padding 20. Massimo quattro affiancati, poi vanno a capo secondo la griglia della sezione 10.

Il valore non è colorato. Se un confronto è positivo o negativo, il colore sta sulla freccina e sulla variazione, non sul numero principale.

### Chip e badge

Pillola, altezza 32 (28 dentro una riga di elenco), padding orizzontale 12, testo `piccolo` peso 500. Tre varianti:

- **neutro**: fondo `superficieAlt`, bordo 1px `linea`, testo `testoSecondario`;
- **selezionato**: fondo `azioneTenue`, bordo 1px `azione`, testo `azione` peso 600, icona di spunta 16 a sinistra;
- **di dominio** (zona, calottina, stato): come descritto in sezione 7, punto pieno più sigla.

Usati per: zona, sport, categoria, stato presenza, ruolo, filtri.

### Schermate vuote

**Regola non negoziabile.** Una schermata senza dati non mostra mai una riga di testo grigio. Struttura fissa, centrata, larghezza massima 560:

1. icona 48 in `testoTenue`;
2. titolo `sezione` che dice cosa manca, in frase normale: "Nessun test registrato";
3. una o due righe `piccolo` in `testoSecondario` che spiegano cosa succede quando ci sarà qualcosa: "I passi delle zone si calcolano dal primo test BVS o T30.";
4. un pulsante principale con l'azione: "Aggiungi test".

Se dalla schermata vuota si può fare più di una cosa, il secondo pulsante è secondario e sta di fianco, non sotto.

Uno stato vuoto non è illustrato. Niente disegni, niente vignette.

### Caricamento

Niente rotellina sola in mezzo allo schermo (oggi succede nella schermata MESO). Si usano **scheletri**: rettangoli della forma del contenuto che sta arrivando, raggio 8, colore `superficieAlt` nel chiaro e `superficieAlt` nello scuro, con un'onda di luce che attraversa da sinistra a destra ogni 1,4 s — opacità massima 0,06 nel chiaro, 0,08 nello scuro.

Lo scheletro ha la stessa altezza del contenuto reale, così la pagina non salta quando i dati arrivano.

La rotellina è ammessa solo dentro un pulsante mentre si salva.

### Errori

**Non deve mai comparire un errore tecnico grezzo nell'interfaccia.** Oggi succede: nella schermata "Nuova partita" viene stampato un `SqliteException` completo di query SQL. Da correggere ovunque.

Un errore si presenta come una fascia con fondo `rossoTenue`, filetto sinistro `rosso` di 3px, raggio 12, icona 20 in `rosso`, e:

- **cosa è successo**, in linguaggio umano: "Non è stato possibile salvare la partita.";
- **cosa fare**: "Riprova. Se l'errore continua, chiudi e riapri l'app.";
- il dettaglio tecnico solo dentro un "Mostra dettagli" chiuso, utile per segnalare il problema.

L'errore non si scusa e non è vago.

### Conferme

Azione riuscita → snackbar in basso, livello 3, filetto sinistro `ok`, testo al passato che riprende il verbo del pulsante: "Salva atleta" → "Atleta salvato". Dura 3 secondi. Nel tema scuro la snackbar è `superficieAlta`, non un rettangolo chiaro invertito.

Azione distruttiva → dialog con titolo che nomina l'oggetto ("Archiviare Sara Napoletani?"), una riga sulle conseguenze, pulsante distruttivo a destra, secondario a sinistra.

---

## 14. Schermate da bordo vasca

Sono un'altra cosa. Riguardano: allenamento in esecuzione, segna presenze, eventi partita in diretta.

**Regole specifiche, che prevalgono su tutto il resto:**

- **Altezza minima dei bersagli: 64**, preferibile 72. Mani bagnate, movimento, fretta.
- **Massimo tre azioni per schermata.** Tutto il resto sta dietro un menu.
  **Eccezione:** un'azione con una variante binaria imprevedibile che va registrata nell'istante in cui succede (es. superiorità numerica nostra o avversaria) resta due bersagli affiancati invece di un bottone più una scelta successiva. Contano come una sola azione ai fini del limite. Si applica solo quando l'evento è imprevedibile e il ritardo di un passaggio in più è il problema reale.
- Tipografia `display` per l'informazione centrale (la serie in corso, il punteggio, il tempo): 64 su tablet. Deve leggersi a mezzo metro senza avvicinare il tablet.
- **Layout a tre bande**, pensato per orizzontale su tablet:

```
┌────────┬────────────────────────────────┬────────┐
│ stato  │                                │ azioni │
│        │           1:25.4               │        │
│  ● in  │         4 × 100 SL             │ [  +  ]│
│  corso │        ▌ B2 · 1'40"            │ [  −  ]│
│        │                                │ [  ⏸  ]│
│  12/20 │         serie 3 di 6           │        │
└────────┴────────────────────────────────┴────────┘
   160            tutto lo spazio            160
```

  Le bande laterali sono raggiungibili col pollice tenendo il tablet con due mani. Il centro non è toccabile: è informazione.
- Il rosso `rosso` compare qui, e solo qui, come indicatore di "in corso": un punto di 10px accanto al cronometro, o un filetto sul blocco attivo.
  **Eccezione:** il campo disegnato degli eventi partita pallanuoto usa rosso e giallo per le linee reali della vasca (2m, 5m, 6m) — un uso rappresentativo dei colori del regolamento, non uno stato "in corso".
- **Nessun form.** Se serve inserire un dato, si fa con bottoni grandi o un bottom sheet con al massimo tre scelte.
  **Eccezione:** scegliere una persona dentro un'intera rosa (13+ convocati) non ci sta in tre bottoni né in un menu a tendina (vietato a bordo vasca). Pattern accettato: una fascia di calottine numerate sui bordi dello schermo (bianche a sinistra/casa, blu a destra/trasferta), sempre visibili, che diventano toccabili solo quando serve scegliere un giocatore.
- Nessuna azione distruttiva raggiungibile con un tap solo.
- Lo schermo non si spegne mentre una sessione è attiva.
- Nessuna animazione oltre al punto rosso che pulsa e al cambio delle cifre.

---

## 15. Giorno e notte

Il tema è **una scelta dell'utente su tutta l'app**, non solo sulle schermate da bordo vasca.

### L'impostazione

| Dove | Valori | Predefinito |
| --- | --- | --- |
| Impostazioni → Aspetto | Sistema · Chiaro · Scuro | Sistema |
| AppBar delle tre schermate da bordo vasca (icona sole/luna) | Segui l'app · Chiaro · Scuro | Segui l'app |

L'interruttore a bordo vasca resta perché lì la decisione dipende dall'impianto, non dal gusto: in una piscina molto illuminata uno schermo chiaro alla massima luminosità si legge meglio, perché uno schermo scuro fa da specchio e restituisce i riflessi delle luci e dell'acqua. Con poca luce vale l'opposto. È una cosa da valutare a occhio in vasca, non a tavolino, e può cambiare da impianto a impianto nella stessa settimana.

Entrambe le preferenze si salvano con `shared_preferences` sul dispositivo, **non su Supabase**: sono un gusto del device, non un dato del club. Chiavi: `tema_app` e `tema_bordo_vasca`.

Il cambio di tema è **immediato**, senza dissolvenza fra i due temi. Una transizione animata su tutta l'app costa e dà fastidio.

### Principi del tema scuro

1. **Non è il chiaro invertito.** Cambiano i valori dei token, mai il loro significato.
2. **Mai nero pieno, mai bianco pieno.** Fondo più scuro `#0B141B`, testo più chiaro `#E8EFF4`.
3. **La profondità si fa con la luminosità, non con l'ombra.** Più un elemento è "sopra", più la sua superficie è chiara. Le ombre nello scuro non si vedono e vanno tolte, non attenuate.
4. **I bordi diventano essenziali.** Nel chiaro un bordo è rifinitura, nello scuro è struttura.
5. **Gli accenti salgono di luminosità e scendono di saturazione.** `#0D5C87` diventa `#4FC3E8`. Un colore saturo e scuro su fondo scuro è invisibile; un colore saturo e chiarissimo vibra.
6. **L'inchiostro sopra gli accenti si inverte.** Sopra `azione` nel tema scuro va testo scuro, non bianco.
7. **I fondi tenui sono trasparenze, non tinte.** `azioneTenue` nello scuro è l'accento al 14% sopra la superficie.
8. **I colori di dominio hanno una variante.** Zone, calottine e serie dei grafici sono elencate in sezione 7 con entrambi i valori. Nessuno dei due elenchi è ricavabile dall'altro con una formula: sono scelti a occhio.
9. **Il peso del testo cala di un gradino percepito.** Vedi sezione 8.
10. **Nulla si inverte automaticamente.** Niente filtri di inversione, niente `ColorFiltered` applicato a un'intera schermata.

### Come si verifica

Una schermata non è finita finché non è stata guardata in tutti e due i temi, con dati veri, e:

- ogni pannello si distingue dal fondo;
- nessun testo scende sotto 4,5:1 nel tema in cui si guarda;
- nessun elemento è più chiaro del contenitore che lo contiene senza motivo;
- nessuna ombra è rimasta accesa nello scuro;
- i colori delle zone restano distinguibili fra loro.

---

## 16. Movimento

- Micro-interazioni (pressione di un pulsante, riempimento di un'icona, apertura di un menu): **120 ms**.
- Transizioni fra schermate, apertura di un pannello o di un bottom sheet: **220 ms**.
- Chiusura: **180 ms**, sempre più veloce dell'apertura.
- Curva: `Curves.easeOutCubic` in entrata, `Curves.easeInCubic` in uscita. Niente rimbalzi, niente molle.
- **Il movimento risponde a un'azione della persona.** Nessuna animazione d'ingresso sugli elenchi, nessuna dissolvenza a scaglioni al caricamento di una pagina, nessuna transizione al passaggio del mouse su ogni card.
- Due sole animazioni non richieste sono ammesse, perché comunicano uno stato reale: il punto rosso che pulsa quando una sessione è in corso (1,6 s per ciclo, opacità da 1 a 0,4) e l'onda dello scheletro di caricamento.
- I numeri che cambiano (punteggio, cronometro) non si animano con un contatore che scorre: cambiano e basta. Un numero che rotola è illeggibile nell'istante in cui serve leggerlo.
- Rispettare l'impostazione di sistema per la riduzione del movimento: con quella attiva restano solo le dissolvenze, a 120 ms.

---

## 17. Accessibilità

- Contrasto minimo **4,5:1 per il testo, 3:1 per gli elementi grafici e i bordi degli elementi interattivi**, in entrambi i temi. Da verificare, non da supporre.
- Bersagli toccabili minimo 48, 64 a bordo vasca, con 12 di spazio fra uno e l'altro.
- L'app regge l'ingrandimento del testo di sistema fino al **130%** senza rompere i layout. Niente altezze fisse sui contenitori di testo: si usa un'altezza minima.
- **Nessuna informazione affidata al solo colore.** Le zone hanno la sigla, gli stati hanno un'icona, gli errori hanno un testo, le serie dei grafici hanno una legenda con etichetta.
- Ogni icona senza etichetta ha un `Semantics` label.
- Ordine di messa a fuoco coerente con la lettura, per chi usa una tastiera esterna sul tablet o il browser.
- L'anello di messa a fuoco non si rimuove mai.
- Il tema scuro non è una funzione di accessibilità e non sostituisce il contrasto: va verificato con lo stesso metro del chiaro.

---

## 18. Come si scrive nell'app

Le parole sono contenuto, non decorazione.

- **Voce:** quella di un collega competente. Diretta, senza fronzoli, senza entusiasmo forzato. Niente punti esclamativi.
- **Frase normale** ovunque: titoli, pulsanti, etichette.
- **Verbi attivi.** Il pulsante dice cosa succede: "Segna presenze", "Genera allenamento", "Archivia atleta".
- **Lo stesso verbo per tutto il percorso.** Se il pulsante dice "Archivia", la conferma dice "Archiviare…?" e il messaggio finale dice "Atleta archiviato". Mai tre parole diverse per la stessa azione.
- **Il linguaggio è quello dell'allenatore**, non del database: "ripartenza", "passo", "vasca", "distinta", "convocati". Mai "record", "entità", "sincronizzazione fallita".
- Una schermata vuota è un invito ad agire, non un dispiacere.
- Ogni testo fa un lavoro solo. Se una frase non aiuta a capire o a decidere, si toglie.

---

## 19. Da non fare

Elenco chiuso. Se una schermata contiene una di queste cose, non è finita.

**Colore e tema**

- Un valore esadecimale scritto dentro il file di una schermata.
- Una costante di colore statica letta da una schermata invece di `Theme.of(context)`.
- Lo stesso esadecimale usato nei due temi per un token semantico.
- `#000000` come fondo o `#FFFFFF` come testo nel tema scuro.
- Ombre lasciate accese nel tema scuro.
- Un pulsante rosso pieno.
- Un titolo colorato.
- Più di un pulsante principale nella stessa schermata.
- Sfumature usate come decoro (l'unica ammessa è in sezione 6).

**Tipografia**

- Etichette in MAIUSCOLO spaziato sopra i contenuti.
- Testo sotto i 13 in qualsiasi punto dell'app, compresa la navigazione.
- Una parola sola evidenziata dentro un titolo.
- Numeri senza cifre tabulari.

**Struttura**

- `ListTile` appoggiati direttamente sul fondo, senza pannello.
- Tutto chiuso dentro riquadri identici, con lo stesso raggio e la stessa ombra grigia.
- Più di cinque campi di fila senza intestazione di gruppo.
- Campi di testo sottolineati in stile Material di default.
- Contenuto steso a tutta larghezza oltre i 1200.
- Un elenco verticale dentro un altro elenco verticale.
- Un form a tutta larghezza su schermo largo.
- Metadati incollati con puntini in mezzo per più di due informazioni.
- Freccia "→" attaccata al testo di un pulsante.

**Stati**

- Testo tecnico grezzo (eccezioni, SQL, nomi di tabelle) visibile all'utente.
- Rotellina di caricamento da sola al centro dello schermo.
- Schermata vuota risolta con una riga di testo grigio.
- Uno stato vuoto illustrato con un disegno.
- Un'animazione d'ingresso su un elenco.

---

## 20. Implementazione in Flutter

### Struttura dei file

```
lib/theme/
  tokens/
    palette.dart          # primitivi. Importato solo da tokens_chiaro/scuro.
    tokens_chiaro.dart    # ColoriApp.chiaro  + TokenDominio.chiaro
    tokens_scuro.dart     # ColoriApp.scuro   + TokenDominio.scuro
  colori_app.dart         # ThemeExtension<ColoriApp>
  tokens_dominio.dart     # ThemeExtension<TokenDominio>: zone, calottine, "in corso"
  app_typography.dart     # scala, cifre tabulari, zero barrato
  app_spacing.dart        # scala 4, raggi, durate
  app_elevation.dart      # ombre del chiaro, superfici dello scuro
  app_layout.dart         # Breakpoint, margini, larghezze massime, densità
  app_theme.dart          # ThemeData chiaro + ThemeData scuro
  tema_provider.dart      # Sistema/Chiaro/Scuro + override bordo vasca
```

`lib/theme/app_colors.dart` va **svuotato e rimosso** a migrazione finita: è la classe statica che oggi rende impossibile il tema scuro. Finché esiste, ogni schermata che la importa è una schermata non migrata.

### Mappatura su `ColorScheme`

Quello che Material sa già gestire passa da `ColorScheme`, così i widget standard si comportano bene senza override sparsi:

| Slot `ColorScheme` | Token |
| --- | --- |
| `brightness` | `light` / `dark` |
| `primary` | `azione` |
| `onPrimary` | `azioneInk` |
| `primaryContainer` | `azioneTenue` |
| `onPrimaryContainer` | `testo` |
| `surface` | `superficie` |
| `onSurface` | `testo` |
| `onSurfaceVariant` | `testoSecondario` |
| `surfaceContainerLowest` | `sfondo` |
| `surfaceContainerLow` | `superficieAlt` |
| `surfaceContainerHigh` | `superficieAlta` |
| `surfaceContainerHighest` | `superficieMassima` |
| `outline` | `lineaForte` |
| `outlineVariant` | `linea` |
| `error` | `rosso` |
| `errorContainer` | `rossoTenue` |
| `scrim` | `scrim` |

Tutto il resto (`superficieAlt` con il suo nome, `testoTenue`, `ok`, `attenzione`, le tinte, `azioneFuoco`) vive in `ColoriApp`, letto con `Theme.of(context).extension<ColoriApp>()!`. I token di dominio vivono in `TokenDominio`, letto allo stesso modo. Conviene una estensione di comodo: `context.colori.testoSecondario`.

`app_theme.dart` configura per **entrambi** i temi almeno: `colorScheme`, `textTheme`, `inputDecorationTheme`, `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `cardTheme`, `appBarTheme`, `dividerTheme`, `chipTheme`, `snackBarTheme`, `bottomSheetTheme`, `dialogTheme`, `navigationBarTheme`, `navigationRailTheme`, `floatingActionButtonTheme`, `focusColor`, `splashFactory` (nessuna onda che esce dai bordi), `extensions: [ColoriApp…, TokenDominio…]`.

`MaterialApp` riceve `theme`, `darkTheme` e `themeMode` dal `tema_provider`.

### Widget riutilizzabili

Vivono in `lib/widgets/`. Una schermata nuova si compone con questi, non ricostruisce nulla da zero.

Esistenti: `AppScaffold`, `SectionHeader`, `FormGroup`, `AppTextField`, `AppSelect`, `PrimaryButton`, `SecondaryButton`, `DangerButton`, `AppListPanel`, `ReorderableAppListPanel`, `AppListRow`, `StatPanel`, `ZoneChip`, `CapBadge`, `LaneRule`, `EmptyState`, `ErrorBanner`, `LoadingSkeleton`, `PoolCard`, `OrdineBadge`, `BreadcrumbBar`, `FabAzioni`.

Da aggiungere per il layout e il tema:

| Widget | Cosa fa |
| --- | --- |
| `AppNavigation` | barra in basso o rail secondo il punto di rottura, con una sola lista di voci |
| `TwoPaneLayout` | lista 360 + dettaglio, con fallback a navigazione a pagine sotto `esteso` |
| `ContentColumn` | applica margini e larghezza massima secondo il punto di rottura |
| `StickyActionBar` | barra fissa in basso, livello 2, sale sopra la tastiera |
| `PanelGrid` | griglia del cruscotto, colonne per punto di rottura |
| `TonalChip` | chip nelle tre varianti della sezione 13 |
| `ThemeToggle` | selettore Sistema/Chiaro/Scuro, e la variante a tre stati per bordo vasca |
| `PoolHeroBlock` | blocco centrale della schermata vasca, unico posto con la sfumatura |

`ReorderableAppListPanel` è la variante di `AppListPanel` con le righe trascinabili, usata dove l'ordine lo decide il coach. `BreadcrumbBar` resta disponibile per una futura gerarchia annidata. `FabAzioni` sostituisce più `FloatingActionButton` impilati: con un'azione sola si comporta come un FAB normale, con più azioni il tocco apre un elenco con etichette sempre visibili.

Se serve un componente nuovo, si aggiunge qui e si documenta in questo file. Non si scrive un widget su misura dentro una singola schermata.

### Regole di codice

- Nessun `Color(0x…)`, nessun `Colors.*`, nessun `EdgeInsets` con numeri arbitrari, nessun `TextStyle` inline dentro le schermate.
- Nessun accesso a una classe statica di colori da una schermata.
- Nessun `Card` con elevazione di default.
- Nessun `MediaQuery…width` confrontato a mano con un numero: si usa `Breakpoint.of(context)`.
- I numeri passano sempre da uno stile con cifre tabulari.
- Le dimensioni vengono da `AppSpacing`, le durate da `AppSpacing.durata*`.
- Un `lint` personalizzato o una ricerca in CI su `Color(0x`, `Colors.`, `AppColors.` dentro `lib/screens/` tiene onesta la migrazione.

### Ordine di lavoro

Non si rifà tutta l'app in una volta. Ordine:

1. `lib/theme/` completo: primitivi, i due set di token, le due `ThemeData`, il provider, `MaterialApp` collegata. Nessuna schermata cambia aspetto in questo passo, ma l'interruttore di tema deve già funzionare.
2. I widget riutilizzabili, scritti leggendo i token dal contesto.
3. **Una schermata pilota** portata a termine e approvata **nei due temi** — proposta: la scheda atleta, perché contiene form, gruppi, azione distruttiva e stato vuoto.
4. Le tre schermate da bordo vasca, perché sono quelle che si usano davvero.
5. Tutte le altre, una per volta.
6. Rimozione di `app_colors.dart` e attivazione del controllo in CI.

---

## 21. Checklist prima di dire "finita"

Da passare **due volte**, una per tema.

**Token**
- [ ] Nessun colore, spazio, raggio o durata scritto a mano nel file della schermata
- [ ] Nessuna classe statica di colori importata
- [ ] Provata in chiaro e in scuro con dati veri

**Gerarchia**
- [ ] Un solo pulsante principale
- [ ] Al massimo un elemento rosso, e piccolo
- [ ] Socchiudendo gli occhi si vede una macchia colorata sola

**Struttura**
- [ ] Margini e larghezza massima corretti per il punto di rottura
- [ ] Nessun gruppo di più di cinque campi senza intestazione
- [ ] Provata a `compatto`, `esteso` e `largo`
- [ ] Un solo scorrimento verticale per pannello

**Stati**
- [ ] Stato vuoto con icona, titolo, spiegazione e azione
- [ ] Stato di caricamento a scheletro, della stessa altezza del contenuto
- [ ] Stato di errore leggibile, senza testo tecnico
- [ ] Stato a fuoco visibile con la tastiera

**Contenuto**
- [ ] I numeri usano cifre tabulari e zero barrato
- [ ] Le zone hanno colore **e** sigla
- [ ] Testo delle azioni coerente fra pulsante, conferma e messaggio finale

**Tenuta**
- [ ] Tutti i bersagli almeno 48 (64 a bordo vasca)
- [ ] Provata a 130% di ingrandimento testo senza rotture
- [ ] Provata in orizzontale su tablet se è una schermata da vasca
- [ ] Nessuna voce della sezione 19 presente

---

## 22. Decisioni ancora aperte

Da chiudere con l'uso reale, non a tavolino.

1. ~~Chiaro o scuro a bordo vasca~~ — risolto: il tema è una scelta dell'utente su tutta l'app, con un override locale per le tre schermate da vasca (sezione 15).
2. ~~Densità su tablet~~ — risolto: elenco a due pannelli da `esteso` in su, cruscotto a griglia (sezione 10).
3. **Colore delle zone.** Se un allenatore che usa già una convenzione diversa fatica a leggerle, si cambia la palette: sono token, cambia un file.
4. **Carattere condensato.** Da riprovare quando esiste un'alternativa sicura sul web, per i campi numerici in colonna stretta.
5. **Variante ad altissimo contrasto per bordo vasca.** Se in impianto nemmeno il chiaro basta, valutare un terzo tema con soli bianco, nero e rosso. Da decidere dopo qualche settimana di uso vero, non prima.
