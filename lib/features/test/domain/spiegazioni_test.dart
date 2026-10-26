import 'test_club.dart';

/// Le spiegazioni dei test ("come si fa"): a cosa serve, cosa serve,
/// come si fa, come si misura, errori da evitare. Sono testo libero che
/// l'allenatore può cambiare; queste sono quelle dei test pronti.
///
/// Forma del testo: blocchi separati da una riga vuota. In un blocco di
/// più righe la prima è il titolo; una riga che comincia con "• " è un
/// punto di un elenco (vedi `SpiegazioneTest`).

/// Lunghezza massima di una spiegazione (come nel database).
const lunghezzaMassimaSpiegazione = 4000;

const _sprintComeSiMisura =
    'Il cronometro parte al fischio e si ferma quando la testa passa il '
    'segno d\'arrivo. In classifica va la prova migliore.';

const _sprintErrori =
    'Errori da evitare\n'
    '• Spingersi dal muro o partire prima del fischio.\n'
    '• Cambiare chi cronometra fra una prova e l\'altra.\n'
    '• Fare il test stanchi, a fine allenamento: va fatto dopo il '
    'riscaldamento, all\'inizio.';

const spiegazioneSprint10 =
    'A cosa serve\n'
    'Misura l\'accelerazione da fermo: la partenza in contropiede, '
    'l\'anticipo, lo scatto per conquistare la palla.\n'
    '\n'
    'Cosa serve\n'
    'Un cronometro (meglio uno per corsia), il fischietto, un segno a 10 m '
    '(il segno della corsia o un cono a bordo vasca).\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento di almeno 10 minuti, con qualche accelerazione.\n'
    '• L\'atleta aspetta in acqua, fermo e senza toccare il muro.\n'
    '• Al fischio parte a stile libero e nuota a tutta fino al segno.\n'
    '• Due prove, con 2-3 minuti di recupero fra una e l\'altra.\n'
    '\n'
    'Come si misura\n'
    '$_sprintComeSiMisura\n'
    '\n'
    '$_sprintErrori';

const spiegazioneSprint15 =
    'A cosa serve\n'
    'Misura la velocità sui primi metri, quelli che contano in partita: '
    'il contropiede, il rientro in difesa.\n'
    '\n'
    'Cosa serve\n'
    'Un cronometro (meglio uno per corsia), il fischietto, un segno a 15 m.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento di almeno 10 minuti, con qualche accelerazione.\n'
    '• L\'atleta aspetta in acqua, fermo e senza toccare il muro.\n'
    '• Al fischio parte a stile libero e nuota a tutta fino ai 15 m.\n'
    '• Due prove, con 2-3 minuti di recupero fra una e l\'altra.\n'
    '\n'
    'Come si misura\n'
    '$_sprintComeSiMisura\n'
    '\n'
    '$_sprintErrori';

const spiegazioneSprint15Palla =
    'A cosa serve\n'
    'Misura quanto si va veloci portando la palla, a confronto con lo '
    'sprint senza palla: più i due tempi sono vicini, meglio si conduce.\n'
    '\n'
    'Cosa serve\n'
    'Un cronometro, il fischietto, un pallone a testa, un segno a 15 m.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento di almeno 10 minuti, con qualche conduzione veloce.\n'
    '• L\'atleta aspetta in acqua, fermo, con la palla davanti e senza '
    'toccare il muro.\n'
    '• Al fischio parte a testa alta, con la palla fra le braccia, e nuota '
    'a tutta fino ai 15 m.\n'
    '• Due prove, con 2-3 minuti di recupero fra una e l\'altra.\n'
    '\n'
    'Come si misura\n'
    'Il cronometro parte al fischio e si ferma quando la testa passa i 15 '
    'm con la palla ancora sotto controllo. Se la perde, la prova si '
    'rifà. In classifica va la prova migliore.\n'
    '\n'
    'Errori da evitare\n'
    '• Spingere la palla avanti e rincorrerla: deve restare fra le '
    'braccia.\n'
    '• Abbassare la testa per andare più veloci.\n'
    '• Spingersi dal muro o partire prima del fischio.';

