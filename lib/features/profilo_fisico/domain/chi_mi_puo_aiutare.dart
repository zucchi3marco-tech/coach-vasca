import 'specialista.dart';

/// I problemi di «Chi mi può aiutare?» (profilo fisico, passo C), con lo
/// specialista del club a cui portano. È solo un indirizzo, mai una
/// diagnosi.
enum ProblemaFisico {
  dolore(
    'Dolore a spalla, schiena o ginocchio',
    TipoSpecialista.fisioterapista,
  ),
  rigidita('Rigidità o postura', TipoSpecialista.osteopata),
  gambe('Gambe pesanti o muscoli contratti', TipoSpecialista.massoterapista),
  energia(
    'Energia, alimentazione, peso per lo sport',
    TipoSpecialista.nutrizionista,
  ),

  /// Solo «senti il medico»: nessuno specialista.
  forte('Dolore forte, che non passa o con febbre', null),

  /// Tutti gli specialisti del club, e «parlane con il tuo allenatore».
  nonLoSo('Non lo so, o è un\'altra cosa', null);

  const ProblemaFisico(this.etichetta, this.tipo);

  final String etichetta;

  /// Lo specialista a cui porta; null per [forte] e [nonLoSo].
  final TipoSpecialista? tipo;

  bool get soloMedico => this == forte;

  /// Come si scrive nella traccia dei contatti (`contatti_specialisti`).
  String get codice => this == nonLoSo ? 'non_lo_so' : name;

  static ProblemaFisico? daCodice(String codice) {
    for (final p in values) {
      if (p.codice == codice) return p;
    }
    return null;
  }

  /// Gli specialisti del club per questo problema: quelli del suo tipo,
  /// tutti per [nonLoSo], nessuno per [forte].
  List<Specialista> specialisti(Iterable<Specialista> delClub) =>
      switch (this) {
        forte => const [],
        nonLoSo => ordinaSpecialisti(delClub),
        _ => ordinaSpecialisti(delClub.where((s) => s.tipo == tipo)),
      };
}

/// Il messaggio WhatsApp già scritto: chi è, di che club, per cosa e il
/// suo codice (la prova per la royalty, se c'è). L'atleta lo può
/// cambiare in WhatsApp prima di mandarlo.
String messaggioSpecialista({
  required String nomeAtleta,
  required String? nomeClub,
  required ProblemaFisico problema,
  String? codice,
}) {
  final club = nomeClub == null || nomeClub.trim().isEmpty
      ? 'atleta di pallanuoto'
      : 'atleta del club ${nomeClub.trim()}';
  final richiesta = problema.tipo == null
      ? 'vorrei qualche informazione.'
      : 'vorrei un appuntamento per: ${problema.etichetta.toLowerCase()}.';
  return 'Buongiorno, sono ${nomeAtleta.trim()}, $club. Ho trovato il '
      'vostro contatto su WaterTactics e $richiesta'
      '${codice == null ? '' : ' Il mio codice WaterTactics è $codice.'}';
}

/// Le lettere dei codici: senza quelle che si confondono (0 e O, 1 e I,
/// 2 e Z, 5 e S, 8 e B). Le stesse della funzione del database.
const _lettereCodice = 'ACDEFGHJKLMNPQRTUVWXY34679';

/// Un codice come quelli del database, «WT-4K7Q»: solo per la demo, che
/// non ha un server.
String codiceCasuale(int Function(int max) caso) =>
    'WT-${List.generate(4, (_) => _lettereCodice[caso(_lettereCodice.length)]).join()}';

/// Da dove l'atleta ha contattato lo specialista.
enum CanaleContatto {
  whatsapp('WhatsApp'),
  sito('il sito');

  const CanaleContatto(this.etichetta);

  final String etichetta;

  static CanaleContatto? daNome(String nome) {
    for (final c in values) {
      if (c.name == nome) return c;
    }
    return null;
  }
}

/// Un contatto con uno specialista (tabella `contatti_specialisti`): lo
/// segna l'app quando l'atleta tocca «Scrivi su WhatsApp» o «Apri il
/// sito». Lo legge solo il responsabile, che spunta le visite confermate.
class ContattoSpecialista {
  const ContattoSpecialista({
    required this.id,
    required this.clubId,
    required this.atletaId,
    required this.nomeAtleta,
    required this.specialistaNome,
    required this.tipo,
    required this.problema,
    required this.canale,
    required this.codice,
    required this.giorno,
    this.specialistaId,
    this.confermataIl,
  });

