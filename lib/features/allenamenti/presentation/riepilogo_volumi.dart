import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../domain/serie.dart';
import 'serie_labels.dart';

/// 3200 -> "3.200".
String formattaMetri(int metri) {
  final cifre = metri.abs().toString();
  final gruppi = <String>[];
  for (var fine = cifre.length; fine > 0; fine -= 3) {
    gruppi.insert(0, cifre.substring(fine - 3 < 0 ? 0 : fine - 3, fine));
  }
  return '${metri < 0 ? '-' : ''}${gruppi.join('.')}';
}

/// Riepilogo di un allenamento in poche righe: il totale, i metri per
/// blocco (solo quelli con serie) e il materiale. Sostituisce il vecchio
/// riepilogo a più righe, che su smartphone toglieva spazio alle serie.
class RiepilogoVolumi extends StatelessWidget {
  const RiepilogoVolumi({required this.serie, super.key});

  final List<Serie> serie;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final totale = serie.fold<int>(0, (t, s) => t + s.distanzaTotaleM);
    final perBlocco = <String, int>{};
    for (final s in serie) {
      perBlocco[s.blocco] = (perBlocco[s.blocco] ?? 0) + s.distanzaTotaleM;
    }
    final blocchi = [
      for (final b in ordineBlocchi)
        if (perBlocco[b] != null)
          '${labelBloccoBreve(b)} ${formattaMetri(perBlocco[b]!)}',
    ];
    final materiale = {
      for (final s in serie)
        if (s.attrezzatura != null && s.attrezzatura!.trim().isNotEmpty)
          s.attrezzatura!.trim(),
    }.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${formattaMetri(totale)} m',
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
              if (blocchi.isNotEmpty)
                TextSpan(
                  text: '   ${blocchi.join(' · ')}',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
            ],
          ),
        ),
        if (materiale.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Materiale: ${materiale.join(', ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ],
      ],
    );
  }
}
