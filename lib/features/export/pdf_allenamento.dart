import '../../core/utils/pace_format.dart';
import '../allenamenti/domain/durata_serie.dart';
import '../allenamenti/domain/riordino_serie.dart';
import '../allenamenti/domain/serie.dart';
import '../allenamenti/domain/testo_allenamento.dart';
import '../allenamenti/domain/volume_allenamento.dart';
import '../allenamenti/presentation/serie_labels.dart';
import 'csv_export.dart' show piramideSuUnaRiga, testoPerChi;

/// Il modello del PDF di un allenamento, senza tipi di `pdf`: le serie
/// diventano sezioni (un blocco l'una) con righe già scritte come si
/// leggono sulla carta. Così si prova a parte (`test/export/`) e il
/// disegno ([generaPdf]) resta solo impaginazione.

/// Un elemento di una sezione, o di una colonna in parallelo. [livello]
/// è quanto è rientrato (dentro un "3x").
sealed class ElementoPdf {
  const ElementoPdf(this.livello);

  final int livello;
}

/// Una serie (o una piramide, scritta su una riga sola), con le celle già
/// in testo; vuoto dove non c'è niente da dire.
class RigaPdf extends ElementoPdf {
  const RigaPdf({
    required this.volume,
    this.lavoro = '',
    this.zona = '',
    this.partenza = '',
    this.attrezzi = '',
    this.note = '',
    int livello = 0,
  }) : super(livello);

  /// "6×100", "200", "10'", "3×5'", "50-100-200-100-50": sempre su una riga.
  final String volume;

  /// "Libero", "Dorso gambe", "Palleggio", "Tecnico-tattico".
  final String lavoro;
  final String zona;

  /// "@2:00 r15'' passo 1:25".
  final String partenza;
  final String attrezzi;

  /// Le note della serie, con davanti per chi è se non è di tutti
  /// ("Solo portieri").
  final String note;
}

/// Il recupero dopo una serie, prima della successiva: "Recupero 2'".
class RecuperoPdf extends ElementoPdf {
  const RecuperoPdf(this.testo, {int livello = 0}) : super(livello);

  final String testo;
}

/// L'inizio di un gruppo da ripetere: le righe che seguono, rientrate di
/// un livello, si fanno [volte] volte, una sola riga invece delle copie.
class RipetiPdf extends ElementoPdf {
  const RipetiPdf(this.volte, {int livello = 0}) : super(livello);

  final int volte;

  String get testo => '$volte×';
}

/// Una colonna di un momento in parallelo.
class ColonnaPdf {
  const ColonnaPdf({
    required this.titolo,
    required this.minuti,
    required this.elementi,
  });

  /// "Tutti", "Portieri", "Rossi, Bianchi".
  final String titolo;

  /// La durata stimata della colonna; 0 se non c'è niente da stimare.
  final int minuti;
  final List<ElementoPdf> elementi;
}

/// Lavoro fatto nello stesso tempo da persone diverse, affiancato.
class ParallelaPdf extends ElementoPdf {
  const ParallelaPdf(this.colonne, {int livello = 0}) : super(livello);

  final List<ColonnaPdf> colonne;
}

/// Un blocco dell'allenamento con le sue righe.
class SezionePdf {
  const SezionePdf({
    required this.blocco,
    required this.titolo,
    required this.metri,
    required this.secondiATempo,
    required this.elementi,
  });

  final String blocco;

  /// "Riscaldamento", "Principale"…
  final String titolo;

  /// I metri del gruppo (un giocatore di movimento) nel blocco.
  final int metri;

  /// Il lavoro a tempo del gruppo nel blocco, in secondi: un minuto non
  /// diventa metri.
  final int secondiATempo;
  final List<ElementoPdf> elementi;

  /// "1.200 m", "40'", "1.200 m + 40'": per la destra del titolo; vuoto
  /// se il blocco non ha né metri né lavoro a tempo.
  String get riepilogo => [
    if (metri > 0) formattaMetri(metri),
    if (secondiATempo > 0) formattaTempoLavoro(secondiATempo),
  ].join(' + ');
}

/// "4300" -> "4.300 m".
String formattaMetri(int metri) {
  final cifre = metri.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < cifre.length; i++) {
    if (i > 0 && (cifre.length - i) % 3 == 0) buffer.write('.');
    buffer.write(cifre[i]);
  }
  return '$buffer m';
}

