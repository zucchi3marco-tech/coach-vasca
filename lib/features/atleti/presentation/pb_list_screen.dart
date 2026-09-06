import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../application/personal_best_providers.dart';
import '../domain/atleta.dart';
import '../domain/personal_best.dart';
import 'pb_form_screen.dart';

String _capitalizza(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class PbListScreen extends ConsumerWidget {
  const PbListScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbAsync = ref.watch(personalBestListProvider(atleta.id));

    void apriForm({PersonalBest? personalBest}) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PbFormScreen(
          atletaId: atleta.id,
          personalBest: personalBest,
        ),
      ),
    );

    return AppScaffold(
      appBar: AppBar(title: const Text('I miei personal best')),
      body: pbAsync.when(
        data: (righe) => righe.isEmpty
            ? EmptyState(
                icona: Icons.emoji_events_outlined,
                titolo: 'Nessun personal best registrato',
                descrizione:
                    'Aggiungi il tuo primo tempo per iniziare a tenerne '
                    'traccia.',
                azionePrincipale: 'Nuovo personal best',
                onAzionePrincipale: () => apriForm(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: AppListPanel(
                  righe: [
                    for (final pb in righe)
                      AppListRow(
                        titolo: '${pb.distanzaM}m ${_capitalizza(pb.stile)}',
                        sottotitolo: formatPaceSeconds(pb.tempoS),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => apriForm(personalBest: pb),
                      ),
                  ],
                ),
              ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare i personal best.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-pb',
        onPressed: () => apriForm(),
        tooltip: 'Nuovo personal best',
        child: const Icon(Icons.add),
      ),
    );
  }
}
