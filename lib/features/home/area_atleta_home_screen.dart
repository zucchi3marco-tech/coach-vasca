import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_list_panel.dart';
import '../../widgets/app_list_row.dart';
import '../../widgets/stat_panel.dart';
import '../allenamenti/application/allenamenti_providers.dart';
import '../allenamenti/domain/allenamento.dart';
import '../atleti/domain/atleta.dart';
import '../atleti/presentation/pb_list_screen.dart';
import '../carico/presentation/carico_atleta_screen.dart';
import '../club/application/current_club_provider.dart';
import '../pallanuoto/application/pallanuoto_providers.dart';
import '../pallanuoto/domain/partita.dart';
import '../pallanuoto/presentation/partite_atleta_list_screen.dart';
import '../presenze/application/presenze_providers.dart';
import '../presenze/presentation/mie_presenze_screen.dart';
import '../stagioni/application/stagioni_providers.dart';
import '../stagioni/domain/stagione.dart';
import '../stagioni/presentation/stagione_atleta_screen.dart';
import '../statistiche/presentation/statistiche_atleta_screen.dart';

String _formattaData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year}';

/// Home dell'atleta collegato (FASE 9, ampliata FASE 13 punto 3): mostrata
/// da HomeScreen al posto delle tab da coach quando l'account autenticato
/// non e' membro di nessun club ma e' collegato a un record atleti.
/// Nessun Scaffold proprio: e' incorporata nel body di HomeScreen, che ha
/// gia' AppBar e pulsante "Esci".
class AreaAtletaHomeScreen extends ConsumerWidget {
  const AreaAtletaHomeScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(currentClubProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(atleta.nomeCompleto, style: AppTypography.titoloXl),
            const SizedBox(height: AppSpacing.s4),
            clubAsync.when(
              data: (club) =>
                  Text(club?.nome ?? '', style: AppTypography.piccolo),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.s24),
            _RiepilogoOggi(atleta: atleta),
            const SizedBox(height: AppSpacing.s24),
            _ProssimiAllenamenti(atleta: atleta),
            if (atleta.sport == 'pallanuoto') ...[
              const SizedBox(height: AppSpacing.s24),
              _ProssimoEvento(clubId: atleta.clubId),
            ],
            const SizedBox(height: AppSpacing.s24),
            AppListPanel(
              righe: [
                AppListRow(
                  leading: const Icon(Icons.emoji_events_outlined),
                  titolo: 'I miei personal best',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PbListScreen(atleta: atleta),
                    ),
                  ),
                ),
                if (atleta.sport == 'pallanuoto')
                  AppListRow(
                    leading: const Icon(Icons.bar_chart_outlined),
                    titolo: 'Le mie statistiche',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StatisticheAtletaScreen(atleta: atleta),
                      ),
                    ),
                  ),
                if (atleta.sport == 'pallanuoto')
                  AppListRow(
                    leading: const Icon(Icons.sports_outlined),
                    titolo: 'Le mie partite',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PartiteAtletaListScreen(clubId: atleta.clubId),
                      ),
                    ),
                  ),
                AppListRow(
                  leading: const Icon(Icons.show_chart),
                  titolo: 'Il mio carico',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CaricoAtletaScreen(atleta: atleta),
                    ),
                  ),
                ),
                AppListRow(
                  leading: const Icon(Icons.how_to_reg_outlined),
                  titolo: 'Le mie presenze',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MiePresenzeScreen(atleta: atleta),
                    ),
                  ),
                ),
                AppListRow(
                  leading: const Icon(Icons.event_note_outlined),
                  titolo: 'La mia stagione',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StagioneAtletaScreen(atleta: atleta),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Data odierna, percentuale presenze e stagione in corso del gruppo
/// dell'atleta, in un'unica riga di riepilogo in testa alla home.
class _RiepilogoOggi extends ConsumerWidget {
  const _RiepilogoOggi({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenzeAsync = ref.watch(presenzePerAtletaProvider(atleta.id));
    final allenamentiAsync = ref.watch(
      allenamentiAtletaProvider(atleta.clubId),
    );
    final stagioniAsync = ref.watch(stagioniListProvider(atleta.clubId));

    String? percentuale;
    if (presenzeAsync.hasValue && allenamentiAsync.hasValue) {
      final allenamenti = allenamentiAsync.value!;
      final haGruppo = atleta.gruppoId != null;
      final delGruppo = haGruppo
          ? allenamenti.where((a) => a.gruppoId == atleta.gruppoId).toList()
          : allenamenti;
      final rilevanti = delGruppo.isEmpty ? allenamenti : delGruppo;
      if (rilevanti.isNotEmpty) {
        final idRilevanti = rilevanti.map((a) => a.id).toSet();
        final presenti = presenzeAsync.value!
            .where(
              (p) =>
                  p.stato == 'presente' &&
                  idRilevanti.contains(p.allenamentoId),
            )
            .length;
        percentuale = '${(presenti / rilevanti.length * 100).round()}%';
      }
    }

    final stagioneCorrente = stagioniAsync.hasValue
        ? stagioneCorrenteDiGruppo(stagioniAsync.value!, atleta.gruppoId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s24,
          runSpacing: AppSpacing.s16,
          children: [
            StatPanel(etichetta: 'Oggi', valore: _formattaData(DateTime.now())),
            StatPanel(etichetta: '% presenze', valore: percentuale ?? '—'),
          ],
        ),
        if (stagioneCorrente != null) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Stagione in corso: ${stagioneCorrente.nome} '
            '(${_formattaData(stagioneCorrente.dataInizio)} - '
            '${_formattaData(stagioneCorrente.dataFine)})',
            style: AppTypography.piccolo,
          ),
        ],
      ],
    );
  }
}

