/// Un avviso per il coach (FASE 13, punto 1) — oggi solo del tipo
/// "atleta_registrato", creato dalle funzioni di registrazione atleta.
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