/// "4.300 m · circa 95'", per l'intestazione; solo i metri o solo i minuti
/// se manca l'altro, vuoto senza serie.
String totaliPdf(List<Serie> serie) {
  if (serie.isEmpty) return '';
  final metri = volumeDi(serieDelGruppo(serie)).metri;
  final minuti = minutiSeduta(serie);
  return [
    if (metri > 0) formattaMetri(metri),
    if (minuti > 0) "circa $minuti'",
  ].join(' · ');
}

/// I secondi come si scrivono nel recupero: "15''", "1'", "1'30''".
String testoDurataBreve(int secondi) {
  if (secondi < 60) return "$secondi''";
  final minuti = secondi ~/ 60;
  final resto = secondi % 60;
  return resto == 0
      ? "$minuti'"
      : "$minuti'${resto.toString().padLeft(2, '0')}''";
}

/// Il volume di una serie per la tabella, senza metri ("m" sta nel
/// titolo del blocco): "6×100", "200" (una ripetuta sola), "10'", "3×5'".
String volumePdf(DatiSerie s) {
  final durata = s.durataS;
  final unita = durata != null ? formatDurataS(durata) : '${s.distanzaM ?? 0}';
  return s.ripetute == 1 ? unita : '${s.ripetute}×$unita';
}

/// Lo stile solo se conta, e l'esecuzione se non è nuoto semplice:
/// "Libero", "Dorso gambe", "Palleggio", "Tecnico-tattico".
String lavoroPdf(DatiSerie s) {
  final stile = labelStileSerie(s);
  if (s.esecuzione == 'nuoto') return stile ?? '';
  final esecuzione = labelEsecuzione(s.esecuzione);
  if (stile == null) return esecuzione;
  return '$stile ${esecuzione.toLowerCase()}';
}

/// "@2:00 r15'' passo 1:25": ripartenza, recupero fra le ripetute e passo
/// (per 100) di una serie; vuoto se non ne ha.
String partenzaPdf(DatiSerie s) => [
  if (s.ripartenzaS case final r?) '@${formatTempoCompatto(r)}',
  if (s.recuperoS case final r?) 'r${testoDurataBreve(r)}',
  if (s.passoObiettivoS case final p?) 'passo ${formatTempoCompatto(p)}',
].join(' ');

/// "Solo portieri", "Solo Rossi", "Tutti tranne Rossi"; null per tutto il
/// gruppo.
String? soloPer(Destinatari d, Map<String, String> nomiAtleti) {
  final chi = testoPerChi(d, nomiAtleti);
  if (chi == null) return null;
  if (d.tranneAtleti.isNotEmpty && d.soloAtleti.isEmpty) return chi;
  return 'Solo ${chi[0].toLowerCase()}${chi.substring(1)}';
}

RigaPdf _riga(
  DatiSerie s, {
  required int livello,
  required Map<String, String> nomiAtleti,
  bool conPerChi = true,
}) {
  final perChi = conPerChi ? soloPer(s.destinatari, nomiAtleti) : null;
  final attrezzi = s.attrezzatura?.trim() ?? '';
  return RigaPdf(
    volume: volumePdf(s),
    lavoro: lavoroPdf(s),
    zona: s.zona ?? '',
    partenza: partenzaPdf(s),
    attrezzi: attrezzi,
    note: [
      ?perChi,
      if (s.note?.trim() case final n? when n.isNotEmpty) n,
    ].join(' · '),
    livello: livello,
  );
}

