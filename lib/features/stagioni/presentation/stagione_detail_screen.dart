import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/domain/categoria_fin.dart';
import '../../gruppi/presentation/cambio_categoria_screen.dart';
import '../../impegni/application/impegni_providers.dart';
import '../../impegni/domain/impegno.dart';
import '../../impegni/presentation/impegno_form_screen.dart';
import '../../impegni/presentation/impegno_screen.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../pallanuoto/presentation/distinta_screen.dart';
import '../../pallanuoto/presentation/partita_form_screen.dart';
import '../../statistiche/presentation/statistiche_squadra_screen.dart';
import '../data/duplicazione_stagione_service.dart';
import '../data/stagioni_repository.dart';
import '../domain/evento_calendario.dart';
import '../domain/stagione.dart';
import 'calendario_stagione_view.dart';
import '../../obiettivi/presentation/sezione_schede_obiettivi.dart';
import 'elimina_dialogs.dart';
import 'sezione_fasi.dart';
import 'stagione_form_screen.dart';

enum _AzioneStagione { duplica, modifica, elimina }

/// Scheda di una stagione: il calendario dei mesi della stagione (un tocco
/// su un giorno crea o apre una partita), poi il collegamento alle
/// statistiche di stagione, e campionato/obiettivo.
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
    } else if (origine is Impegno) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ImpegnoScreen(impegno: origine)),
      );
    }
  }

  void _creaImpegno(BuildContext context, DateTime giorno) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImpegnoFormScreen(
          clubId: stagione.clubId,
          giornoIniziale: giorno,
          gruppoIniziale: stagione.gruppoId,
        ),
      ),
    );
  }

  /// Un tocco su un giorno: quello che c'è (se c'è) e i due pulsanti per
  /// aggiungere una partita o un impegno.
  void _giornoSelezionato(
    BuildContext context,
    WidgetRef ref,
    DateTime giorno,
    List<EventoCalendario> eventi,
  ) {
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
              if (eventi.isNotEmpty) ...[
                AppListPanel(
                  righe: [
                    for (final e in eventi)
                      AppListRow(
                        titolo: e.titolo,
                        sottotitolo: [
                          if (e.diClub)
                            e.impegno
                                ? 'Tutto il club'
                                : 'Evento di tutto il club',
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
              ],
              SecondaryButton(
                label: 'Aggiungi partita',
                icon: Icons.add,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _creaEvento(context, ref, giorno);
                },
              ),
              const SizedBox(height: AppSpacing.s8),
              SecondaryButton(
                label: 'Aggiungi impegno',
                icon: Icons.event_note_outlined,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _creaImpegno(context, giorno);
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
      final navigator = Navigator.of(context);
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => StagioneDetailScreen(stagione: nuovaStagione),
        ),
      );
      // Su un altro anno sportivo: chi cambia categoria.
      final anno = annoStagioneSportiva(nuovaDataInizio);
      if (anno != annoStagioneSportiva(stagione.dataInizio)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Stagione duplicata sul ${etichettaStagioneSportiva(anno)}.',
            ),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Chi cambia categoria',
              onPressed: () => navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => CambioCategoriaScreen(
                    clubId: stagione.clubId,
                    annoStagione: anno,
                  ),
                ),
              ),
            ),
          ),
        );
      }
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
    final colori = context.colori;
    final partite =
        ref.watch(partiteListProvider(stagione.clubId)).value ?? const [];
    final eventi = eventiVisibiliInStagione(stagione, [
      for (final p in partite) EventoCalendario.daPartita(p),
    ]);
    final oggi = soloData(DateTime.now());
    final svolti = eventi.where((e) => e.data.isBefore(oggi)).length;
    final prossimo = eventi
        .where((e) => !e.data.isBefore(oggi))
        .map((e) => e.data)
        .fold<DateTime?>(
          null,
          (min, d) => min == null || d.isBefore(min) ? d : min,
        );
    const nomeEventi = 'Partite';
    // Nel calendario anche i giorni degli impegni (non nei numeri in alto).
    final conImpegni = [
      ...eventi,
      ...eventiVisibiliInStagione(
        stagione,
        eventiDaImpegni(
          ref.watch(impegniListProvider(stagione.clubId)).value ?? const [],
        ),
      ),
    ];

    String periodo(DateTime d) =>
        '${d.day} ${mesiBrevi[d.month - 1]} ${d.year}';

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: const Text('Stagione'),
        actions: [
          PopupMenuButton<_AzioneStagione>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Altre azioni',
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
          // Campionato, obiettivo e il collegamento alle statistiche
          // stanno in testata: prima erano in fondo, sotto un calendario
          // lungo quanto la stagione.
          TestataPagina(
            occhiello: [
              '${periodo(stagione.dataInizio)} – ${periodo(stagione.dataFine)}',
              if ((stagione.campionato ?? '').isNotEmpty) stagione.campionato!,
            ].join(' · '),
            titolo: stagione.nome,
            sottotitolo: (stagione.obiettivo ?? '').isNotEmpty
                ? 'Obiettivo: ${stagione.obiettivo}'
                : null,
            numeri: [
              NumeroTestata(valore: '${eventi.length}', etichetta: nomeEventi),
              NumeroTestata(valore: '$svolti', etichetta: 'Giocate'),
              NumeroTestata(
                valore: prossimo == null ? '—' : dataCompatta(prossimo),
                etichetta: 'La prossima',
              ),
            ],
            azioni: [
              AzioneTestata(
                icona: Icons.add,
                etichetta: 'Nuova partita',
                principale: true,
                onTap: () => _creaEvento(context, ref, DateTime.now()),
              ),
              AzioneTestata(
                icona: Icons.event_note_outlined,
                etichetta: 'Nuovo impegno',
                onTap: () => _creaImpegno(context, DateTime.now()),
              ),
              AzioneTestata(
                icona: Icons.query_stats,
                etichetta: 'Statistiche',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StatisticheSquadraScreen(
                      clubId: stagione.clubId,
                      stagioneId: stagione.id,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          SezioneFasi(stagione: stagione),
          const SizedBox(height: AppSpacing.s24),
          SezioneSchedeObiettivi(stagione: stagione),
          const SizedBox(height: AppSpacing.s24),
          const TitoloSezione(
            'Calendario',
            spiegazione:
                'Tocca un giorno per aggiungere una partita o un impegno '
                '(collegiale, trasferta, riposo, torneo) in quella data, o '
                'per aprire quello che c\'è in programma.',
          ),
          PoolCard(
            padding: const EdgeInsets.all(AppSpacing.s8),
            // Larghezza contenuta: su schermo largo le celle quadrate di
            // sette colonne diventavano enormi.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: CalendarioStagioneView(
                  primoGiorno: stagione.dataInizio,
                  ultimoGiorno: stagione.dataFine,
                  eventi: conImpegni,
                  onGiornoSelezionato: (giorno, eventiDelGiorno) =>
                      _giornoSelezionato(context, ref, giorno, eventiDelGiorno),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
