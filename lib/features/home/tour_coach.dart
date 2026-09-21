import 'package:flutter/material.dart';

import '../../core/onboarding/onboarding_coach.dart';
import '../../theme/app_spacing.dart';
import 'voci_home.dart';

/// Il tour di benvenuto dell'allenatore: un dialogo con le voci della
/// barra di navigazione spiegate. Si mostra da solo al primo accesso e si
/// rivede a comando dal menu ("Rivedi la guida"). [context] deve stare
/// sotto il Navigator.
Future<void> mostraTourCoach(BuildContext context, String? sport) async {
  // Segnato come visto subito, prima del tocco su "Ho capito": anche
  // chiudendo il dialogo toccando fuori o con "indietro" non deve
  // ripresentarsi al prossimo avvio.
  await segnaOnboardingCoachVisto();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Benvenuto su WaterTactics'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s16),
              child: Text(
                'In alto trovi sempre il nome del tuo club: tocca il logo '
                'per tornare alla home. Dal menu ☰ cambi gruppo, leggi le '
                'notifiche e rivedi questa guida.',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
            ),
            for (final voce in vociHome(
              sport,
            ).map((v) => destinazioneHome(v, sport)))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(voce.icona),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voce.etichetta,
                            style: Theme.of(dialogContext).textTheme.titleSmall,
                          ),
                          Text(
                            voce.guida,
                            style: Theme.of(dialogContext).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Ho capito, iniziamo'),
        ),
      ],
    ),
  );
}
