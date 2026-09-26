/// Un avviso in app (e, con le notifiche push, anche sul telefono): tipi
/// `atleta_registrato` (per il coach), `convocazione_gara` e
/// `convocazione_partita` (per l'atleta), `visita_medica` (coach e atleta).
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
