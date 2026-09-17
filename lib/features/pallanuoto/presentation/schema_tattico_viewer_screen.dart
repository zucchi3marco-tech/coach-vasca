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
        giocatoriIniziali: [
          for (final p in schema.giocatori) Offset(p.$1, p.$2),
        ],
        frecceIniziali: [
          for (final f in schema.frecce)
            (Offset(f.$1.$1, f.$1.$2), Offset(f.$2.$1, f.$2.$2)),
        ],
      ),
    );
  }
}
