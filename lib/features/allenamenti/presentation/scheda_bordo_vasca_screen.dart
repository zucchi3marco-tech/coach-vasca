import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/domain_tokens.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/lane_rule.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/zone_chip.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../domain/allenamento.dart';
import '../domain/serie.dart';
import 'serie_labels.dart';

/// Vista pensata per un tablet fissato a bordo vasca — vedi DESIGN.md
/// sezione 2 e 9: tipografia enorme, colori ridotti all'osso, bersagli
/// da 64, orientamento forzato landscape. Solo lettura: la modifica
/// della scheda resta nella schermata di dettaglio "da ufficio".
class SchedaBordoVascaScreen extends ConsumerStatefulWidget {
  const SchedaBordoVascaScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  ConsumerState<SchedaBordoVascaScreen> createState() =>
      _SchedaBordoVascaScreenState();
}

class _SchedaBordoVascaScreenState
    extends ConsumerState<SchedaBordoVascaScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  List<String> _metaSerie(Serie s) {
    final parti = <String>[];
    if (s.passoObiettivoS != null) {
      parti.add('${formatPaceSeconds(s.passoObiettivoS!)}/100m');
    }
    if (s.recuperoS != null) parti.add("rec ${s.recuperoS}''");
    if (s.ripartenzaS != null) {
      parti.add('rip ${formatPaceSeconds(s.ripartenzaS!)}');
    }
    return parti;
  }

  @override
  Widget build(BuildContext context) {
    final allenamento = widget.allenamento;
    final serieAsync = ref.watch(serieListProvider(allenamento.id));

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          '${allenamento.data.day.toString().padLeft(2, '0')}/'
          '${allenamento.data.month.toString().padLeft(2, '0')}/'
          '${allenamento.data.year}'
          '${allenamento.gruppo != null && allenamento.gruppo!.isNotEmpty ? ' · ${allenamento.gruppo}' : ''}',
        ),
      ),
      body: serieAsync.when(
        data: (serie) => serie.isEmpty
            ? EmptyState(
                icona: Icons.pool_outlined,
                titolo: 'Nessuna serie in questo allenamento',
                descrizione:
                    'Aggiungi le serie dalla scheda allenamento per vederle '
                    'qui a bordo vasca.',
                azionePrincipale: 'Torna indietro',
                onAzionePrincipale: () => Navigator.of(context).pop(),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemCount: serie.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.s12),
                itemBuilder: (context, index) {
                  final s = serie[index];
                  final tokens =
                      Theme.of(context).extension<DomainTokens>() ??
                      DomainTokens.standard;
                  final coloreZona = s.zona != null
                      ? tokens.colorePerZona(s.zona)
                      : AppColors.linea;
                  final meta = _metaSerie(s);
                  return LaneRule(
                    colore: coloreZona,
                    child: PoolCard(
                      padding: const EdgeInsets.all(AppSpacing.s20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                labelBlocco(s.blocco),
                                style: AppTypography.etichetta,
                              ),
                              if (s.zona != null) ...[
                                const SizedBox(width: AppSpacing.s8),
                                ZoneChip(sigla: s.zona!),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            '${s.ripetute}×${s.distanzaM}m '
                            '${labelStile(s.stile)} ${labelEsecuzione(s.esecuzione)}',
                            style: AppTypography.display,
                          ),
                          if (meta.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s8),
                            Wrap(
                              spacing: AppSpacing.s16,
                              runSpacing: AppSpacing.s4,
                              children: [
                                for (final m in meta)
                                  Text(m, style: AppTypography.piccolo),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare la scheda.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: SizedBox(
            height: AppSpacing.altezzaMinimaBersaglioVasca,
            child: PrimaryButton(
              label: 'Segna presenze',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PresenzeScreen(allenamento: allenamento),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
