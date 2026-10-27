import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/date_italiane.dart';
import '../../export/marchio_pdf.dart';
import '../../export/tema_pdf.dart';

/// Un biglietto del foglio dei codici: l'atleta, la squadra (se ce l'ha),
/// il suo codice personale e fino a quando vale.
class BigliettoCodice {
  const BigliettoCodice({
    required this.cognome,
    required this.nome,
    required this.codice,
    required this.scade,
    this.squadra,
  });

  final String cognome;
  final String nome;
  final String? squadra;
  final String codice;
  final DateTime scade;

  /// "Rossi Mario": come si legge in tutti gli elenchi dell'app.
  String get cognomeNome => '$cognome $nome';
}

/// Biglietti per pagina: 2 colonne per 4 righe.
const bigliettiPerPagina = 8;

/// "A1B2C3D4E5" → "A1B2C 3D4E5": due gruppi da 5, più facili da copiare a
/// mano. Se il codice non è di 10 caratteri resta com'è (in maiuscolo).
String formattaCodice(String codice) {
  final c = codice.trim().toUpperCase();
  if (c.length != 10) return c;
  return '${c.substring(0, 5)} ${c.substring(5)}';
}

/// I biglietti per squadra (in ordine alfabetico, quelli senza squadra in
/// fondo) e, dentro la squadra, per cognome e nome. Non tocca la lista data.
List<BigliettoCodice> ordinaBiglietti(Iterable<BigliettoCodice> biglietti) {
  int confronta(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());
  return biglietti.toList()..sort((a, b) {
    final sa = a.squadra, sb = b.squadra;
    if (sa != sb) {
      if (sa == null) return 1;
      if (sb == null) return -1;
      final c = confronta(sa, sb);
      if (c != 0) return c;
    }
    final c = confronta(a.cognome, b.cognome);
    return c != 0 ? c : confronta(a.nome, b.nome);
  });
}

/// Il PDF del foglio: un biglietto per atleta, 8 per pagina A4, con le
/// linee tratteggiate dove tagliare. [indirizzoApp] è l'indirizzo dell'app
/// (se c'è, sul biglietto compare anche il suo QR: mai il codice, che
/// resta scritto solo in chiaro).
Future<Uint8List> generaBigliettiCodici({
  required String nomeClub,
  required List<BigliettoCodice> biglietti,
  String? indirizzoApp,
  Uint8List? logo,
}) async {
  final doc = await documentoBigliettiCodici(
    nomeClub: nomeClub,
    biglietti: biglietti,
    indirizzoApp: indirizzoApp,
    logo: logo,
  );
  return doc.save();
}

