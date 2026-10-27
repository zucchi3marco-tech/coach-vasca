import '../../../core/utils/giorni.dart';
import '../../campionati/domain/campionato_fin.dart';
import '../../referti/domain/referto_letto.dart';
import '../../referti/domain/referto_partita.dart';
import 'evento_partita.dart';
import 'partita.dart';
import 'risultato_partita.dart';
import 'statistiche_eventi.dart';

/// Le sigle che il coach scrive e il sito FIN scrive per intero
/// («PN Monza» è «PALLANUOTO MONZA»).
const _sigle = {
  'pn': 'pallanuoto',
  'nc': 'nuoto club',
  'rn': 'rari nantes',
  'cn': 'circolo nautico',
  'sc': 'sporting club',
  'ss': 'società sportiva',
  'ssd': '',
  'asd': '',
};

/// Le parole che dicono che tipo di società è, non quale: senza di loro
/// «NC Monza» e «Nuoto Monza» sono la stessa squadra, se nel girone non
/// c'è un'altra Monza.
const _paroleGeneriche = {
  'pallanuoto',
  'nuoto',
  'club',
  'circolo',
  'nautico',
  'sporting',
  'società',
  'societa',
  'sportiva',
  'associazione',
  'polisportiva',
  'rari',
  'nantes',
  'an',
  'waterpolo',
};

List<String> _parole(String nome) {
  final pulito = nome
      .toLowerCase()
      .replaceAll(RegExp(r"[.’']"), '')
      .replaceAll(RegExp(r'[-_/,()]'), ' ');
  return [
    for (final p in pulito.split(RegExp(r'\s+')))
      if (p.isNotEmpty)
        for (final q in (_sigle[p] ?? p).split(' '))
          if (q.isNotEmpty) q,
  ];
}

/// Il nome di una squadra senza maiuscole, punti e sigle: «P.N. Monza»,
/// «pn monza» e «PALLANUOTO MONZA» hanno la stessa chiave.
String chiaveSquadra(String nome) => _parole(nome).join(' ');

/// Le parole che distinguono una società da un'altra.
String _distintive(String nome) => [
  for (final p in _parole(nome))
    if (!_paroleGeneriche.contains(p)) p,
].join(' ');

/// I nomi fra [nomi] che sono la stessa squadra di [nome]: prima quelli
/// con la stessa chiave; se non ce ne sono, quelli con le stesse parole
/// distintive, ma solo se sono una squadra sola (con «PN Monza» e
/// «NC Monza» nello stesso girone «Monza» non basta).
List<String> stessaSquadraFra(String nome, Iterable<String> nomi) {
  final chiave = chiaveSquadra(nome);
  if (chiave.isEmpty) return const [];
  final uguali = [
    for (final n in nomi)
      if (chiaveSquadra(n) == chiave) n,
  ];
  if (uguali.isNotEmpty) return uguali;
  final distintive = _distintive(nome);
  if (distintive.isEmpty) return const [];
  final simili = [
    for (final n in nomi)
      if (_distintive(n) == distintive) n,
  ];
  final squadre = {for (final n in simili) chiaveSquadra(n)};
  return squadre.length == 1 ? simili : const [];
}

/// Una partita già giocata contro l'avversario, con il risultato dal
/// referto (quello ufficiale) o, se non c'è, dagli eventi dal vivo.
class Precedente {
  const Precedente({
    required this.partita,
    this.nostri,
    this.loro,
    this.daReferto = false,
  });

  final Partita partita;
  final int? nostri;
  final int? loro;
  final bool daReferto;

  bool get haRisultato => nostri != null && loro != null;

  /// 'V', 'N' o 'P'; null senza risultato.
  String? get esito {
    if (!haRisultato) return null;
    return nostri! > loro!
        ? 'V'
        : nostri == loro
        ? 'N'
        : 'P';
  }

  /// «12-8», prima i nostri gol.
  String? get punteggio => haRisultato ? '$nostri-$loro' : null;
}

