import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../domain/schema_tattico.dart';
import 'water_polo_tactics_board.dart';

/// Vista in sola lettura di uno schema tattico salvato dall'allenatore:
/// sfoglia i passi come [SchemaTatticoPlayer], compreso il tasto play
/// per vederli in movimento uno dopo l'altro.
class SchemaTatticoViewerScreen extends StatelessWidget {
  const SchemaTatticoViewerScreen({required this.schema, super.key});

  final SchemaTattico schema;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: Text(schema.titolo)),
      body: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8),
        child: SchemaTatticoPlayer(
          campo: CampoLavagna.values.byName(schema.campo),
          passi: [
            for (final passo in schema.passi)
              (
                giocatori: [
                  for (final g in passo.giocatori)
                    GiocatoreLavagna(
                      posizione: Offset(g.punto.$1, g.punto.$2),
                      colore: ColoreLavagna.values.byName(g.colore),
                    ),
                ],
                frecce: [
                  for (final f in passo.frecce)
                    FrecciaLavagna(
                      inizio: Offset(f.inizio.$1, f.inizio.$2),
                      fine: Offset(f.fine.$1, f.fine.$2),
                      colore: ColoreLavagna.values.byName(f.colore),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
