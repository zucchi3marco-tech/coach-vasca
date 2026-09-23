import 'parametri_generazione.dart';

/// Parametri per pianificare una settimana intera (FASE 10, punto 5):
/// solo lo scheletro (codice, volume), non il dettaglio delle serie —
/// quello lo produce poi `genera-allenamento` una volta per seduta,
/// riusando gli stessi passi di riferimento.
class ParametriSettimana {
  const ParametriSettimana({
    required this.gruppo,
    required this.giorniSettimana,
    required this.volumeSettimanaleMetri,
    this.volumeLavoroCentraleSettimanaleM,
    required this.focusPerSeduta,
    this.attrezzaturaLavoroCentrale = const [],
    this.minutiMax,
    this.vascaM,
    this.tipoSettimana,
    this.vincoli,
    this.corsie = const [],
    this.riassuntoProgrammazione,
  });

  final String gruppo;

  /// Un'etichetta leggibile per ciascun giorno scelto dal coach (es.
  /// "Lunedì 15/9"), nello stesso ordine di [focusPerSeduta]: il giorno
  /// non lo decide più l'AI, che riceve solo questi come contesto per il
  /// prompt (per ragionare sulla spaziatura fra sedute).
  final List<String> giorniSettimana;
  final int volumeSettimanaleMetri;

  /// Metri di lavoro centrale (blocco "principale") per l'intera
  /// settimana: ripartiti proporzionalmente al volume di ogni seduta
  /// quando si genera il dettaglio (nessun campo per singola seduta).
  final int? volumeLavoroCentraleSettimanaleM;

  /// Un focus per ciascuna seduta, nello stesso ordine di
  /// [giorniSettimana]: l'AI resta libera di scegliere volume/codice ma
  /// deve rispettare l'ordine e il conteggio.
  final List<String> focusPerSeduta;

  /// Una volta per l'intera settimana (non per seduta): propagata
  /// identica ad ogni chiamata di dettaglio.
  final List<String> attrezzaturaLavoroCentrale;
  final int? minutiMax;
  final int? vascaM;

  final String? tipoSettimana;
  final String? vincoli;
  final List<CorsiaGenerazione> corsie;

  /// Come il gruppo è stato allenato negli ultimi ~2 mesi (vedi
  /// `storico_settimana_service.dart`), da `RiassuntoProgrammazione.
  /// toMap()`: guida lo stile della settimana generata.
  final Map<String, dynamic>? riassuntoProgrammazione;

  Map<String, dynamic> toMap() {
    return {
      'gruppo': gruppo,
      'giorniSettimana': giorniSettimana,
      'volumeSettimanaleMetri': volumeSettimanaleMetri,
      'volumeLavoroCentraleSettimanaleMetri': volumeLavoroCentraleSettimanaleM,
      'focusPerSeduta': focusPerSeduta,
      'attrezzaturaLavoroCentrale': attrezzaturaLavoroCentrale,
      'minutiMax': minutiMax,
      'vascaM': vascaM,
      'tipoSettimana': tipoSettimana,
      'vincoli': vincoli,
      'corsie': corsie.map((c) => c.toMap()).toList(),
      'riassuntoProgrammazione': riassuntoProgrammazione,
    };
  }
}

/// Una singola seduta proposta per la settimana: solo lo scheletro,
/// prima che venga generato il dettaglio delle serie. Il giorno non è
/// più un campo dell'AI: è il client ad accoppiare l'elemento i-esimo
/// restituito con `giorniSettimana[i]`.
class SedutaGenerata {
  const SedutaGenerata({required this.codice, required this.volumeMetri});

  final String codice;
  final int volumeMetri;

  factory SedutaGenerata.fromMap(Map<String, dynamic> map) {
    return SedutaGenerata(
      codice: map['codice'] as String,
      volumeMetri: map['volumeMetri'] as int,
    );
  }
}

class SettimanaGenerata {
  const SettimanaGenerata({required this.sedute});

  final List<SedutaGenerata> sedute;

  factory SettimanaGenerata.fromMap(Map<String, dynamic> map) {
    return SettimanaGenerata(
      sedute: (map['sedute'] as List)
          .map((voce) => SedutaGenerata.fromMap(voce as Map<String, dynamic>))
          .toList(),
    );
  }
}