const spiegazioneSprintRipetuti =
    'A cosa serve\n'
    'Misura quanto l\'atleta tiene la velocità sugli scatti ripetuti, come '
    'in partita: non solo quanto è veloce, ma quanto rallenta.\n'
    '\n'
    'Cosa serve\n'
    'Un cronometro che segni i parziali (o una persona per atleta), il '
    'fischietto, un segno a 15 m, l\'orologio della vasca.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento di almeno 10 minuti, con qualche accelerazione.\n'
    '• Sei sprint da 15 m, uno ogni 20 secondi: quello che resta dei 20 '
    'secondi è il recupero.\n'
    '• Ogni sprint parte da fermo in acqua, senza toccare il muro: dopo '
    'l\'arrivo l\'atleta torna con calma al segno di partenza (o parte '
    'dal lato opposto).\n'
    '• Tutti e sei a tutta, senza risparmiarsi per gli ultimi.\n'
    '\n'
    'Come si misura\n'
    'Si scrive il tempo di ognuno dei sei sprint. In classifica va la '
    'media. L\'indice di affaticamento dice di quanto per cento la serie '
    'è più lenta di sei sprint tutti uguali al migliore: più è basso, '
    'meglio l\'atleta tiene.\n'
    '\n'
    'Errori da evitare\n'
    '• Partire piano per tenere il tempo: falsa l\'indice di '
    'affaticamento.\n'
    '• Recuperare più dei 20 secondi.\n'
    '• Spingersi dal muro.';

const spiegazioneWist =
    'A cosa serve\n'
    'Il Water-polo Intermittent Shuttle Test misura la resistenza alle '
    'azioni ripetute: nuotate avanti e indietro con brevi pause, sempre '
    'più veloci, come i cambi di fronte di una partita.\n'
    '\n'
    'Cosa serve\n'
    'Due segni in acqua alla distanza del protocollo che usi, la traccia '
    'audio (o la tabella dei tempi) con i segnali, uno che controlla chi '
    'arriva in ritardo.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento di 10-15 minuti.\n'
    '• Al segnale l\'atleta nuota da un segno all\'altro e deve arrivare '
    'prima del segnale dopo; fra un gruppo di vasche e l\'altro c\'è una '
    'breve pausa.\n'
    '• Il ritmo aumenta a ogni livello.\n'
    '• Il test finisce quando l\'atleta arriva in ritardo per due volte di '
    'seguito, o si ferma.\n'
    '\n'
    'Come si misura\n'
    'Si scrivono i metri nuotati in tutto, fino all\'ultima vasca '
    'arrivata in tempo. In classifica vince chi ne fa di più.\n'
    '\n'
    'Errori da evitare\n'
    '• Cambiare distanza o tracce audio fra un test e l\'altro: i '
    'risultati non si confrontano più.\n'
    '• Contare le vasche arrivate in ritardo.';

const spiegazioneVerticalePeso =
    'A cosa serve\n'
    'Misura la forza e la resistenza delle gambe a rana alternata '
    '(eggbeater): quanto l\'atleta resta alto in acqua con le braccia '
    'occupate, come quando para, tira o lotta in centro.\n'
    '\n'
    'Cosa serve\n'
    'Un peso (palla zavorrata, disco o manubrio), sempre lo stesso per la '
    'stessa categoria, e un cronometro. Scrivi qui il peso che usi.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento con qualche minuto di gambe a rana alternata.\n'
    '• L\'atleta in acqua alta, in verticale, prende il peso e lo porta '
    'sopra la testa a braccia tese.\n'
    '• Al via tiene il peso più a lungo che può, con le gambe a rana '
    'alternata.\n'
    '\n'
    'Come si misura\n'
    'Il cronometro si ferma quando le braccia si piegano, il peso '
    'scende davanti alla testa o l\'acqua arriva al mento. In classifica '
    'vince chi resta su più a lungo.\n'
    '\n'
    'Errori da evitare\n'
    '• Appoggiarsi al muro o alla corsia.\n'
    '• Cambiare il peso fra un test e l\'altro.';

