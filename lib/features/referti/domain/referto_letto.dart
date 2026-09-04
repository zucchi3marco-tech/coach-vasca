class GiocatoreReferto {
  const GiocatoreReferto({
    required this.numeroCalottina,
    required this.nome,
    required this.reti,
    required this.espulsioni,
    this.atletaId,
  });

  final int numeroCalottina;
  final String nome;
  final int reti;
  final int espulsioni;

  /// Collegato a un Atleta solo per i giocatori della nostra squadra
  /// (scelto a mano dopo la lettura AI, mai dedotto): serve per le
  /// statistiche stagionali per singolo atleta. Null se non ancora
  /// collegato o se e' un giocatore avversario.
  final String? atletaId;

  factory GiocatoreReferto.fromMap(Map<String, dynamic> map) {
    return GiocatoreReferto(
      numeroCalottina: map['numeroCalottina'] as int,
      nome: map['nome'] as String,
      reti: map['reti'] as int,
      espulsioni: map['espulsioni'] as int,
      atletaId: map['atletaId'] as String?,
    );
  }
}

class ParzialeReferto {
  const ParzialeReferto({required this.casa, required this.trasferta});

  final int casa;
  final int trasferta;

  factory ParzialeReferto.fromMap(Map<String, dynamic> map) {
    return ParzialeReferto(
      casa: map['casa'] as int,
      trasferta: map['trasferta'] as int,
    );
  }
}

class RefertoLetto {
  const RefertoLetto({
    required this.squadraCasa,
    required this.squadraTrasferta,
    required this.risultatoCasa,
    required this.risultatoTrasferta,
    required this.parziali,
    required this.giocatoriCasa,
    required this.giocatoriTrasferta,
  });

  final String squadraCasa;
  final String squadraTrasferta;
  final int risultatoCasa;
  final int risultatoTrasferta;
  final List<ParzialeReferto> parziali;
  final List<GiocatoreReferto> giocatoriCasa;
  final List<GiocatoreReferto> giocatoriTrasferta;

  factory RefertoLetto.fromMap(Map<String, dynamic> map) {
    return RefertoLetto(
      squadraCasa: map['squadraCasa'] as String,
      squadraTrasferta: map['squadraTrasferta'] as String,
      risultatoCasa: map['risultatoCasa'] as int,
      risultatoTrasferta: map['risultatoTrasferta'] as int,
      parziali: (map['parziali'] as List)
          .map((p) => ParzialeReferto.fromMap(p as Map<String, dynamic>))
          .toList(),
      giocatoriCasa: (map['giocatoriCasa'] as List)
          .map((g) => GiocatoreReferto.fromMap(g as Map<String, dynamic>))
          .toList(),
      giocatoriTrasferta: (map['giocatoriTrasferta'] as List)
          .map((g) => GiocatoreReferto.fromMap(g as Map<String, dynamic>))
          .toList(),
    );
  }
}
