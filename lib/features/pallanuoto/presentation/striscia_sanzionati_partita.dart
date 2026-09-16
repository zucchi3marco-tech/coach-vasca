import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/cap_badge.dart';
import '../domain/partita.dart';
import 'selettore_giocatore_partita.dart';

/// Striscia informativa (non toccabile) con i soli giocatori — nostri o
/// avversari — che hanno già accumulato almeno un'espulsione da rigore in
/// questa partita: quando la fascia calottine è nascosta (fuori
/// dall'interazione di tiro/sanzione, per lasciare più spazio al campo),
/// è l'unico modo per tenere d'occhio chi rischia la squalifica (3
/// espulsioni da rigore) senza dover aprire la selezione giocatore.
/// Vuota (e quindi invisibile) finché nessuno ha ancora una sanzione.
class StrisciaSanzionatiPartita extends StatelessWidget {
  const StrisciaSanzionatiPartita({
    required this.partita,
    required this.convocati,
    required this.conteggiRigore,
    super.key,
  });

  final Partita partita;
  final List<ConvocatoConAtleta> convocati;
  final Map<GiocatorePartitaId, int> conteggiRigore;

  @override
  Widget build(BuildContext context) {
    if (conteggiRigore.isEmpty) return const SizedBox.shrink();

    final convocatoPerAtletaId = {for (final c in convocati) c.atleta.id: c};

    return SizedBox(
      height: AppSpacing.s40 + AppSpacing.s8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in conteggiRigore.entries)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: _ChipSanzionato(
                id: entry.key,
                conteggio: entry.value,
                partita: partita,
                convocatoPerAtletaId: convocatoPerAtletaId,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipSanzionato extends StatelessWidget {
  const _ChipSanzionato({
    required this.id,
    required this.conteggio,
    required this.partita,
    required this.convocatoPerAtletaId,
  });

  final GiocatorePartitaId id;
  final int conteggio;
  final Partita partita;
  final Map<String, ConvocatoConAtleta> convocatoPerAtletaId;

  @override
  Widget build(BuildContext context) {
    final casaENostra = partita.nostraSquadra == 'casa';
    final int numero;
    final CapColore colore;
    String? nome;
    switch (id) {
      case NostroGiocatoreId(:final atletaId):
        final convocato = convocatoPerAtletaId[atletaId];
        numero = convocato?.giocatore.numeroCalottina ?? 0;
        nome = convocato?.atleta.nomeCompleto;
        colore = casaENostra ? CapColore.bianca : CapColore.blu;
      case AvversarioGiocatoreId(:final numeroCalottina):
        numero = numeroCalottina;
        colore = casaENostra ? CapColore.blu : CapColore.bianca;
    }

    final squalificato = conteggio >= 3;
    final colori = context.colori;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: colori.superficieAlt,
        borderRadius: BorderRadius.circular(AppRadius.pillola),
        border: Border.all(color: colori.linea),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CapBadge(numero: numero, colore: colore),
          const SizedBox(width: AppSpacing.s8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nome != null)
                Text(
                  nome,
                  style: AppTypography.piccolo.copyWith(color: colori.testo),
                ),
              Text(
                squalificato ? 'Squalificato' : 'Rigore ×$conteggio',
                style: AppTypography.etichetta.copyWith(
                  color: colori.rosso,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
