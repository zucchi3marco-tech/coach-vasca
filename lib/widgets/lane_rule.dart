import 'package:flutter/material.dart';

/// Il filetto di corsia — vedi DESIGN.md sezione 6: un filetto verticale
/// di 3px sul lato sinistro di un blocco, colorato secondo l'informazione
/// che porta. Si usa solo quando porta un'informazione reale (colore di
/// zona, tipo di sessione, "in corso"), mai come decorazione.
class LaneRule extends StatelessWidget {
  const LaneRule({required this.colore, required this.child, super.key});

  final Color colore;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight: senza, il Row con CrossAxisAlignment.stretch va in
    // crash appena finisce dentro una lista (ListView/SliverList), che gli
    // passa un'altezza illimitata — lo stretch non ha un'altezza a cui
    // riferirsi. IntrinsicHeight gliene dà una concreta, presa dal
    // contenuto, così il filetto può ancora estendersi per tutta l'altezza
    // della card.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 3, color: colore),
          Expanded(child: child),
        ],
      ),
    );
  }
}
