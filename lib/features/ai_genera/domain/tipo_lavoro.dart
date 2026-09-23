/// Il vocabolario dei "tipi di lavoro" (zone di intensità A1..D) mostrato
/// al coach: alternativa leggibile alle sigle, con un pulsante info per
/// zona. Contenuto adattato da `METODOLOGIA_ZONE` (la stessa distillazione
/// della metodologia del coach già usata per generare le ripartenze in
/// `supabase/functions/genera-allenamento/index.ts`).
///
/// **Fonte unica**: questo file è la copia canonica; le tre Edge Function
/// (`genera-allenamento`, `genera-settimana`, `detta-allenamento`) tengono
/// ciascuna la propria costante Deno con lo stesso contenuto — nessun
/// meccanismo di codice condiviso fra le Edge Function in questo repo
/// (nessuna cartella `_shared/`), quindi vanno risincronizzate a mano se
/// questo file cambia.
///
/// Le percentuali di frequenza cardiaca sono **indicative e generiche**
/// (valori tipici di fisiologia sportiva): l'app non registra la
/// frequenza cardiaca di nessun atleta, quindi non sono mai calcolate sui
/// dati reali — vedi [TipoLavoro.disclaimerFrequenzaCardiaca].
class TipoLavoro {
  const TipoLavoro({
    required this.codice,
    required this.nome,
    required this.intensita,
    this.fcMaxMinPct,
    this.fcMaxMaxPct,
    required this.aCosaServe,
    required this.riferimenti,
  });

  /// 'A1'..'D'.
  final String codice;

  /// Nome descrittivo mostrato al posto della sigla.
  final String nome;

  /// "bassa" | "moderata" | "medio-alta" | "alta" | "molto alta" |
  /// "massimale".
  final String intensita;

  /// Range indicativo di %FCmax, se ha senso per questa zona (assente
  /// per C3: è uno sforzo massimale breve, non un lavoro a soglia
  /// cardiaca — vedi `aCosaServe`).
  final int? fcMaxMinPct;
  final int? fcMaxMaxPct;

  final String aCosaServe;
  final String riferimenti;

  static const disclaimerFrequenzaCardiaca =
      'Valori generici di riferimento della fisiologia sportiva, non '
      "calcolati sui dati di questo gruppo: l'app non registra la "
      'frequenza cardiaca.';

  /// Testo unico per il pulsante info: intensità (+ range FC se presente),
  /// a cosa serve, riferimenti pratici, disclaimer.
  String get spiegazione {
    final fc = fcMaxMinPct != null && fcMaxMaxPct != null
        ? ' (circa $fcMaxMinPct-$fcMaxMaxPct% della frequenza cardiaca massima)'
        : '';
    return 'Intensità $intensita$fc.\n\n'
        '$aCosaServe\n\n'
        '$riferimenti\n\n'
        '$disclaimerFrequenzaCardiaca';
  }
}

/// Stesso ordine di `ordineZone` in `lib/features/tabelle_passi/domain/`.
const ordineTipiLavoro = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'C3', 'D'];

