import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/testata_pagina.dart';
import '../../referti/presentation/referto_partita_screen.dart';
import '../application/pallanuoto_providers.dart';
import '../domain/partita.dart';
import 'chip_risultato.dart';
import 'statistiche_partita_screen.dart';

/// Elenco partite per l'atleta collegato (FASE 13, punto 4): prossime e
/// giocate come nella schermata del coach, con il risultato sulle
/// giocate; da una partita giocata si raggiungono referto e statistiche
/// di squadra. Sola lettura: nessuna modifica (distinta/eventi/form) è
/// possibile da qui.
class PartiteAtletaListScreen extends ConsumerWidget {
  const PartiteAtletaListScreen({
    required this.clubId,
    this.filtroGruppoId,
    this.vistaAllenatore = false,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (mostra le partite di tutti i gruppi).
  final String? filtroGruppoId;

  /// Aperta dall'allenatore dalla scheda di un atleta: titolo non in
  /// prima persona.
  final bool vistaAllenatore;

  void _apriAzioni(BuildContext context, Partita partita) {
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
    final ambra = context.dominio.evidenzaAmbra;
    final oggi = soloData(DateTime.now());

    Widget scheda(Partita p, {required bool giocata}) {
      final oggiStesso = giorniTra(oggi, p.data) == 0;
      return SchedaElenco(
        leading: RiquadroData(p.data, colore: ambra, spento: giocata),
        occhiello: oggiStesso ? 'Oggi' : null,
        evidenza: oggiStesso ? ambra : null,
        titolo: 'vs ${p.avversario}',
        sottotitolo: [
          // Oggi lo dice gia' l'etichetta sopra: resta l'ora.
          if (!oggiStesso)
            quandoConOra(p.data, p.ora)
          else if (p.ora != null && p.ora!.isNotEmpty)
            'ore ${p.ora}',
          [
            p.inCasa ? 'in casa' : 'in trasferta',
            if (p.luogo != null && p.luogo!.isNotEmpty) p.luogo!,
          ].join(', '),
        ].join(' · '),
        trailing: giocata ? ChipRisultato(partita: p) : null,
        mostraFreccia: giocata,
        onTap: giocata ? () => _apriAzioni(context, p) : null,
      );
    }

    return AppScaffold(
      appBar: AppBar(),
      body: partiteAsync.when(
        data: (partite) {
          final prossime = partite.where((p) => !p.data.isBefore(oggi)).toList()
            ..sort((a, b) => a.data.compareTo(b.data));
          final giocate = partite.where((p) => p.data.isBefore(oggi)).toList()
            ..sort((a, b) => b.data.compareTo(a.data));
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s32),
            children: [
              TestataPagina(
                titolo: vistaAllenatore ? 'Partite' : 'Le mie partite',
                numeri: [
                  NumeroTestata(
                    valore: '${giocate.length}',
                    etichetta: 'Giocate',
                  ),
                  NumeroTestata(
                    valore: '${prossime.length}',
                    etichetta: 'Da giocare',
                  ),
                  NumeroTestata(
                    valore: prossime.isEmpty
                        ? '—'
                        : dataCompatta(prossime.first.data),
                    etichetta: 'La prossima',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
              if (partite.isEmpty)
                const EmptyState(
                  icona: Icons.sports_handball_outlined,
                  titolo: 'Nessuna partita',
                  descrizione: 'Le partite del club compariranno qui.',
                  azionePrincipale: 'Ho capito',
                ),
              if (prossime.isNotEmpty) ...[
                SezioneSchede(
                  titolo: 'Prossime',
                  figli: [for (final p in prossime) scheda(p, giocata: false)],
                ),
                const SizedBox(height: AppSpacing.s24),
              ],
              if (giocate.isNotEmpty)
                SezioneSchede(
                  titolo: 'Giocate',
                  figli: [for (final p in giocate) scheda(p, giocata: true)],
                ),
            ],
          );
        },
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
