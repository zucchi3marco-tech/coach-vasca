/// Un avviso in app (e, con le notifiche push, anche sul telefono): tipi
/// `atleta_registrato` (per il coach), `convocazione_gara` e
/// `convocazione_partita` (per l'atleta; per le partite parte quando
/// l'allenatore invia la convocazione), `visita_medica` (coach e atleta),
/// `benessere` (per il coach: scheda da sentire o molto sotto il solito),
/// `video_partita` (per l'atleta convocato: il video della partita o una
/// nota per lui), `allenamento_modificato` (per il capo della squadra),
/// `segnalazione` (per chi legge le segnalazioni di «Scrivimi»),
/// `segnalazione_risposta` (per chi l'ha scritta), `scheda_obiettivi`
/// (per l'atleta: una scheda da compilare), `obiettivi_risposta` (per
/// allenatori e assistenti: un atleta ha risposto) e `obiettivi_ritorno`
/// (per l'atleta: le due righe dell'allenatore).
class Notifica {
  const Notifica({
    required this.id,
    required this.tipo,
    required this.messaggio,
    required this.letta,
    required this.creataIl,
  });

  final String id;
  final String tipo;
  final String messaggio;
  final bool letta;
  final DateTime creataIl;

  factory Notifica.fromMap(Map<String, dynamic> map) => Notifica(
    id: map['id'] as String,
    tipo: map['tipo'] as String,
    messaggio: map['messaggio'] as String,
    letta: map['letta'] as bool,
    creataIl: DateTime.parse(map['created_at'] as String),
  );
}
