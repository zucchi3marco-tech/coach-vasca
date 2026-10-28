/// A chi serve una novità.
enum PerChi { allenatori, atleti, tutti }

/// Una novità dell'app, come la racconta il registro: cosa è cambiato, in
/// due righe, per chi la usa.
class Novita {
  const Novita({
    required this.id,
    required this.data,
    required this.titolo,
    required this.testo,
    this.importante = false,
    this.perChi = PerChi.allenatori,
  });

  /// Breve, in minuscolo con i trattini ("scrivimi-e-novita"). Non cambia
  /// mai e non si riusa: il telefono si ricorda l'ultima novità vista da lì.
  final String id;

  /// Il giorno della pubblicazione (l'ora non conta).
  final DateTime data;

  final String titolo;
  final String testo;

  /// Compare da sola, una volta, dopo l'aggiornamento.
  final bool importante;

  final PerChi perChi;

  /// Se la novità serve a chi guarda: un [atleta] oppure un allenatore.
  bool perAtleta(bool atleta) => switch (perChi) {
    PerChi.tutti => true,
    PerChi.atleti => atleta,
    PerChi.allenatori => !atleta,
  };
}

/// Il registro delle novità, dalla più recente alla più vecchia.
///
/// A ogni pubblicazione si aggiunge una voce IN CIMA all'elenco. Gli `id`
/// già scritti non cambiano mai. `importante: true` solo per ciò che ogni
/// utente deve sapere: compare da solo una volta sola; tutto il resto si
/// legge dalla pagina «Novità».
final List<Novita> registroNovita = [
  Novita(
    id: 'assistente-appello',
    data: DateTime(2026, 10, 28),
    titolo: 'L\'appello con una frase',
    testo:
        'Nell\'assistente scrivi o detta «assenti Rossi e Bianchi, Verdi in '
        'ritardo»: ti prepara l\'appello della seduta di oggi, con tutti gli '
        'altri presenti e chi avevi già segnato com\'era. Cambi chi serve '
        'con un tocco e lo salvi tu.',
  ),
  Novita(
    id: 'solo-pallanuoto-ritocchi',
    data: DateTime(2026, 10, 28),
    titolo: 'Gli ultimi testi sul nuoto',
    testo:
        'Nella prima stagione e tra i riquadri dell\'atleta non si parla '
        'più di gare né di nuoto: «I miei tempi» sono i personal best a '
        'stile libero, dai 25 ai 200 metri.',
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'via-le-gare-del-nuoto',
    data: DateTime(2026, 10, 28),
    titolo: 'Via le gare del nuoto',
    testo:
        'Tolte le gare, le iscrizioni e i tempi di gara del nuoto, anche '
        'dall\'Excel del club. La demo è di pallanuoto, con i test T30 e '
        'le tabelle dei passi.',
  ),
  Novita(
    id: 'solo-pallanuoto',
    data: DateTime(2026, 10, 28),
    titolo: 'WaterTactics è solo pallanuoto',
    testo:
        'Il nuoto avrà un\'app sua. Qui non si sceglie più lo sport: club, '
        'squadre e atleti sono tutti di pallanuoto, con ruolo, partite, '
        'schemi e categorie FIN per tutti. Il nuoto degli allenamenti, i '
        'personal best e i test BVS e T30 restano.',
    importante: true,
  ),
  Novita(
    id: 'convocati-manca-campo',
    data: DateTime(2026, 10, 28),
    titolo: 'Scegli i convocati: niente più «Manca un campo obbligatorio»',
    testo:
        'Salvando insieme un portiere, il capitano o il vice e gli altri '
        'convocati, il salvataggio veniva rifiutato. Ora vanno tutti.',
  ),
  Novita(
    id: 'report-squadra',
    data: DateTime(2026, 10, 27),
    titolo: 'Il report PDF della squadra',
    testo:
        'In «Statistiche stagione», l\'icona del PDF in alto: scegli la '
        'stagione, una fase o le date, scrivi una nota e «Crea il PDF». '
        'Dentro le partite con il risultato e il bilancio, la classifica '
        'FIN, i marcatori, le presenze di ognuno e i numeri dal vivo; '
        'benessere e RPE solo con la spunta, e solo le medie della squadra.',
    importante: true,
  ),
  Novita(
    id: 'report-atleta',
    data: DateTime(2026, 10, 27),
    titolo: 'Il report PDF dell\'atleta',
    testo:
        'Nella scheda di un atleta, l\'icona del PDF in alto: scegli la '
        'stagione, una fase o le date, scrivi una nota e «Crea il PDF». '
        'Dentro presenze, partite con gol ed espulsioni, test e obiettivi; '
        'benessere e RPE solo se metti la spunta, e solo le medie.',
    importante: true,
  ),
  Novita(
    id: 'logo-del-club',
    data: DateTime(2026, 10, 27),
    titolo: 'Il logo del club nei PDF',
    testo:
        'In «Il mio club», «Carica il logo» (PNG o JPG, fino a 1 MB): da lì '
        'è in alto nel PDF della seduta, dello schema tattico e nei '
        'biglietti dei codici, accanto al nome del club. Lo mette, cambia o '
        'toglie solo il responsabile del club.',
    importante: true,
  ),
  Novita(
    id: 'note-avversario',
    data: DateTime(2026, 10, 27),
    titolo: 'Le note sull\'avversario',
    testo:
        'Nella scheda dell\'avversario, «Scrivi le note»: come giocano e i '
        'giocatori da tenere d\'occhio, con numero e cosa fanno (quelli dei '
        'referti si aggiungono con un tocco). Le legge tutta la squadra, '
        'anche chi non è convocato. Se l\'app non trova l\'avversario nel '
        'girone FIN, «Scegli la squadra» e se lo ricorda.',
    importante: true,
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'scheda-avversario',
    data: DateTime(2026, 10, 27),
    titolo: 'La scheda dell\'avversario',
    testo:
        'Nella partita, «Avversario» in alto: le partite della squadra '
        'contro di loro con il risultato, i loro marcatori dai referti, i '
        'numeri dal vivo e la loro classifica nel girone FIN, con gli ultimi '
        'risultati. Si apre anche da «Avversari» nelle Partite e toccando una '
        'squadra nella classifica. Gli atleti la aprono toccando la partita.',
    importante: true,
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'impegni-nel-calendario',
    data: DateTime(2026, 10, 27),
    titolo: 'Collegiali, trasferte, riposi e tornei nel calendario',
    testo:
        'Nella stagione, tocca un giorno e «Aggiungi impegno» (o «Nuovo '
        'impegno» in alto): collegiale, trasferta, riposo, torneo o altro, '
        'dal giorno al giorno, per una squadra o per tutto il club, con luogo '
        'e note. Li vedi nel calendario della stagione e in quello degli '
        'allenamenti; li vedono anche gli atleti. Su un giorno di riposo, '
        'creando un allenamento, l\'app te lo ricorda.',
    importante: true,
  ),
  Novita(
    id: 'chi-cambia-categoria',
    data: DateTime(2026, 10, 27),
    titolo: 'Chi cambia categoria a inizio stagione',
    testo:
        'A settembre e ottobre, nella scelta della squadra e in «Gestisci '
        'gruppi», il riquadro «Chi cambia categoria» elenca chi sale di '
        'categoria, per esempio i 2013 che passano negli U16, con la squadra '
        'della categoria nuova. Togli la spunta a chi resta, poi «Sposta». '
        'Lo trovi anche subito dopo «Duplica stagione» sull\'anno dopo. Chi '
        'hai messo sotto età o fuori quota non compare: resta dov\'è.',
  ),
  Novita(
    id: 'categoria-dall-anno',
    data: DateTime(2026, 10, 27),
    titolo: 'La categoria FIN accanto al nome',
    testo:
        'Nella pallanuoto l\'elenco degli atleti mostra la classe e la '
        'categoria FIN della stagione, per esempio «classe 2012 (U16)», '
        'calcolate dall\'anno di nascita: cambiano da sole a settembre. Chi '
        'gioca in una squadra di un\'altra categoria ha il segno «Sotto età» '
        'o «Fuori quota». Le squadre restano quelle che decidi tu.',
  ),
  Novita(
    id: 'proponi-le-fasi',
    data: DateTime(2026, 10, 27),
    titolo: 'Le fasi della stagione a ritroso dall\'obiettivo',
    testo:
        'Nella stagione, sotto «Fasi e obiettivi», «Proponi le fasi»: scegli '
        'fino a tre obiettivi (una partita, una gara o un giorno a mano) e '
        'l\'app propone Preparazione, Andata e Ritorno dalle partite della '
        'squadra, lo Scarico e il giorno dell\'obiettivo. Con − e + allunghi '
        'o accorci ogni fase di una settimana, poi «Usa queste fasi». Le '
        'fasi con lo stesso nome di prima tengono «A cosa serve».',
    importante: true,
  ),
  Novita(
    id: 'statistiche-stagione-per-squadra',
    data: DateTime(2026, 10, 27),
    titolo: 'Statistiche della stagione: solo le partite della squadra',
    testo:
        'In «Statistiche stagione» ogni stagione conta solo le partite della '
        'sua squadra (e quelle segnate per tutto il club). Prima, con U14 e '
        'U16 nelle stesse date, la partita degli U14 finiva anche fra quelle '
        'degli U16. Le statistiche di un atleta contano ancora tutte le sue '
        'partite, con qualunque squadra.',
    importante: true,
  ),
  Novita(
    id: 'csv-piramidi-una-riga',
    data: DateTime(2026, 10, 27),
    titolo: 'Il CSV con le piramidi su una riga',
    testo:
        'In «Esporta CSV» una piramide (50-100-200-100-50) è una riga sola, '
        'come nel dettaglio e nel PDF. La colonna nuova «Metri» dice i metri '
        'di ogni riga, così in Excel la somma dà i metri dell\'allenamento.',
  ),
  Novita(
    id: 'campionati-fin-sito-cambiato',
    data: DateTime(2026, 10, 27),
    titolo: 'Campionati FIN: se il sito cambia, l\'app lo dice',
    testo:
        'Classifica e calendario si leggono dal sito della FIN Lombardia, '
        'anche per la stagione 2026-2027. Se un giorno il sito cambia e '
        'l\'app non riesce più a leggerlo tutto, nella pagina lo dice invece '
        'di scrivere «la FIN non ha ancora pubblicato», e parte da sola una '
        'segnalazione per sistemarlo.',
    perChi: PerChi.allenatori,
  ),
  Novita(
    id: 'senza-rete-niente-sovrascritture',
    data: DateTime(2026, 10, 27),
    titolo: 'Senza rete non si sovrascrive più un collega',
    testo:
        'Le modifiche fatte senza rete partono quando la rete torna. Se '
        'intanto un collega ha cambiato o tolto la stessa cosa (una serie, '
        'una presenza, una partita…), la tua non la sovrascrive: resta la '
        'sua versione, la pagina si aggiorna e la spia in alto ti dice cosa '
        'non è partito, così la rifai se serve.',
    importante: true,
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'seduta-aperta-da-un-collega',
    data: DateTime(2026, 10, 27),
    titolo: 'Due allenatori sulla stessa seduta',
    testo:
        'Se un collega ha aperta la seduta che stai guardando, in cima '
        'compare «Edoardo la sta modificando». Se intanto l\'ha cambiata, '
        '«Aggiorna» ti fa vedere la sua versione. Se salvi dopo di lui, '
        'l\'app te lo dice e scegli: «Vedi la sua versione» o «Salva la '
        'mia». Prima vinceva chi salvava per ultimo, senza dirlo.',
    importante: true,
  ),
  Novita(
    id: 'voce-sulle-clip',
    data: DateTime(2026, 10, 26),
    titolo: 'Il commento a voce sulle clip',
    testo:
        'Nel video della partita, su una nota, «Registra il commento»: la '
        'clip riparte e registri mentre scorre, fino a 3 minuti. Il '
        'giocatore tocca «Ascolta il commento» e sente la tua voce con il '
        'video; sotto la nota ti può rispondere per iscritto, e ti arriva '
        'un avviso.',
    importante: true,
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'schede-obiettivi',
    data: DateTime(2026, 10, 26),
    titolo: 'Le schede obiettivi',
    testo:
        'Nella pagina della stagione, «Schede obiettivi» → «Nuova scheda»: '
        'scegli le domande (pronte o tue, niente sulla salute) e mandale '
        'agli atleti. Ognuno risponde dalla sua home; tu leggi le risposte '
        'atleta per atleta e scrivi due righe di ritorno. Arrivano gli '
        'avvisi a te e a loro.',
    importante: true,
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'settimana-nella-home-atleta',
    data: DateTime(2026, 10, 26),
    titolo: 'A cosa serve la settimana, nella home degli atleti',
    testo:
        'Nel modulo di una fase scrivi «A cosa serve», una o due righe. Se '
        'vuoi, scrivi una riga diversa per una settimana precisa. Gli '
        'atleti la leggono in cima alla loro home con la fase e la '
        'settimana («Preparazione · settimana 3 di 6»), senza km e carico.',
    importante: true,
  ),
  Novita(
    id: 'test-segnati-atleti',
    data: DateTime(2026, 10, 26),
    titolo: 'I test li segnano anche gli atleti',
    testo:
        'Nel modulo di un test accendi «Lo segnano anche gli atleti»: '
        'ognuno scrive il suo risultato da «I miei tempi», che entra subito '
        'in classifica con «segnato dall\'atleta». Lo puoi togliere dallo '
        'storico dell\'atleta. L\'atleta corregge o toglie solo i suoi, mai '
        'quelli scritti da te.',
    importante: true,
  ),
  Novita(
    id: 'dal-vivo-niente-doppi',
    data: DateTime(2026, 10, 26),
    titolo: 'Dal vivo, niente eventi doppi',
    testo:
        'Con la rete lenta, mentre un evento si salva al centro del campo '
        'compare «Salvo…» e un secondo tocco sul giocatore non lo registra '
        'di nuovo. Nelle statistiche, sotto i rigori segnati, «su 2 a '
        'favore» dice quanti rigori ci hanno fischiato quando non li '
        'abbiamo tirati tutti.',
  ),
  Novita(
    id: 'spiegazioni-test',
    data: DateTime(2026, 10, 26),
    titolo: 'Come si fa ogni test',
    testo:
        'Ogni test ha la sua scheda «Come si fa»: a cosa serve, cosa serve, '
        'come si fa, come si misura, errori da evitare. La trovi nella '
        'pagina Test (il tasto ⓘ su ogni test), nella classifica del test e, '
        'per gli atleti, nella pagina dei tempi. La cambi dalla matita del '
        'test; un test pronto si legge prima di aggiungerlo e si può '
        'cambiare subito. Anche BVS e T30 hanno la loro spiegazione.',
    importante: true,
  ),
  Novita(
    id: 'clip-del-portiere',
    data: DateTime(2026, 10, 26),
    titolo: 'Le clip del portiere',
    testo:
        'Nel video della partita, fra «Le tue azioni» il portiere trova '
        'anche i tiri avversari dei tempi in cui era in porta: parate, gol '
        'subiti e tiri fuori.',
  ),
  Novita(
    id: 'clip-piu-lunghe',
    data: DateTime(2026, 10, 26),
    titolo: 'Clip del video più lunghe',
    testo:
        'Ogni clip della partita parte 5 secondi prima e finisce 5 secondi '
        'dopo: si vede l\'azione completa. Vale anche per i video già '
        'allineati, senza rifare niente.',
  ),
  Novita(
    id: 'dashboard-gol-dal-referto',
    data: DateTime(2026, 10, 26),
    titolo: 'Gol in pagina anche dal referto',
    testo:
        'Nella pagina dell\'atleta i gol contano anche le partite non '
        'seguite dal vivo, dal referto (letto o scritto a mano). La '
        'precisione resta calcolata solo sui tiri dal vivo. Tornando '
        'nell\'app gol e gol subiti si aggiornano da soli.',
  ),
  Novita(
    id: 'referto-a-mano',
    data: DateTime(2026, 10, 25),
    titolo: 'Il referto anche a mano',
    testo:
        'Nel referto di una partita, «Scrivi a mano» apre il modulo senza '
        'foto: i convocati sono già in elenco, scrivi i gol di ogni tempo '
        '(il risultato si somma da solo), reti ed espulsioni. Un referto già '
        'salvato si corregge con «Correggi a mano».',
    importante: true,
  ),
  Novita(
    id: 'video-in-orizzontale',
    data: DateTime(2026, 10, 25),
    titolo: '«È qui» sempre sotto il video',
    testo:
        'Allineando il video della partita, «È qui» e «Annulla» stanno fissi '
        'subito sotto il video, sul PC come sul telefono in orizzontale: non '
        'serve più scorrere per trovarli.',
  ),
  Novita(
    id: 'portieri-parate',
    data: DateTime(2026, 10, 25),
    titolo: 'Parate e gol subiti dei portieri',
    testo:
        'Dal vivo, accanto al tempo, «In porta» dice chi gioca in porta: lo '
        'tocchi per cambiarlo, anche a metà tempo, e a ogni cambio di tempo '
        'l\'app lo chiede. Il tiro avversario si segna Gol, Parato o '
        'Palo/fuori. Leggendo un referto scegli chi era in porta in ogni '
        'tempo. Nella sua pagina il portiere vede parate, gol subiti e '
        '% parate al posto dei gol.',
    importante: true,
  ),
  Novita(
    id: 'falli-gravi-dal-vivo',
    data: DateTime(2026, 10, 25),
    titolo: 'Falli gravi e calottine dal vivo',
    testo:
        'Nella partita dal vivo espulsioni e rigori contano insieme come '
        'falli gravi: accanto alla calottina il numero, al terzo diventa nera '
        'e il giocatore non si sceglie più. Le calottine ai lati del campo '
        'stanno tutte nello schermo, anche col telefono in orizzontale.',
    importante: true,
  ),
  Novita(
    id: 'convocati-insieme',
    data: DateTime(2026, 10, 25),
    titolo: 'Tutti i convocati in una volta',
    testo:
        'Nella distinta di una partita il pulsante in basso apre «Scegli i '
        'convocati»: spunti i nomi, con «Tutta la squadra» o «Come l\'ultima '
        'partita», e salvi una volta. Ognuno riprende il numero dell\'ultima '
        'partita, i portieri l\'1 e il 13.',
    importante: true,
  ),
  Novita(
    id: 'numeri-e-capitani',
    data: DateTime(2026, 10, 25),
    titolo: 'Numeri, capitano e vice',
    testo:
        'In cima alla distinta tocchi «Capitano» o «Vice capitano» e scegli '
        'fra i convocati: chi lo era torna giocatore. «Riordina i numeri» li '
        'cambia trascinando le righe; se dai a un atleta un numero già preso, '
        'i due si scambiano.',
  ),
  Novita(
    id: 'modulo-distinta',
    data: DateTime(2026, 10, 25),
    titolo: 'Il modulo della distinta in Excel',
    testo:
        'Nella distinta, l\'icona per scaricare prepara il modulo FIN in '
        'Excel: convocati con tessera, CAP e VICE, lo staff con le tessere e '
        'lo spazio per le firme. Lo staff lo scrivi la prima volta che '
        'scarichi il modulo e vale per tutte le partite della squadra.',
  ),
  Novita(
    id: 'tablet-squadra',
    data: DateTime(2026, 10, 21),
    titolo: 'Il tablet della squadra',
    testo:
        'In una seduta a secco, «Tablet della squadra» apre i nomi del '
        'gruppo: chi non ha il telefono tocca il suo e registra serie per '
        'serie, come dal suo telefono. Chi registra risulta presente. Dal '
        'tablet non si va nel resto dell\'app: per uscire tieni premuto '
        '«Esci».',
  ),
  Novita(
    id: 'variante-secco',
    data: DateTime(2026, 10, 21),
    titolo: 'La variante di un esercizio a secco',
    testo:
        'Nel menu di un esercizio a secco, «Variante per un atleta»: chi ha '
        'male alla spalla fa un altro esercizio, lo stesso più leggero, o '
        'non lo fa. Gli altri vedono l\'esercizio di sempre, lui solo il '
        'suo. Se qualcuno ha segnato un dolore alla spalla, la seduta te lo '
        'propone.',
  ),
  Novita(
    id: 'voto-serie',
    data: DateTime(2026, 10, 21),
    titolo: 'Com\'è andata ogni serie a secco',
    testo:
        'Durante il recupero di una serie a secco ci sono tre bottoni: '
        'facile, giusta, dura. La volta dopo, accanto al carico, vedi com\'era '
        'andata; l\'allenatore lo vede in chi ha registrato la seduta.',
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'monotonia',
    data: DateTime(2026, 10, 21),
    titolo: 'Quanto è varia la settimana',
    testo:
        'In «Forma e carico» di un atleta, sotto l\'ACWR, la monotonia: '
        'quanto si somigliano i giorni della settimana, con lo strain. Sopra '
        '2 i giorni sono quasi tutti uguali e il rischio di sovraccarico '
        'sale. In «Benessere della squadra» è in giallo per chi è sopra 2.',
  ),
  Novita(
    id: 'com-e-andata',
    data: DateTime(2026, 10, 20),
    titolo: 'Com\'è andata',
    testo:
        'A bordo vasca, accanto a «Fatta» e «Saltata», c\'è «In parte»: '
        'scegli quante ripetute, minuti o metri avete fatto. Nel dettaglio '
        'di un allenamento già fatto il riquadro «Com\'è andata» mostra i '
        'metri fatti su quelli scritti, zona per zona, e da «Segna com\'è '
        'andata» lo segni anche dall\'ufficio. Il carico conta solo la '
        'parte fatta.',
  ),
  Novita(
    id: 'appello-ritardo',
    data: DateTime(2026, 10, 20),
    titolo: 'L\'appello più ricco',
    testo:
        'Nelle presenze c\'è «In ritardo»: conta come presente, e il '
        'riepilogo dice quanti erano in ritardo. Sotto ogni nome le presenze '
        'della settimana e del mese; accanto al nome un pallino per chi quel '
        'giorno stava peggio del solito o aveva un dolore: toccalo per '
        'aprire il suo benessere.',
  ),
  Novita(
    id: 'rete-in-vista',
    data: DateTime(2026, 10, 20),
    titolo: 'La rete in vista',
    testo:
        'Quando la rete manca o il server non risponde, in alto compare una '
        'nuvola: toccala per vedere cosa aspetta di partire e riprovare. Le '
        'pagine mostrano subito i dati salvati sul telefono, e nessuna '
        'chiamata aspetta più di qualche secondo.',
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'numeri-giusti',
    data: DateTime(2026, 10, 20),
    titolo: 'Metri e segni sempre al posto giusto',
    testo:
        'Se riscrivi a testo un allenamento già fatto, «fatta» e «saltata» '
        'restano sulle loro serie anche se ne aggiungi una sopra. Una '
        'variante per un solo atleta non diventa più un lavoro in '
        'parallelo. Il carico senza rete e l\'avviso di carico di «Genera '
        'settimana con AI» non contano più il lavoro dei portieri come '
        'quello di tutti.',
  ),
  Novita(
    id: 'ai-con-tetto',
    data: DateTime(2026, 10, 19),
    titolo: 'L\'AI ha un tetto di richieste',
    testo:
        'Genera con l\'AI, il modulo compilato dal testo, la lettura delle '
        'foto e l\'assistente contano insieme: 30 richieste a settimana a '
        'persona (da lunedì) e 300 al mese per il club. Arrivati al limite '
        'l\'app lo dice e si continua a mano.',
  ),
  Novita(
    id: 'campionati-fin-sito-nuovo',
    data: DateTime(2026, 10, 19),
    titolo: 'I campionati FIN di nuovo al loro posto',
    testo:
        'La FIN Lombardia ha rifatto il suo sito: l\'app ora lo legge di '
        'nuovo. Si collegano i gironi, e classifica e calendario tornano '
        'ad aggiornarsi.',
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'scrivimi-e-novita',
    data: DateTime(2026, 10, 19),
    titolo: 'Scrivimi e le novità',
    testo:
        'Nel menu ☰ «Scrivimi» manda a chi sviluppa WaterTactics cosa non '
        'va, con la schermata dove eri. Qui in «Novità» trovi cosa è '
        'cambiato a ogni aggiornamento.',
    importante: true,
  ),
  Novita(
    id: 'guida-rinnovata',
    data: DateTime(2026, 10, 19),
    titolo: 'La guida rinnovata',
    testo:
        'La guida mostra le schede vere mentre le spiega, e il menu ☰. La '
        'rivedi quando vuoi da ☰ → Rivedi la guida.',
  ),
  Novita(
    id: 'configurazione-guidata',
    data: DateTime(2026, 10, 18),
    titolo: 'Configurazione guidata',
    testo:
        'Chi crea un club viene guidato in cinque passi: club, squadre, '
        'allenatori, atleti e codici. In «Oggi» la scheda «Per cominciare» '
        'mostra al responsabile i passi che mancano.',
  ),
  Novita(
    id: 'scarica-dati-club',
    data: DateTime(2026, 10, 18),
    titolo: 'Scarica i dati del club',
    testo:
        'In ☰ → Il mio club il responsabile scarica tutti i dati del club '
        'in un file Excel, un foglio per tipo di dato.',
  ),
  Novita(
    id: 'atleti-da-excel',
    data: DateTime(2026, 10, 18),
    titolo: 'Atleti da un foglio Excel',
    testo:
        'Nella scheda Atleti «Da Excel» aggiunge tutta la squadra da un '
        'file, senza doppioni; «Codici» prepara il foglio con il codice di '
        'ogni atleta, da stampare.',
  ),
  Novita(
    id: 'club-e-assistenti',
    data: DateTime(2026, 10, 18),
    titolo: 'Il club: allenatori e assistenti',
    testo:
        'In ☰ → Il mio club inviti gli altri allenatori con un codice e '
        'scegli il capo di ogni squadra. In «Oggi» vedi chi ha modificato '
        'i tuoi allenamenti.',
  ),
  Novita(
    id: 'partite-nel-calendario',
    data: DateTime(2026, 10, 18),
    titolo: 'Partite nel calendario del telefono',
    testo:
        'Nel menu ☰ «Partite nel calendario» collega le partite al '
        'calendario del telefono: si aggiorna da solo.',
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'pdf-allenamento',
    data: DateTime(2026, 10, 18),
    titolo: "PDF dell'allenamento più leggibile",
    testo:
        "Il PDF e il foglio dell'allenamento escono nell'ordine delle "
        'serie, con i blocchi e i lavori in parallelo affiancati.',
  ),
  Novita(
    id: 'altra-squadra',
    data: DateTime(2026, 10, 15),
    titolo: "Allenarsi anche con un'altra squadra",
    testo:
        "Nella scheda dell'atleta «Si allena anche con» indica un'altra "
        "squadra e i giorni: l'atleta vede anche quegli allenamenti e "
        'quelle partite.',
    perChi: PerChi.tutti,
  ),
  Novita(
    id: 'lavori-in-parallelo',
    data: DateTime(2026, 10, 15),
    titolo: 'Lavori in parallelo',
    testo:
        'Nel compilatore le serie dei portieri e degli specializzati si '
        'scrivono accanto a quelle di tutti, nello stesso tempo.',
  ),
];

/// Le novità da far comparire da sole: quelle uscite dopo l'ultima vista
/// ([ultimaVista] è l'`id` dell'ultima novità che il telefono ha già
/// mostrato), solo le importanti e solo per [atleta] o allenatore.
///
/// Su un telefono nuovo ([ultimaVista] nullo) o con un `id` che non si
/// trova più nel [registro] non compare niente: chi comincia adesso non
/// riceve le novità vecchie.
List<Novita> novitaDaMostrare({
  required List<Novita> registro,
  required String? ultimaVista,
  required bool atleta,
}) {
  if (ultimaVista == null) return const [];
  final posizione = registro.indexWhere((n) => n.id == ultimaVista);
  if (posizione < 0) return const [];
  return [
    for (final n in registro.take(posizione))
      if (n.importante && n.perAtleta(atleta)) n,
  ];
}

/// Tutte le novità che servono a [atleta] o all'allenatore, dalla più
/// recente.
List<Novita> novitaPer({
  required List<Novita> registro,
  required bool atleta,
}) => [
  for (final n in registro)
    if (n.perAtleta(atleta)) n,
];
