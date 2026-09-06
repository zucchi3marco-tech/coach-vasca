import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/stat_panel.dart';
import '../../atleti/domain/atleta.dart';
import '../../stagioni/domain/stagione.dart';
import '../application/statistiche_providers.dart';
import '../domain/statistiche_stagionali.dart';
import 'selettore_stagione.dart';

class StatisticheAtletaScreen extends ConsumerStatefulWidget {
  const StatisticheAtletaScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  ConsumerState<StatisticheAtletaScreen> createState() =>
      _StatisticheAtletaScreenState();
}

class _StatisticheAtletaScreenState
    extends ConsumerState<StatisticheAtletaScreen> {
  Stagione? _stagione;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text('Statistiche — ${widget.atleta.nomeCompleto}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelettoreStagione(
            clubId: widget.atleta.clubId,
            onCambiata: (s) => setState(() => _stagione = s),
          ),
          if (_stagione != null) ...[
            const SizedBox(height: AppSpacing.s16),
            Expanded(
              child: _DatiAtleta(atleta: widget.atleta, stagione: _stagione!),
            ),
          ],
        ],
      ),
    );
  }
}

class _DatiAtleta extends ConsumerWidget {
  const _DatiAtleta({required this.atleta, required this.stagione});

  final Atleta atleta;
  final Stagione stagione;

  RigaAtletaReferti? _trovaReferti(List<RigaAtletaReferti> righe) {
    for (final r in righe) {
      if (r.atletaId == atleta.id) return r;
    }
    return null;
  }

  RigaAtletaEventi? _trovaEventi(List<RigaAtletaEventi> righe) {
    for (final r in righe) {
      if (r.atletaId == atleta.id) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chiave = (
      clubId: atleta.clubId,
      dataInizio: stagione.dataInizio,
      dataFine: stagione.dataFine,
    );
    final refertiAsync = ref.watch(riepilogoRefertiProvider(chiave));
    final eventiAsync = ref.watch(riepilogoEventiProvider(chiave));

    return refertiAsync.when(
      data: (r) => eventiAsync.when(
        data: (e) {
          final rigaReferti = _trovaReferti(r.perAtleta);
          final rigaEventi = _trovaEventi(e.perAtleta);
          return ListView(
            children: [
              SectionHeader('Da referti'),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Non include i tiri sbagliati (non registrati nel referto).',
                style: AppTypography.piccolo,
              ),
              const SizedBox(height: AppSpacing.s16),
              if (rigaReferti == null)
                Text(
                  'Nessun dato da referto in questa stagione.',
                  style: AppTypography.corpo,
                )
              else
                Wrap(
                  spacing: AppSpacing.s24,
                  runSpacing: AppSpacing.s16,
                  children: [
                    StatPanel(etichetta: 'Reti', valore: '${rigaReferti.reti}'),
                    StatPanel(
                      etichetta: 'Espulsioni',
                      valore: '${rigaReferti.espulsioni}',
                    ),
                    StatPanel(
                      etichetta: 'Partite',
                      valore: '${rigaReferti.partite}',
                    ),
                    StatPanel(
                      etichetta: 'Reti/partita',
                      valore: rigaReferti.mediaRetiPartita.toStringAsFixed(2),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.s28),
              SectionHeader('Da eventi live'),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Solo dalle partite seguite dal vivo con "Eventi partita".',
                style: AppTypography.piccolo,
              ),
              const SizedBox(height: AppSpacing.s16),
              if (rigaEventi == null)
                Text(
                  'Nessun evento registrato in questa stagione.',
                  style: AppTypography.corpo,
                )
              else ...[
                Wrap(
                  spacing: AppSpacing.s24,
                  runSpacing: AppSpacing.s16,
                  children: [
                    StatPanel(
                      etichetta: 'Gol',
                      valore: '${rigaEventi.gol}/${rigaEventi.tiri}',
                      confronto: rigaEventi.tiri > 0
                          ? '${(rigaEventi.gol / rigaEventi.tiri * 100).round()}%'
                          : null,
                    ),
                    StatPanel(
                      etichetta: 'Espulsioni',
                      valore: '${rigaEventi.espulsioni}',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                Wrap(
                  spacing: AppSpacing.s24,
                  runSpacing: AppSpacing.s16,
                  children: [
                    StatPanel(
                      etichetta: 'Gol azione',
                      valore: '${rigaEventi.golAzione}',
                    ),
                    StatPanel(
                      etichetta: 'Gol superiorità',
                      valore: '${rigaEventi.golSuperiorita}',
                    ),
                    StatPanel(
                      etichetta: 'Gol rigore',
                      valore: '${rigaEventi.golRigore}',
                    ),
                  ],
                ),
              ],
            ],
          );
        },
        loading: () => const LoadingSkeletonList(righe: 4),
        error: (err, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli eventi.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(err),
        ),
      ),
      loading: () => const LoadingSkeletonList(righe: 4),
      error: (err, _) => ErrorBanner(
        messaggio: 'Non è stato possibile caricare i referti.',
        suggerimento:
            'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
        dettaglioTecnico: messaggioErrore(err),
      ),
    );
  }
}
