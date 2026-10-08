import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../domain/schema_tattico.dart';
import 'esporta_schema.dart';
import 'water_polo_tactics_board.dart';
import '../../../widgets/nascondi_barra_club.dart';

/// Vista in sola lettura di uno schema tattico salvato dall'allenatore:
/// sfoglia i passi come [SchemaTatticoPlayer], compreso il tasto play
/// per vederli in movimento uno dopo l'altro.
class SchemaTatticoViewerScreen extends StatelessWidget {
  const SchemaTatticoViewerScreen({required this.schema, super.key});

  final SchemaTattico schema;

  @override
  Widget build(BuildContext context) =>
      NascondiBarraClub(child: _costruisci(context));

  Widget _costruisci(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(schema.titolo),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Esporta lo schema',
            onPressed: () => mostraEsportaSchema(
              context,
              titolo: schema.titolo,
              categoria: schema.categoria,
              campo: CampoLavagna.values.byName(schema.campo),
              passi: [for (final p in schema.passi) passoLavagnaDaSchema(p)],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8),
        child: SchemaTatticoPlayer(
          campo: CampoLavagna.values.byName(schema.campo),
          passi: [
            for (final passo in schema.passi) passoLavagnaDaSchema(passo),
          ],
        ),
      ),
    );
  }
}
