import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/date_italiane.dart';
import '../../export/marchio_pdf.dart';
import '../../export/tema_pdf.dart';
import '../../test/domain/test_club.dart';
import '../domain/report_atleta.dart';
import 'report_pdf.dart';

/// Il PDF del report di un atleta: presenze, partite, test, obiettivi,
/// se scelti benessere e RPE, e la nota dell'allenatore.
Future<Uint8List> generaReportAtletaPdf(
  ReportAtleta report, {
  MarchioPdf? marchio,
}) async {
  final tema = await temaPdf();
  final atleta = report.atleta;
  final doc = pw.Document(
    theme: tema,
    title: 'Report di ${atleta.nomeCompleto}',
    creator: 'WaterTactics',
  );
  final sotto = [
    ?report.categoria,
    ?report.squadra,
    '${report.periodo.nome}, ${report.periodo.descrizione}',
  ].join('  ·  ');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(margineReport),
      theme: tema,
      footer: (context) => piedeReport(context, report.creatoIl),
      build: (context) => [
        if (marchio != null) testataClubPdf(marchio),
        ...titoloReport(atleta.nomeCompleto, sotto),
        ..._presenze(report),
        ..._partite(report),
        ..._test(report),
        ..._obiettivi(report),
        if (report.benessere case final b?) ..._benessere(b),
        if (report.nota case final nota?) ...[
          sezioneReport("La nota dell'allenatore"),
          pw.Text(
            nota,
            style: const pw.TextStyle(fontSize: 10.5, color: inchiostroReport),
          ),
        ],
      ],
    ),
  );
  return doc.save();
}

List<pw.Widget> _presenze(ReportAtleta r) {
  final percentuale = r.percentualePresenze;
  return [
    sezioneReport('Presenze'),
    if (percentuale == null)
      vuotoReport('Nessun allenamento nel periodo.')
    else
      numeriReport([
        ('$percentuale%', 'presenze'),
        ('${r.presenti} su ${r.allenamenti}', 'allenamenti'),
        ('${r.ritardi}', 'in ritardo'),
        (
          '${r.assenti + r.giustificati}',
          r.giustificati == 0
              ? 'assenze'
              : 'assenze, ${r.giustificati} ${r.giustificati == 1 ? 'giustificata' : 'giustificate'}',
        ),
      ]),
  ];
}

List<pw.Widget> _partite(ReportAtleta r) {
  final portiere = r.portiere;
  final numeri = <(String, String)>[
    ('${r.partite.length}', r.partite.length == 1 ? 'partita' : 'partite'),
    if (portiere != null) ...[
      ('${portiere.parate}', 'parate dal vivo'),
      ('${portiere.golSubiti}', 'gol subiti'),
      (
        portiere.percentualeParate == null
            ? '—'
            : '${portiere.percentualeParate}%',
        'parate sui tiri in porta',
      ),
    ] else ...[
      ('${r.gol}', 'gol'),
      ('${r.espulsioni}', r.espulsioni == 1 ? 'espulsione' : 'espulsioni'),
      (
        r.precisione == null ? '—' : '${r.precisione}%',
        r.tiri == 0 ? 'precisione al tiro' : 'precisione su ${r.tiri} tiri',
      ),
    ],
  ];
  return [
    sezioneReport('Partite'),
    if (r.partite.isEmpty)
      vuotoReport('Nessuna partita giocata nel periodo.')
    else ...[
      numeriReport(numeri),
      pw.SizedBox(height: 8),
      tabellaReport(
        intestazione: const ['Data', 'Avversario', 'Risultato', 'Gol', 'Esp.'],
        destra: const {2, 3, 4},
        larghezze: const {
          0: pw.FixedColumnWidth(62),
          1: pw.FlexColumnWidth(),
          2: pw.FixedColumnWidth(56),
          3: pw.FixedColumnWidth(34),
          4: pw.FixedColumnWidth(34),
        },
        righe: [
          for (final p in r.partite)
            [
              dataNumerica(p.partita.data),
              p.partita.avversario,
              p.risultato,
              p.gol?.toString() ?? '—',
              p.espulsioni?.toString() ?? '—',
            ],
        ],
      ),
      pw.SizedBox(height: 4),
      vuotoReport(
        'Gol ed espulsioni dal referto, se no dal vivo. I tiri e la '
        'precisione solo dal vivo.',
      ),
    ],
  ];
}

