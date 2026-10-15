import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../allenamenti/domain/serie.dart';
import '../allenamenti/presentation/serie_labels.dart';
import 'csv_export.dart' show AllenamentoConSerie, numeriMomenti, testoPerChi;

String _formattaData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year}';

/// Un PDF con una pagina per allenamento (scheda singola o intera
/// settimana), ciascuna con l'elenco delle sue serie in tabella.
/// [nomiGruppi] risolve l'id del gruppo dell'allenamento nel suo nome.
Future<Uint8List> generaPdf(
  List<AllenamentoConSerie> allenamenti, {
  Map<String, String> nomiGruppi = const {},
  Map<String, String> nomiAtleti = const {},
}) async {
  final doc = pw.Document();

  for (final (allenamento, serie) in allenamenti) {
    final nomeGruppo = nomiGruppi[allenamento.gruppoId];
    // La colonna "Per chi" solo se qualche serie non è di tutti. Nei
    // momenti in parallelo dice anche con chi va insieme ("Portieri ·
    // insieme 1": le serie con lo stesso numero si fanno nello stesso
    // tempo).
    final momenti = numeriMomenti(serie);
    final perChi = serie.any((s) => !s.destinatari.perTutti);
    String colonnaPerChi(Serie s) => [
      testoPerChi(s.destinatari, nomiAtleti) ?? 'Tutti',
      if (momenti[s.momentoId] case final n?) 'insieme $n',
    ].join(' · ');
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            text: allenamento.titolo != null && allenamento.titolo!.isNotEmpty
                ? allenamento.titolo!
                : 'Allenamento',
          ),
          pw.Text(
            '${_formattaData(allenamento.data)}'
            '${nomeGruppo != null ? ' · $nomeGruppo' : ''}',
          ),
          if (allenamento.note != null && allenamento.note!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(allenamento.note!),
          ],
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              'Blocco',
              'Serie',
              'Stile',
              'Esecuzione',
              'Zona',
              if (perChi) 'Per chi',
              'Recupero',
              'Attrezzatura',
              'Note',
            ],
            data: [
              for (final s in serie)
                [
                  ..._rigaTabella(s).take(6),
                  if (perChi) colonnaPerChi(s),
                  ..._rigaTabella(s).skip(6),
                ],
            ],
          ),
        ],
      ),
    );
  }

  return doc.save();
}

List<String> _rigaTabella(Serie s) {
  return [
    '${s.ordine}',
    labelBlocco(s.blocco),
    labelVolumeSerie(s),
    labelStile(s.stile),
    labelEsecuzione(s.esecuzione),
    s.zona ?? '',
    s.recuperoS != null ? "${s.recuperoS}''" : '',
    s.attrezzatura ?? '',
    s.note ?? '',
  ];
}
