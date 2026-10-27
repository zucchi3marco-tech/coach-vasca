import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/date_italiane.dart';

/// I pezzi comuni dei report PDF (atleta e squadra): stessi colori della
/// stampa delle sedute, titoli di sezione, riquadri con i numeri, tabelle.

const inchiostroReport = PdfColor.fromInt(0xFF1A1A1A);
const grigioReport = PdfColor.fromInt(0xFF5C5C5C);
const filettoReport = PdfColor.fromInt(0xFFD4D4D4);
const tintaReport = PdfColor.fromInt(0xFFEFF3F6);

const margineReport = 1.5 * PdfPageFormat.cm;

/// Il titolo del report e, sotto, chi e quando.
List<pw.Widget> titoloReport(String titolo, String sotto) => [
  pw.Text(
    titolo,
    style: const pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
      color: inchiostroReport,
    ),
  ),
  pw.SizedBox(height: 4),
  pw.Text(sotto, style: const pw.TextStyle(fontSize: 11, color: grigioReport)),
  pw.SizedBox(height: 8),
];

/// Il titolo di una sezione, con un filetto sotto.
pw.Widget sezioneReport(String titolo) => pw.Container(
  width: double.infinity,
  margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
  padding: const pw.EdgeInsets.only(bottom: 3),
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: filettoReport, width: 0.6)),
  ),
  child: pw.Text(
    titolo.toUpperCase(),
    style: const pw.TextStyle(
      fontSize: 9.5,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 0.8,
      color: grigioReport,
    ),
  ),
);

/// Una riga di riquadri con un numero grande e cosa vuol dire.
pw.Widget numeriReport(
  List<(String valore, String etichetta)> numeri,
) => pw.Row(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    for (var i = 0; i < numeri.length; i++) ...[
      if (i > 0) pw.SizedBox(width: 8),
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const pw.BoxDecoration(
            color: tintaReport,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                numeri[i].$1,
                style: const pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                  color: inchiostroReport,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                numeri[i].$2,
                style: const pw.TextStyle(fontSize: 8.5, color: grigioReport),
              ),
            ],
          ),
        ),
      ),
    ],
  ],
);

/// Una tabella semplice: intestazione in grigio, righe con il filetto.
/// [destra]: le colonne con i numeri, allineate a destra.
pw.Widget tabellaReport({
  required List<String> intestazione,
  required List<List<String>> righe,
  Set<int> destra = const {},
  Map<int, pw.TableColumnWidth> larghezze = const {},
}) {
  pw.Widget cella(String testo, int colonna, {bool testa = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Text(
          testo,
          textAlign: destra.contains(colonna)
              ? pw.TextAlign.right
              : pw.TextAlign.left,
          style: testa
              ? const pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: grigioReport,
                )
              : const pw.TextStyle(fontSize: 9.5, color: inchiostroReport),
        ),
      );
  return pw.Table(
    columnWidths: larghezze,
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: filettoReport, width: 0.5),
      bottom: pw.BorderSide(color: filettoReport, width: 0.5),
    ),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: tintaReport),
        children: [
          for (var i = 0; i < intestazione.length; i++)
            cella(intestazione[i], i, testa: true),
        ],
      ),
      for (final r in righe)
        pw.TableRow(
          children: [for (var i = 0; i < r.length; i++) cella(r[i], i)],
        ),
    ],
  );
}

/// Un testo in grigio, per dire che una sezione è vuota.
pw.Widget vuotoReport(String testo) => pw.Text(
  testo,
  style: const pw.TextStyle(fontSize: 9.5, color: grigioReport),
);

/// Il piede di ogni pagina: quando è stato fatto e la pagina.
pw.Widget piedeReport(pw.Context context, DateTime creatoIl) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 8),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'Fatto il ${dataLunga(creatoIl)} con WaterTactics',
        style: const pw.TextStyle(fontSize: 8, color: grigioReport),
      ),
      pw.Text(
        'Pagina ${context.pageNumber} di ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: grigioReport),
      ),
    ],
  ),
);

/// "6,2".
String decimaleReport(double v, {int cifre = 1}) =>
    v.toStringAsFixed(cifre).replaceAll('.', ',');

/// "8 h", "7 h 30".
String oreReport(double ore) {
  final minuti = (ore * 60).round();
  final h = minuti ~/ 60;
  final m = minuti % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}
