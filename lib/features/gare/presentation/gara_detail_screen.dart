import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/gare_providers.dart';
import '../domain/gara.dart';
import 'gara_form_screen.dart';

/// Scheda di una gara: dati della manifestazione, poi (nei passi
/// successivi) gli atleti iscritti e i loro risultati. Legge la gara
/// dall'elenco, così le modifiche dal form si vedono subito.
class GaraDetailScreen extends ConsumerWidget {
  const GaraDetailScreen({required this.gara, super.key});

  final Gara gara;

  static const _nomiGiorni = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  String _formattaData(DateTime d) =>
      '${_nomiGiorni[d.weekday - 1]} ${d.day}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final aggiornata = ref
        .watch(gareListProvider(gara.clubId))
        .value
        ?.where((g) => g.id == gara.id)
        .firstOrNull;
    final g = aggiornata ?? gara;
    final nomeGruppo = {
      for (final x in ref.watch(gruppiListProvider(g.clubId)).value ?? [])
        x.id: x.nome,
    }[g.gruppoId];

    Widget riga(IconData icona, String testo) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        children: [
          Icon(icona, size: 20, color: colori.testoSecondario),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              testo,
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ),
        ],
      ),
    );

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(g.nome),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final esito = await Navigator.of(context).push<Object?>(
                MaterialPageRoute(
                  builder: (_) => GaraFormScreen(clubId: g.clubId, gara: g),
                ),
              );
              // Gara eliminata dal form: si esce anche dalla sua scheda.
              if (esito == GaraFormScreen.esitoEliminata && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifica'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          riga(Icons.calendar_today_outlined, _formattaData(g.data)),
          if (g.ora != null && g.ora!.isNotEmpty)
            riga(Icons.access_time, g.ora!),
          if (g.luogo != null && g.luogo!.isNotEmpty)
            riga(Icons.place_outlined, g.luogo!),
          riga(
            Icons.groups_outlined,
            g.diClub ? 'Tutto il club' : (nomeGruppo ?? 'Gruppo'),
          ),
          if (g.note != null && g.note!.isNotEmpty)
            riga(Icons.notes_outlined, g.note!),
        ],
      ),
    );
  }
}
