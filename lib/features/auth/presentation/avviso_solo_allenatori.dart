import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';

/// "Questa strada è per gli allenatori", con l'uscita per l'atleta che ci
/// è arrivato per sbaglio. Sulla registrazione da allenatore e su "Crea il
/// tuo club" (dove arriva anche chi entra la prima volta con Google):
/// alcuni atleti si erano registrati come allenatori e avevano creato un
/// club vuoto invece di entrare in quello della squadra.
class AvvisoSoloAllenatori extends StatelessWidget {
  const AvvisoSoloAllenatori({
    required this.onSonoAtleta,
    this.testo =
        'Questa registrazione è per gli allenatori: crea un nuovo club. '
        'Se sei un atleta non serve, entri nel club della tua squadra con '
        'il codice dell\'allenatore.',
    super.key,
  });

  final String testo;
  final VoidCallback onSonoAtleta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s8,
        AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: colori.azioneTenue,
        borderRadius: BorderRadius.circular(AppRadius.controllo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: colori.azione),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  testo,
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onSonoAtleta,
              child: const Text('Sono un atleta, ho un codice'),
            ),
          ),
        ],
      ),
    );
  }
}
