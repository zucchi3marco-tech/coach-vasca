import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../atleti/domain/atleta.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/partita.dart';

typedef ConvocatoConAtleta = ({DistintaGiocatore giocatore, Atleta atleta});

String _formattaData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year}';

String _ruoli(DistintaGiocatore g) {
  final tag = <String>[
    if (g.capitano) 'CAP',
    if (g.viceCapitano) 'VICE',
    if (g.portiere) 'POR',
    if (g.fuoriquota) 'FQ',
  ];
  return tag.join('/');
}

/// PDF di convocazione per una partita: intestazione con i dati della
/// gara e tabella dei convocati ordinata per numero di calottina. Non
/// riproduce il modulo ufficiale FIN (che va compilato dagli ufficiali di
/// gara), e' un promemoria pratico per squadra e famiglie.
Future<Uint8List> generaDistintaPdf({
  required Partita partita,
  required List<ConvocatoConAtleta> convocati,
}) async {
  final doc = pw.Document();
  final ordinati = [...convocati]
    ..sort(
      (a, b) => a.giocatore.numeroCalottina.compareTo(b.giocatore.numeroCalottina),
    );

  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Header(
          level: 0,
          text: '${partita.squadraCasa} - ${partita.squadraTrasferta}',
        ),
        pw.Text(
          [
            _formattaData(partita.data),
            if (partita.ora != null && partita.ora!.isNotEmpty) partita.ora!,
            if (partita.luogo != null && partita.luogo!.isNotEmpty)
              partita.luogo!,
          ].join(' · '),
        ),
        if (partita.campionato != null && partita.campionato!.isNotEmpty)
          pw.Text('Campionato: ${partita.campionato}'),
        if (partita.coloreCalottina != null &&
            partita.coloreCalottina!.isNotEmpty)
          pw.Text('Colore calottina: ${partita.coloreCalottina}'),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['N°', 'Giocatore', 'Tessera FIN', 'Ruolo'],
          data: [
            for (final c in ordinati)
              [
                '${c.giocatore.numeroCalottina}',
                c.atleta.nomeCompleto,
                c.atleta.numeroTesseraFin ?? '',
                _ruoli(c.giocatore),
              ],
          ],
        ),
        if (partita.note != null && partita.note!.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Note: ${partita.note}'),
        ],
      ],
    ),
  );

  return doc.save();
}