  /// null se tipo, problema o canale non sono fra quelli conosciuti.
  static ContattoSpecialista? fromMap(Map<String, dynamic> m) {
    final tipo = TipoSpecialista.daNome(m['specialista_tipo'] as String? ?? '');
    final problema = ProblemaFisico.daCodice(m['problema'] as String? ?? '');
    final canale = CanaleContatto.daNome(m['canale'] as String? ?? '');
    if (tipo == null || problema == null || canale == null) return null;
    final atleta = m['atleti'];
    final nome = atleta is Map
        ? '${atleta['nome'] ?? ''} ${atleta['cognome'] ?? ''}'.trim()
        : (m['atleta_nome'] as String? ?? '');
    return ContattoSpecialista(
      id: m['id'] as String,
      clubId: m['club_id'] as String,
      atletaId: m['atleta_id'] as String,
      nomeAtleta: nome.isEmpty ? 'Atleta non più nel club' : nome,
      specialistaId: m['specialista_id'] as String?,
      specialistaNome: m['specialista_nome'] as String,
      tipo: tipo,
      problema: problema,
      canale: canale,
      codice: m['codice'] as String,
      giorno: DateTime.parse(m['giorno'] as String),
      confermataIl: m['visita_confermata_il'] == null
          ? null
          : DateTime.parse(m['visita_confermata_il'] as String),
    );
  }

  final String id;
  final String clubId;
  final String atletaId;

  /// «Sofia Rossi».
  final String nomeAtleta;
  final String? specialistaId;
  final String specialistaNome;
  final TipoSpecialista tipo;
  final ProblemaFisico problema;
  final CanaleContatto canale;
  final String codice;
  final DateTime giorno;
  final DateTime? confermataIl;

  bool get confermata => confermataIl != null;

  ContattoSpecialista conConferma(DateTime? il) => ContattoSpecialista(
    id: id,
    clubId: clubId,
    atletaId: atletaId,
    nomeAtleta: nomeAtleta,
    specialistaId: specialistaId,
    specialistaNome: specialistaNome,
    tipo: tipo,
    problema: problema,
    canale: canale,
    codice: codice,
    giorno: giorno,
    confermataIl: il,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'club_id': clubId,
    'atleta_id': atletaId,
    'atleta_nome': nomeAtleta,
    'specialista_id': specialistaId,
    'specialista_nome': specialistaNome,
    'specialista_tipo': tipo.name,
    'problema': problema.codice,
    'canale': canale.name,
    'codice': codice,
    'giorno': _giorno(giorno),
    'visita_confermata_il': confermataIl == null
        ? null
        : _giorno(confermataIl!),
  };
}

String _giorno(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Il totale di uno specialista in un mese.
typedef TotaleSpecialista = ({String nome, int contatti, int confermate});

/// I contatti di un mese, dal giorno più recente, con il totale di ogni
/// specialista (dal più contattato).
typedef MeseContatti = ({
  DateTime mese,
  List<ContattoSpecialista> contatti,
  List<TotaleSpecialista> totali,
});

/// I contatti divisi per mese, dal più recente.
List<MeseContatti> contattiPerMese(Iterable<ContattoSpecialista> elenco) {
  final perMese = <DateTime, List<ContattoSpecialista>>{};
  for (final c in elenco) {
    perMese
        .putIfAbsent(DateTime(c.giorno.year, c.giorno.month), () => [])
        .add(c);
  }
  final mesi = perMese.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final mese in mesi)
      () {
        final contatti = perMese[mese]!
          ..sort((a, b) {
            final g = b.giorno.compareTo(a.giorno);
            return g != 0 ? g : a.nomeAtleta.compareTo(b.nomeAtleta);
          });
        final perSpecialista = <String, List<ContattoSpecialista>>{};
        for (final c in contatti) {
          perSpecialista.putIfAbsent(c.specialistaNome, () => []).add(c);
        }
        final totali =
            [
              for (final e in perSpecialista.entries)
                (
                  nome: e.key,
                  contatti: e.value.length,
                  confermate: e.value.where((c) => c.confermata).length,
                ),
            ]..sort((a, b) {
              final n = b.contatti.compareTo(a.contatti);
              return n != 0 ? n : a.nome.compareTo(b.nome);
            });
        return (mese: mese, contatti: contatti, totali: totali);
      }(),
  ];
}

/// Il collegamento che apre WhatsApp sulla chat con [numero]
/// («+393331234567») e il [testo] già scritto.
String collegamentoWhatsapp(String numero, String testo) =>
    'https://wa.me/${numero.replaceFirst('+', '')}'
    '?text=${Uri.encodeComponent(testo)}';