const spiegazioneSalto =
    'A cosa serve\n'
    'Misura l\'esplosività delle gambe: quanto l\'atleta esce dall\'acqua '
    'per tirare, parare o prendere una palla alta.\n'
    '\n'
    'Cosa serve\n'
    'Un\'asta o un tabellone graduato in centimetri tenuto in verticale a '
    'bordo vasca, con lo zero al pelo dell\'acqua. In alternativa un '
    'video di lato con un riferimento graduato.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento con qualche minuto di gambe a rana alternata e '
    'qualche salto.\n'
    '• L\'atleta, in verticale accanto all\'asta, parte da fermo con le '
    'gambe a rana alternata.\n'
    '• Salta più in alto che può e tocca l\'asta con la mano, il braccio '
    'teso.\n'
    '• Tre prove, con un minuto di recupero fra una e l\'altra.\n'
    '\n'
    'Come si misura\n'
    'L\'altezza del tocco sopra il pelo dell\'acqua, in centimetri. In '
    'classifica va la prova migliore.\n'
    '\n'
    'Errori da evitare\n'
    '• Prendere la rincorsa o spingersi dal muro.\n'
    '• Leggere l\'altezza da lontano: chi legge deve stare all\'altezza '
    'dell\'asta.';

const spiegazioneVelocitaTiro =
    'A cosa serve\n'
    'Misura quanto forte tira l\'atleta: la potenza di braccio, tronco e '
    'gambe insieme.\n'
    '\n'
    'Cosa serve\n'
    'Un radar per la velocità (una pistola radar o un\'app che la misuri '
    'dal video), i palloni, la porta. Il radar sta dietro la porta, in '
    'linea con il tiro.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento delle spalle e qualche tiro piano prima del test.\n'
    '• L\'atleta tira da 5 m, da fermo in verticale, senza portiere.\n'
    '• Tre tiri, con qualche secondo fra uno e l\'altro.\n'
    '• Conta solo il tiro che entra in porta.\n'
    '\n'
    'Come si misura\n'
    'La velocità letta dal radar, in km/h. In classifica va il tiro più '
    'veloce.\n'
    '\n'
    'Errori da evitare\n'
    '• Tirare senza scaldare le spalle.\n'
    '• Spostare il radar o cambiare distanza fra un test e l\'altro.';

const spiegazionePrecisioneTiro =
    'A cosa serve\n'
    'Misura la precisione: mettere la palla dove si vuole, negli angoli '
    'dove il portiere non arriva.\n'
    '\n'
    'Cosa serve\n'
    'Quattro bersagli negli angoli della porta (cerchi o sagome appese '
    'alla traversa e ai pali), i palloni.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento delle spalle e qualche tiro piano.\n'
    '• L\'atleta tira da 5 m, da fermo in verticale, senza portiere.\n'
    '• Dieci tiri: chi conduce il test chiama ogni volta l\'angolo, e '
    'l\'atleta ha 3 secondi per tirare.\n'
    '\n'
    'Come si misura\n'
    'Un punto per ogni bersaglio colpito, quello chiamato. In classifica '
    'vince chi ne prende di più (al massimo 10).\n'
    '\n'
    'Errori da evitare\n'
    '• Lasciare scegliere l\'angolo all\'atleta.\n'
    '• Contare un tiro che entra ma fuori dal bersaglio chiamato.';

