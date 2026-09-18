import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../domain/schema_tattico.dart';
import 'water_polo_tactics_board.dart';

/// Vista in sola lettura di uno schema tattico salvato dall'allenatore
/// — stessa resa grafica di [WaterPoloTacticsBoard], senza i controlli
/// di modifica (li nasconde [WaterPoloTacticsBoard.modificabile]). Se lo
/// schema ha più passi, un selettore sopra la lavagna permette di
/// sfogliarli come una piccola sequenza.
class SchemaTatticoViewerScreen extends StatefulWidget {
  const SchemaTatticoViewerScreen({required this.schema, super.key});

  final SchemaTattico schema;

  @override
  State<SchemaTatticoViewerScreen> createState() =>
      _SchemaTatticoViewerScreenState();
}

class _SchemaTatticoViewerScreenState extends State<SchemaTatticoViewerScreen> {
  int _passoAttuale = 0;

  @override
  Widget build(BuildContext context) {
    final passi = widget.schema.passi;
    final passoAttuale = passi[_passoAttuale];

    return AppScaffold(
      appBar: AppBar(title: Text(widget.schema.titolo)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (passi.length > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Passo precedente',
                  onPressed: _passoAttuale == 0
                      ? null
                      : () => setState(() => _passoAttuale--),
                ),
                Text(
                  'Passo ${_passoAttuale + 1} di ${passi.length}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Passo successivo',
                  onPressed: _passoAttuale == passi.length - 1
                      ? null
                      : () => setState(() => _passoAttuale++),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.s8,
              children: [
                for (var i = 0; i < passi.length; i++)
                  ChoiceChip(
                    label: Text('${i + 1}'),
                    selected: i == _passoAttuale,
                    onSelected: (_) => setState(() => _passoAttuale = i),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          WaterPoloTacticsBoard(
            key: ValueKey(_passoAttuale),
            modificabile: false,
            campo: CampoLavagna.values.byName(widget.schema.campo),
            giocatoriIniziali: [
              for (final g in passoAttuale.giocatori)
                GiocatoreLavagna(
                  posizione: Offset(g.punto.$1, g.punto.$2),
                  colore: ColoreLavagna.values.byName(g.colore),
                ),
            ],
            frecceIniziali: [
              for (final f in passoAttuale.frecce)
                FrecciaLavagna(
                  inizio: Offset(f.inizio.$1, f.inizio.$2),
                  fine: Offset(f.fine.$1, f.fine.$2),
                  colore: ColoreLavagna.values.byName(f.colore),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
