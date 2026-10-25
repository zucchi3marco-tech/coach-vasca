import 'dart:convert';

class DistintaGiocatore {
  const DistintaGiocatore({
    required this.id,
    required this.partitaId,
    required this.atletaId,
    required this.clubId,
    required this.numeroCalottina,
    required this.capitano,
    required this.viceCapitano,
    required this.portiere,
    required this.fuoriquota,
    this.tempiInPorta = const [],
  });

  final String id;
  final String partitaId;
  final String atletaId;
  final String clubId;
  final int numeroCalottina;
  final bool capitano;
  final bool viceCapitano;
  final bool portiere;
  final bool fuoriquota;

  /// I tempi (1-4, oltre per i supplementari) in cui è stato in porta,
  /// in ordine. Dal vivo si aggiornano da soli; con il solo referto li
  /// indica l'allenatore.
  final List<int> tempiInPorta;

  factory DistintaGiocatore.fromMap(Map<String, dynamic> map) {
    return DistintaGiocatore(
      id: map['id'] as String,
      partitaId: map['partita_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      numeroCalottina: map['numero_calottina'] as int,
      capitano: map['capitano'] as bool,
      viceCapitano: map['vice_capitano'] as bool,
      portiere: map['portiere'] as bool,
      fuoriquota: map['fuoriquota'] as bool,
      tempiInPorta: tempiDaLista(map['tempi_in_porta']),
    );
  }
}

/// Da quello che arriva dal server (lista di numeri) o dalla cache
/// locale (testo JSON) a una lista ordinata senza doppioni.
List<int> tempiDaLista(Object? valore) {
  final Object? lista = valore is String && valore.isNotEmpty
      ? jsonDecode(valore)
      : valore;
  if (lista is! List) return const [];
  return {for (final v in lista) (v as num).toInt()}.toList()..sort();
}