/// La spiegazione dei massimali, con la tecnica dell'esercizio
/// ([tecnica], vuota per un massimale inventato dall'allenatore).
String spiegazioneMassimale([String? tecnica]) =>
    'A cosa serve\n'
    'Stima il massimale dell\'atleta in questo esercizio senza fargli '
    'sollevare il massimo vero. Nelle sedute a secco un carico «70%» '
    'diventa i chili di ognuno.\n'
    '\n'
    'Cosa serve\n'
    'Il bilanciere o i manubri, i dischi, qualcuno che assiste.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento generale, poi qualche serie dell\'esercizio con '
    'carichi leggeri.\n'
    '• Si sale di carico serie dopo serie, con 2-3 minuti di recupero.\n'
    '• Ci si ferma al carico più pesante con cui l\'atleta fa da 3 a 6 '
    'ripetizioni pulite, senza perdere la tecnica.\n'
    '${tecnica == null || tecnica.isEmpty ? '' : '• $tecnica\n'}'
    '\n'
    'Come si misura\n'
    'Si scrivono i chili e le ripetizioni fatte: l\'app stima il '
    'massimale con la formula di Brzycki. Oltre 10 ripetizioni la stima '
    'non è affidabile.\n'
    '\n'
    'Errori da evitare\n'
    '• Cercare il massimo vero con una ripetizione sola: non serve ed è '
    'rischioso per i ragazzi.\n'
    '• Contare le ripetizioni fatte male o aiutate.\n'
    '• Fare il test senza nessuno che assiste.';

/// La tecnica da tenere in ogni massimale pronto.
const _tecnicaMassimali = {
  'massimale_squat':
      'Squat: schiena dritta, talloni a terra, si scende almeno finché le '
      'cosce sono parallele al pavimento.',
  'massimale_panca':
      'Panca: il bilanciere tocca il petto senza rimbalzare, i glutei '
      'restano sulla panca; chi assiste sta dietro la testa.',
  'massimale_stacco':
      'Stacco: schiena dritta dall\'inizio alla fine, il bilanciere sale '
      'vicino alle gambe.',
  'massimale_rematore':
      'Rematore: un ginocchio e una mano sulla panca, schiena piatta, il '
      'manubrio sale fino al fianco senza ruotare il busto; i chili e le '
      'ripetizioni sono quelli di un braccio.',
};

const spiegazioneBvs =
    'A cosa serve\n'
    'È il test di soglia: dal passo medio l\'app calcola le tabelle dei '
    'passi per zona, usate dalle ripartenze e dalla generazione degli '
    'allenamenti.\n'
    '\n'
    'Cosa serve\n'
    'Un cronometro e qualcuno che conti le vasche.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento di 10-15 minuti.\n'
    '• L\'atleta nuota a stile libero una distanza lunga (di solito fra '
    '1500 e 3000 m: scegline una e tienila sempre uguale) al passo più '
    'veloce che riesce a tenere costante fino alla fine.\n'
    '• Né una gara né un allenamento facile: deve arrivare in fondo '
    'stanco, senza essere crollato a metà.\n'
    '\n'
    'Come si misura\n'
    'Si scrivono la distanza e il tempo totale: l\'app calcola il passo '
    'medio sui 100 m.\n'
    '\n'
    'Errori da evitare\n'
    '• Partire troppo forte e rallentare: il passo medio non è più quello '
    'di soglia.\n'
    '• Sbagliare il conto delle vasche.';

const spiegazioneT30 =
    'A cosa serve\n'
    'Un altro test di soglia: come il BVS, dal passo medio l\'app calcola '
    'le tabelle dei passi per zona.\n'
    '\n'
    'Cosa serve\n'
    'Un cronometro e qualcuno che conti le vasche.\n'
    '\n'
    'Come si fa\n'
    '• Riscaldamento di 10-15 minuti.\n'
    '• L\'atleta nuota a stile libero per 30 minuti senza fermarsi, al '
    'passo più veloce che riesce a tenere costante.\n'
    '• Allo scadere dei 30 minuti si segna dove è arrivato.\n'
    '\n'
    'Come si misura\n'
    'Si scrivono i metri nuotati in 30 minuti: l\'app calcola il passo '
    'medio sui 100 m.\n'
    '\n'
    'Errori da evitare\n'
    '• Partire troppo forte e rallentare.\n'
    '• Arrotondare i metri: conta anche l\'ultima vasca a metà.';

