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
