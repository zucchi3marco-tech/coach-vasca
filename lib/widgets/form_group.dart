import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'section_header.dart';

/// Un gruppo di campi con la sua intestazione — vedi DESIGN.md sezione 8,
/// "Form": "Nessun form mostra più di cinque campi di fila senza
/// un'interruzione". Più [FormGroup] in colonna si spaziano da soli
/// (28px fra un gruppo e l'altro): non serve aggiungere SizedBox fra loro.
class FormGroup extends StatelessWidget {
  const FormGroup({
    required this.titolo,
    required this.campi,
    this.isUltimo = false,
    super.key,
  });

  final String titolo;
  final List<Widget> campi;

  /// L'ultimo gruppo di una schermata non ha bisogno dello spazio sotto:
  /// ci pensa già il padding della schermata.
  final bool isUltimo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isUltimo ? 0 : AppSpacing.s28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(titolo),
          const SizedBox(height: AppSpacing.s16),
          for (var i = 0; i < campi.length; i++) ...[
            campi[i],
            if (i != campi.length - 1) const SizedBox(height: AppSpacing.s16),
          ],
        ],
      ),
    );
  }
}