/// La spiegazione originale di un test pronto ([modello]); null per un
/// test inventato. Con [massimale] e nessun modello, quella generica dei
/// massimali.
String? spiegazioneOriginale(String? modello, {bool massimale = false}) {
  if (modello != null) {
    for (final m in modelliTest) {
      if (m.chiave == modello) return m.descrizione;
    }
    if (_tecnicaMassimali.containsKey(modello)) {
      return spiegazioneMassimale(_tecnicaMassimali[modello]);
    }
  }
  return massimale ? spiegazioneMassimale() : null;
}

/// Le descrizioni di una riga dei test pronti di prima: chi non le ha
/// cambiate legge la spiegazione nuova.
const _descrizioniDiPrima = {
  'Partenza da fermi in acqua, al fischio. Due prove.',
  'Nuotata con la palla davanti, partenza da fermi. Due prove.',
  "Una partenza ogni 20''. In classifica la media; l'indice di "
      "affaticamento dice quanto cala dalla prova migliore.",
  'Water-polo Intermittent Shuttle Test: metri percorsi fino '
      "all'esaurimento.",
  'Secondi in verticale con il peso sopra la testa, braccia tese '
      '(scrivi qui il peso).',
  'Altezza raggiunta con la mano, da fermi. Tre prove.',
  'Con il radar, da 5 m. Tre tiri.',
  'Dieci tiri da 5 m sui bersagli negli angoli: un punto a '
      'bersaglio.',
  'Dopo il riscaldamento, il carico più pesante con cui l\'atleta fa da 3 '
      'a 6 ripetizioni pulite: si scrivono chili e ripetizioni e l\'app '
      'stima il massimale. Sempre con qualcuno che assiste.',
};

/// La spiegazione da leggere di un test: quella scritta dall'allenatore;
/// per un test pronto mai cambiato (o senza), quella originale. null se
/// non ce n'è nessuna.
String? spiegazioneDi(TestClub test) {
  final scritta = test.descrizione?.trim();
  final originale = spiegazioneOriginale(
    test.modello,
    massimale: test.massimale,
  );
  if (originale != null &&
      (scritta == null ||
          scritta.isEmpty ||
          _descrizioniDiPrima.contains(scritta))) {
    return originale;
  }
  return scritta == null || scritta.isEmpty ? null : scritta;
}

/// La spiegazione dei test di nuoto ('BVS' o 'T30') del club: quella
/// scritta dall'allenatore, se no l'originale.
String spiegazioneTestNuoto(String tipo, String? scritta) {
  final s = scritta?.trim();
  if (s != null && s.isNotEmpty) return s;
  return tipo == 'T30' ? spiegazioneT30 : spiegazioneBvs;
}

/// I blocchi di una spiegazione: un titolo (null se il blocco è di una
/// riga sola) e le righe; una riga che comincia con "• " è un punto.
List<({String? titolo, List<String> righe})> blocchiSpiegazione(String testo) {
  final blocchi = <({String? titolo, List<String> righe})>[];
  for (final grezzo
      in testo.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'))) {
    final righe = [
      for (final r in grezzo.split('\n'))
        if (r.trim().isNotEmpty) r.trim(),
    ];
    if (righe.isEmpty) continue;
    final conTitolo = righe.length > 1 && !righe.first.startsWith('•');
    blocchi.add((
      titolo: conTitolo ? righe.first : null,
      righe: conTitolo ? righe.sublist(1) : righe,
    ));
  }
  return blocchi;
}
