import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cap_badge.dart';
import '../domain/partita.dart';
import 'selettore_giocatore_partita.dart';

/// Fascia verticale di calottine ai bordi dello schermo (sostituisce, nella
/// schermata live, la vecchia griglia centrale a due colonne): sinistra =
/// squadra di casa (badge bianchi), destra = squadra fuori casa (badge
/// blu), sempre visibili. In stato di riposo ([attiva] false) i numeri si
/// vedono ma non sono toccabili; [attiva] true li evidenzia e li rende
/// bersagli (per il tiro, solo il lato nostro tramite [soloNostra]).
class FasciaCalottinePartita extends StatelessWidget {
  const FasciaCalottinePartita({
    required this.partita,
    required this.casa,
    required this.convocati,
    required this.attiva,
    required this.disqualificati,
    required this.conteggiRigore,
    required this.onSelezionato,
    this.soloNostra = false,
    super.key,
  });

  /// true = fascia della squadra di casa (sinistra, badge bianchi), false =
  /// fascia della squadra fuori casa (destra, badge blu).
  final bool casa;
  final Partita partita;
  final List<ConvocatoConAtleta> convocati;
  final bool attiva;
  final Set<GiocatorePartitaId> disqualificati;
  final Map<GiocatorePartitaId, int> conteggiRigore;
  final ValueChanged<GiocatorePartitaId> onSelezionato;

  /// Quando true, solo questa fascia risponde al tocco se è quella nostra
  /// (usato per il tiro: solo un nostro giocatore può tirare).
  final bool soloNostra;

  bool get _eNostra => (partita.nostraSquadra == 'casa') == casa;

  @override
  Widget build(BuildContext context) {
    final atletaPerNumero = {
      for (final c in convocati) c.giocatore.numeroCalottina: c.atleta,
    };
    final colore = casa ? CapColore.bianca : CapColore.blu;
    final toccabile = attiva && (!soloNostra || _eNostra);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var n = 1; n <= partita.numeroMaxConvocati; n++) ...[
            _BadgeCalottina(
              numero: n,
              colore: colore,
              attivo:
                  toccabile && (_eNostra ? atletaPerNumero[n] != null : true),
              squalificato: disqualificati.contains(
                _eNostra
                    ? NostroGiocatoreId(atletaPerNumero[n]?.id ?? '')
                    : AvversarioGiocatoreId(n),
              ),
              conteggioRigore:
                  conteggiRigore[_eNostra
                      ? NostroGiocatoreId(atletaPerNumero[n]?.id ?? '')
                      : AvversarioGiocatoreId(n)] ??
                  0,
              onTap: () {
                if (_eNostra) {
                  final atleta = atletaPerNumero[n];
                  if (atleta != null) {
                    onSelezionato(NostroGiocatoreId(atleta.id));
                  }
                } else {
                  onSelezionato(AvversarioGiocatoreId(n));
                }
              },
            ),
            if (n != partita.numeroMaxConvocati)
              const SizedBox(height: AppSpacing.s8),
          ],
        ],
      ),
    );
  }
}

class _BadgeCalottina extends StatelessWidget {
  const _BadgeCalottina({
    required this.numero,
    required this.colore,
    required this.attivo,
    required this.squalificato,
    required this.conteggioRigore,
    required this.onTap,
  });

  final int numero;
  final CapColore colore;
  final bool attivo;
  final bool squalificato;
  final int conteggioRigore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (squalificato) {
      // Nero puro, non il token "testo": deve restare la casella piu'
      // scura sullo schermo anche quando il resto passa al tema scuro.
      return const SizedBox(
        width: AppSpacing.altezzaMinimaBersaglioVasca,
        height: AppSpacing.altezzaMinimaBersaglioVasca,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    final badge = Center(
      child: CapBadge(numero: numero, colore: colore),
    );

    return SizedBox(
      width: AppSpacing.altezzaMinimaBersaglioVasca,
      height: AppSpacing.altezzaMinimaBersaglioVasca,
      child: Opacity(
        opacity: attivo ? 1 : 0.5,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: attivo ? onTap : null,
                customBorder: const CircleBorder(),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: attivo
                        ? Border.all(color: AppColors.blu, width: 2)
                        : null,
                  ),
                  child: badge,
                ),
              ),
            ),
            if (conteggioRigore == 1 || conteggioRigore == 2)
              Positioned(
                top: -2,
                right: -2,
                child: Text(
                  '$conteggioRigore',
                  style: AppTypography.etichetta.copyWith(
                    color: AppColors.rosso,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
