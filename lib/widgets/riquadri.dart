import 'package:flutter/material.dart';

import '../core/utils/date_italiane.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Icona dentro un quadrato arrotondato tinto dello stesso colore: il
/// "biglietto da visita" di ogni scheda in stile "Oggi".
class IconaRiquadro extends StatelessWidget {
  const IconaRiquadro(
    this.icona, {
    this.colore,
    this.dimensione = 40,
    super.key,
  });

  final IconData icona;
  final Color? colore;
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    final colore = this.colore ?? context.colori.azione;
    return Container(
      width: dimensione,
      height: dimensione,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(dimensione * 0.3),
      ),
      child: Icon(icona, color: colore, size: dimensione * 0.55),
    );
  }
}

/// Mese e giorno in un quadrato tinto ("OTT / 8"): la data si legge
/// prima ancora del titolo. [spento] per le date gia' passate.
class RiquadroData extends StatelessWidget {
  const RiquadroData(
    this.data, {
    this.colore,
    this.spento = false,
    this.dimensione = 56,
    super.key,
  });

  final DateTime data;
  final Color? colore;
  final bool spento;
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final accento = spento ? colori.testoSecondario : (colore ?? colori.azione);
    return Container(
      width: dimensione,
      height: dimensione,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: spento ? colori.superficieAlt : accento.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(dimensione * 0.29),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            mesiBrevi[data.month - 1].toUpperCase(),
            style: AppTypography.etichetta.copyWith(
              color: accento,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          Text(
            '${data.day}',
            style: AppTypography.numerica(
              AppTypography.titolo.copyWith(color: accento, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etichetta a pillola tinta (es. "Oggi", "Importante", "Inattivo").
class Pastiglia extends StatelessWidget {
  const Pastiglia(this.testo, {this.colore, super.key});

  final String testo;
  final Color? colore;

  @override
  Widget build(BuildContext context) {
    final colore = this.colore ?? context.colori.azione;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        testo,
        maxLines: 1,
        style: AppTypography.etichetta.copyWith(
          color: colore,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
