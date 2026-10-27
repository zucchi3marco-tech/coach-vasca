import '../../core/utils/pace_format.dart';
import '../allenamenti/domain/allenamento.dart';
import '../allenamenti/domain/riordino_serie.dart';
import '../allenamenti/domain/serie.dart';
import '../allenamenti/domain/testo_allenamento.dart';
import '../allenamenti/presentation/serie_labels.dart';

typedef AllenamentoConSerie = (Allenamento, List<Serie>);

/// Per chi è una serie, con i nomi in [nomiAtleti] (id → nome); null per
/// tutto il gruppo. Senza il nome di un atleta: "un atleta".
String? testoPerChi(Destinatari d, Map<String, String> nomiAtleti) =>
    etichettaDestinatari(d, (id) => nomiAtleti[id] ?? 'un atleta');

/// Il numero (1, 2…) di ogni momento in parallelo delle [serie] di un
/// allenamento, nell'ordine: le serie con lo stesso numero si fanno
/// insieme. Solo i momenti con almeno due colonne.
Map<String, int> numeriMomenti(List<Serie> serie) {
  final numeri = <String, int>{};
  for (final g in raggruppaPerMomento(serie)) {
    if (eMomento(g)) numeri[g.first.momentoId!] = numeri.length + 1;
  }
  return numeri;
}

/// Se [gruppo] (righe con lo stesso `piramideId`) si stampa su una riga
/// sola, come nel dettaglio: una piramide (50-100-200-100-50, o
/// 2×(50-100)) con le distanze che cambiano e nessun recupero a parte fra
/// un pezzo e l'altro. [sequenza] è un giro, "50-100-200-100-50". Null per
/// una riga sola, un "3x" o una piramide con recuperi dentro.
({int giri, String sequenza})? piramideSuUnaRiga(List<Serie> gruppo) {
  if (gruppo.length < 2) return null;
  final piramide = strutturaPiramide(gruppo);
  if (piramide == null) return null;
  if (gruppo.map((s) => s.distanzaM).toSet().length < 2) return null;
  if (gruppo.take(gruppo.length - 1).any((s) => s.recuperoDopoS != null)) {
    return null;
  }
  return (
    giri: piramide.giri,
    sequenza: gruppo.take(piramide.distanze).map((s) => s.distanzaM).join('-'),
  );
}

const _intestazione = [
  'Data',
  'Allenamento',
  'Gruppo',
  'Ordine',
  'Blocco',
  'Ripetute',
  'Distanza (m)',
  'Metri',
  'Durata (s)',
  'Stile',
  'Esecuzione',
  'Zona',
  'Passo obiettivo',
  'Recupero (s)',
  'Ripartenza',
  'Attrezzatura',
  'Note',
  'Per chi',
  'In parallelo',
];

String _formattaData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year}';

/// Racchiude tra virgolette solo se necessario (RFC 4180): il carattere
/// virgoletta al suo interno va raddoppiato.
String _cella(Object? valore) {
  final testo = valore?.toString() ?? '';
  if (testo.contains(',') || testo.contains('"') || testo.contains('\n')) {
    return '"${testo.replaceAll('"', '""')}"';
  }
  return testo;
}

/// Una riga del CSV per la serie [s]. Per una piramide [s] è la prima
/// serie e [piramide] le altre colonne: i giri come ripetute, la sequenza
/// come distanza, i metri di tutto il gruppo, i recuperi diversi con "/".
List<String> _riga(
  Allenamento allenamento,
  Serie s,
  Map<String, String> nomiGruppi,
  Map<String, String> nomiAtleti,
  Map<String, int> momenti, {
  ({int giri, String sequenza, int metri, String recupero})? piramide,
}) {
  return [
    _formattaData(allenamento.data),
    allenamento.titolo ?? '',
    nomiGruppi[allenamento.gruppoId] ?? '',
    '${s.ordine}',
    labelBlocco(s.blocco),
    '${piramide?.giri ?? s.ripetute}',
    piramide?.sequenza ?? s.distanzaM?.toString() ?? '',
    if (piramide != null)
      '${piramide.metri}'
    else if (s.distanzaM case final d?)
      '${s.ripetute * d}'
    else
      '',
    s.durataS?.toString() ?? '',
    labelStile(s.stile),
    labelEsecuzione(s.esecuzione),
    s.zona ?? '',
    s.passoObiettivoS != null ? formatPaceSeconds(s.passoObiettivoS!) : '',
    piramide?.recupero ?? s.recuperoS?.toString() ?? '',
    s.ripartenzaS != null ? formatPaceSeconds(s.ripartenzaS!) : '',
    s.attrezzatura ?? '',
    s.note ?? '',
    testoPerChi(s.destinatari, nomiAtleti) ?? 'Tutti',
    // Il numero del momento: le serie con lo stesso si fanno insieme.
    momenti[s.momentoId]?.toString() ?? '',
  ];
}

/// Un CSV con una riga per serie, per uno o più allenamenti (scheda singola
/// o intera settimana); una piramide su una riga sola, come nel dettaglio e
/// nel PDF. [nomiGruppi] risolve l'id del gruppo dell'allenamento nel suo
/// nome, per mostrarlo nella colonna "Gruppo". Le [serie] di ogni
/// allenamento vanno già nell'ordine.
String generaCsv(
  List<AllenamentoConSerie> allenamenti, {
  Map<String, String> nomiGruppi = const {},
  Map<String, String> nomiAtleti = const {},
}) {
  final righe = [_intestazione.map(_cella).join(',')];
  void aggiungi(List<String> riga) => righe.add(riga.map(_cella).join(','));
  for (final (allenamento, serie) in allenamenti) {
    final momenti = numeriMomenti(serie);
    for (final gruppo in raggruppaPerPiramide(serie)) {
      final piramide = piramideSuUnaRiga(gruppo);
      if (piramide == null) {
        for (final s in gruppo) {
          aggiungi(_riga(allenamento, s, nomiGruppi, nomiAtleti, momenti));
        }
        continue;
      }
      final recuperi = <int>{for (final s in gruppo) ?s.recuperoS};
      aggiungi(
        _riga(
          allenamento,
          gruppo.first,
          nomiGruppi,
          nomiAtleti,
          momenti,
          piramide: (
            giri: piramide.giri,
            sequenza: piramide.sequenza,
            metri: gruppo.fold(0, (m, s) => m + (s.distanzaM ?? 0)),
            recupero: recuperi.join('/'),
          ),
        ),
      );
    }
  }
  return righe.join('\r\n');
}
