/// Il ruolo di chi lavora nel club. Nel database `ruolo_club`: 'owner',
/// 'coach', 'assistente'.
enum RuoloClub {
  /// Chi ha creato il club (nel database 'owner').
  responsabile,
  allenatore,
  assistente;

  /// Il valore nel database.
  String get db => switch (this) {
    RuoloClub.responsabile => 'owner',
    RuoloClub.allenatore => 'coach',
    RuoloClub.assistente => 'assistente',
  };

  static RuoloClub fromDb(String valore) => switch (valore) {
    'owner' => RuoloClub.responsabile,
    'coach' => RuoloClub.allenatore,
    'assistente' => RuoloClub.assistente,
    _ => throw ArgumentError.value(valore, 'valore', 'Ruolo del club ignoto'),
  };

  String get etichetta => switch (this) {
    RuoloClub.responsabile => 'Responsabile',
    RuoloClub.allenatore => 'Allenatore',
    RuoloClub.assistente => 'Assistente',
  };

  String get descrizione => switch (this) {
    RuoloClub.responsabile =>
      'Invita e toglie allenatori e assistenti, e fa tutto il resto.',
    RuoloClub.allenatore => 'Fa tutto: allenamenti, atleti, squadre, partite.',
    RuoloClub.assistente =>
      'Allenamenti, presenze, partite e test; non aggiunge o toglie atleti e '
          'squadre.',
  };

  /// Aggiungere e togliere atleti e squadre, e dare ai ragazzi i codici per
  /// entrare: non lo fa un assistente.
  bool get puoGestireAtletiESquadre => this != RuoloClub.assistente;

  /// Invitare e togliere allenatori e assistenti, cambiare i loro ruoli.
  bool get puoGestireStaff => this == RuoloClub.responsabile;
}

/// Una persona che lavora nel club, come la elenca `membri_del_club`.
class MembroClub {
  const MembroClub({
    required this.userId,
    required this.ruolo,
    required this.sonoIo,
    this.nome,
    this.email,
  });

  final String userId;

  /// Null per chi non l'ha ancora scritto.
  final String? nome;
  final RuoloClub ruolo;

  /// L'email la vede solo il responsabile.
  final String? email;
  final bool sonoIo;

  factory MembroClub.fromMap(Map<String, dynamic> map) {
    final nome = (map['nome'] as String?)?.trim();
    return MembroClub(
      userId: map['user_id'] as String,
      nome: (nome == null || nome.isEmpty) ? null : nome,
      ruolo: RuoloClub.fromDb(map['ruolo'] as String),
      email: map['email'] as String?,
      sonoIo: map['sono_io'] as bool? ?? false,
    );
  }
}

/// Di che club è un codice per allenatori e con che ruolo si entra.
class InvitoStaff {
  const InvitoStaff({required this.clubNome, required this.ruolo});

  final String clubNome;
  final RuoloClub ruolo;
}
