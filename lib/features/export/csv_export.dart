import '../../core/utils/pace_format.dart';
import '../allenamenti/domain/allenamento.dart';
import '../allenamenti/domain/serie.dart';
import '../allenamenti/presentation/serie_labels.dart';

typedef AllenamentoConSerie = (Allenamento, List<Serie>);

const _intestazione = [
  'Data',
  'Allenamento',
  'Gruppo',
  'Ordine',
  'Blocco',
  'Ripetute',
  'Distanza (m)',
  'Stile',
  'Esecuzione',
  'Zona',
  'Passo obiettivo',
  'Recupero (s)',
  'Ripartenza',
  'Attrezzatura',
  'Note',
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
) {
  return [
    _formattaData(allenamento.data),
    allenamento.titolo ?? '',
    nomiGruppi[allenamento.gruppoId] ?? '',
    '${s.ordine}',
    labelBlocco(s.blocco),
    '${s.ripetute}',
    '${s.distanzaM}',
    labelStile(s.stile),
    labelEsecuzione(s.esecuzione),
    s.zona ?? '',
    s.passoObiettivoS != null ? formatPaceSeconds(s.passoObiettivoS!) : '',
    s.recuperoS?.toString() ?? '',
    s.ripartenzaS != null ? formatPaceSeconds(s.ripartenzaS!) : '',
    s.attrezzatura ?? '',
    s.note ?? '',
  ];
}

/// Un CSV con una riga per serie, per uno o più allenamenti (scheda singola
/// o intera settimana). [nomiGruppi] risolve l'id del gruppo dell'allenamento
/// nel suo nome, per mostrarlo nella colonna "Gruppo".
String generaCsv(
  List<AllenamentoConSerie> allenamenti, {
  Map<String, String> nomiGruppi = const {},
}) {
  final righe = [_intestazione.map(_cella).join(',')];
  for (final (allenamento, serie) in allenamenti) {
    for (final s in serie) {
      righe.add(_riga(allenamento, s, nomiGruppi).map(_cella).join(','));
    }
  }
  return righe.join('\r\n');
}
