import '../../../core/utils/giorni.dart';
import '../../../core/utils/gruppo_visibilita.dart';

/// I tipi di impegno (proposta 18, scelta del coach: anche torneo e altro).
enum TipoImpegno {
  collegiale('Collegiale'),
  trasferta('Trasferta'),
  riposo('Riposo'),
  torneo('Torneo'),
  altro('Altro');

  const TipoImpegno(this.etichetta);

  final String etichetta;

  static TipoImpegno daValore(String valore) => TipoImpegno.values.firstWhere(
    (t) => t.name == valore,
    orElse: () => TipoImpegno.altro,
  );
}

/// Quello che non è un allenamento, una partita o una gara ma occupa dei
/// giorni: un collegiale, una trasferta, un riposo (anche piscina chiusa o
/// vacanze), un torneo, altro. Dal giorno [dal] al giorno [al] compresi,
/// anche uno solo. [gruppoId] nullo = di tutto il club.
class Impegno {
  const Impegno({
    required this.id,
    required this.clubId,
    required this.tipo,
    required this.dal,
    required this.al,
    this.gruppoId,
    this.nome,
    this.luogo,
    this.note,
  });

  final String id;
  final String clubId;
  final String? gruppoId;
  final TipoImpegno tipo;
  final DateTime dal;
  final DateTime al;

  /// Facoltativo, tranne per «Altro» («Collegiale a Lignano», «Vacanze
  /// di Natale»).
  final String? nome;
  final String? luogo;
  final String? note;

  bool get diClub => gruppoId == null;

  /// Il nome, o il tipo quando il nome non c'è.
  String get titolo {
    final n = nome?.trim() ?? '';
    return n.isEmpty ? tipo.etichetta : n;
  }

  /// Quanti giorni dura (almeno uno).
  int get giorni => giorniTra(soloData(dal), soloData(al)) + 1;

  /// I giorni dell'impegno, dal primo all'ultimo.
  List<DateTime> get elencoGiorni => [
    for (var i = 0; i < giorni; i++) aggiungiGiorni(soloData(dal), i),
  ];

  bool contiene(DateTime giorno) {
    final g = soloData(giorno);
    return !g.isBefore(soloData(dal)) && !g.isAfter(soloData(al));
  }

  factory Impegno.fromMap(Map<String, dynamic> map) => Impegno(
    id: map['id'] as String,
    clubId: map['club_id'] as String,
    gruppoId: map['gruppo_id'] as String?,
    tipo: TipoImpegno.daValore(map['tipo'] as String),
    dal: DateTime.parse(map['dal'] as String),
    al: DateTime.parse(map['al'] as String),
    nome: map['nome'] as String?,
    luogo: map['luogo'] as String?,
    note: map['note'] as String?,
  );
}

/// Gli impegni visibili alla squadra [gruppoId] (i suoi e quelli di club;
/// null = tutti) che toccano il [giorno].
List<Impegno> impegniDelGiorno(
  Iterable<Impegno> impegni,
  DateTime giorno, {
  required String? gruppoId,
}) => [
  for (final i in impegni)
    if (i.contiene(giorno) &&
        visibileNelGruppo(
          gruppoDelRecord: i.gruppoId,
          gruppoSelezionato: gruppoId,
        ))
      i,
];

/// Il riposo che vale per un allenamento della squadra [gruppoId] il
/// [giorno]: uno della squadra o di tutto il club. Un allenamento di club
/// ([gruppoId] null) guarda solo i riposi di club, perché quelli di una
/// squadra non fermano le altre.
Impegno? riposoNelGiorno(
  Iterable<Impegno> impegni,
  DateTime giorno, {
  required String? gruppoId,
}) {
  for (final i in impegni) {
    if (i.tipo != TipoImpegno.riposo || !i.contiene(giorno)) continue;
    if (i.gruppoId == null || i.gruppoId == gruppoId) return i;
  }
  return null;
}

/// «sab 31 ott» per un giorno, «sab 31 ott – lun 2 nov» per più giorni.
String periodoImpegno(Impegno impegno, String Function(DateTime) data) =>
    impegno.giorni == 1
    ? data(impegno.dal)
    : '${data(impegno.dal)} – ${data(impegno.al)}';
