import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// PDF di uno schema tattico, da stampare o mandare alla squadra: titolo,
/// categoria, poi i passi come immagini, due per riga, e sotto la legenda
/// delle frecce usate. Le immagini le disegna la lavagna
/// (`immaginePasso`), qui si impagina soltanto.
Future<Uint8List> generaSchemaPdf({
  required String titolo,
  required String categoria,
  required String campo,
  required List<Uint8List> immaginiPassi,
  List<String> legenda = const [],
}) async {
  final doc = pw.Document(title: titolo, creator: 'WaterTactics');
  const margine = 28.0;
  const spazio = 12.0;
  final larghezzaPasso = (PdfPageFormat.a4.width - 2 * margine - spazio) / 2;
  final passi = immaginiPassi.length;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(margine),
      build: (context) => [
        pw.Header(level: 0, text: titolo),
        pw.Text(
          [
            if (categoria.isNotEmpty) categoria,
            campo,
            passi == 1 ? '1 passo' : '$passi passi',
          ].join(' · '),
        ),
        pw.SizedBox(height: spazio),
        pw.Wrap(
          spacing: spazio,
          runSpacing: spazio,
          children: [
            for (var i = 0; i < passi; i++)
              pw.SizedBox(
                width: larghezzaPasso,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Passo ${i + 1}',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Image(
                      pw.MemoryImage(immaginiPassi[i]),
                      width: larghezzaPasso,
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (legenda.isNotEmpty) ...[
          pw.SizedBox(height: spazio),
          pw.Text(
            'Frecce: ${legenda.join(' · ')}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ],
    ),
  );
  return doc.save();
}
