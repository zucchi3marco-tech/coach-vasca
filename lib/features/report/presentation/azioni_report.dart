import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/scarica_file.dart';
import '../../export/marchio_pdf.dart';
import '../domain/report_atleta.dart';
import '../domain/report_squadra.dart';
import '../pdf/report_atleta_pdf.dart';
import '../pdf/report_squadra_pdf.dart';

/// Come si fa il PDF e cosa farne quando è pronto. Dietro un provider
/// perché nei test non c'è né un browser né il foglio di condivisione.
class AzioniReport {
  const AzioniReport();

  Future<Uint8List> creaPdf(ReportAtleta report, MarchioPdf? marchio) =>
      generaReportAtletaPdf(report, marchio: marchio);

  Future<Uint8List> creaPdfSquadra(ReportSquadra report, MarchioPdf? marchio) =>
      generaReportSquadraPdf(report, marchio: marchio);

  /// Sul computer si scarica, sul telefono si apre la condivisione.
  Future<void> consegna(Uint8List bytes, String nomeFile) async {
    if (scaricaFileDisponibile) {
      scaricaFile(bytes, nomeFile, mimeType: 'application/pdf');
    } else {
      await Printing.sharePdf(bytes: bytes, filename: nomeFile);
    }
  }
}

final azioniReportProvider = Provider<AzioniReport>(
  (ref) => const AzioniReport(),
);

/// "report-rossi-luca-2026-10-27.pdf".
String nomeFileReport(String nome, DateTime giorno) {
  const accenti = {
    'à': 'a', 'á': 'a', 'è': 'e', 'é': 'e', 'ì': 'i', 'í': 'i', //
    'ò': 'o', 'ó': 'o', 'ù': 'u', 'ú': 'u',
  };
  final semplice =
      [for (final c in nome.toLowerCase().split('')) accenti[c] ?? c]
          .join()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
  final data =
      '${giorno.year}-${giorno.month.toString().padLeft(2, '0')}-'
      '${giorno.day.toString().padLeft(2, '0')}';
  return 'report-${semplice.isEmpty ? 'atleta' : semplice}-$data.pdf';
}
