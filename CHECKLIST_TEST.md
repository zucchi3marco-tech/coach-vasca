# Checklist di test manuale

Da passare **prima di chiudere una fase** e dopo ogni giro di modifiche
grosse. Serve perché i test automatici (`flutter test`) non aprono l'app
vera: non vedono come appare una schermata né provano un login reale.

**Come si avvia:** dal terminale, nella cartella del progetto,
`flutter run -d chrome --web-port=8765`. Per provare il telefono:
stessa cosa dal telefono Android collegato (`flutter run`) oppure il sito
pubblicato aperto dal telefono.

**Come si usa:** spunta ogni riga; se qualcosa non torna, scrivi accanto
cosa hai visto (schermata + cosa ti aspettavi) e passamelo.

**Consiglio:** usa un atleta e una partita/gara *di prova*, così puoi
eliminarli senza danni.

---

## 1. Account allenatore

### Accesso e barra in alto
- [ ] Dopo il login (e la scelta del gruppo) in alto vedi il **nome del tuo club**, con il logo a sinistra.
- [ ] Il logo, da una schermata aperta (es. dettaglio di un allenamento), ti riporta alla tab **Atleti**.
- [ ] Icona tema (sole/luna): si aprono **Sistema / Chiaro / Scuro** e il cambio si vede subito.
- [ ] Menu ☰: **Notifiche**, **Sincronizza** (o «Tutto sincronizzato»), **Cambia gruppo**, **Rivedi la guida**, **Esci**.
- [ ] «Rivedi la guida» mostra il tour con la frase sulla barra in alto e le tue tab.
- [ ] La barra **non c'è** su: lavagna tattica, partita dal vivo, eventi partita, segna presenze, scheda bordo vasca. Quando esci da queste, **ricompare**.

### Tab Atleti
- [ ] Il riepilogo sopra l'elenco è **una riga bassa**: 3 icone con il dato e una didascalia sotto.
- [ ] «Nuovo atleta» (+): compili e salvi, l'atleta compare nell'elenco.
- [ ] Menu ⋮ di un atleta: **Modifica anagrafica**, **Account atleta**, **Elimina atleta**.
- [ ] «Elimina atleta» (solo su quello di prova): chiede conferma con l'elenco di cosa si perde; «Annulla» non fa nulla, «Elimina» lo toglie dall'elenco.
- [ ] Toccando la riga si apre la sua dashboard.

### Allenamenti
- [ ] Crei un allenamento con qualche serie (riscaldamento, principale, defaticamento).
- [ ] Dal dettaglio apri la **vista bordo vasca**: serie grandi, barra in alto assente, in orizzontale sul telefono.
- [ ] Da lì «Segna presenze» funziona e il tema vasca (chiaro/scuro) si cambia.

### Stagioni e calendario
- [ ] «Nuova stagione»: **non** chiede il nome né il gruppo; c'è «Campionato», la **Categoria** (sola lettura) e le date.
- [ ] Il titolo che compare è del tipo **«Campionato U14 - 1/09/2026-30/06/2027»**.
- [ ] Sotto il titolo c'è il **calendario del mese**; puoi sfogliare i mesi solo dentro la stagione.
- [ ] Tocchi un giorno vuoto: puoi creare una partita (pallanuoto) o una gara (nuoto) con la data già messa.
- [ ] Il giorno con l'evento diventa un **riquadro colorato**; toccandolo vedi l'elenco con «Apri» e «Aggiungi».
- [ ] Una stagione **«Tutti gli atleti»** mostra i suoi eventi in **ambra**, quelle di gruppo nel colore d'azione.

### Solo pallanuoto
- [ ] La barra in basso ha **5 voci**: Atleti, Allenamenti, **Schemi tattici**, Stagioni, Partite.
- [ ] Tab Partite: elenco della stagione in corso, **dalla più vecchia alla più recente**, senza «Nuova partita» né «Statistiche stagione».
- [ ] Aprendo una partita: distinta, eventi dal vivo (barra assente), **referto** con «Leggi referto».
- [ ] Le statistiche di stagione stanno nel dettaglio della stagione.
- [ ] Lavagna tattica: disegni uno schema, lo salvi, lo rivedi in anteprima (barra assente).

### Solo nuoto
- [ ] La barra in basso ha **4 voci** (niente Schemi tattici) e l'ultima si chiama **Gare**.
- [ ] Apri una gara: **iscrivi** atleti con la spunta.
- [ ] «Aggiungi risultato» per un iscritto: se il tempo batte il personal best compare l'avviso e il PB si aggiorna.

## 2. Account atleta

- [ ] **Registrazione con codice**: dopo l'ultimo passo vedi subito la **dashboard atleta** (non la schermata «crea il club»).
- [ ] In alto c'è il **nome del tuo club**.
- [ ] «Prossimo allenamento» mostra i **metri totali** (es. «2.400 m»); toccandolo si apre la scheda **senza «Segna presenze»**.
- [ ] «Prossimi eventi» mostra partite (o gare, per il nuoto) del tuo gruppo e di tutto il club («Tutto il club»).
- [ ] Le righe **Le mie presenze / La mia stagione / Le mie statistiche / Le mie partite** hanno l'icona colorata e si aprono.
- [ ] L'atleta **non vede** allenamenti, schemi o eventi di **un altro gruppo** e non vede le **note** dell'allenatore.

## 3. Senza rete (modalità aereo)

- [ ] Con la rete spenta crei un allenamento o modifichi un atleta: l'app **non dà errore**.
- [ ] Nel menu ☰ compare «Sincronizza» con il **numero di modifiche in coda**.
- [ ] Riaccendi la rete: la coda si svuota da sola (o con «Sincronizza») e il menu torna a «Tutto sincronizzato».
- [ ] Da un altro dispositivo/browser la modifica risulta arrivata.

## 4. Telefono

- [ ] La barra in alto sta **sotto la tacca/orologio** e non è tagliata.
- [ ] Tema scuro: testi leggibili, nessun rettangolo bianco fuori posto.
- [ ] I menu (☰, tema, ⋮) si aprono **dentro lo schermo**, non tagliati.
- [ ] La barra in basso è raggiungibile col pollice; con schermo largo (tablet/PC) diventa una colonna a lato.
