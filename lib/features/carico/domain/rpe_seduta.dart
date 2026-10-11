/// Quanto è stata dura una seduta per un atleta, da 0 a 10 (scala CR-10
/// di Foster), detto a fine allenamento o a fine partita.
class RpeSeduta {
  const RpeSeduta({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.eventoTipo,
    required this.eventoId,
    required this.data,
    required this.rpe,
  });

  final String id;
  final String atletaId;
  final String clubId;

  /// 'allenamento' | 'partita'.
  final String eventoTipo;
  final String eventoId;

  /// Il giorno della seduta.
  final DateTime data;
  final int rpe;
}
