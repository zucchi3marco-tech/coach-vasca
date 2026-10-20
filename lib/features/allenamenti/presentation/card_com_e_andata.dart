import 'package:flutter/material.dart';

import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/secondary_button.dart';
import '../domain/allenamento.dart';
import '../domain/com_e_andata.dart';
import '../domain/serie.dart';
import '../domain/volume_allenamento.dart';

/// La riga di sintesi di «Com'è andata»: «Fatti 2.600 di 3.200 m» (e il
/// lavoro a tempo), poi quante serie sono in parte o saltate. Senza
/// nessuna serie segnata dice che contano come scritte.
class SintesiComEAndata extends StatelessWidget {
  const SintesiComEAndata(this.riepilogo, {super.key});

  final RiepilogoComEAndata riepilogo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final r = riepilogo;
    final nessunaSegnata = r.fatteTutte + r.inParte + r.saltate == 0;
    final conti = [
      if (r.inParte > 0) '${r.inParte} in parte',
      if (r.saltate > 0) r.saltate == 1 ? '1 saltata' : '${r.saltate} saltate',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!r.scritto.vuoto)
          Text(
            'Fatti ${fattoDiScritto(r.scritto, r.fatto, aTempo: true)}',
            style: AppTypography.numerica(
              AppTypography.corpoForte.copyWith(color: colori.testo),
            ),
          ),
        if (nessunaSegnata)
          Text(
            'Nessuna serie segnata: contano come scritte.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          )
        else if (conti.isNotEmpty)
          Text(
            conti.join(' · '),
            style: AppTypography.numerica(
              AppTypography.piccolo.copyWith(color: colori.testoSecondario),
            ),
          ),
      ],
    );
  }
}

/// La zona che dà il colore a una famiglia (A, B, C, D).
const _zonaDellaFamiglia = {'A': 'A1', 'B': 'B1', 'C': 'C1', 'D': 'D'};

/// «Com'è andata» nel dettaglio di un allenamento già svolto: quanto è
/// stato fatto di quanto era scritto, in parte per zona, e il pulsante per
/// segnarlo. Conta le serie del gruppo ([serieDelGruppo]). Non c'è per un
/// allenamento di un giorno a venire né senza serie.
class CardComEAndata extends StatelessWidget {
  const CardComEAndata({
    required this.allenamento,
    required this.serie,
    required this.onSegna,
    super.key,
  });

  final Allenamento allenamento;

  /// Tutte le serie dell'allenamento.
  final List<Serie> serie;
  final VoidCallback onSegna;

  @override
  Widget build(BuildContext context) {
    final inFuturo = soloData(allenamento.data)
        .isAfter(soloData(DateTime.now()));
    if (serie.isEmpty || inFuturo) return const SizedBox.shrink();
    final colori = context.colori;
    final gruppo = serieDelGruppo(serie);
    final r = riepilogoComEAndata(gruppo);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: PoolCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Com'è andata",
              style: AppTypography.sezione.copyWith(
                color: colori.testo,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (gruppo.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s8),
              SintesiComEAndata(r),
              if (r.perFamiglia.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Divider(height: 1, color: colori.linea),
                const SizedBox(height: AppSpacing.s12),
                for (final (i, scarto) in r.perFamiglia.indexed) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.s8),
                  _RigaFamiglia(scarto),
                ],
              ],
            ],
            const SizedBox(height: AppSpacing.s16),
            SecondaryButton(
              label: "Segna com'è andata",
              icon: Icons.fact_check_outlined,
              onPressed: onSegna,
              unaRiga: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Una famiglia di zona: «Zona A», quanto è stato fatto e di quanto si è
/// scesi sotto lo scritto. Se non ci stanno sulla stessa riga vanno a
/// capo.
class _RigaFamiglia extends StatelessWidget {
  const _RigaFamiglia(this.scarto);

  final ScartoFamiglia scarto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final famiglia = scarto.famiglia;
    final colore = famiglia == null
        ? colori.testoTenue
        : context.dominio.colorePerZona(
            _zonaDellaFamiglia[famiglia],
            rispetto: colori.testoTenue,
          );
    final differenza = scartoScritto(scarto.scritto, scarto.fatto);
    final numeri = AppTypography.numerica(
      AppTypography.piccolo.copyWith(color: colori.testoSecondario),
    );
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.s12,
      runSpacing: 2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              famiglia == null ? 'Senza zona' : 'Zona $famiglia',
              style: AppTypography.piccolo.copyWith(
                color: colori.testo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.s12,
          children: [
            Text(fattoDiScritto(scarto.scritto, scarto.fatto), style: numeri),
            if (differenza != null)
              Text(
                differenza,
                style: numeri.copyWith(
                  color: colori.testo,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
