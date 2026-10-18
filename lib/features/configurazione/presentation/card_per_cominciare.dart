import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../club/application/membri_club_providers.dart';
import '../../club/domain/ruolo_club.dart';
import '../application/configurazione_providers.dart';
import '../data/configurazione_repository.dart';
import '../domain/stato_configurazione.dart';

/// "Per cominciare" in "Oggi": i passi della configurazione guidata con la
/// spunta su quelli fatti, presi dai dati veri del club. La vede solo il
/// responsabile; non c'è quando è tutto fatto, quando l'ha nascosta su
/// questo dispositivo, o finché lo stato non si legge (senza rete, ad
/// esempio).
class CardPerCominciare extends ConsumerWidget {
  const CardPerCominciare({
    required this.clubId,
    required this.onApriPasso,
    super.key,
  });

  final String clubId;

  /// Il tocco su un passo da fare: di solito apre la configurazione guidata
  /// da quel passo.
  final void Function(PassoConfigurazione passo) onApriPasso;

  Future<void> _nascondi(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(preferenzeConfigurazioneProvider).nascondi(clubId);
    ref.invalidate(configurazioneNascostaProvider(clubId));
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Scheda nascosta. La configurazione resta in ☰ → Il mio club.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsabile =
        ref.watch(mioRuoloProvider(clubId)).value == RuoloClub.responsabile;
    if (!responsabile) return const SizedBox.shrink();
    // Finché non si sa se è nascosta, non c'è: niente scheda che compare e
    // sparisce subito.
    if (ref.watch(configurazioneNascostaProvider(clubId)).value != false) {
      return const SizedBox.shrink();
    }
    final stato = ref.watch(statoConfigurazioneProvider(clubId)).value;
    if (stato == null || stato.tuttoFatto) return const SizedBox.shrink();

    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    color: colori.azioneTenue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flag_outlined, color: colori.azione),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Per cominciare',
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.testo,
                        ),
                      ),
                      Text(
                        '${stato.fatti} di ${PassoConfigurazione.totale} '
                        'fatti · tocca un passo per farlo',
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            _Avanzamento(stato: stato),
            const SizedBox(height: AppSpacing.s4),
            for (final passo in PassoConfigurazione.values)
              _RigaPasso(
                passo: passo,
                fatto: stato.fatto(passo),
                prossimo: passo == stato.prossimo,
                onTap: () => onApriPasso(passo),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _nascondi(context, ref),
                child: const Text('Nascondi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cinque tratti, uno per passo: pieni quelli fatti.
class _Avanzamento extends StatelessWidget {
  const _Avanzamento({required this.stato});

  final StatoConfigurazione stato;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      label: '${stato.fatti} passi fatti su ${PassoConfigurazione.totale}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (final passo in PassoConfigurazione.values) ...[
            if (passo.index > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: stato.fatto(passo) ? colori.ok : colori.linea,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un passo: fatto (la spunta, non si tocca) o da fare (si tocca e apre).
class _RigaPasso extends StatelessWidget {
  const _RigaPasso({
    required this.passo,
    required this.fatto,
    required this.prossimo,
    required this.onTap,
  });

  final PassoConfigurazione passo;
  final bool fatto;

  /// Il primo da fare: il titolo in evidenza.
  final bool prossimo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return InkWell(
      onTap: fatto ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        // 48: il minimo per il dito, più basse delle righe di un elenco
        // perché sono cinque dentro una scheda.
        constraints: const BoxConstraints(minHeight: AppSpacing.s48),
        child: Row(
          children: [
            Icon(
              fatto ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: fatto ? colori.ok : colori.testoTenue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fatto ? passo.titolo : passo.daFare,
                style:
                    (prossimo ? AppTypography.corpoForte : AppTypography.corpo)
                        .copyWith(
                          color: fatto ? colori.testoSecondario : colori.testo,
                        ),
              ),
            ),
            if (!fatto)
              Icon(Icons.chevron_right, color: colori.testoSecondario),
          ],
        ),
      ),
    );
  }
}
