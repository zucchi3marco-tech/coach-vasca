import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';
import 'primary_button.dart';
import 'riquadri.dart';
import 'secondary_button.dart';

/// Schermata/sezione vuota — vedi DESIGN.md sezione 13, "Schermate
/// vuote". Regola non negoziabile: mai una riga di testo grigio da sola.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icona,
    required this.titolo,
    required this.descrizione,
    required this.azionePrincipale,
    this.onAzionePrincipale,
    this.azioneSecondaria,
    this.onAzioneSecondaria,
    super.key,
  });

  final IconData icona;
  final String titolo;
  final String descrizione;
  final String azionePrincipale;
  final VoidCallback? onAzionePrincipale;
  final String? azioneSecondaria;
  final VoidCallback? onAzioneSecondaria;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        // Su schermi larghi il testo resta una colonna leggibile.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconaRiquadro(icona, dimensione: 64),
              const SizedBox(height: AppSpacing.s16),
              Text(
                titolo,
                style: AppTypography.sezione.copyWith(
                  color: colori.testo,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                descrizione,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
                textAlign: TextAlign.center,
              ),
              // Senza azione collegata il pulsante sarebbe disattivato e
              // basta ("Torna indietro" che non torna): si toglie.
              if (onAzionePrincipale != null)
                const SizedBox(height: AppSpacing.s20),
              if (onAzionePrincipale != null)
                // Larghezza contenuta: il tema allarga i pulsanti a tutto
                // schermo, e su tablet/PC finivano sotto il pulsante "+".
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        label: azionePrincipale,
                        onPressed: onAzionePrincipale,
                        expanded: false,
                      ),
                      if (azioneSecondaria != null) ...[
                        const SizedBox(height: AppSpacing.s12),
                        SecondaryButton(
                          label: azioneSecondaria!,
                          onPressed: onAzioneSecondaria,
                          expanded: false,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una sezione senza dati dentro una pagina che ne ha altri: una scheda
/// bassa con l'icona e la frase, al posto di una riga grigia da sola
/// (DESIGN.md sezione 19). Per una pagina intera vuota c'è [EmptyState].
class RiquadroVuoto extends StatelessWidget {
  const RiquadroVuoto(this.testo, {this.icona = Icons.info_outline, super.key});

  final String testo;
  final IconData icona;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: Row(
        children: [
          IconaRiquadro(icona, colore: colori.testoSecondario, dimensione: 40),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              testo,
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
