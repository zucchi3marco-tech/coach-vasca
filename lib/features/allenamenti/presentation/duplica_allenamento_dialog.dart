import 'package:flutter/material.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_select.dart';
import '../../gruppi/domain/gruppo.dart';
import '../domain/allenamento.dart';

/// Dove copiare un allenamento: il giorno e la squadra (richiesta del
/// coach 2026-10-08: "duplica allenamento per copiarlo in un'altra
/// squadra e poi modificarlo"). `null` se si annulla.
Future<({DateTime data, String? gruppoId})?> chiediDoveDuplicare(
  BuildContext context, {
  required Allenamento allenamento,
  required List<Gruppo> gruppi,
}) {
  var data = allenamento.data;
  // Di solito si copia per un'altra squadra: si propone la prima diversa.
  var gruppoId =
      gruppi.where((g) => g.id != allenamento.gruppoId).firstOrNull?.id ??
      allenamento.gruppoId;
  return showDialog<({DateTime data, String? gruppoId})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, aggiorna) {
        final colori = context.colori;
        return AlertDialog(
          title: const Text('Duplica allenamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSelect<String?>(
                etichetta: 'Squadra',
                value: gruppoId,
                hint: 'Nessun gruppo',
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Nessun gruppo'),
                  ),
                  for (final g in gruppi)
                    DropdownMenuItem(
                      value: g.id,
                      child: Text(
                        g.id == allenamento.gruppoId
                            ? '${g.nome} (questa)'
                            : g.nome,
                      ),
                    ),
                ],
                onChanged: (valore) => aggiorna(() => gruppoId = valore),
              ),
              const SizedBox(height: AppSpacing.s12),
              OutlinedButton.icon(
                onPressed: () async {
                  final scelta = await showDatePicker(
                    context: context,
                    initialDate: data,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (scelta != null) {
                    // Il giorno nuovo, l'ora di prima.
                    aggiorna(
                      () => data = DateTime(
                        scelta.year,
                        scelta.month,
                        scelta.day,
                        data.hour,
                        data.minute,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(dataEstesa(data)),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'Si copiano titolo, note e tutte le serie. Recuperi e '
                'ripartenze restano questi: controllali per la squadra nuova.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop((data: data, gruppoId: gruppoId)),
              child: const Text('Duplica'),
            ),
          ],
        );
      },
    ),
  );
}
