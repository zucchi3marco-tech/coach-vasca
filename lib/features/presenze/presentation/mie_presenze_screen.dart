import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/stat_panel.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/domain/atleta.dart';
import '../application/presenze_providers.dart';
import '../domain/presenza.dart';

String _etichettaStato(String stato) {
  switch (stato) {
    case 'presente':
      return 'Presente';
    case 'giustificato':
      return 'Giustificato';
    default:
      return 'Assente';
  }
}

IconData _iconaStato(String stato) {
  switch (stato) {
    case 'presente':
      return Icons.check_circle_outline;
    case 'giustificato':
      return Icons.event_note_outlined;
    default:
      return Icons.close;
  }
}

Color _coloreStato(String stato) {
  switch (stato) {
    case 'presente':
      return AppColors.ok;
    case 'giustificato':
      return AppColors.attenzione;
    default:
      return AppColors.testoSecondario;
  }
}

/// Presenze e percentuali del solo atleta collegato (FASE 9). La
/// percentuale usa come denominatore gli allenamenti del club con lo
/// stesso `gruppo` dell'atleta (campo testo libero: se l'atleta non ha
/// un gruppo impostato, o nessun allenamento lo riporta, si conta su
/// tutti gli allenamenti del club).
class MiePresenzeScreen extends ConsumerWidget {
  const MiePresenzeScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenzeAsync = ref.watch(presenzePerAtletaProvider(atleta.id));
    final allenamentiAsync = ref.watch(allenamentiListProvider(atleta.clubId));

    return AppScaffold(
      appBar: AppBar(title: const Text('Le mie presenze')),
      body: presenzeAsync.when(
        data: (presenze) => allenamentiAsync.when(
          data: (allenamenti) => _Contenuto(
            atleta: atleta,
            presenze: presenze,
            allenamenti: allenamenti,
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s16),
            child: LoadingSkeletonList(righe: 5),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: ErrorBanner(
              messaggio: 'Non è stato possibile caricare gli allenamenti.',
              suggerimento:
                  'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
              dettaglioTecnico: messaggioErrore(error),
            ),
          ),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare le presenze.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}

class _Contenuto extends StatelessWidget {
  const _Contenuto({
    required this.atleta,
    required this.presenze,
    required this.allenamenti,
  });

  final Atleta atleta;
  final List<Presenza> presenze;
  final List<Allenamento> allenamenti;

  @override
  Widget build(BuildContext context) {
    final haGruppo = atleta.gruppoId != null;
    final delGruppo = haGruppo
        ? allenamenti.where((a) => a.gruppoId == atleta.gruppoId).toList()
        : allenamenti;
    final rilevanti = delGruppo.isEmpty ? allenamenti : delGruppo;

    final oggi = DateTime.now();
    final inizioMese = DateTime(oggi.year, oggi.month, 1);
    final delMese = rilevanti
        .where((a) => !a.data.isBefore(inizioMese))
        .toList();

    final allenamentoPerId = {for (final a in allenamenti) a.id: a};

    int contaPresenti(List<Allenamento> periodo) {
      final idPeriodo = periodo.map((a) => a.id).toSet();
      return presenze
          .where(
            (p) => p.stato == 'presente' && idPeriodo.contains(p.allenamentoId),
          )
          .length;
    }

    final numeroPresenze = presenze.where((p) => p.stato == 'presente').length;
    final percentualeMese = delMese.isEmpty
        ? null
        : contaPresenti(delMese) / delMese.length * 100;
    final percentualeTotale = rilevanti.isEmpty
        ? null
        : contaPresenti(rilevanti) / rilevanti.length * 100;

    final storico = [...presenze]
      ..sort((a, b) {
        final dataA = allenamentoPerId[a.allenamentoId]?.data;
        final dataB = allenamentoPerId[b.allenamentoId]?.data;
        if (dataA == null || dataB == null) return 0;
        return dataB.compareTo(dataA);
      });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        Wrap(
          spacing: AppSpacing.s24,
          runSpacing: AppSpacing.s16,
          children: [
            StatPanel(etichetta: 'Presenze totali', valore: '$numeroPresenze'),
            StatPanel(
              etichetta: '% questo mese',
              valore: percentualeMese == null
                  ? '—'
                  : '${percentualeMese.round()}%',
            ),
            StatPanel(
              etichetta: '% totale',
              valore: percentualeTotale == null
                  ? '—'
                  : '${percentualeTotale.round()}%',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        SectionHeader('Storico'),
        const SizedBox(height: AppSpacing.s16),
        if (storico.isEmpty)
          Text(
            'Nessuna presenza registrata ancora.',
            style: AppTypography.corpo,
          )
        else
          AppListPanel(
            righe: [
              for (final p in storico)
                AppListRow(
                  leading: Icon(_iconaStato(p.stato), color: _coloreStato(p.stato)),
                  titolo: _formattaData(allenamentoPerId[p.allenamentoId]?.data),
                  sottotitolo: _etichettaStato(p.stato),
                ),
            ],
          ),
      ],
    );
  }

  String _formattaData(DateTime? data) {
    if (data == null) return 'Allenamento';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }
}