List<pw.Widget> _test(ReportAtleta r) {
  if (r.test.isEmpty) return const [];
  String andamento(TestNelReport t) {
    final meglio = t.migliorato;
    if (meglio == null) return t.volte < 2 ? 'una volta' : 'uguale';
    final differenza = formattaDifferenza(
      t.test.unita,
      t.valoreUltimo - t.valorePrimo,
    );
    return '$differenza, ${meglio ? 'meglio' : 'peggio'}';
  }

  return [
    sezioneReport('Test'),
    tabellaReport(
      intestazione: const ['Test', 'Primo', 'Ultimo', 'Com\'è andata'],
      destra: const {1, 2},
      larghezze: const {
        0: pw.FlexColumnWidth(),
        1: pw.FixedColumnWidth(92),
        2: pw.FixedColumnWidth(92),
        3: pw.FixedColumnWidth(110),
      },
      righe: [
        for (final t in r.test)
          [
            t.test.nome,
            '${formattaValore(t.test.unita, t.valorePrimo)}\n'
                '${dataNumerica(t.primo.data)}',
            '${formattaValore(t.test.unita, t.valoreUltimo)}\n'
                '${dataNumerica(t.ultimo.data)}',
            andamento(t),
          ],
      ],
    ),
  ];
}

List<pw.Widget> _obiettivi(ReportAtleta r) {
  if (!r.obiettiviLetti) {
    return [
      sezioneReport('Obiettivi'),
      vuotoReport(
        'Gli obiettivi non si sono potuti leggere: servono la rete. '
        'Rifai il report quando torna.',
      ),
    ];
  }
  if (r.obiettivi.isEmpty) return const [];
  return [
    sezioneReport('Obiettivi'),
    for (final o in r.obiettivi) ...[
      pw.Text(
        o.scheda.titolo,
        style: const pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: inchiostroReport,
        ),
      ),
      pw.SizedBox(height: 3),
      for (final (domanda, risposta) in o.righe)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                domanda,
                style: const pw.TextStyle(fontSize: 8.5, color: grigioReport),
              ),
              pw.Text(
                risposta,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: inchiostroReport,
                ),
              ),
            ],
          ),
        ),
      if (o.risposta.ritorno?.trim().isNotEmpty ?? false)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            "L'allenatore: ${o.risposta.ritorno!.trim()}",
            style: const pw.TextStyle(
              fontSize: 9.5,
              fontStyle: pw.FontStyle.italic,
              color: grigioReport,
            ),
          ),
        ),
      pw.SizedBox(height: 6),
    ],
  ];
}

List<pw.Widget> _benessere(BenessereNelReport b) => [
  sezioneReport('Benessere e RPE'),
  if (b.schede == 0 && b.sedute == 0)
    vuotoReport('Nessuna scheda del benessere e nessun RPE nel periodo.')
  else ...[
    numeriReport([
      (b.indice == null ? '—' : '${b.indice}/100', 'benessere medio'),
      (b.sonno == null ? '—' : oreReport(b.sonno!), 'sonno medio'),
      (
        b.rpe == null ? '—' : decimaleReport(b.rpe!),
        b.sedute == 0 ? 'RPE medio' : 'RPE medio su ${b.sedute} sedute',
      ),
    ]),
    pw.SizedBox(height: 4),
    vuotoReport(
      'Il benessere è la media di sonno, energia, muscoli, stress e umore '
      'di ${b.schede} ${b.schede == 1 ? 'scheda' : 'schede'}, su 100. '
      'Dolori e sintomi non sono nel report.',
    ),
  ],
];
