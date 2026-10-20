/// Gli stati di una presenza (colonna `stato`, enum `stato_presenza`).
const statoPresente = 'presente';
const statoRitardo = 'ritardo';
const statoAssente = 'assente';
const statoGiustificato = 'giustificato';

/// L'unica regola per «c'era»: chi è presente o è arrivato in ritardo.
/// Carico, percentuali, statistiche, Excel, assistente e home dell'atleta
/// la usano tutti; confrontare lo stato con `'presente'` fa sparire chi è
/// in ritardo (il test `presenze_ritardo_test.dart` lo impedisce).
bool contaComePresente(String? stato) =>
    stato == statoPresente || stato == statoRitardo;

/// «Presente», «In ritardo»... come si leggono in app e nell'Excel.
String etichettaStatoPresenza(String stato) => switch (stato) {
  statoPresente => 'Presente',
  statoRitardo => 'In ritardo',
  statoAssente => 'Assente',
  statoGiustificato => 'Giustificato',
  _ => stato,
};

class Presenza {
  const Presenza({
    required this.id,
    required this.allenamentoId,
    required this.atletaId,
    required this.clubId,
    required this.stato,
    this.note,
  });

  final String id;
  final String allenamentoId;
  final String atletaId;
  final String clubId;
  final String stato; // presente | ritardo | assente | giustificato
  final String? note;

  factory Presenza.fromMap(Map<String, dynamic> map) {
    return Presenza(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      stato: map['stato'] as String,
      note: map['note'] as String?,
    );
  }
}
