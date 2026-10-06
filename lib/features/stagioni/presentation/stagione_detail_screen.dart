import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/secondary_button.dart';
import '../../atleti/presentation/record_club_screen.dart';
import '../../club/application/current_club_provider.dart';
import '../../gare/application/gare_providers.dart';
import '../../gare/domain/gara.dart';
import '../../gare/presentation/gara_detail_screen.dart';
import '../../gare/presentation/gara_form_screen.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../pallanuoto/presentation/distinta_screen.dart';
import '../../pallanuoto/presentation/partita_form_screen.dart';
import '../../statistiche/presentation/statistiche_squadra_screen.dart';
import '../data/duplicazione_stagione_service.dart';
import '../data/stagioni_repository.dart';
import '../domain/evento_calendario.dart';
import '../domain/stagione.dart';
import '../../../widgets/titolo_due_righe.dart';
import 'calendario_stagione_view.dart';
import 'elimina_dialogs.dart';
import 'stagione_form_screen.dart';

enum _AzioneStagione { duplica, modifica, elimina }

/// Scheda di una stagione: il calendario dei mesi della stagione (un tocco
/// su un giorno crea o apre una partita/gara), poi il collegamento alle
/// statistiche di stagione (pallanuoto) o ai record di club (nuoto),
/// secondo lo sport del club, e campionato/obiettivo.
class StagioneDetailScreen extends ConsumerWidget {
  const StagioneDetailScreen({required this.stagione, super.key});

  final Stagione stagione;

  static const _nomiGiorni = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  String _titoloGiorno(DateTime d) =>
      '${_nomiGiorni[d.weekday - 1]} ${d.day}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _creaEvento(BuildContext context, WidgetRef ref, DateTime giorno) {
    final sport = ref.read(currentClubProvider).value?.sport;
    if (sport == 'nuoto') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GaraFormScreen(
            clubId: stagione.clubId,
            stagione: stagione,
            dataIniziale: giorno,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PartitaFormScreen(
          clubId: stagione.clubId,
          stagione: stagione,
          dataIniziale: giorno,
        ),
      ),
    );
  }

  void _apriEvento(BuildContext context, EventoCalendario evento) {
    final origine = evento.origine;
    if (origine is Partita) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DistintaScreen(partita: origine)),
      );
    } else if (origine is Gara) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GaraDetailScreen(gara: origine)),
      );
    }
  }

  void _giornoSelezionato(
    BuildContext context,
    WidgetRef ref,
    DateTime giorno,
    List<EventoCalendario> eventi,
  ) {
    if (eventi.isEmpty) {
      _creaEvento(context, ref, giorno);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _titoloGiorno(giorno),
                style: AppTypography.sezione.copyWith(
                  color: sheetContext.colori.testo,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              AppListPanel(
                righe: [
                  for (final e in eventi)
                    AppListRow(
                      titolo: e.titolo,
                      sottotitolo: [
                        if (e.diClub) 'Evento di tutto il club',
                        ?e.sottotitolo,
                      ].join(' · '),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _apriEvento(context, e);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              SecondaryButton(
                label: ref.read(currentClubProvider).value?.sport == 'nuoto'
                    ? 'Aggiungi gara'
                    : 'Aggiungi partita',
                icon: Icons.add,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _creaEvento(context, ref, giorno);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _elimina(BuildContext context, WidgetRef ref) async {
    final conferma = await confermaEliminaStagione(context);
    if (conferma && context.mounted) {
      await ref.read(stagioniRepositoryProvider).deleteStagione(stagione.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _duplicaStagione(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final nuovaDataInizio = await showDatePicker(
      context: context,
      initialDate: stagione.dataInizio,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'Data di inizio della nuova stagione',
    );
    if (nuovaDataInizio == null) return;
    try {
      final nuovaStagione = await ref
          .read(duplicazioneStagioneServiceProvider)
          .duplica(stagione, nuovaDataInizio);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StagioneDetailScreen(stagione: nuovaStagione),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Errore nella duplicazione: ${messaggioErrore(e)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // null finche' il club non ha ancora compilato lo sport (o durante il
    // caricamento): in quel caso si mostrano entrambe le sezioni, non si
    // nasconde contenuto per un dato mancante.
    final sport = ref.watch(currentClubProvider).value?.sport;
    final mostraPallanuoto = sport == null || sport == 'pallanuoto';
    final mostraNuoto = sport == null || sport == 'nuoto';
    final colori = context.colori;
    final partite = mostraPallanuoto
        ? ref.watch(partiteListProvider(stagione.clubId)).value ?? const []
        : const <Partita>[];
    final gare = mostraNuoto
        ? ref.watch(gareListProvider(stagione.clubId)).value ?? const []
        : const <Gara>[];
    final eventi = eventiVisibiliInStagione(stagione, [
      for (final p in partite) EventoCalendario.daPartita(p),
      for (final g in gare) EventoCalendario.daGara(g),
    ]);

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        // "Stagione agonistica 2026/2027" su telefono veniva troncato:
        // il nome intero sta nella seconda riga.
        title: TitoloDueRighe(titolo: 'Stagione', sottotitolo: stagione.nome),
        actions: [
          PopupMenuButton<_AzioneStagione>(
            icon: const Icon(Icons.more_vert),
            onSelected: (azione) {
              switch (azione) {
                case _AzioneStagione.duplica:
                  _duplicaStagione(context, ref);
                case _AzioneStagione.modifica:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StagioneFormScreen(
                        clubId: stagione.clubId,
                        stagione: stagione,
                      ),
                    ),
                  );
                case _AzioneStagione.elimina:
                  _elimina(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _AzioneStagione.duplica,
                child: Row(
                  children: [
                    Icon(Icons.content_copy_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Duplica stagione'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _AzioneStagione.modifica,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Modifica'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AzioneStagione.elimina,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: colori.rosso),
                    const SizedBox(width: AppSpacing.s12),
                    Text('Elimina', style: TextStyle(color: colori.rosso)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalendarioStagioneView(
            primoGiorno: stagione.dataInizio,
            ultimoGiorno: stagione.dataFine,
            eventi: eventi,
            onGiornoSelezionato: (giorno, eventiDelGiorno) =>
                _giornoSelezionato(context, ref, giorno, eventiDelGiorno),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppListPanel(
            righe: [
              if (mostraPallanuoto)
                AppListRow(
                  leading: const Icon(Icons.query_stats),
                  titolo: 'Statistiche di stagione',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          StatisticheSquadraScreen(clubId: stagione.clubId),
                    ),
                  ),
                ),
              if (mostraNuoto)
                AppListRow(
                  leading: const Icon(Icons.emoji_events_outlined),
                  titolo: 'Record',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecordClubScreen(clubId: stagione.clubId),
                    ),
                  ),
                ),
            ],
          ),
          if ((stagione.campionato ?? '').isNotEmpty ||
              (stagione.obiettivo ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s16),
            if ((stagione.campionato ?? '').isNotEmpty)
              Text(
                'Campionato: ${stagione.campionato}',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
            if ((stagione.obiettivo ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Obiettivo: ${stagione.obiettivo}',
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
