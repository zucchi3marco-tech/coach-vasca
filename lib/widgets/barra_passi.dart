import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/colori_app.dart';

/// Come sta un passo in [BarraPassi].
enum StatoPassoBarra { fatto, corrente, daFare }

/// Una fila di segmenti, uno per passo di un percorso guidato (es. la
/// configurazione di un club nuovo): fatti in `ok`, quello di adesso in
/// `azione`, gli altri in `linea`. Non porta testo: il numero del passo lo
/// scrive la schermata ("Passo 2 di 5") e [etichetta] lo ripete per chi usa
/// uno screen reader.
class BarraPassi extends StatelessWidget {
  const BarraPassi({required this.passi, this.etichetta, super.key});

  final List<StatoPassoBarra> passi;
  final String? etichetta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final barra = Row(
      children: [
        for (var i = 0; i < passi.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Container(
              height: AppSpacing.s4,
              decoration: BoxDecoration(
                color: switch (passi[i]) {
                  StatoPassoBarra.fatto => colori.ok,
                  StatoPassoBarra.corrente => colori.azione,
                  StatoPassoBarra.daFare => colori.linea,
                },
                borderRadius: BorderRadius.circular(AppRadius.pillola),
              ),
            ),
          ),
        ],
      ],
    );
    if (etichetta == null) return barra;
    return Semantics(label: etichetta, excludeSemantics: true, child: barra);
  }
}
