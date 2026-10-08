import 'package:flutter/material.dart';

import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/lane_rule.dart';
import '../domain/serie.dart';
import 'serie_labels.dart';

enum AzioneSerie { su, giu, cambiaBlocco, duplica, salvaComeBlocco, elimina }

/// Una serie nell'elenco del dettaglio allenamento, su circa 64 px:
/// maniglia di trascinamento a sinistra, filetto del colore di zona, due
/// righe di testo e il menu ⋮ con le azioni (sposta, cambia blocco,
/// duplica, elimina). Il tocco sulla riga apre la modifica.
///
/// La [maniglia] la costruisce chi usa il widget (in un elenco riordinabile
/// è un `ReorderableDragStartListener`): qui non si dipende dall'elenco, e
/// il widget resta provabile da solo.
class RigaSerie extends StatelessWidget {
  const RigaSerie({
    required this.serie,
    required this.maniglia,
    required this.primo,
    required this.ultimo,
    required this.onApri,
    required this.onAzione,
    super.key,
  });

  final Serie serie;
  final Widget maniglia;
  final bool primo;
  final bool ultimo;
  final VoidCallback onApri;
  final ValueChanged<AzioneSerie> onAzione;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final s = serie;
    final coloreZona = context.dominio.colorePerZona(
      s.zona,
      rispetto: colori.linea,
    );

    final titolo = StringBuffer('${labelVolumeSerie(s)} ')
      ..write(labelStile(s.stile));
    if (s.esecuzione != 'nuoto') {
      titolo.write(' ${labelEsecuzione(s.esecuzione)}');
    }

    final dettagli = <String>[
      labelBloccoBreve(s.blocco),
      if (s.passoObiettivoS != null)
        '${formatTempoCompatto(s.passoObiettivoS!)}/100m',
      if (s.recuperoS != null) "rec ${s.recuperoS}''",
      if (s.ripartenzaS != null) 'rip ${formatTempoCompatto(s.ripartenzaS!)}',
      if (s.attrezzatura != null && s.attrezzatura!.isNotEmpty) s.attrezzatura!,
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: LaneRule(
        colore: coloreZona,
        child: InkWell(
          onTap: onApri,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                SizedBox(width: 44, height: 56, child: Center(child: maniglia)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${s.ordine}  ',
                                style: AppTypography.piccolo.copyWith(
                                  color: colori.testoTenue,
                                ),
                              ),
                              TextSpan(
                                text: titolo.toString(),
                                style: AppTypography.corpoForte.copyWith(
                                  color: colori.testo,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              if (s.zona != null) ...[
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: coloreZona,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${s.zona} · ',
                                  style: AppTypography.piccolo.copyWith(
                                    color: colori.testo,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              TextSpan(
                                text: dettagli.join(' · '),
                                style: AppTypography.piccolo.copyWith(
                                  color: colori.testoSecondario,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<AzioneSerie>(
                  tooltip: 'Azioni sulla serie',
                  icon: const Icon(Icons.more_vert),
                  onSelected: onAzione,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: AzioneSerie.su,
                      enabled: !primo,
                      child: const _Voce(Icons.arrow_upward, 'Sposta su'),
                    ),
                    PopupMenuItem(
                      value: AzioneSerie.giu,
                      enabled: !ultimo,
                      child: const _Voce(Icons.arrow_downward, 'Sposta giù'),
                    ),
                    const PopupMenuItem(
                      value: AzioneSerie.cambiaBlocco,
                      child: _Voce(Icons.swap_vert, 'Cambia blocco'),
                    ),
                    const PopupMenuItem(
                      value: AzioneSerie.duplica,
                      child: _Voce(Icons.copy_outlined, 'Duplica'),
                    ),
                    const PopupMenuItem(
                      value: AzioneSerie.salvaComeBlocco,
                      child: _Voce(Icons.bookmark_add_outlined, 'Salva blocco'),
                    ),
                    PopupMenuItem(
                      value: AzioneSerie.elimina,
                      child: _Voce(
                        Icons.delete_outline,
                        'Elimina',
                        colore: colori.rosso,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Voce extends StatelessWidget {
  const _Voce(this.icona, this.etichetta, {this.colore});

  final IconData icona;
  final String etichetta;
  final Color? colore;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      children: [
        Icon(icona, size: 20, color: colore ?? colori.testoSecondario),
        const SizedBox(width: AppSpacing.s12),
        Text(
          etichetta,
          style: AppTypography.corpo.copyWith(color: colore ?? colori.testo),
        ),
      ],
    );
  }
}
