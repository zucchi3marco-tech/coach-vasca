import 'package:flutter/material.dart';

import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../domain/serie.dart';
import '../domain/volume_allenamento.dart';
import 'serie_labels.dart';

/// 3200 -> "3.200".
String formattaMetri(int metri) {
  final cifre = metri.abs().toString();
  final gruppi = <String>[];
  for (var fine = cifre.length; fine > 0; fine -= 3) {
    gruppi.insert(0, cifre.substring(fine - 3 < 0 ? 0 : fine - 3, fine));
  }
  return '${metri < 0 ? '-' : ''}${gruppi.join('.')}';
}

/// "4.200 m", "4.200 m + 20'", "45'" (solo lavoro a tempo); null se
/// l'allenamento non ha ancora serie.
String? etichettaVolume(VolumeAllenamento v) {
  if (v.vuoto) return null;
  if (v.metri == 0) return formattaTempoLavoro(v.secondi);
  final metri = '${formattaMetri(v.metri)} m';
  return v.secondi == 0 ? metri : '$metri + ${formattaTempoLavoro(v.secondi)}';
}

/// Il volume a destra di una scheda dell'elenco allenamenti, accanto al
/// titolo: i metri in evidenza e il lavoro a tempo sotto (solo il tempo
/// se l'allenamento è tutto a tempo). Niente senza serie.
class VolumeScheda extends StatelessWidget {
  const VolumeScheda(this.volume, {this.attenuato = false, super.key});

  final VolumeAllenamento volume;

  /// Allenamenti già svolti: come il titolo, più tenue.
  final bool attenuato;

  @override
  Widget build(BuildContext context) {
    if (volume.vuoto) return const SizedBox.shrink();
    final colori = context.colori;
    final aTempo = formattaTempoLavoro(volume.secondi);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          volume.metri > 0 ? '${formattaMetri(volume.metri)} m' : aTempo,
          style: AppTypography.numerica(
            AppTypography.corpoForte,
          ).copyWith(color: attenuato ? colori.testoSecondario : colori.testo),
        ),
        if (volume.metri > 0 && volume.secondi > 0)
          Text(
            '+ $aTempo',
            style: AppTypography.numerica(AppTypography.piccolo)
                .copyWith(color: colori.testoSecondario),
          ),
      ],
    );
  }
}

/// Riepilogo di un allenamento in poche righe: il totale, i metri per
/// blocco (solo quelli con serie) e il materiale. Sostituisce il vecchio
/// riepilogo a più righe, che su smartphone toglieva spazio alle serie.
class RiepilogoVolumi extends StatelessWidget {
  const RiepilogoVolumi({
    required this.serie,
    this.mostraTotale = true,
    super.key,
  });

  final List<Serie> serie;

  /// false quando il totale e' gia' scritto in grande sopra (testata del
  /// dettaglio allenamento): qui restano i metri per blocco e il materiale.
  final bool mostraTotale;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final totale = serie.fold<int>(0, (t, s) => t + s.distanzaTotaleM);
    final perBlocco = <String, int>{};
    for (final s in serie) {
      perBlocco[s.blocco] = (perBlocco[s.blocco] ?? 0) + s.distanzaTotaleM;
    }
    final blocchi = [
      for (final b in ordineBlocchi)
        // Fasi solo a tempo (0 m) non si elencano; spazio fisso tra
        // etichetta e metri, cosi' "Altro" e il suo numero non si separano.
        if ((perBlocco[b] ?? 0) > 0)
          '${labelBloccoBreve(b)} ${formattaMetri(perBlocco[b]!)}',
    ];
    final totaleDurataS = serie
        .where((s) => s.aTempo)
        .fold<int>(0, (t, s) => t + s.ripetute * s.durataS!);
    // Segnate saltate a bordo vasca: il volume davvero svolto è un altro.
    final saltate = serie.where((s) => s.saltata).toList();
    final metriSaltati = saltate.fold<int>(0, (t, s) => t + s.distanzaTotaleM);
    final materiale = {
      for (final s in serie)
        if (s.attrezzatura != null && s.attrezzatura!.trim().isNotEmpty)
          s.attrezzatura!.trim(),
    }.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              if (mostraTotale)
                TextSpan(
                  text: '${formattaMetri(totale)} m   ',
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
              if (blocchi.isNotEmpty)
                TextSpan(
                  text: blocchi.join(' · '),
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              if (totaleDurataS > 0)
                TextSpan(
                  text:
                      '${blocchi.isEmpty ? '' : '   '}+ '
                      '${formatDurataS(totaleDurataS)} a tempo '
                      '(non contati nei metri)',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
            ],
          ),
        ),
        if (saltate.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            '${saltate.length == 1 ? '1 serie saltata' : '${saltate.length} serie saltate'}: '
            'svolti ${formattaMetri(totale - metriSaltati)} di '
            '${formattaMetri(totale)} m',
            style: AppTypography.numerica(AppTypography.piccolo)
                .copyWith(color: colori.testoSecondario),
          ),
        ],
        if (materiale.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Materiale: ${materiale.join(', ')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ],
      ],
    );
  }
}
