import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
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

/// Un [FormGroup] che si apre e si chiude: per le impostazioni che si
/// toccano di rado. Chiuso mostra solo il titolo e un riassunto delle
/// scelte attuali, cosi' il form resta corto senza nascondere nulla.
class FormGroupComprimibile extends StatefulWidget {
  const FormGroupComprimibile({
    required this.titolo,
    required this.riassunto,
    required this.campi,
    this.inizialmenteAperto = false,
    this.isUltimo = false,
    super.key,
  });

  final String titolo;

  /// Le scelte attuali in una riga (es. "Tiro semplice · tempo non
  /// tracciato"), visibili anche a gruppo chiuso.
  final String riassunto;
  final List<Widget> campi;
  final bool inizialmenteAperto;
  final bool isUltimo;

  @override
  State<FormGroupComprimibile> createState() => _FormGroupComprimibileState();
}

class _FormGroupComprimibileState extends State<FormGroupComprimibile> {
  late bool _aperto = widget.inizialmenteAperto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: EdgeInsets.only(bottom: widget.isUltimo ? 0 : AppSpacing.s24),
      child: Container(
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          border: Border.all(color: colori.linea),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _aperto = !_aperto),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.paddingPannello),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.titolo,
                            style: AppTypography.sezione.copyWith(
                              color: colori.testo,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_aperto)
                            Text(
                              widget.riassunto,
                              style: AppTypography.piccolo.copyWith(
                                color: colori.testoSecondario,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _aperto ? Icons.expand_less : Icons.expand_more,
                      color: colori.testoSecondario,
                    ),
                  ],
                ),
              ),
            ),
            if (_aperto)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.paddingPannello,
                  0,
                  AppSpacing.paddingPannello,
                  AppSpacing.paddingPannello,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.campi.length; i++) ...[
                      widget.campi[i],
                      if (i != widget.campi.length - 1)
                        const SizedBox(height: AppSpacing.s16),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
