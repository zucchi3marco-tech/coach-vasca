import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../allenamenti/application/modifiche_providers.dart';
import '../../allenamenti/domain/modifica_allenamento.dart';
import '../../allenamenti/presentation/modifiche_da_controllare_screen.dart';
import '../../gruppi/application/gruppi_providers.dart';

/// Quante modifiche mostra la scheda in "Oggi"; il resto è in "Vedi tutte".
const modificheInScheda = 3;

/// "Da controllare" in "Oggi": gli allenamenti che un altro allenatore ha
/// cambiato (o aggiunto) in una squadra di cui sei il capo. Non c'è finché
/// non c'è niente da vedere (e nella demo, o senza rete, non c'è mai).
class CardDaControllare extends ConsumerWidget {
  const CardDaControllare({required this.clubId, this.onApri, super.key});

  final String clubId;

  /// Cosa fa il tocco su una modifica; di solito apre l'allenamento.
  final void Function(ModificaAllenamento modifica)? onApri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiche =
        ref.watch(modificheDaControllareProvider(clubId)).value ?? const [];
    if (modifiche.isEmpty) return const SizedBox.shrink();
    final colori = context.colori;
    final nomiSquadre = {
      for (final g in ref.watch(gruppiListProvider(clubId)).value ?? const [])
        g.id: g.nome,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colori.attenzione.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit_note, color: colori.attenzione),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Da controllare',
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.testo,
                        ),
                      ),
                      Text(
                        'Allenamenti cambiati da altri nelle tue squadre',
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final m in modifiche.take(modificheInScheda))
              RigaModifica(
                modifica: m,
                squadra: nomiSquadre[m.gruppoId],
                onTap: () => onApri != null
                    ? onApri!(m)
                    : apriAllenamentoDellaModifica(context, ref, m),
              ),
            if (modifiche.length > modificheInScheda)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ModificheDaControllareScreen(clubId: clubId),
                    ),
                  ),
                  child: Text('Vedi tutte (${modifiche.length})'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
