import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Intestazione di un gruppo (form, elenco): stile `sezione` con un
/// filetto sotto — vedi DESIGN.md sezione 13, "Form". Con [spiegazione]
/// mostra anche un'iconcina "i" che apre una spiegazione a comparsa
/// (mai automatica: solo su tocco, per chi la vuole leggere).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.titolo, {this.spiegazione, super.key});

  final String titolo;
  final String? spiegazione;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titolo,
                style: AppTypography.sezione.copyWith(color: colori.testo),
              ),
            ),
            if (spiegazione != null)
              PulsanteSpiegazione(titolo: titolo, spiegazione: spiegazione!),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Divider(color: colori.linea, height: 1),
      ],
    );
  }
}

/// Iconcina "i" che apre una spiegazione in un dialogo — riusabile
/// anche fuori da [SectionHeader] (es. dentro un widget che ha già la
/// propria intestazione, come la lavagna tattica).
class PulsanteSpiegazione extends StatelessWidget {
  const PulsanteSpiegazione({
    required this.titolo,
    required this.spiegazione,
    super.key,
  });

  final String titolo;
  final String spiegazione;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline, size: 20),
      tooltip: 'Spiegazione',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(titolo),
          content: Text(spiegazione),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ho capito'),
            ),
          ],
        ),
      ),
    );
  }
}
