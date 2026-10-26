import '../../atleti/domain/atleta.dart';

/// Una scheda obiettivi (proposta 14 del «Piano di WaterTactics»):
/// l'allenatore sceglie le domande e la manda agli atleti di una
/// stagione; ognuno risponde e l'allenatore scrive due righe di ritorno.
/// Tabella `schede_obiettivi`; le domande non cambiano dopo la prima
/// risposta (lo controlla il database).
class SchedaObiettivi {
  const SchedaObiettivi({
    required this.id,
    required this.clubId,
    required this.titolo,
    required this.domande,
    required this.createdAt,
    this.stagioneId,
    this.gruppoId,
    this.chiusa = false,
  });

  factory SchedaObiettivi.fromMap(Map<String, dynamic> m) => SchedaObiettivi(
    id: m['id'] as String,
    clubId: m['club_id'] as String,
    stagioneId: m['stagione_id'] as String?,
    gruppoId: m['gruppo_id'] as String?,
    titolo: m['titolo'] as String,
    domande: [for (final d in m['domande'] as List) d as String],
    chiusa: m['chiusa'] as bool? ?? false,
    createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
  );

  final String id;
  final String clubId;
  final String? stagioneId;

  /// Gli atleti a cui arriva: quelli di questo gruppo (anche come altra
  /// squadra); null = tutto il club.
  final String? gruppoId;
  final String titolo;
  final List<String> domande;

  /// Chiusa: gli atleti la leggono ma non rispondono più.
  final bool chiusa;
  final DateTime createdAt;

  /// La scheda arriva all'[atleta].
  bool perAtleta(Atleta atleta) =>
      gruppoId == null ||
      gruppoId == atleta.gruppoId ||
      gruppoId == atleta.altroGruppoId;
}

/// Le risposte di un atleta a una scheda e il ritorno dell'allenatore
/// (tabella `risposte_obiettivi`).
class RispostaObiettivi {
  const RispostaObiettivi({
    required this.id,
    required this.schedaId,
    required this.atletaId,
    required this.clubId,
    required this.risposte,
    required this.inviataAt,
    this.ritorno,
    this.ritornoAt,
  });

  factory RispostaObiettivi.fromMap(Map<String, dynamic> m) =>
      RispostaObiettivi(
        id: m['id'] as String,
        schedaId: m['scheda_id'] as String,
        atletaId: m['atleta_id'] as String,
        clubId: m['club_id'] as String,
        risposte: [for (final r in m['risposte'] as List) r as String],
        ritorno: m['ritorno'] as String?,
        ritornoAt: m['ritorno_at'] == null
            ? null
            : DateTime.parse(m['ritorno_at'] as String).toLocal(),
        inviataAt: DateTime.parse(m['inviata_at'] as String).toLocal(),
      );

  final String id;
  final String schedaId;
  final String atletaId;
  final String clubId;

  /// Una per domanda, nello stesso ordine.
  final List<String> risposte;

  /// Le due righe dell'allenatore.
  final String? ritorno;
  final DateTime? ritornoAt;
  final DateTime inviataAt;
}

/// Le domande pronte: nessuna sulla salute (gli atleti sono spesso
/// minorenni), valgono per la pallanuoto e per il nuoto.
const domandeObiettiviPronte = [
  'Cosa vuoi migliorare quest\'anno?',
  'Qual è il tuo obiettivo per questa stagione?',
  'Un obiettivo per la partita o la gara più importante',
  'In cosa ti senti già forte?',
  'Cosa ti aspetti dalla squadra?',
  'Cosa ti aspetti dall\'allenatore?',
  'Cosa ti piace di più degli allenamenti?',
  'Cosa puoi fare tu per aiutare i compagni?',
];

const massimoDomandeObiettivi = 10;
const lunghezzaMassimaDomanda = 300;
const lunghezzaMassimaRisposta = 1000;
const lunghezzaMassimaRitorno = 1000;
const lunghezzaMassimaTitoloScheda = 80;

/// Il titolo proposto per una scheda nuova: la prima della stagione è
/// quella di inizio, le altre servono a fare il punto.
String titoloSchedaProposto(int giaFatte) =>
    giaFatte == 0 ? 'Obiettivi di inizio stagione' : 'A che punto siamo';

const _paroleSalute = [
  'salute',
  'infortun',
  'dolor',
  'male ',
  'malatt',
  'medic',
  'farmac',
  'peso',
  'dieta',
  'mangi',
  'cicl',
  'mestru',
  'allerg',
  'ansia',
  'depress',
  'cuore',
  'sonno',
  'dormi',
];

/// Una domanda scritta dall'allenatore che sembra chiedere della salute:
/// l'app lo fa notare (non la blocca: decide lui).
bool sembraSullaSalute(String domanda) {
  final d = '${domanda.toLowerCase()} ';
  return _paroleSalute.any(d.contains);
}