/// Un giocatore avversario come lo scrivono i referti.
class GiocatoreAvversario {
  const GiocatoreAvversario({
    required this.nome,
    required this.numero,
    required this.reti,
    required this.espulsioni,
    required this.partite,
  });

  final String nome;

  /// Il numero di calottina dell'ultima partita.
  final int numero;
  final int reti;
  final int espulsioni;
  final int partite;
}

/// Tutto quello che sappiamo di un avversario dalle nostre partite.
class SchedaAvversario {
  const SchedaAvversario({
    required this.nome,
    required this.giocate,
    required this.prossime,
    required this.giocatori,
    required this.dalVivo,
    required this.partiteDalVivo,
    required this.espulsioniPerNumero,
  });

  /// Il nome come lo scriviamo nelle partite (l'ultima), o quello cercato.
  final String nome;

  /// Le partite giocate contro di loro, dalla più recente.
  final List<Precedente> giocate;

  /// Le partite ancora da giocare, dalla più vicina.
  final List<Partita> prossime;

  /// I loro giocatori dai referti: chi segna di più in cima.
  final List<GiocatoreAvversario> giocatori;

  /// I nostri numeri dal vivo contro di loro (i loro tiri sono i nostri
  /// «subiti»).
  final NumeriEventi dalVivo;
  final int partiteDalVivo;

  /// Le loro espulsioni segnate dal vivo, per numero di calottina.
  final Map<int, int> espulsioniPerNumero;

  List<Precedente> get conRisultato => [
    for (final p in giocate)
      if (p.haRisultato) p,
  ];

  int get vinte => conRisultato.where((p) => p.esito == 'V').length;
  int get pari => conRisultato.where((p) => p.esito == 'N').length;
  int get perse => conRisultato.where((p) => p.esito == 'P').length;
  int get golFatti => conRisultato.fold(0, (s, p) => s + p.nostri!);
  int get golSubiti => conRisultato.fold(0, (s, p) => s + p.loro!);

  bool get vuota => giocate.isEmpty && prossime.isEmpty;
}

/// Le partite della squadra [gruppoId] (null: quelle di tutto il club)
/// contro [nome]. Solo la squadra della partita: gli U14 contro la U14
/// di Monza non dicono niente agli U16.
List<Partita> partiteControAvversario({
  required String nome,
  required String? gruppoId,
  required List<Partita> partite,
}) {
  final dellaSquadra = [
    for (final p in partite)
      if (p.gruppoId == gruppoId) p,
  ];
  final nomi = stessaSquadraFra(nome, {
    for (final p in dellaSquadra) p.avversario,
  }).toSet();
  return [
    for (final p in dellaSquadra)
      if (nomi.contains(p.avversario)) p,
  ];
}

