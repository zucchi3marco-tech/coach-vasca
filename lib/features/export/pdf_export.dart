import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../allenamenti/domain/serie.dart';
import '../allenamenti/presentation/serie_labels.dart';
import 'csv_export.dart' show AllenamentoConSerie;

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
}) async {
  final doc = pw.Document();

  for (final (allenamento, serie) in allenamenti) {
    final nomeGruppo = nomiGruppi[allenamento.gruppoId];
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
              'Recupero',
              'Attrezzatura',
              'Note',
            ],
            data: [
              for (final s in serie) _rigaTabella(s),
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
