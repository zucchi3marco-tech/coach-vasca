import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/colori_app.dart';
import 'section_header.dart';

/// Un gruppo di campi in stile "Oggi": titolo di sezione sopra e i campi
/// raccolti in una scheda arrotondata. "Nessun form mostra più di cinque
/// campi di fila senza un'interruzione" (DESIGN.md, "Form"). Più
/// [FormGroup] in colonna si spaziano da soli: non serve aggiungere
/// SizedBox fra loro.
class FormGroup extends StatelessWidget {
  const FormGroup({
    required this.titolo,
    required this.campi,
    this.spiegazione,
    this.isUltimo = false,
    super.key,
  });

  final String titolo;
  final List<Widget> campi;
  final String? spiegazione;

  /// L'ultimo gruppo di una schermata non ha bisogno dello spazio sotto:
  /// ci pensa già il padding della schermata.
  final bool isUltimo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: EdgeInsets.only(bottom: isUltimo ? 0 : AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitoloSezione(titolo, spiegazione: spiegazione),
          Container(
            padding: const EdgeInsets.all(AppSpacing.paddingPannello),
            decoration: BoxDecoration(
              color: colori.superficie,
              borderRadius: BorderRadius.circular(AppRadius.pannello),
              border: Border.all(color: colori.linea),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < campi.length; i++) ...[
                  campi[i],
                  if (i != campi.length - 1)
                    const SizedBox(height: AppSpacing.s16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
