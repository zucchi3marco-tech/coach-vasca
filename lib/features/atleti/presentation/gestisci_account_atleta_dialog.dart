import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../data/atleti_repository.dart';
import '../data/inviti_atleta_repository.dart';
import '../domain/atleta.dart';

/// Dialog per collegare/scollegare l'account di un atleta (FASE 9),
/// raggiunto dal menu della sua riga in elenco.
class GestisciAccountAtletaDialog extends ConsumerStatefulWidget {
  const GestisciAccountAtletaDialog({required this.atleta, super.key});

  final Atleta atleta;

  @override
  ConsumerState<GestisciAccountAtletaDialog> createState() =>
      _GestisciAccountAtletaDialogState();
}

class _GestisciAccountAtletaDialogState
    extends ConsumerState<GestisciAccountAtletaDialog> {
  bool _isLoading = false;
  String? _errore;
  String? _codiceGenerato;

  Future<void> _generaInvito() async {
    setState(() {
      _isLoading = true;
      _errore = null;
    });
    try {
      final codice = await ref
          .read(invitiAtletaRepositoryProvider)
          .generaInvito(widget.atleta.id);
      if (mounted) setState(() => _codiceGenerato = codice);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copiaCodice() async {
    final codice = _codiceGenerato;
    if (codice == null) return;
    await Clipboard.setData(ClipboardData(text: codice));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codice copiato negli appunti')),
      );
    }
  }

  Future<void> _confermaScollega() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scollegare ${widget.atleta.nomeCompleto}?'),
        content: const Text(
          'L\'atleta perderà l\'accesso alla propria area; potrà '
          'ricollegarsi con un nuovo invito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Scollega',
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true) return;

    setState(() {
      _isLoading = true;
      _errore = null;
    });
    try {
      await ref
          .read(atletiRepositoryProvider)
          .scollegaAccount(widget.atleta.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Account atleta'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.atleta.haAccountCollegato) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.ok),
                  const SizedBox(width: AppSpacing.s8),
                  Text('Account collegato', style: AppTypography.corpoForte),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              DangerButton(
                label: 'Scollega account',
                onPressed: _isLoading ? null : _confermaScollega,
              ),
            ] else if (_codiceGenerato != null) ...[
              Text(
                'Condividi questo codice con ${widget.atleta.nomeCompleto}: '
                'valido 7 giorni.',
                style: AppTypography.piccolo,
              ),
              const SizedBox(height: AppSpacing.s12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.superficieTenue,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.raggioControllo,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _codiceGenerato!,
                  style: AppTypography.cifreTabulari(
                    AppTypography.titoloXl,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              SecondaryButton(
                label: 'Copia codice',
                icon: Icons.copy_outlined,
                onPressed: _copiaCodice,
              ),
            ] else ...[
              Text(
                'Nessun account collegato. Genera un invito da condividere '
                'con l\'atleta.',
                style: AppTypography.piccolo,
              ),
              const SizedBox(height: AppSpacing.s16),
              PrimaryButton(
                label: 'Genera invito',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _generaInvito,
              ),
            ],
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}
