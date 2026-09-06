import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold.dart';

/// Il CSV non ha un salvataggio nativo su file cross-platform senza
/// dipendenze aggiuntive: si mostra il testo pronto da copiare e incollare
/// in Excel/Fogli Google, che copre lo stesso bisogno con meno rischio.
///
/// Nota di design: il testo resta monospace per allineare le colonne del
/// CSV — DESIGN.md non prevede un carattere a spaziatura fissa nella
/// scala tipografica, quindi qui si usa `fontFamily: 'monospace'` invece
/// di un token. Dimensione comunque non sotto i 14 (sezione 13).
class CsvPreviewScreen extends StatelessWidget {
  const CsvPreviewScreen({required this.titolo, required this.csv, super.key});

  final String titolo;
  final String csv;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(titolo),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copiato negli appunti')),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined, size: 20),
            label: const Text('Copia'),
          ),
        ],
      ),
      body: SelectableText(
        csv,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: AppColors.testo,
        ),
      ),
    );
  }
}
