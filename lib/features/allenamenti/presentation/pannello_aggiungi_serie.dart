import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../domain/testo_allenamento.dart';
import 'serie_labels.dart';

/// Apre il pannello dal basso per aggiungere serie. Tutto quello che prima
/// stava in una barra fissa molto alta (scelta del blocco, campo rapido,
/// "scrivi l'allenamento", "serie completa") sta qui, e la barra non c'è
/// più: le serie occupano lo schermo. La riga si legge come una riga di
/// "Scrivi l'allenamento" ([leggiRigaSerie]).
///
/// [aggiungiRapida] riceve la serie già interpretata e il blocco scelto; se
/// non lancia, il pannello resta aperto per aggiungerne altre. Il blocco
/// scelto si ricorda fra un'apertura e l'altra tramite [onBloccoCambiato].
Future<void> mostraPannelloAggiungiSerie(
  BuildContext context, {
  required String bloccoIniziale,
  required ValueChanged<String> onBloccoCambiato,
  required Future<void> Function(List<SerieScritta> serie) aggiungiRapida,
  required VoidCallback onScrivi,
  required VoidCallback onSerieCompleta,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => PannelloAggiungiSerie(
      bloccoIniziale: bloccoIniziale,
      onBloccoCambiato: onBloccoCambiato,
      aggiungiRapida: aggiungiRapida,
      onScrivi: () {
        Navigator.of(sheetContext).pop();
        onScrivi();
      },
      onSerieCompleta: () {
        Navigator.of(sheetContext).pop();
        onSerieCompleta();
      },
    ),
  );
}

class PannelloAggiungiSerie extends StatefulWidget {
  const PannelloAggiungiSerie({
    required this.bloccoIniziale,
    required this.onBloccoCambiato,
    required this.aggiungiRapida,
    required this.onScrivi,
    required this.onSerieCompleta,
    super.key,
  });

  final String bloccoIniziale;
  final ValueChanged<String> onBloccoCambiato;

  /// Riceve le serie già nel blocco scelto.
  final Future<void> Function(List<SerieScritta> serie) aggiungiRapida;
  final VoidCallback onScrivi;
  final VoidCallback onSerieCompleta;

  @override
  State<PannelloAggiungiSerie> createState() => _PannelloAggiungiSerieState();
}

class _PannelloAggiungiSerieState extends State<PannelloAggiungiSerie> {
  final _controller = TextEditingController();
  late String _blocco = widget.bloccoIniziale;
  bool _inCorso = false;
  String? _ultimaAggiunta;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _descrizione(List<SerieScritta> serie) => [
    if (serie.length > 1) titoloGruppo(serie) else titoloSerie(serie.single),
    ...dettagliSerie(serie.first),
    if (serie.first.note case final nota?) 'nota: $nota',
  ].join(' · ');

  String _aiuto(List<SerieScritta>? parsed) {
    if (_controller.text.trim().isEmpty) {
      return _ultimaAggiunta != null
          ? 'Aggiunta: $_ultimaAggiunta. Scrivi la prossima.'
          : "Es. 10x100 A2 1:25 r15 sl, 400 gambe pinne, 10' remate, "
                'oppure 50-100-200-100-50 sl';
    }
    if (parsed == null) {
      return 'Scrivi ripetute×distanza (es. 10x100), una distanza (400), '
          "una durata (10') oppure una piramide (es. 50-100-200-100-50)";
    }
    return '→ ${_descrizione(parsed)}';
  }

  Future<void> _aggiungi() async {
    final parsed = leggiRigaSerie(_controller.text, blocco: _blocco);
    if (parsed == null || _inCorso) return;
    setState(() => _inCorso = true);
    try {
      await widget.aggiungiRapida(parsed);
      if (!mounted) return;
      setState(() {
        _ultimaAggiunta = _descrizione(parsed);
        _controller.clear();
      });
    } catch (_) {
      // L'errore lo mostra chi ha passato aggiungiRapida: qui il testo
      // resta nel campo per riprovare.
    } finally {
      if (mounted) setState(() => _inCorso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final parsed = leggiRigaSerie(_controller.text, blocco: _blocco);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aggiungi serie',
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final b in ordineBlocchi)
                  TonalChip(
                    etichetta: labelBloccoBreve(b),
                    selezionato: _blocco == b,
                    onSelezionato: (_) {
                      setState(() => _blocco = b);
                      widget.onBloccoCambiato(b);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            AppTextField(
              etichetta: 'Scrivi la serie',
              controller: _controller,
              aiuto: _aiuto(parsed),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _aggiungi(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle),
                tooltip: 'Aggiungi',
                color: parsed != null ? colori.azione : colori.testoTenue,
                onPressed: parsed != null && !_inCorso ? _aggiungi : null,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            SecondaryButton(
              label: "Scrivi tutto l'allenamento",
              icon: Icons.edit_note,
              onPressed: widget.onScrivi,
            ),
            const SizedBox(height: AppSpacing.s8),
            SecondaryButton(
              label: 'Serie completa (tutti i campi)',
              icon: Icons.list_alt,
              onPressed: widget.onSerieCompleta,
            ),
          ],
        ),
      ),
    );
  }
}