/// Come [generaBigliettiCodici], ma ritorna il documento (ai test serve per
/// contare le pagine).
Future<pw.Document> documentoBigliettiCodici({
  required String nomeClub,
  required List<BigliettoCodice> biglietti,
  String? indirizzoApp,
  Uint8List? logo,
}) async {
  final tema = await temaPdf();
  final doc = pw.Document(theme: tema, title: 'Codici di accesso');
  final immagine = immagineLogoPdf(logo);
  final ordinati = ordinaBiglietti(biglietti);
  final indirizzo = indirizzoApp?.trim();
  final app = (indirizzo == null || indirizzo.isEmpty) ? null : indirizzo;

  if (ordinati.isEmpty) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margine),
        build: (_) => pw.Text('Nessun biglietto da stampare.'),
      ),
    );
    return doc;
  }

  for (var i = 0; i < ordinati.length; i += bigliettiPerPagina) {
    final gruppo = ordinati.skip(i).take(bigliettiPerPagina).toList();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margine),
        build: (_) => pw.Stack(
          children: [
            pw.CustomPaint(
              size: PdfPoint(_larghezzaGriglia, _altezzaGriglia),
              painter: _disegnaTaglio,
            ),
            pw.Column(
              children: [
                for (var r = 0; r < _righe; r++)
                  pw.Row(
                    children: [
                      for (var c = 0; c < _colonne; c++)
                        _cella(
                          r * _colonne + c < gruppo.length
                              ? gruppo[r * _colonne + c]
                              : null,
                          nomeClub: nomeClub,
                          indirizzo: app,
                          logo: immagine,
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  return doc;
}

// Margini larghi: le stampanti di casa tagliano il bordo del foglio.
const _margine = 1.5 * PdfPageFormat.cm;
const _colonne = 2;
const _righe = 4;

// Misure intere, un filo sotto lo spazio disponibile.
final _larghezzaCella = ((PdfPageFormat.a4.width - 2 * _margine) / _colonne)
    .floorToDouble();
final _altezzaCella = ((PdfPageFormat.a4.height - 2 * _margine) / _righe)
    .floorToDouble();
final _larghezzaGriglia = _larghezzaCella * _colonne;
final _altezzaGriglia = _altezzaCella * _righe;

const _inchiostro = PdfColor.fromInt(0xFF1A1A1A);
const _grigio = PdfColor.fromInt(0xFF5C5C5C);
const _taglio = PdfColor.fromInt(0xFF9A9A9A);

const _lato = 14.0;
const _qr = 44.0;

/// Le linee tratteggiate: bordo e separazioni dei biglietti.
void _disegnaTaglio(PdfGraphics canvas, PdfPoint size) {
  canvas
    ..setStrokeColor(_taglio)
    ..setLineWidth(0.5)
    ..setLineDashPattern([4, 3]);
  for (var c = 0; c <= _colonne; c++) {
    final x = c * _larghezzaCella;
    canvas
      ..moveTo(x, 0)
      ..lineTo(x, size.y)
      ..strokePath();
  }
  for (var r = 0; r <= _righe; r++) {
    final y = r * _altezzaCella;
    canvas
      ..moveTo(0, y)
      ..lineTo(size.x, y)
      ..strokePath();
  }
  canvas.setLineDashPattern();
}

pw.Widget _cella(
  BigliettoCodice? b, {
  required String nomeClub,
  required String? indirizzo,
  required pw.ImageProvider? logo,
}) {
  return pw.SizedBox(
    width: _larghezzaCella,
    height: _altezzaCella,
    child: b == null
        ? null
        : pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: _lato,
              vertical: 10,
            ),
            child: _biglietto(
              b,
              nomeClub: nomeClub,
              indirizzo: indirizzo,
              logo: logo,
            ),
          ),
  );
}

pw.Widget _biglietto(
  BigliettoCodice b, {
  required String nomeClub,
  required String? indirizzo,
  required pw.ImageProvider? logo,
}) {
  final squadra = b.squadra;
  final intestazione = (squadra == null || squadra.trim().isEmpty)
      ? nomeClub
      : '$nomeClub · $squadra';
  final dove = indirizzo == null
      ? "Apri l'app WaterTactics"
      : 'Apri ${_senzaProtocollo(indirizzo)}';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.ConstrainedBox(
                  constraints: const pw.BoxConstraints(
                    maxHeight: 16,
                    maxWidth: 48,
                  ),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 5),
              ],
              pw.Expanded(
                child: pw.Text(
                  intestazione,
                  maxLines: 1,
                  style: const pw.TextStyle(fontSize: 8, color: _grigio),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              b.cognomeNome,
              style: const pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _inchiostro,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              formattaCodice(b.codice),
              style: const pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2.5,
                color: _inchiostro,
              ),
            ),
          ),
        ],
      ),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '1. $dove e tocca «Registrati»',
                  style: const pw.TextStyle(fontSize: 8, color: _inchiostro),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '2. Scegli «Sono un atleta»',
                  style: const pw.TextStyle(fontSize: 8, color: _inchiostro),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '3. Scrivi questo codice e i tuoi dati',
                  style: const pw.TextStyle(fontSize: 8, color: _inchiostro),
                ),
              ],
            ),
          ),
          if (indirizzo != null) ...[
            pw.SizedBox(width: 8),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: indirizzo,
              width: _qr,
              height: _qr,
              drawText: false,
            ),
          ],
        ],
      ),
      pw.Text(
        'Vale fino al ${dataNumerica(b.scade)}, una volta sola. '
        'È personale: non darlo ad altri.',
        style: const pw.TextStyle(fontSize: 7, color: _grigio),
      ),
    ],
  );
}

String _senzaProtocollo(String indirizzo) =>
    indirizzo.replaceFirst(RegExp(r'^https?://'), '');
