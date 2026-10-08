/// Volume di allenamento di un atleta, contato solo nei giorni in cui
/// risulta "presente" — stesso perimetro dati del modello Banister (vedi
/// [PuntoBanister]), scomposto per zona di intensità e per tipo di lavoro
/// invece che aggregato giorno per giorno.
///
/// I metri delle serie a distanza e il tempo delle serie a tempo
/// (palleggio, tattica, a secco...) si contano a parte: prima il lavoro a
/// tempo compariva come "0 m" (segnalazione del coach 2026-10-08).
class VolumiAtleta {
  const VolumiAtleta({
    required this.volumeTotaleM,
    required this.perZona,
    required this.perEsecuzione,
    this.tempoTotaleS = 0,
    this.tempoPerZona = const {},
    this.tempoPerEsecuzione = const {},
  });

  /// Le [serie] (righe di `serie_per_carico`: allenamento_id, ripetute,
  /// distanza_m, durata_s, zona, esecuzione) degli allenamenti
  /// [presenti].
  factory VolumiAtleta.daSerie(
    Iterable<Map<String, dynamic>> serie,
    Set<String> presenti,
  ) {
    var metri = 0;
    var secondi = 0;
    final perZona = <String, int>{};
    final perEsecuzione = <String, int>{};
    final tempoPerZona = <String, int>{};
    final tempoPerEsecuzione = <String, int>{};
    void aggiungi(Map<String, int> mappa, String chiave, int valore) {
      if (valore > 0) mappa[chiave] = (mappa[chiave] ?? 0) + valore;
    }

    for (final r in serie) {
      if (!presenti.contains(r['allenamento_id'] as String)) continue;
      final ripetute = r['ripetute'] as int;
      final volume = ripetute * (r['distanza_m'] as int? ?? 0);
      final tempo = ripetute * (r['durata_s'] as int? ?? 0);
      metri += volume;
      secondi += tempo;
      if (r['zona'] case final String zona) {
        aggiungi(perZona, zona, volume);
        aggiungi(tempoPerZona, zona, tempo);
      }
      final esecuzione = r['esecuzione'] as String;
      aggiungi(perEsecuzione, esecuzione, volume);
      aggiungi(tempoPerEsecuzione, esecuzione, tempo);
    }
    return VolumiAtleta(
      volumeTotaleM: metri,
      perZona: perZona,
      perEsecuzione: perEsecuzione,
      tempoTotaleS: secondi,
      tempoPerZona: tempoPerZona,
      tempoPerEsecuzione: tempoPerEsecuzione,
    );
  }

  final int volumeTotaleM;

  /// Chiave = sigla zona ('A1'...'D', anche 'C' storica); solo le zone
  /// con metri nuotati.
  final Map<String, int> perZona;

  /// Chiave = esecuzione ('nuoto', 'gambe', ...); solo quelle con metri.
  final Map<String, int> perEsecuzione;

  /// Il lavoro a tempo, in secondi (le ripetute per la durata, senza i
  /// recuperi).
  final int tempoTotaleS;

  /// Come [perZona], per le serie a tempo con una zona.
  final Map<String, int> tempoPerZona;

  /// Come [perEsecuzione], per le serie a tempo ('palleggio': 2700).
  final Map<String, int> tempoPerEsecuzione;
}
