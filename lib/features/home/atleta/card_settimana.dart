import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/premibile.dart';
import '../../atleti/domain/atleta.dart';
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/domain/stagione.dart';
import '../../stagioni/presentation/stagione_atleta_screen.dart';

/// In cima alla home dell'atleta: la fase della stagione, a che settimana
/// siamo e «A cosa serve» (o la riga di questa settimana) scritto
/// dall'allenatore. Niente numeri: quelli restano all'allenatore. Non
/// compare se oggi nessuna fase è in corso.
class CardSettimana extends ConsumerWidget {
  const CardSettimana({
    required this.atleta,
    this.vistaAllenatore = false,
    this.oggi,
    super.key,
  });

  final Atleta atleta;
  final bool vistaAllenatore;

  /// Per le prove; di solito oggi.
  final DateTime? oggi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagioni = ref.watch(stagioniListProvider(atleta.clubId)).value;
    if (stagioni == null) return const SizedBox.shrink();
    final settimana = settimanaDellAtleta(
      stagioni,
      atleta.gruppoId,
      oggi ?? DateTime.now(),
    );
    if (settimana == null) return const SizedBox.shrink();
    final colori = context.colori;
    final (:fase, :numero, :totale, :testo) = settimana;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Premibile(
        etichetta:
            '${fase.nome}, settimana $numero di $totale'
            '${testo == null ? '' : ': $testo'}. Apri la stagione',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StagioneAtletaScreen(
              atleta: atleta,
              vistaAllenatore: vistaAllenatore,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colori.superficie,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colori.linea),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colori.azioneTenue,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$numero',
                      style: AppTypography.numerica(
                        AppTypography.titolo.copyWith(
                          color: colori.azione,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      'DI $totale',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.azione,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questa settimana',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fase.nome} · settimana $numero di $totale',
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    if (testo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        testo,
                        style: AppTypography.corpo.copyWith(
                          color: colori.testo,
                        ),
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
