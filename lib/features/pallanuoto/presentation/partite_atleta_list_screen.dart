import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../referti/presentation/referto_partita_screen.dart';
import '../application/pallanuoto_providers.dart';
import '../domain/partita.dart';
import '../domain/risultato_partita.dart';
import 'statistiche_partita_screen.dart';

String _formattaData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year}';

/// Elenco partite per l'atleta collegato (FASE 13, punto 4): risultato
/// visibile direttamente in riga per le partite già giocate, senza
/// doverle aprire; da una partita giocata si raggiungono referto (se
/// analizzato) e statistiche di squadra. Sola lettura: a differenza della
/// schermata del coach, nessuna modifica (distinta/eventi/form) è
/// possibile da qui.
class PartiteAtletaListScreen extends ConsumerWidget {
  const PartiteAtletaListScreen({
    required this.clubId,
    this.filtroGruppoId,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (mostra le partite di tutti i gruppi).
  final String? filtroGruppoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuttePartite = ref.watch(partiteListProvider(clubId));
    // Stessa regola di isolamento per gruppo delle liste del coach: una
    // partita senza gruppo resta visibile a tutti.
    final partiteAsync = filtroGruppoId == null
        ? tuttePartite
        : tuttePartite.whenData(
            (partite) => partite
                .where(
                  (p) => p.gruppoId == filtroGruppoId || p.gruppoId == null,
                )
                .toList(),
          );

    return AppScaffold(
      appBar: AppBar(title: const Text('Le mie partite')),
      body: partiteAsync.when(
        data: (partite) => partite.isEmpty
            ? const EmptyState(
                icona: Icons.sports_handball_outlined,
                titolo: 'Nessuna partita',
                descrizione: 'Le partite del club compariranno qui.',
                azionePrincipale: 'Torna indietro',
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: AppListPanel(
                  righe: [for (final p in partite) _RigaPartita(partita: p)],
                ),
              ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 6),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare le partite.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}

class _RigaPartita extends ConsumerWidget {
  const _RigaPartita({required this.partita});

  final Partita partita;

  void _apriAzioni(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Statistiche di squadra'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StatistichePartitaScreen(partita: partita),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Referto'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RefertoPartitaScreen(partita: partita),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventiAsync = ref.watch(eventiPartitaListProvider(partita.id));
    final risultato = eventiAsync.value == null
        ? null
        : risultatoPartita(eventiAsync.value!, partita);

    return AppListRow(
      leading: const Icon(Icons.sports_outlined),
      titolo: '${partita.squadraCasa} - ${partita.squadraTrasferta}',
      sottotitolo:
          '${_formattaData(partita.data)}'
          '${partita.luogo != null ? ' · ${partita.luogo}' : ''}',
      trailing: risultato == null
          ? null
          : Text(
              '${risultato.golCasa} - ${risultato.golTrasferta}',
              style: AppTypography.corpoForte.copyWith(
                color: context.colori.testo,
              ),
            ),
      onTap: risultato == null ? null : () => _apriAzioni(context),
    );
  }
}