/// La scheda dalle partite contro l'avversario ([partite], già scelte con
/// [partiteControAvversario]), con i loro referti ed eventi dal vivo.
/// Giocata: prima di oggi, o oggi con un risultato.
SchedaAvversario schedaAvversario({
  required String nome,
  required List<Partita> partite,
  required List<RefertoPartita> referti,
  required List<EventoPartita> eventi,
  required DateTime oggi,
}) {
  final giorno = soloData(oggi);
  final refertoPer = {for (final r in referti) r.partitaId: r};
  final eventiPer = <String, List<EventoPartita>>{};
  for (final e in eventi) {
    eventiPer.putIfAbsent(e.partitaId, () => []).add(e);
  }

  final giocate = <Precedente>[];
  final prossime = <Partita>[];
  for (final p in partite) {
    final referto = refertoPer[p.id];
    Precedente precedente;
    if (referto != null) {
      precedente = Precedente(
        partita: p,
        nostri: p.inCasa ? referto.risultatoCasa : referto.risultatoTrasferta,
        loro: p.inCasa ? referto.risultatoTrasferta : referto.risultatoCasa,
        daReferto: true,
      );
    } else {
      final r = risultatoPartita(eventiPer[p.id] ?? const [], p);
      precedente = r == null
          ? Precedente(partita: p)
          : Precedente(
              partita: p,
              nostri: p.inCasa ? r.golCasa : r.golTrasferta,
              loro: p.inCasa ? r.golTrasferta : r.golCasa,
            );
    }
    final dopo = soloData(p.data).isAfter(giorno);
    final oggiStesso = soloData(p.data) == giorno;
    if (dopo || (oggiStesso && !precedente.haRisultato)) {
      prossime.add(p);
    } else {
      giocate.add(precedente);
    }
  }
  giocate.sort((a, b) => b.partita.data.compareTo(a.partita.data));
  prossime.sort((a, b) => a.data.compareTo(b.data));

  // I loro giocatori: dal referto più recente al più vecchio, così il
  // numero e il nome scritti sono quelli dell'ultima volta.
  final perNome = <String, GiocatoreAvversario>{};
  for (final g in giocate) {
    final referto = refertoPer[g.partita.id];
    if (referto == null) continue;
    final loro = g.partita.inCasa
        ? referto.giocatoriTrasferta
        : referto.giocatoriCasa;
    for (final GiocatoreReferto gr in loro) {
      final nome = gr.nome.trim();
      final chiave = nome.isEmpty
          ? '#${gr.numeroCalottina}'
          : nome.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final prima = perNome[chiave];
      perNome[chiave] = GiocatoreAvversario(
        nome: prima?.nome ?? nome,
        numero: prima?.numero ?? gr.numeroCalottina,
        reti: (prima?.reti ?? 0) + gr.reti,
        espulsioni: (prima?.espulsioni ?? 0) + gr.espulsioni,
        partite: (prima?.partite ?? 0) + 1,
      );
    }
  }
  final giocatori =
      [
        for (final g in perNome.values)
          if (g.reti > 0 || g.espulsioni > 0) g,
      ]..sort((a, b) {
        final reti = b.reti.compareTo(a.reti);
        if (reti != 0) return reti;
        final esp = b.espulsioni.compareTo(a.espulsioni);
        if (esp != 0) return esp;
        return a.numero.compareTo(b.numero);
      });

  final idGiocate = {for (final g in giocate) g.partita.id};
  final eventiGiocate = [
    for (final e in eventi)
      if (idGiocate.contains(e.partitaId)) e,
  ];
  final stat = StatisticheEventi.da(eventiGiocate);
  final espulsioni = <int, int>{};
  for (final e in eventiGiocate) {
    final numero = e.numeroCalottinaAvversario;
    if (e.tipo != 'espulsione' || e.squadra == 'nostra' || numero == null) {
      continue;
    }
    espulsioni[numero] = (espulsioni[numero] ?? 0) + 1;
  }

  final ultima = giocate.firstOrNull?.partita ?? prossime.firstOrNull;
  return SchedaAvversario(
    nome: ultima?.avversario ?? nome,
    giocate: giocate,
    prossime: prossime,
    giocatori: giocatori,
    dalVivo: stat.squadra,
    partiteDalVivo: stat.partite,
    espulsioniPerNumero: espulsioni,
  );
}

/// Gli avversari di una squadra, uno per società anche se il nome è
/// scritto in modi diversi: il nome dell'ultima partita, quante partite,
/// la prossima. [gruppoId] è la squadra delle partite (null: di tutto il
/// club), la scheda si apre con quella.
typedef AvversarioInElenco = ({
  String nome,
  String? gruppoId,
  int partite,
  DateTime? prossima,
  DateTime ultima,
});

