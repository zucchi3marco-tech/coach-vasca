import '../../core/utils/pace_format.dart';
import '../allenamenti/domain/allenamento.dart';
import '../allenamenti/domain/serie.dart';
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

const _intestazione = [
  'Data',
  'Allenamento',
  'Gruppo',
  'Ordine',
  'Blocco',
  'Ripetute',
  'Distanza (m)',
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

List<String> _riga(
  Allenamento allenamento,
  Serie s,
  Map<String, String> nomiGruppi,
  Map<String, String> nomiAtleti,
  Map<String, int> momenti,
) {
  return [
    _formattaData(allenamento.data),
    allenamento.titolo ?? '',
    nomiGruppi[allenamento.gruppoId] ?? '',
    '${s.ordine}',
    labelBlocco(s.blocco),
    '${s.ripetute}',
    s.distanzaM?.toString() ?? '',
    s.durataS?.toString() ?? '',
    labelStile(s.stile),
    labelEsecuzione(s.esecuzione),
    s.zona ?? '',
    s.passoObiettivoS != null ? formatPaceSeconds(s.passoObiettivoS!) : '',
    s.recuperoS?.toString() ?? '',
    s.ripartenzaS != null ? formatPaceSeconds(s.ripartenzaS!) : '',
    s.attrezzatura ?? '',
    s.note ?? '',
    testoPerChi(s.destinatari, nomiAtleti) ?? 'Tutti',
    // Il numero del momento: le serie con lo stesso si fanno insieme.
    momenti[s.momentoId]?.toString() ?? '',
  ];
}

/// Un CSV con una riga per serie, per uno o più allenamenti (scheda singola
/// o intera settimana). [nomiGruppi] risolve l'id del gruppo dell'allenamento
/// nel suo nome, per mostrarlo nella colonna "Gruppo".
String generaCsv(
  List<AllenamentoConSerie> allenamenti, {
  Map<String, String> nomiGruppi = const {},
  Map<String, String> nomiAtleti = const {},
}) {
  final righe = [_intestazione.map(_cella).join(',')];
  for (final (allenamento, serie) in allenamenti) {
    final momenti = numeriMomenti(serie);
    for (final s in serie) {
      righe.add(
        _riga(
          allenamento,
          s,
          nomiGruppi,
          nomiAtleti,
          momenti,
        ).map(_cella).join(','),
      );
    }
  }
  return righe.join('\r\n');
}
