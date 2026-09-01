/// Una voce dello storico delle generazioni AI (FASE 5, punto 6): cosa e'
/// stato chiesto, cosa e' tornato (o l'errore), e se e' poi diventata un
/// allenamento salvato. Serve a rivedere e migliorare i prompt nel tempo.
class GenerazioneAiRegistrata {
  const GenerazioneAiRegistrata({
    required this.id,
    required this.creatoIl,
    required this.parametri,
    required this.esito,
    this.scheda,
    this.messaggioErrore,
    this.allenamentoId,
  });

  final String id;
  final DateTime creatoIl;
  final Map<String, dynamic> parametri;
  final String esito;
  final Map<String, dynamic>? scheda;
  final String? messaggioErrore;
  final String? allenamentoId;

  bool get successo => esito == 'successo';

  factory GenerazioneAiRegistrata.fromMap(Map<String, dynamic> map) {
    return GenerazioneAiRegistrata(
      id: map['id'] as String,
      creatoIl: DateTime.parse(map['created_at'] as String),
      parametri: Map<String, dynamic>.from(map['parametri'] as Map),
      esito: map['esito'] as String,
      scheda: map['scheda'] == null
          ? null
          : Map<String, dynamic>.from(map['scheda'] as Map),
      messaggioErrore: map['messaggio_errore'] as String?,
      allenamentoId: map['allenamento_id'] as String?,
    );
  }
}
