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
