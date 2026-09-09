import 'parametri_generazione.dart';

/// Parametri per pianificare una settimana intera (FASE 10, punto 5):
/// solo lo scheletro (numero di sedute, codice, volume), non il
/// dettaglio delle serie — quello lo produce poi `genera-allenamento`
/// una volta per seduta, riusando gli stessi passi di riferimento.
class ParametriSettimana {
  const ParametriSettimana({
    required this.gruppo,
    required this.numeroSedute,
    required this.volumeSettimanaleMetri,
    required this.focus,
    this.tipoMicrociclo,
    this.vincoli,
    this.corsie = const [],
  });

  final String gruppo;
  final int numeroSedute;
  final int volumeSettimanaleMetri;
  final String focus;
  final String? tipoMicrociclo;
  final String? vincoli;
  final List<CorsiaGenerazione> corsie;

  Map<String, dynamic> toMap() {
    return {
      'gruppo': gruppo,
      'numeroSedute': numeroSedute,
      'volumeSettimanaleMetri': volumeSettimanaleMetri,
      'focus': focus,
      'tipoMicrociclo': tipoMicrociclo,
      'vincoli': vincoli,
      'corsie': corsie.map((c) => c.toMap()).toList(),
    };
  }
}

/// Una singola seduta proposta per la settimana: solo lo scheletro,
/// prima che venga generato il dettaglio delle serie.
class SedutaGenerata {
  const SedutaGenerata({
    required this.giorno,
    required this.codice,
    required this.volumeMetri,
  });

  /// 1 = primo giorno della settimana (data_inizio del microciclo).
  final int giorno;
  final String codice;
  final int volumeMetri;

  factory SedutaGenerata.fromMap(Map<String, dynamic> map) {
    return SedutaGenerata(
      giorno: map['giorno'] as int,
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
