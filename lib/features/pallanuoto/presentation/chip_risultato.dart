import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../application/pallanuoto_providers.dart';
import '../domain/partita.dart';
import '../domain/risultato_partita.dart';

/// Il risultato di una partita giocata, dagli eventi registrati dal
/// vivo: verde se vinta, rosso se persa. Niente se non ci sono gol
/// registrati (partita seguita senza il campo live).
class ChipRisultato extends ConsumerWidget {
  const ChipRisultato({required this.partita, super.key});

  final Partita partita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventi = ref.watch(eventiPartitaListProvider(partita.id)).value;
    final r = eventi == null ? null : risultatoPartita(eventi, partita);
    if (r == null) return const SizedBox.shrink();
    final colori = context.colori;
    final nostri = partita.inCasa ? r.golCasa : r.golTrasferta;
    final loro = partita.inCasa ? r.golTrasferta : r.golCasa;
    final colore = nostri > loro
        ? colori.ok
        : nostri < loro
        ? colori.rosso
        : colori.testoSecondario;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${r.golCasa}–${r.golTrasferta}',
        style: AppTypography.numerica(
          AppTypography.corpoForte.copyWith(
            color: colore,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
