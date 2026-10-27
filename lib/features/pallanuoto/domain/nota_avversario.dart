import 'scheda_avversario.dart';

/// Un giocatore avversario da tenere d'occhio: numero (se si sa), nome e
/// cosa fa.
class GiocatoreDaNotare {
  const GiocatoreDaNotare({this.numero, required this.nome, this.nota = ''});

  final int? numero;
  final String nome;
  final String nota;

  bool get vuoto =>
      numero == null && nome.trim().isEmpty && nota.trim().isEmpty;

  Map<String, dynamic> toMap() => {
    'numero': numero,
    'nome': nome.trim(),
    'nota': nota.trim(),
  };

  factory GiocatoreDaNotare.fromMap(Map<String, dynamic> m) =>
      GiocatoreDaNotare(
        numero: (m['numero'] as num?)?.toInt(),
        nome: m['nome'] as String? ?? '',
        nota: m['nota'] as String? ?? '',
      );
}

/// Le note dello staff su un avversario di una squadra (tabella
/// `note_avversari`): le vede tutta la squadra.
class NotaAvversario {
  const NotaAvversario({
    required this.id,
    required this.clubId,
    required this.gruppoId,
    required this.chiave,
    required this.nome,
    this.nomeFin,
    this.nota = '',
    this.giocatori = const [],
    this.aggiornataIl,
  });

  final String? id;
  final String clubId;
  final String? gruppoId;
  final String chiave;

  /// Il nome come lo scriviamo noi.
  final String nome;

  /// Il nome scelto a mano fra le squadre del girone FIN.
  final String? nomeFin;
  final String nota;
  final List<GiocatoreDaNotare> giocatori;
  final DateTime? aggiornataIl;

  /// Niente da far vedere: né nota né giocatori (il nome FIN da solo
  /// non è una nota).
  bool get senzaNote => nota.trim().isEmpty && giocatori.every((g) => g.vuoto);

  static const limiteNota = 2000;
  static const limiteGiocatori = 30;
  static const limiteNomeGiocatore = 80;
  static const limiteNotaGiocatore = 300;

  NotaAvversario copiaCon({
    String? nomeFin,
    bool togliNomeFin = false,
    String? nota,
    List<GiocatoreDaNotare>? giocatori,
  }) => NotaAvversario(
    id: id,
    clubId: clubId,
    gruppoId: gruppoId,
    chiave: chiave,
    nome: nome,
    nomeFin: togliNomeFin ? null : (nomeFin ?? this.nomeFin),
    nota: nota ?? this.nota,
    giocatori: giocatori ?? this.giocatori,
    aggiornataIl: aggiornataIl,
  );

  /// Per il database: le righe vuote dei giocatori non si salvano.
  Map<String, dynamic> toMap() => {
    'club_id': clubId,
    'gruppo_id': gruppoId,
    'chiave': chiave,
    'nome': nome.trim(),
    'nome_fin': nomeFin,
    'nota': nota.trim().isEmpty ? null : nota.trim(),
    'giocatori': [
      for (final g in giocatori)
        if (!g.vuoto) g.toMap(),
    ],
  };

  factory NotaAvversario.fromMap(Map<String, dynamic> m) => NotaAvversario(
    id: m['id'] as String?,
    clubId: m['club_id'] as String,
    gruppoId: m['gruppo_id'] as String?,
    chiave: m['chiave'] as String,
    nome: m['nome'] as String,
    nomeFin: m['nome_fin'] as String?,
    nota: m['nota'] as String? ?? '',
    giocatori: [
      for (final g in (m['giocatori'] as List?) ?? const [])
        GiocatoreDaNotare.fromMap(Map<String, dynamic>.from(g as Map)),
    ],
    aggiornataIl: m['updated_at'] == null
        ? null
        : DateTime.tryParse(m['updated_at'] as String)?.toLocal(),
  );

  /// Una nota nuova, ancora da salvare, per l'avversario [nome].
  factory NotaAvversario.nuova({
    required String clubId,
    required String? gruppoId,
    required String nome,
  }) => NotaAvversario(
    id: null,
    clubId: clubId,
    gruppoId: gruppoId,
    chiave: chiaveSquadra(nome),
    nome: nome.trim(),
  );
}

/// La nota di [nomi] (il nome della scheda e quello con cui si è
/// aperta) fra quelle della squadra: con lo stesso nome, o con il nome
/// FIN scelto a mano.
NotaAvversario? notaPer(List<NotaAvversario> note, List<String> nomi) {
  for (final nome in nomi) {
    final chiave = chiaveSquadra(nome);
    for (final n in note) {
      if (n.chiave == chiave) return n;
    }
  }
  for (final nome in nomi) {
    for (final n in note) {
      final fin = n.nomeFin;
      if (fin != null && chiaveSquadra(fin) == chiaveSquadra(nome)) return n;
    }
  }
  for (final nome in nomi) {
    final simili = stessaSquadraFra(nome, [for (final n in note) n.nome]);
    if (simili.isNotEmpty) {
      return note.firstWhere((n) => n.nome == simili.first);
    }
  }
  return null;
}
