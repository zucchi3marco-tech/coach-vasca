import 'package:flutter/material.dart';

import '../../../widgets/app_scaffold.dart';
import '../domain/schema_tattico.dart';
import 'water_polo_tactics_board.dart';

/// Vista in sola lettura di uno schema tattico salvato dall'allenatore
/// — stessa resa grafica di [WaterPoloTacticsBoard], senza i controlli
/// di modifica (li nasconde [WaterPoloTacticsBoard.modificabile]).
class SchemaTatticoViewerScreen extends StatelessWidget {
  const SchemaTatticoViewerScreen({required this.schema, super.key});

  final SchemaTattico schema;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(schema.titolo)),
      body: WaterPoloTacticsBoard(
        modificabile: false,
        campo: CampoLavagna.values.byName(schema.campo),
        giocatoriIniziali: [
          for (final g in schema.giocatori)
            GiocatoreLavagna(
              posizione: Offset(g.punto.$1, g.punto.$2),
              colore: ColoreLavagna.values.byName(g.colore),
            ),
        ],
        frecceIniziali: [
          for (final f in schema.frecce)
            FrecciaLavagna(
              inizio: Offset(f.inizio.$1, f.inizio.$2),
              fine: Offset(f.fine.$1, f.fine.$2),
              colore: ColoreLavagna.values.byName(f.colore),
            ),
        ],
      ),
    );
  }
}
