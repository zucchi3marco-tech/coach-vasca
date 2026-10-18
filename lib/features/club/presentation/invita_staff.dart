import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/condivisione/condividi_testo.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../data/membri_club_repository.dart';
import '../domain/ruolo_club.dart';

/// Invita un allenatore o un assistente: il foglio "Chi inviti?", il codice
/// creato sul server e il dialogo per mandarlo. Torna il codice, o null se
/// si è annullato o se non si è potuto creare (in quel caso un avviso dice
/// perché).
///
/// [onOccupato] avvisa chi chiama mentre il codice si sta creando (`true`) e
/// quando ha finito (`false`), per tenere fermi i suoi pulsanti.
/// [onCodiceCreato] dice chi chiama che il codice c'è e per quale ruolo, prima
/// ancora di mostrarlo.
Future<String?> invitaStaff(
  BuildContext context,
  WidgetRef ref, {
  required String clubId,
  required String clubNome,
  ValueChanged<bool>? onOccupato,
  void Function(RuoloClub ruolo, String codice)? onCodiceCreato,
}) async {
  final ruolo = await showModalBottomSheet<RuoloClub>(
    context: context,
    showDragHandle: true,
    builder: (_) => const ScegliRuoloInvito(),
  );
  if (ruolo == null || !context.mounted) return null;
  final repository = ref.read(membriClubRepositoryProvider);
  String codice;
  onOccupato?.call(true);
  try {
    codice = await repository.generaInvito(clubId, ruolo);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Il codice non è stato creato. ${messaggioErrore(e)}'),
        ),
      );
    }
    return null;
  } finally {
    onOccupato?.call(false);
  }
  onCodiceCreato?.call(ruolo, codice);
  if (!context.mounted) return codice;
  await showDialog<void>(
    context: context,
    builder: (_) =>
        DialogoCodiceInvito(codice: codice, ruolo: ruolo, clubNome: clubNome),
  );
  return codice;
}

/// Il foglio "Chi inviti?": allenatore o assistente. Torna il ruolo scelto.
class ScegliRuoloInvito extends StatelessWidget {
  const ScegliRuoloInvito({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi inviti?',
              style: AppTypography.sezione.copyWith(
                color: context.colori.testo,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final ruolo in const [
              RuoloClub.allenatore,
              RuoloClub.assistente,
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ruolo.etichetta),
                subtitle: Text(ruolo.descrizione),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(ruolo),
              ),
          ],
        ),
      ),
    );
  }
}

/// Il codice appena creato, da copiare o mandare.
class DialogoCodiceInvito extends StatelessWidget {
  const DialogoCodiceInvito({
    required this.codice,
    required this.ruolo,
    required this.clubNome,
    super.key,
  });

  final String codice;
  final RuoloClub ruolo;
  final String clubNome;

  String get _testoInvito =>
      'Ti invito in $clubNome su WaterTactics come '
      '${ruolo.etichetta.toLowerCase()}. Registrati come allenatore e '
      'scegli «Ho un codice da allenatore»: $codice';

  Future<void> _copia(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: codice));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Codice copiato')));
  }

  Future<void> _condividi(BuildContext context) async {
    final condiviso = await condividiTesto(_testoInvito);
    if (condiviso || !context.mounted) return;
    // Senza il foglio "Condividi" si copia il messaggio intero.
    await Clipboard.setData(ClipboardData(text: _testoInvito));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Messaggio copiato')));
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AlertDialog(
      title: Text('Codice per ${ruolo.etichetta.toLowerCase()}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.s16,
              horizontal: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              color: colori.superficieAlt,
              borderRadius: BorderRadius.circular(AppRadius.controllo),
              border: Border.all(color: colori.linea),
            ),
            child: SelectableText(
              codice,
              textAlign: TextAlign.center,
              style: AppTypography.numeroMedio.copyWith(
                color: colori.testo,
                fontFamily: 'monospace',
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Vale 7 giorni, una volta sola.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          PrimaryButton(
            label: 'Condividi',
            icon: Icons.ios_share,
            onPressed: () => _condividi(context),
          ),
          const SizedBox(height: AppSpacing.s8),
          SecondaryButton(
            label: 'Copia',
            icon: Icons.copy_outlined,
            onPressed: () => _copia(context),
          ),
        ],
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
