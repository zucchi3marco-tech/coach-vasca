import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/lane_rule.dart';
import '../domain/com_e_andata.dart';
import '../domain/serie.dart';
import '../domain/testo_allenamento.dart';
import '../domain/volume_allenamento.dart';
import 'riepilogo_volumi.dart';
import 'riga_serie.dart' show AzioneSerie;
import 'nota_serie.dart';
import 'per_chi_serie.dart';
import 'serie_labels.dart';

/// Una piramide (es. 50-100-200-100-50, dalla barra rapida) o un "2x"
/// scritto a testo nell'elenco del dettaglio allenamento: stesso
/// stile/altezza di [RigaSerie], ma
/// rappresenta **tutte** le serie del gruppo come una riga sola — ogni
/// azione del menu si applica all'intero gruppo, mai a una singola
/// distanza (per modificarne una si cancella e si riscrive, scelta del
/// coach).
class RigaGruppoPiramide extends StatelessWidget {
  const RigaGruppoPiramide({
    required this.gruppo,
    required this.maniglia,
    required this.primo,
    required this.ultimo,
    required this.onAzione,
    this.perChi,
    super.key,
  });

  final List<Serie> gruppo;
  final Widget maniglia;
  final bool primo;
  final bool ultimo;
  final ValueChanged<AzioneSerie> onAzione;

  /// Il nome di chi fa una serie ("Portieri", "Rossi"), null se è di
  /// tutto il gruppo: sopra il titolo se il gruppo è per le stesse
  /// persone, davanti a ogni pezzo se no.
  final String? Function(Destinatari d)? perChi;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final prima = gruppo.first;
    final coloreZona = context.dominio.colorePerZona(
      prima.zona,
      rispetto: colori.linea,
    );

    final uniforme = gruppo.every((s) => s.destinatari == prima.destinatari);
    final titolo = titoloGruppo(
      gruppo,
      perChi: perChi == null ? null : (s) => perChi!(s.destinatari),
    );
    final perTutti = uniforme ? perChi?.call(prima.destinatari) : null;
    final piramide = strutturaPiramide(gruppo) != null;

    // Con serie per persone diverse, i metri del gruppo (un giocatore di
    // movimento): come nella testata.
    final metriTotali = (uniforme ? gruppo : serieDelGruppo(gruppo)).fold<int>(
      0,
      (t, s) => t + s.distanzaTotaleM,
    );

    // Il recupero più frequente nel gruppo è "tra una distanza e
    // l'altra"; un secondo valore distinto (se c'è, solo con più di un
    // giro) è il recupero "tra un giro e l'altro".
    final recuperi = gruppo.map((s) => s.recuperoS).whereType<int>().toList();
    final conteggio = <int, int>{};
    for (final r in recuperi) {
      conteggio[r] = (conteggio[r] ?? 0) + 1;
    }
    final valoriOrdinati = conteggio.keys.toList()
      ..sort((a, b) => conteggio[b]!.compareTo(conteggio[a]!));

    final dettagli = <String>[
      // Segnate a bordo vasca, una per riga del gruppo.
      ?riassuntoEsiti(gruppo),
      labelBloccoBreve(prima.blocco),
      '${formattaMetri(metriTotali)} m',
      if (piramide && valoriOrdinati.isNotEmpty)
        "rec ${valoriOrdinati.first}''",
      if (piramide && valoriOrdinati.length > 1)
        "tra i giri ${valoriOrdinati[1]}''",
    ];

    // Le note diverse delle serie del gruppo (in una piramide è una sola).
    final note = <String>{for (final s in gruppo) ?notaPiena(s.note)};

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: LaneRule(
        colore: coloreZona,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              SizedBox(width: 44, height: 56, child: Center(child: maniglia)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  child: ConNotaAccanto(
                    nota: note.isEmpty ? null : note.join('\n'),
                    principale: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (perTutti case final chi?)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: EtichettaPerChi(chi),
                          ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${prima.ordine}  ',
                                style: AppTypography.piccolo.copyWith(
                                  color: colori.testoTenue,
                                ),
                              ),
                              TextSpan(
                                text: titolo,
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
                              if (prima.zona != null) ...[
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
                                  text: ' ${prima.zona} · ',
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
              ),
              PopupMenuButton<AzioneSerie>(
                tooltip: piramide
                    ? 'Azioni sulla piramide'
                    : 'Azioni sul gruppo',
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