/// Allenamenti del gruppo dell'atleta nei prossimi 7 giorni (oggi
/// incluso).
class _ProssimiAllenamenti extends ConsumerWidget {
  const _ProssimiAllenamenti({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allenamentiAsync = ref.watch(
      allenamentiAtletaProvider(atleta.clubId),
    );

    return allenamentiAsync.when(
      data: (allenamenti) {
        final oggi = DateTime.now();
        final inizio = DateTime(oggi.year, oggi.month, oggi.day);
        final fine = inizio.add(const Duration(days: 7));
        final prossimi =
            allenamenti
                .where(
                  (a) =>
                      (atleta.gruppoId == null ||
                          a.gruppoId == atleta.gruppoId) &&
                      !a.data.isBefore(inizio) &&
                      a.data.isBefore(fine),
                )
                .toList()
              ..sort((a, b) => a.data.compareTo(b.data));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allenamenti dei prossimi 7 giorni',
              style: AppTypography.etichetta,
            ),
            const SizedBox(height: AppSpacing.s8),
            if (prossimi.isEmpty)
              Text('Nessuno in programma.', style: AppTypography.piccolo)
            else
              AppListPanel(
                righe: [
                  for (final Allenamento a in prossimi)
                    AppListRow(
                      leading: const Icon(Icons.calendar_month_outlined),
                      titolo: a.titolo ?? 'Allenamento',
                      sottotitolo: _formattaData(a.data),
                    ),
                ],
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Prossima partita in agenda per il club (solo atleti di pallanuoto).
class _ProssimoEvento extends ConsumerWidget {
  const _ProssimoEvento({required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partitaAsync = ref.watch(prossimaPartitaProvider(clubId));

    return partitaAsync.when(
      data: (Partita? partita) {
        if (partita == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prossimo evento', style: AppTypography.etichetta),
            const SizedBox(height: AppSpacing.s8),
            AppListPanel(
              righe: [
                AppListRow(
                  leading: const Icon(Icons.sports_outlined),
                  titolo:
                      '${partita.squadraCasa} - ${partita.squadraTrasferta}',
                  sottotitolo:
                      '${_formattaData(partita.data)}'
                      '${partita.ora != null ? ' · ${partita.ora}' : ''}'
                      '${partita.luogo != null ? ' · ${partita.luogo}' : ''}',
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
