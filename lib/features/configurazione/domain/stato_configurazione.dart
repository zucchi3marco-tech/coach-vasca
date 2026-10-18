/// I passi della configurazione guidata di un club nuovo, nell'ordine in
/// cui li propone: "Passo 2 di 5".
enum PassoConfigurazione {
  club,
  squadre,
  allenatori,
  atleti,
  codici;

  /// 1 per il club, 5 per i codici.
  int get numero => index + 1;

  static int get totale => values.length;

  String get titolo => switch (this) {
    PassoConfigurazione.club => 'Il club',
    PassoConfigurazione.squadre => 'Le squadre',
    PassoConfigurazione.allenatori => 'Gli allenatori',
    PassoConfigurazione.atleti => 'Gli atleti',
    PassoConfigurazione.codici => 'I codici',
  };

  /// La riga della scheda "Per cominciare" quando il passo non è fatto.
  String get daFare => switch (this) {
    PassoConfigurazione.club => 'Crea il club',
    PassoConfigurazione.squadre => 'Crea le squadre',
    PassoConfigurazione.allenatori => 'Invita chi allena con te',
    PassoConfigurazione.atleti => 'Aggiungi gli atleti',
    PassoConfigurazione.codici => 'Dai ai ragazzi i loro codici',
  };

  /// Si può lasciare per dopo: il club e le squadre no, senza una squadra
  /// l'app non va avanti.
  bool get facoltativo => index > PassoConfigurazione.squadre.index;
}

/// A che punto è la configurazione di un club, presa dai dati veri: quello
/// che c'è già conta come fatto anche se non è passato dai passi.
class StatoConfigurazione {
  const StatoConfigurazione({
    required this.squadre,
    required this.altriAllenatori,
    required this.invitiAllenatori,
    required this.allenaDaSolo,
    required this.atleti,
    required this.atletiConAccount,
    required this.codiciAtleti,
  });

  /// Le squadre (gruppi) del club.
  final int squadre;

  /// Allenatori e assistenti nel club, oltre a chi guarda.
  final int altriAllenatori;

  /// È stato creato almeno un codice per un allenatore o un assistente.
  final bool invitiAllenatori;

  /// Il responsabile ha detto che allena da solo ("Alleno da solo").
  final bool allenaDaSolo;

  /// Gli atleti attivi.
  final int atleti;

  /// Gli atleti attivi che hanno già l'account nell'app.
  final int atletiConAccount;

  /// È stato creato almeno un codice personale per un atleta (dal foglio
  /// dei codici o dalla sua scheda).
  final bool codiciAtleti;

  bool fatto(PassoConfigurazione passo) => switch (passo) {
    PassoConfigurazione.club => true,
    PassoConfigurazione.squadre => squadre > 0,
    PassoConfigurazione.allenatori =>
      altriAllenatori > 0 || invitiAllenatori || allenaDaSolo,
    PassoConfigurazione.atleti => atleti > 0,
    PassoConfigurazione.codici => atletiConAccount > 0 || codiciAtleti,
  };

  /// Quanti passi sono fatti, il club compreso: "3 di 5".
  int get fatti => PassoConfigurazione.values.where(fatto).length;

  bool get tuttoFatto => fatti == PassoConfigurazione.totale;

  /// Il primo passo ancora da fare, null se è tutto fatto.
  PassoConfigurazione? get prossimo =>
      PassoConfigurazione.values.where((p) => !fatto(p)).firstOrNull;
}
