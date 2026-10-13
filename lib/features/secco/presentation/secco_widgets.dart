import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../carico/domain/carico_rpe.dart' show minutiSeccoPredefiniti;
import '../domain/esercizio_secco.dart';

/// L'icona di una categoria di esercizi.
IconData iconaCategoria(CategoriaEsercizio c) => switch (c) {
  CategoriaEsercizio.spalla => Icons.sports_handball,
  CategoriaEsercizio.scapole => Icons.accessibility_new,
  CategoriaEsercizio.core => Icons.crop_square,
  CategoriaEsercizio.gambe => Icons.directions_run,
  CategoriaEsercizio.forza => Icons.fitness_center,
  CategoriaEsercizio.mobilita => Icons.self_improvement,
  CategoriaEsercizio.altro => Icons.more_horiz,
};

/// I minuti di una seduta a secco: quelli scritti o, senza, quelli che
/// usa il carico.
int minutiSeduta(Allenamento a) => a.durataMin ?? minutiSeccoPredefiniti;

/// A destra di una scheda dell'elenco allenamenti, dove l'acqua ha i
/// metri: la durata e "a secco".
class DurataSecco extends StatelessWidget {
  const DurataSecco(this.allenamento, {this.attenuato = false, super.key});

  final Allenamento allenamento;
  final bool attenuato;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${minutiSeduta(allenamento)}'",
          style: AppTypography.numerica(
            AppTypography.corpoForte,
          ).copyWith(color: attenuato ? colori.testoSecondario : colori.testo),
        ),
        Text(
          'a secco',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );
  }
}

/// Una riga di esercizio in una seduta: il numero, il nome, quanto
/// ("3 × 12, elastico rosso · recupero 1'") e, sotto, le note o come si
/// fa.
class RigaEsercizio extends StatelessWidget {
  const RigaEsercizio({
    required this.numero,
    required this.esercizio,
    required this.riga,
    this.sotto,
    this.trailing,
    this.onTap,
    super.key,
  });

  final int numero;
  final EsercizioSecco? esercizio;
  final EsercizioSeduta riga;

  /// Una riga in più sotto la prescrizione (le note dell'allenatore).
  final String? sotto;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final attrezzo = esercizio?.attrezzo;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaRiga,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s12,
            AppSpacing.s8,
            AppSpacing.s12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$numero',
                  style: AppTypography.numerica(AppTypography.corpoForte)
                      .copyWith(color: colori.testoSecondario),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      esercizio?.nome ?? 'Esercizio tolto dall\'elenco',
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prescrizioneEsercizio(riga),
                      style: AppTypography.numerica(AppTypography.corpo)
                          .copyWith(color: colori.testo),
                    ),
                    if (attrezzo != null && attrezzo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        attrezzo,
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                    if (sotto != null && sotto!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        sotto!,
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
