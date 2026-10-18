import 'package:flutter/material.dart';

/// Il foglio dei codici: un biglietto da stampare per ogni atleta senza
/// account, con il suo codice personale (30 giorni, una volta sola).
///
/// [gruppoId]: la squadra proposta all'apertura (null = tutto il club).
/// [soloAtletaIds]: solo questi atleti (es. quelli appena aggiunti da un
/// foglio Excel); se c'è, la scelta della squadra non serve.
class FoglioCodiciScreen extends StatelessWidget {
  const FoglioCodiciScreen({super.key, this.gruppoId, this.soloAtletaIds});

  final String? gruppoId;
  final List<String>? soloAtletaIds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foglio dei codici')),
      body: const Center(child: Text('In arrivo')),
    );
  }
}
