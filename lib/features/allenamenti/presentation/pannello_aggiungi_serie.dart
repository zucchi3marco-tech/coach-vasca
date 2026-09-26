import 'package:flutter/material.dart';

import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../domain/serie_rapida.dart';
import 'serie_labels.dart';

/// Apre il pannello dal basso per aggiungere serie. Tutto quello che prima
/// stava in una barra fissa molto alta (scelta del blocco, campo rapido,
/// "scrivi o detta", "serie completa") sta qui, e la barra non c'è più: le
/// serie occupano lo schermo.
///
/// [aggiungiRapida] riceve la serie già interpretata e il blocco scelto; se
/// non lancia, il pannello resta aperto per aggiungerne altre. Il blocco
/// scelto si ricorda fra un'apertura e l'altra tramite [onBloccoCambiato].
Future<void> mostraPannelloAggiungiSerie(
  BuildContext context, {
  required String bloccoIniziale,
  required ValueChanged<String> onBloccoCambiato,
  required Future<void> Function(SerieRapida serie, String blocco)
  aggiungiRapida,
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
  final Future<void> Function(SerieRapida serie, String blocco) aggiungiRapida;
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

  String _descrizione(SerieRapida s) {
    final parti = <String>[
      '${s.ripetute} × ${s.distanzaM}m ${labelStile(s.stile)}',
    ];
    if (s.zona != null) parti.add('zona ${s.zona}');
    if (s.passoObiettivoS != null) {
      parti.add('passo ${formatPaceSeconds(s.passoObiettivoS!)}/100m');
    }
    if (s.recuperoS != null) parti.add("rec ${s.recuperoS}''");
    return parti.join(' · ');
  }

  String _aiuto(SerieRapida? parsed) {
    if (_controller.text.trim().isEmpty) {
      return _ultimaAggiunta != null
          ? 'Aggiunta: $_ultimaAggiunta. Scrivi la prossima.'
          : 'Es. 10x100 A2 1:25 r15 sl';
    }
    if (parsed == null) return 'Scrivi almeno ripetute×distanza (es. 10x100)';
    return '→ ${_descrizione(parsed)}';
  }

  Future<void> _aggiungi() async {
    final parsed = parseSerieRapida(_controller.text);
    if (parsed == null || _inCorso) return;
    setState(() => _inCorso = true);
    try {
      await widget.aggiungiRapida(parsed, _blocco);
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
    final parsed = parseSerieRapida(_controller.text);
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
              label: 'Scrivi o detta più serie insieme',
              icon: Icons.mic_none_outlined,
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
