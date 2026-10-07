import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Titolo di una sezione in stile "Oggi": testo `sezione` in grassetto,
/// senza filetto sotto (lo stacco lo danno le schede che seguono). Con
/// [conteggio] mostra il numero di voci accanto al titolo, con [azione]
/// un collegamento a destra (es. "Vedi tutti"), con [spiegazione]
/// un'iconcina "i" che apre una spiegazione a comparsa.
class TitoloSezione extends StatelessWidget {
  const TitoloSezione(
    this.testo, {
    this.conteggio,
    this.spiegazione,
    this.azione,
    this.onAzione,
    super.key,
  });

  final String testo;
  final int? conteggio;
  final String? spiegazione;
  final String? azione;
  final VoidCallback? onAzione;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    testo,
                    style: AppTypography.sezione.copyWith(
                      color: colori.testo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (conteggio != null) ...[
                  const SizedBox(width: AppSpacing.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colori.superficieAlt,
                      borderRadius: BorderRadius.circular(AppRadius.pillola),
                    ),
                    child: Text(
                      '$conteggio',
                      style: AppTypography.numerica(
                        AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                if (spiegazione != null) ...[
                  const SizedBox(width: AppSpacing.s4),
                  PulsanteSpiegazione(titolo: testo, spiegazione: spiegazione!),
                ],
              ],
            ),
          ),
          if (azione != null)
            TextButton(
              onPressed: onAzione,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(azione!),
            ),
        ],
      ),
    );
  }
}

/// Intestazione di un gruppo (form, elenco). Stesso aspetto di
/// [TitoloSezione]: resta come nome storico usato da molte schermate.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.titolo, {this.spiegazione, super.key});

  final String titolo;
  final String? spiegazione;

  @override
  Widget build(BuildContext context) =>
      TitoloSezione(titolo, spiegazione: spiegazione);
}

/// Iconcina "i" che apre una spiegazione in un dialogo — riusabile
/// anche fuori da [SectionHeader] (es. dentro un widget che ha già la
/// propria intestazione, come la lavagna tattica).
class PulsanteSpiegazione extends StatelessWidget {
  const PulsanteSpiegazione({
    required this.titolo,
    required this.spiegazione,
    super.key,
  });

  final String titolo;
  final String spiegazione;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline, size: 20),
      tooltip: 'Spiegazione',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(titolo),
          content: Text(spiegazione),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ho capito'),
            ),
          ],
        ),
      ),
    );
  }
}
