import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/utils/error_messages.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/colori_app.dart';
import 'csv_export.dart';
import 'csv_preview_screen.dart';
import 'pdf_export.dart';

/// Mostra la scelta PDF/CSV e porta a termine l'esportazione. [caricaDati]
/// può fare chiamate di rete (es. per raccogliere le serie di più
/// allenamenti in una settimana): viene eseguito dietro un overlay di
/// caricamento non annullabile.
Future<void> mostraMenuExport(
  BuildContext context, {
  required String titoloDocumento,
  required Future<List<AllenamentoConSerie>> Function() caricaDati,
  Map<String, String> nomiGruppi = const {},
}) async {
  final colori = context.colori;
  final scelta = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(
                'Esporta PDF',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
              onTap: () => Navigator.of(context).pop('pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(
                'Esporta CSV',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
              onTap: () => Navigator.of(context).pop('csv'),
            ),
          ],
        ),
      ),
    ),
  );
  if (scelta == null || !context.mounted) return;

  final dati = await _conCaricamento(context, caricaDati);
  if (dati == null || !context.mounted) return;
  if (dati.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nessun allenamento da esportare')),
    );
    return;
  }

  if (scelta == 'pdf') {
    await Printing.layoutPdf(
      onLayout: (_) => generaPdf(dati, nomiGruppi: nomiGruppi),
    );
  } else {
    final csv = generaCsv(dati, nomiGruppi: nomiGruppi);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CsvPreviewScreen(titolo: titoloDocumento, csv: csv),
      ),
    );
  }
}

Future<T?> _conCaricamento<T>(
  BuildContext context,
  Future<T> Function() azione,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final risultato = await azione();
    if (context.mounted) Navigator.of(context).pop();
    return risultato;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore nell'esportazione: ${messaggioErrore(e)}"),
        ),
      );
    }
    return null;
  }
}