const tipiLavoro = <String, TipoLavoro>{
  'A1': TipoLavoro(
    codice: 'A1',
    nome: 'Resistenza aerobica (leggera)',
    intensita: 'bassa',
    fcMaxMinPct: 60,
    fcMaxMaxPct: 70,
    aCosaServe:
        'Smaltimento e costruzione della base aerobica: il lavoro più '
        'facile da sostenere, usato per riscaldamento, defaticamento e '
        'volume leggero.',
    riferimenti:
        'Distanze 100-400m (fino a 400 per i fondisti), recupero 5-30s '
        '(più lungo quanto più lunga la distanza). Passo più lento del '
        'passo di riferimento sui 100.',
  ),
  'A2': TipoLavoro(
    codice: 'A2',
    nome: 'Resistenza aerobica (costruzione)',
    intensita: 'moderata',
    fcMaxMinPct: 70,
    fcMaxMaxPct: 80,
    aCosaServe:
        'Costruzione aerobica: poco più impegnativo di A1, resta un '
        'lavoro sostenibile a lungo.',
    riferimenti:
        'Distanze 100-400m, recupero 5-30s. Passo poco più veloce di A1, '
        'sempre più lento del passo di riferimento sui 100.',
  ),
  'B1': TipoLavoro(
    codice: 'B1',
    nome: 'Soglia anaerobica',
    intensita: 'medio-alta',
    fcMaxMinPct: 80,
    fcMaxMaxPct: 87,
    aCosaServe:
        'Lavoro alla soglia: il passo più veloce sostenibile per un '
        'tempo prolungato prima che il lattato si accumuli rapidamente.',
    riferimenti:
        'Distanze 100-300m, recupero 10-30s. Passo vicino al passo di '
        'riferimento sui 100.',
  ),
  'B2': TipoLavoro(
    codice: 'B2',
    nome: 'VO2max',
    intensita: 'alta',
    fcMaxMinPct: 87,
    fcMaxMaxPct: 93,
    aCosaServe:
        'Potenza aerobica: sviluppa il massimo consumo di ossigeno, il '
        'motore aerobico più potente prima di sconfinare nel lavoro '
        'lattacido.',
    riferimenti:
        'Distanze 200-400m (anche frazionate in 50/100/200 con recuperi '
        'brevi 3-10s), recupero pieno 30s-2min fra le ripetute intere. '
        'Usa il differenziale di gara T200-T100, quando disponibile, per '
        'una ripartenza più precisa.',
  ),
  'C1': TipoLavoro(
    codice: 'C1',
    nome: 'Tolleranza lattacida',
    intensita: 'alta',
    fcMaxMinPct: 90,
    fcMaxMaxPct: 95,
    aCosaServe:
        'Allena a sostenere e smaltire il lattato accumulato: sforzi '
        'quasi massimali con recuperi ancora incompleti.',
    riferimenti:
        'Distanze 50-100m, recupero 30s-2min passivi. Ripartenza vicina '
        'o leggermente sotto il passo di riferimento sui 100.',
  ),
  'C2': TipoLavoro(
    codice: 'C2',
    nome: 'Picco di lattato',
    intensita: 'molto alta',
    fcMaxMinPct: 95,
    fcMaxMaxPct: 100,
    aCosaServe:
        'Il picco di produzione di lattato: sforzi massimali su distanze '
        'brevi, con ampio recupero per esprimere ogni volta la massima '
        'intensità.',
    riferimenti: 'Distanze 50-75m, recupero ampio 1\'30"-5\' passivi.',
  ),
  'C3': TipoLavoro(
    codice: 'C3',
    nome: 'Velocità',
    intensita: 'massimale',
    aCosaServe:
        'Velocità pura e potenza alattacida: non è un lavoro a soglia '
        'cardiaca (per questo qui manca un range di frequenza cardiaca), '
        'ma sforzi brevissimi al massimo.',
    riferimenti:
        'Distanze 10-50m, durata 8-10s per ripetuta, recupero elevato '
        '(fino a 2\') per il recupero neuromuscolare.',
  ),
  'D': TipoLavoro(
    codice: 'D',
    nome: 'Ritmo gara',
    intensita: 'variabile',
    aCosaServe:
        'Simula il ritmo di gara reale: l\'intensità dipende dalla '
        'distanza di gara scelta, non da una zona fissa.',
    riferimenti:
        'Ripartenza il più vicina possibile al ritmo di gara reale alla '
        'distanza della serie.',
  ),
};

/// Etichetta da mostrare per una zona: la sigla, o il nome descrittivo
/// se `mostraCodici` è false. Ripiega sulla sigla se la zona non è nella
/// mappa (es. la "C" storica, mai proposta per le serie nuove).
String etichettaTipoLavoro(String zona, {required bool mostraCodici}) {
  if (mostraCodici) return zona;
  return tipiLavoro[zona]?.nome ?? zona;
}
