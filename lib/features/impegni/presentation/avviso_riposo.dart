import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../application/impegni_providers.dart';
import '../domain/impegno.dart';

/// Sotto la data di un allenamento: «È un giorno di riposo» quando la
/// squadra [gruppoId] (o tutto il club) ha un riposo quel giorno. Si salva
/// lo stesso (scelta del coach); senza riposo non occupa spazio.
class AvvisoRiposo extends ConsumerWidget {
  const AvvisoRiposo({
    required this.clubId,
    required this.data,
    required this.gruppoId,
    super.key,
  });

  final String clubId;
  final DateTime data;
  final String? gruppoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impegni = ref.watch(impegniListProvider(clubId)).value ?? const [];
    final riposo = riposoNelGiorno(impegni, data, gruppoId: gruppoId);
    if (riposo == null) return const SizedBox.shrink();
    final colori = context.colori;
    final nome = riposo.titolo == riposo.tipo.etichetta
        ? ''
        : ' («${riposo.titolo}»)';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.bedtime_outlined, size: 18, color: colori.attenzione),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            '${giornoMese(data)} è un giorno di riposo$nome. Puoi salvare '
            'lo stesso.',
            style: AppTypography.piccolo.copyWith(color: colori.testo),
          ),
        ),
      ],
    );
  }
}