/// Le righe di [serie] (già nell'ordine) come un gruppo solo o una serie
/// sola: una piramide su una riga, un "3x" una volta con il suo periodo.
List<ElementoPdf> _elementiGruppo(
  List<Serie> g, {
  required int livello,
  required Map<String, String> nomiAtleti,
  required bool conPerChi,
}) {
  RigaPdf riga(Serie s, int l) =>
      _riga(s, livello: l, nomiAtleti: nomiAtleti, conPerChi: conPerChi);
  List<ElementoPdf> conRecupero(Serie s, int l) => [
    riga(s, l),
    if (s.recuperoDopoS case final r?)
      RecuperoPdf('Recupero ${testoDurataBreve(r)}', livello: l),
  ];

  if (g.length > 1) {
    // Una piramide (50-100-200-100-50, o 2×(50-100)): le distanze
    // cambiano, il resto no, e fra un pezzo e l'altro non c'è un recupero
    // a parte. Una riga sola.
    if (piramideSuUnaRiga(g) case (:final giri, :final sequenza)) {
      final recuperi = {
        for (final s in g)
          if (s.recuperoS != null) testoDurataBreve(s.recuperoS!),
      };
      final base = riga(g.first, livello);
      return [
        RigaPdf(
          volume: giri > 1 ? '$giri×($sequenza)' : sequenza,
          lavoro: base.lavoro,
          zona: base.zona,
          partenza: [
            if (g.first.ripartenzaS case final r?) '@${formatTempoCompatto(r)}',
            if (recuperi.isNotEmpty) 'r${recuperi.join('/')}',
            if (g.first.passoObiettivoS case final p?)
              'passo ${formatTempoCompatto(p)}',
          ].join(' '),
          attrezzi: base.attrezzi,
          note: base.note,
          livello: livello,
        ),
        if (g.last.recuperoDopoS case final r?)
          RecuperoPdf('Recupero ${testoDurataBreve(r)}', livello: livello),
      ];
    }
    final periodo = periodoGruppo(g);
    final volte = g.length ~/ periodo;
    if (volte > 1) {
      return [
        RipetiPdf(volte, livello: livello),
        for (final s in g.take(periodo)) ...conRecupero(s, livello + 1),
      ];
    }
  }
  return [for (final s in g) ...conRecupero(s, livello)];
}

/// Le serie (già nell'ordine) come righe: un gruppo solo per piramide o
/// "3x", niente copie ripetute.
List<ElementoPdf> _elementi(
  List<Serie> serie, {
  required int livello,
  required Map<String, String> nomiAtleti,
  required bool conPerChi,
}) => [
  for (final g in raggruppaPerPiramide(serie))
    ..._elementiGruppo(
      g,
      livello: livello,
      nomiAtleti: nomiAtleti,
      conPerChi: conPerChi,
    ),
];

/// Un momento in parallelo, con una colonna per chi (prima quella di tutti).
ParallelaPdf _parallela(List<Serie> momento, Map<String, String> nomiAtleti) {
  return ParallelaPdf([
    for (final colonna in colonneMomento(momento))
      ColonnaPdf(
        titolo: testoPerChi(colonna.destinatari, nomiAtleti) ?? 'Tutti',
        minuti: (secondiStimati(colonna.serie) / 60).round(),
        // Il nome della colonna dice già per chi è.
        elementi: _elementi(
          colonna.serie,
          livello: 0,
          nomiAtleti: nomiAtleti,
          conPerChi: false,
        ),
      ),
  ]);
}

/// Le sezioni del PDF: un blocco l'una, nell'ordine in cui compaiono le
/// [serie] (già per `ordine`). Un blocco che torna più avanti è una
/// sezione nuova. I nomi in [nomiAtleti] (id → nome) servono per le serie
/// di alcuni atleti.
List<SezionePdf> sezioniPdf(
  List<Serie> serie, {
  Map<String, String> nomiAtleti = const {},
}) {
  final gruppi = raggruppaPerMomento(serie);
  final perBlocco = <(String, List<List<Serie>>)>[];
  for (final g in gruppi) {
    final blocco = g.first.blocco;
    if (perBlocco.isNotEmpty && perBlocco.last.$1 == blocco) {
      perBlocco.last.$2.add(g);
    } else {
      perBlocco.add((blocco, [g]));
    }
  }
  return [
    for (final (blocco, gruppiBlocco) in perBlocco)
      () {
        final delBlocco = [for (final g in gruppiBlocco) ...g];
        final volume = volumeDi(serieDelGruppo(delBlocco));
        return SezionePdf(
          blocco: blocco,
          titolo: labelBlocco(blocco),
          metri: volume.metri,
          secondiATempo: volume.secondi,
          elementi: [
            for (final g in gruppiBlocco)
              if (eMomento(g))
                _parallela(g, nomiAtleti)
              else
                ..._elementi(
                  g,
                  livello: 0,
                  nomiAtleti: nomiAtleti,
                  conPerChi: true,
                ),
          ],
        );
      }(),
  ];
}