/// Con [gruppoId] le partite di quella squadra e quelle di tutto il club
/// (come nell'elenco delle partite); null: tutte. Un avversario
/// incontrato da due squadre compare due volte, una per squadra.
List<AvversarioInElenco> avversariDellaSquadra({
  required String? gruppoId,
  required List<Partita> partite,
  required DateTime oggi,
}) {
  final giorno = soloData(oggi);
  final perChiave = <(String?, String), List<Partita>>{};
  for (final p in partite) {
    if (gruppoId != null && p.gruppoId != null && p.gruppoId != gruppoId) {
      continue;
    }
    final chiave = chiaveSquadra(p.avversario);
    if (chiave.isEmpty) continue;
    perChiave.putIfAbsent((p.gruppoId, chiave), () => []).add(p);
  }
  final elenco = <AvversarioInElenco>[];
  for (final MapEntry(:key, value: lista) in perChiave.entries) {
    lista.sort((a, b) => b.data.compareTo(a.data));
    final future = [
      for (final p in lista)
        if (!soloData(p.data).isBefore(giorno)) p.data,
    ]..sort();
    elenco.add((
      nome: lista.first.avversario,
      gruppoId: key.$1,
      partite: lista.length,
      prossima: future.firstOrNull,
      ultima: lista.first.data,
    ));
  }
  // Prima chi si incontra presto, poi gli altri per nome.
  elenco.sort((a, b) {
    if (a.prossima != null && b.prossima != null) {
      return a.prossima!.compareTo(b.prossima!);
    }
    if (a.prossima != null) return -1;
    if (b.prossima != null) return 1;
    return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
  });
  return elenco;
}

/// L'avversario nel girone FIN collegato alla squadra: la sua riga di
/// classifica, gli ultimi risultati e la prossima partita.
class AvversarioNelGirone {
  const AvversarioNelGirone({
    required this.nomeFin,
    required this.riga,
    required this.squadre,
    required this.ultimi,
    required this.prossimo,
  });

  /// Il nome come lo scrive il sito («PALLANUOTO MONZA»).
  final String nomeFin;
  final RigaClassificaFin? riga;

  /// Quante squadre ci sono in classifica.
  final int squadre;

  /// Gli incontri già giocati, dal più recente (al massimo 5).
  final List<IncontroFin> ultimi;
  final IncontroFin? prossimo;

  bool _inCasa(IncontroFin i) => stessaSquadra(i.casa, nomeFin);

  /// Esito di un incontro giocato per l'avversario: 'V', 'N' o 'P'.
  String esitoDi(IncontroFin i) {
    final loro = _inCasa(i) ? i.golCasa! : i.golOspite!;
    final altri = _inCasa(i) ? i.golOspite! : i.golCasa!;
    return loro > altri
        ? 'V'
        : loro == altri
        ? 'N'
        : 'P';
  }

  /// L'altra squadra dell'incontro.
  String controChi(IncontroFin i) => _inCasa(i) ? i.ospite : i.casa;

  /// «14-7», prima i gol dell'avversario.
  String punteggioDi(IncontroFin i) => _inCasa(i)
      ? '${i.golCasa}-${i.golOspite}'
      : '${i.golOspite}-${i.golCasa}';
}

/// [nome] nel girone, fra le squadre che non sono la nostra ([nostra],
/// il nome FIN della squadra del club). Null se non c'è o se il nome
/// può essere più di una squadra.
AvversarioNelGirone? avversarioNelGirone(
  GironeFin girone, {
  required String nome,
  required String nostra,
}) {
  final candidati = stessaSquadraFra(nome, [
    for (final s in girone.squadre)
      if (!stessaSquadra(s, nostra)) s,
  ]);
  if (candidati.isEmpty) return null;
  final nomeFin = candidati.first;
  final giocati = [
    for (final i in girone.incontriDi(nomeFin))
      if (i.giocato && !i.riposo) i,
  ];
  return AvversarioNelGirone(
    nomeFin: nomeFin,
    riga: girone.rigaDi(nomeFin),
    squadre: girone.classifica.length,
    ultimi: giocati.reversed.take(5).toList(),
    prossimo: girone.prossimoDi(nomeFin),
  );
}
