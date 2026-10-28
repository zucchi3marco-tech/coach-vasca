import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/date_italiane.dart';
import '../../campionati/domain/campionato_fin.dart';
import '../../export/marchio_pdf.dart';
import '../../export/tema_pdf.dart';
import '../domain/report_atleta.dart';
import '../domain/report_squadra.dart';
import 'report_pdf.dart';

/// Il PDF del report di una squadra: partite e bilancio, classifica FIN,
/// marcatori, presenze di ognuno, numeri dal vivo, se scelti benessere e
/// RPE (medie della squadra) e la nota dell'allenatore.
Future<Uint8List> generaReportSquadraPdf(
  ReportSquadra report, {
  MarchioPdf? marchio,
}) async {
  final tema = await temaPdf();
  final doc = pw.Document(
    theme: tema,
    title: 'Report di ${report.nome}',
    creator: 'WaterTactics',
  );
  final sotto = [
    ?report.campionato,
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
        ...titoloReport(report.nome, sotto),
        ..._partite(report),
        ..._classifiche(report),
        ..._marcatori(report),
        ..._presenze(report),
        ..._dalVivo(report),
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

String _plurale(int n, String uno, String tanti) => n == 1 ? uno : tanti;

List<pw.Widget> _partite(ReportSquadra r) {
  final senza = r.partite.length - r.conRisultato.length;
  return [
    sezioneReport('Partite'),
    if (r.partite.isEmpty)
      vuotoReport('Nessuna partita giocata nel periodo.')
    else ...[
      numeriReport([
        (
          '${r.partite.length}',
          _plurale(r.partite.length, 'partita giocata', 'partite giocate'),
        ),
        ('${r.vinte}-${r.pari}-${r.perse}', 'vinte, pari, perse'),
        ('${r.golFatti}-${r.golSubiti}', 'gol fatti e subiti'),
        (
          r.conRisultato.isEmpty
              ? '—'
              : decimaleReport(r.golFatti / r.conRisultato.length),
          'gol a partita',
        ),
      ]),
      pw.SizedBox(height: 8),
      tabellaReport(
        intestazione: const ['Data', 'Avversario', 'Dove', 'Risultato', ''],
        destra: const {3},
        larghezze: const {
          0: pw.FixedColumnWidth(62),
          1: pw.FlexColumnWidth(),
          2: pw.FixedColumnWidth(44),
          3: pw.FixedColumnWidth(56),
          4: pw.FixedColumnWidth(44),
        },
        righe: [
          for (final p in r.partite)
            [
              dataNumerica(p.partita.data),
              p.partita.avversario,
              p.partita.inCasa ? 'casa' : 'fuori',
              p.risultato,
              p.esito,
            ],
        ],
      ),
      pw.SizedBox(height: 4),
      vuotoReport(
        [
          'Il risultato dal referto, se no dal vivo; prima i nostri gol.',
          if (senza > 0)
            '$senza ${_plurale(senza, 'partita è', 'partite sono')} senza '
                'risultato: manca il referto e non '
                '${_plurale(senza, 'è stata seguita', 'sono state seguite')} '
                'dal vivo.',
        ].join(' '),
      ),
    ],
  ];
}

List<pw.Widget> _classifiche(ReportSquadra r) {
  if (!r.gironiLetti) {
    return [
      sezioneReport('Classifica FIN'),
      vuotoReport(
        'I campionati della squadra non si sono potuti leggere: serve la '
        'rete. Rifai il report quando torna.',
      ),
    ];
  }
  if (r.gironi.isEmpty) return const [];
  return [
    sezioneReport('Classifica FIN'),
    for (final g in r.gironi) ..._girone(g),
  ];
}

List<pw.Widget> _girone(GironeLetto g) {
  final c = g.collegato;
  final titolo = [
    c.campionato,
    c.faseEGirone,
  ].where((s) => s.isNotEmpty).join(' · ');
  final girone = g.girone;
  final classifica = girone?.classifica ?? const <RigaClassificaFin>[];
  return [
    pw.Text(
      titolo,
      style: const pw.TextStyle(
        fontSize: 10.5,
        fontWeight: pw.FontWeight.bold,
        color: inchiostroReport,
      ),
    ),
    pw.SizedBox(height: 4),
    if (girone == null)
      vuotoReport(
        'La classifica non si è potuta leggere dal sito della FIN: serve la '
        'rete.',
      )
    else if (classifica.isEmpty)
      vuotoReport('La classifica non c\'è ancora sul sito della FIN.')
    else ...[
      tabellaReport(
        intestazione: const [
          'Pos.',
          'Squadra',
          'Pt',
          'G',
          'V',
          'N',
          'P',
          'GF',
          'GS',
        ],
        destra: const {0, 2, 3, 4, 5, 6, 7, 8},
        larghezze: {
          0: const pw.FixedColumnWidth(30),
          1: const pw.FlexColumnWidth(),
          for (var i = 2; i <= 8; i++) i: const pw.FixedColumnWidth(28),
        },
        evidenzia: {
          for (var i = 0; i < classifica.length; i++)
            if (stessaSquadra(classifica[i].squadra, c.squadra)) i,
        },
        righe: [
          for (final riga in classifica)
            [
              '${riga.posizione}',
              riga.squadra,
              '${riga.punti}',
              '${riga.giocate}',
              '${riga.vinte}',
              '${riga.pareggiate}',
              '${riga.perse}',
              '${riga.golFatti}',
              '${riga.golSubiti}',
            ],
        ],
      ),
      pw.SizedBox(height: 4),
      vuotoReport(
        [
          if (g.lettoIl case final letto?)
            'Dal sito della FIN, ${g.daCopia ? 'letta l\'ultima volta' : 'letta'} '
                'il ${dataLunga(letto)}.',
          if (girone.nonTuttoLetto)
            'Il sito è cambiato: può mancare qualche riga.',
        ].join(' '),
      ),
    ],
    pw.SizedBox(height: 8),
  ];
}

List<pw.Widget> _marcatori(ReportSquadra r) {
  if (r.partite.isEmpty) return const [];
  return [
    sezioneReport('Marcatori'),
    if (r.marcatori.isEmpty)
      vuotoReport(
        'Nessun gol attribuito: collega i giocatori agli atleti nei referti '
        'o segui le partite dal vivo.',
      )
    else ...[
      tabellaReport(
        intestazione: const ['Atleta', 'Partite', 'Gol', 'Esp.'],
        destra: const {1, 2, 3},
        larghezze: const {
          0: pw.FlexColumnWidth(),
          1: pw.FixedColumnWidth(50),
          2: pw.FixedColumnWidth(40),
          3: pw.FixedColumnWidth(40),
        },
        righe: [
          for (final m in r.marcatori)
            [m.nome, '${m.partite}', '${m.gol}', '${m.espulsioni}'],
        ],
      ),
      pw.SizedBox(height: 4),
      vuotoReport('Gol ed espulsioni dal referto, se no dal vivo.'),
    ],
  ];
}

List<pw.Widget> _presenze(ReportSquadra r) {
  final percentuale = r.percentualePresenze;
  return [
    sezioneReport('Presenze'),
    if (percentuale == null)
      vuotoReport('Nessun allenamento nel periodo.')
    else ...[
      numeriReport([
        ('$percentuale%', 'presenze della squadra'),
        (
          '${r.presenze.length}',
          _plurale(r.presenze.length, 'atleta', 'atleti'),
        ),
      ]),
      pw.SizedBox(height: 8),
      tabellaReport(
        intestazione: const [
          'Atleta',
          'Presenze',
          'Allenamenti',
          'Ritardi',
          'Assenze',
        ],
        destra: const {1, 2, 3, 4},
        larghezze: const {
          0: pw.FlexColumnWidth(),
          1: pw.FixedColumnWidth(56),
          2: pw.FixedColumnWidth(70),
          3: pw.FixedColumnWidth(48),
          4: pw.FixedColumnWidth(80),
        },
        righe: [
          for (final p in r.presenze)
            [
              p.atleta.nomeCompleto,
              p.percentuale == null ? '—' : '${p.percentuale}%',
              p.allenamenti == 0 ? '—' : '${p.presenti} su ${p.allenamenti}',
              '${p.ritardi}',
              p.giustificati == 0
                  ? '${p.assenti}'
                  : '${p.assenti + p.giustificati} '
                        '(${p.giustificati} giust.)',
            ],
        ],
      ),
      pw.SizedBox(height: 4),
      vuotoReport(
        'Contano gli allenamenti già fatti in cui l\'atleta era atteso; chi '
        'arriva in ritardo è presente.',
      ),
    ],
  ];
}

String _su(int fatti, int su) =>
    su == 0 ? '—' : '$fatti su $su (${(fatti / su * 100).round()}%)';

List<pw.Widget> _dalVivo(ReportSquadra r) {
  if (r.partiteDalVivo == 0) return const [];
  final n = r.dalVivo;
  return [
    sezioneReport('Numeri dal vivo'),
    numeriReport([
      (_su(n.gol, n.tiri), 'gol sui tiri'),
      (_su(n.golInSuperiorita, n.superiorita), 'gol in superiorità'),
      (
        n.inferiorita == 0
            ? '—'
            : '${n.inferiorita - n.golSubitiInInferiorita} su ${n.inferiorita}',
        'inferiorità difese',
      ),
      (_su(n.golSubiti, n.tiriSubiti), 'gol subiti sui tiri'),
    ]),
    if (n.haEventiCompleti) ...[
      pw.SizedBox(height: 8),
      numeriReport([
        ('${n.assist}', 'assist'),
        ('${n.pallePerse}', 'palle perse'),
        ('${n.palleRecuperate}', 'palle recuperate'),
        ('${n.espulsioniGuadagnate}', 'espulsioni guadagnate'),
      ]),
    ],
    pw.SizedBox(height: 4),
    vuotoReport(
      'Solo le ${r.partiteDalVivo == 1 ? 'partita seguita' : '${r.partiteDalVivo} partite seguite'} '
      'dal vivo con l\'app: il referto non ha i tiri sbagliati.',
    ),
  ];
}

List<pw.Widget> _benessere(BenessereNelReport b) => [
  sezioneReport('Benessere e RPE della squadra'),
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
      'Le medie di tutta la squadra, mai dei singoli: il benessere è la '
      'media di sonno, energia, muscoli, stress e umore di ${b.schede} '
      '${b.schede == 1 ? 'scheda' : 'schede'}, su 100. Dolori e sintomi '
      'non sono nel report.',
    ),
  ],
];
