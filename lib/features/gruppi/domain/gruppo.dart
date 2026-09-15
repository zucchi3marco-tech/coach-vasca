class Gruppo {
  const Gruppo({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.ordine,
    this.sport,
  });

  final String id;
  final String clubId;
  final String nome;
  final int ordine;

  /// 'nuoto' | 'pallanuoto' | null (club "nuoto e pallanuoto", o gruppo
  /// creato prima di questo campo): quando e' valorizzato, la
  /// registrazione via codice di gruppo non chiede piu' lo sport.
  final String? sport;
}
