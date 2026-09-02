import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Il CSV non ha un salvataggio nativo su file cross-platform senza
/// dipendenze aggiuntive: si mostra il testo pronto da copiare e incollare
/// in Excel/Fogli Google, che copre lo stesso bisogno con meno rischio.
class CsvPreviewScreen extends StatelessWidget {
  const CsvPreviewScreen({required this.titolo, required this.csv, super.key});

  final String titolo;
  final String csv;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titolo),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copia negli appunti',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copiato negli appunti')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          csv,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}
