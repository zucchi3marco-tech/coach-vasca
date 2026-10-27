import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/cap_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../referti/presentation/referto_partita_screen.dart';
import '../application/pallanuoto_providers.dart';
import '../data/distinta_repository.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/partita.dart';
import 'capitani_distinta.dart';
import 'convocazione_screen.dart';
import 'partita_form_screen.dart';
import 'partita_live_screen.dart';
import 'riordina_numeri_screen.dart';
import 'scegli_convocati_screen.dart';
import 'scheda_avversario_screen.dart';
import 'staff_distinta_dialog.dart';
import 'statistiche_partita_screen.dart';
import 'video_partita_screen.dart';

/// La scheda di una partita: dati e azioni del giorno della partita in
/// testata, sotto la distinta dei convocati.
class DistintaScreen extends ConsumerWidget {
  const DistintaScreen({required this.partita, super.key});

  final Partita partita;

  /// Il modulo FIN della distinta, in Excel come il foglio del coach.
  Future<void> _esporta(
    BuildContext context,
    WidgetRef ref,
    List<DistintaGiocatore> convocati,
    Map<String, Atleta> atletiPerId,
  ) => esportaDistintaExcel(
    context,
    ref,
    partita: partita,
    convocati: [
      for (final g in convocati)
        if (atletiPerId[g.atletaId] case final atleta?)
          (giocatore: g, atleta: atleta),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distintaAsync = ref.watch(distintaListProvider(partita.id));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: partita.clubId, includeInactive: false)),
    );
    final convocati = distintaAsync.value;

    void apri(Widget schermata) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => schermata));

    // Tutti i convocati in una pagina: si spuntano e si salva una volta.
    Future<void> scegliConvocati() async {
      final salvato = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ScegliConvocatiScreen(partita: partita),
        ),
      );
      if (salvato == true && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Distinta salvata.')));
      }
    }

    Future<void> riordina(
      List<DistintaGiocatore> convocati,
      Map<String, Atleta> atletiPerId,
    ) async {
      final salvato = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => RiordinaNumeriScreen(
            partita: partita,
            convocati: convocati,
            atletiPerId: atletiPerId,
          ),
        ),
      );
      if (salvato == true && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Numeri salvati.')));
      }
    }

    // La scheda della partita: le azioni del giorno della partita (dal
    // vivo, statistiche, referto) stanno in vista nella testata — prima
    // erano nel menu ⋮ — e sotto c'e' la distinta.
    final testata = TestataPagina(
      occhiello: [
        quandoEsteso(partita.data),
        if (partita.ora != null && partita.ora!.isNotEmpty)
          'ore ${partita.ora}',
      ].join(' · '),
      titolo: '${partita.squadraCasa} – ${partita.squadraTrasferta}',
      // Luogo e campionato; la calottina accanto al luogo, dove serve
      // saperla (in vasca).
      sottotitolo: [
        [
          if (partita.luogo != null && partita.luogo!.isNotEmpty)
            partita.luogo!,
          if (partita.coloreCalottina != null &&
              partita.coloreCalottina!.isNotEmpty)
            'calottina ${partita.coloreCalottina == 'blu' ? 'blu' : 'bianca'}',
        ].join(', '),
        if (partita.campionato != null && partita.campionato!.isNotEmpty)
          partita.campionato!,
      ].where((t) => t.isNotEmpty).join(' · '),
      azioni: [
        AzioneTestata(
          icona: Icons.play_circle_fill,
          etichetta: 'Dal vivo',
          principale: true,
          onTap: () => apri(PartitaLiveScreen(partita: partita)),
        ),
        // La convocazione serve prima: fino al giorno della partita.
        if (!partita.data.isBefore(soloData(DateTime.now())))
          AzioneTestata(
            icona: Icons.campaign_outlined,
            etichetta: 'Convocazione',
            onTap: () => apri(ConvocazioneScreen(partita: partita)),
          ),
        AzioneTestata(
          icona: Icons.bar_chart,
          etichetta: 'Statistiche',
          onTap: () => apri(StatistichePartitaScreen(partita: partita)),
        ),
        AzioneTestata(
          icona: Icons.description_outlined,
          etichetta: 'Referto',
          onTap: () => apri(RefertoPartitaScreen(partita: partita)),
        ),
        AzioneTestata(
          icona: Icons.shield_outlined,
          etichetta: 'Avversario',
          onTap: () => apri(
            SchedaAvversarioScreen(
              clubId: partita.clubId,
              gruppoId: partita.gruppoId,
              nome: partita.avversario,
              partitaId: partita.id,
              vistaStaff: true,
            ),
          ),
        ),
        // Il video c'è solo dopo: dal giorno della partita.
        if (!partita.data.isAfter(DateTime.now()))
          AzioneTestata(
            icona: Icons.ondemand_video_outlined,
            etichetta: 'Video',
            onTap: () => apri(VideoPartitaScreen(partita: partita)),
          ),
      ],
    );

    final List<Widget> corpo = distintaAsync.when(
      data: (convocati) => atletiAsync.when(
        data: (atleti) {
          final atletiPerId = {for (final a in atleti) a.id: a};
          if (convocati.isEmpty) {
            return [
              EmptyState(
                icona: Icons.groups_outlined,
                titolo: 'Nessun convocato',
                descrizione:
                    'Spunta tutti i convocati in una volta: i numeri '
                    'arrivano dall\'ultima partita della squadra.',
                azionePrincipale: 'Scegli i convocati',
                onAzionePrincipale: scegliConvocati,
              ),
            ];
          }
          return [
            CapitaniDistinta(
              partita: partita,
              convocati: convocati,
              atletiPerId: atletiPerId,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppListPanel(
              righe: [
                for (final g in convocati)
                  _RigaConvocato(
                    giocatore: g,
                    atleta: atletiPerId[g.atletaId],
                    coloreCalottina: partita.coloreCalottina,
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => _DialogModificaConvocato(
                        partita: partita,
                        convocato: g,
                        convocati: convocati,
                        atletiPerId: atletiPerId,
                      ),
                    ),
                  ),
              ],
            ),
            if (convocati.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => riordina(convocati, atletiPerId),
                    icon: const Icon(Icons.swap_vert),
                    label: const Text('Riordina i numeri'),
                  ),
                ),
              ),
          ];
        },
        loading: () => const [LoadingSkeletonList(righe: 5)],
        error: (error, _) => [
          ErrorBanner(
            messaggio: 'Non è stato possibile caricare gli atleti.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ],
      ),
      loading: () => const [LoadingSkeletonList(righe: 5)],
      error: (error, _) => [
        ErrorBanner(
          messaggio: 'Non è stato possibile caricare la distinta.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ],
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Partita'),
        actions: [
          IconButton(
            tooltip: 'Scarica il modulo della distinta',
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              final convocati = distintaAsync.value;
              final atleti = atletiAsync.value;
              if (convocati == null || atleti == null) return;
              _esporta(context, ref, convocati, {
                for (final a in atleti) a.id: a,
              });
            },
          ),
          IconButton(
            tooltip: 'Modifica partita',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => apri(
              PartitaFormScreen(clubId: partita.clubId, partita: partita),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          testata,
          const SizedBox(height: AppSpacing.s24),
          TitoloSezione(
            convocati == null
                ? 'Distinta'
                : 'Distinta · ${convocati.length}/'
                      '${partita.numeroMaxConvocati} convocati',
          ),
          ...corpo,
        ],
      ),
      // Anche a distinta piena: nella stessa pagina si tolgono.
      floatingActionButton: distintaAsync.maybeWhen(
        data: (_) => FloatingActionButton(
          heroTag: 'fab-distinta',
          tooltip: 'Scegli i convocati',
          onPressed: scegliConvocati,
          child: const Icon(Icons.group_add_outlined),
        ),
        orElse: () => null,
      ),
    );
  }
}

/// Riga di un convocato — non un [AppListRow] perché deve affiancare
/// tessera e ruoli (capitano/vice/portiere/fuoriquota) senza unirli con
/// puntini (DESIGN.md sezione 13).
class _RigaConvocato extends StatelessWidget {
  const _RigaConvocato({
    required this.giocatore,
    required this.atleta,
    required this.coloreCalottina,
    required this.onTap,
  });

  final DistintaGiocatore giocatore;
  final Atleta? atleta;
  final String? coloreCalottina;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    // Capitano e vice si vedono con la C e la V accanto al nome.
    final ruoli = <String>[
      if (giocatore.portiere) 'Portiere',
      if (giocatore.fuoriquota) 'Fuoriquota',
    ];
    final tessera = atleta?.numeroTesseraFin;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaRiga,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CapBadge(
                numero: giocatore.numeroCalottina,
                colore: giocatore.portiere
                    ? CapColore.rossaPortiere
                    : coloreCalottina == 'blu'
                    ? CapColore.blu
                    : CapColore.bianca,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            atleta?.nomeCompleto ?? 'Atleta rimosso',
                            style: AppTypography.corpoForte.copyWith(
                              color: colori.testo,
                            ),
                          ),
                        ),
                        if (giocatore.capitano) ...[
                          const SizedBox(width: AppSpacing.s8),
                          const SegnoFascia.capitano(),
                        ],
                        if (giocatore.viceCapitano) ...[
                          const SizedBox(width: AppSpacing.s8),
                          const SegnoFascia.vice(),
                        ],
                      ],
                    ),
                    if (tessera != null && tessera.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Tessera $tessera',
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                    if (ruoli.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Wrap(
                        spacing: AppSpacing.s12,
                        runSpacing: AppSpacing.s4,
                        children: [
                          for (final r in ruoli)
                            Text(
                              r,
                              style: AppTypography.piccolo.copyWith(
                                color: colori.azione,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
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

/// Numero, portiere e fuoriquota di un convocato. Capitano e vice si
/// scelgono in cima alla distinta. Se il numero nuovo ce l'ha già un
/// altro, i due numeri si scambiano.
class _DialogModificaConvocato extends ConsumerStatefulWidget {
  const _DialogModificaConvocato({
    required this.partita,
    required this.convocato,
    required this.convocati,
    required this.atletiPerId,
  });

  final Partita partita;
  final DistintaGiocatore convocato;
  final List<DistintaGiocatore> convocati;
  final Map<String, Atleta> atletiPerId;

  @override
  ConsumerState<_DialogModificaConvocato> createState() =>
      _DialogModificaConvocatoState();
}

class _DialogModificaConvocatoState
    extends ConsumerState<_DialogModificaConvocato> {
  late final TextEditingController _numeroController;
  late bool _portiere;
  late bool _fuoriquota;
  bool _isSubmitting = false;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(
      text: '${widget.convocato.numeroCalottina}',
    )..addListener(() => setState(() {}));
    _portiere = widget.convocato.portiere;
    _fuoriquota = widget.convocato.fuoriquota;
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  /// Chi ha già il numero scritto (null se è libero o è il suo).
  DistintaGiocatore? get _conQuelNumero {
    final numero = int.tryParse(_numeroController.text.trim());
    if (numero == null || numero == widget.convocato.numeroCalottina) {
      return null;
    }
    for (final g in widget.convocati) {
      if (g.id != widget.convocato.id && g.numeroCalottina == numero) {
        return g;
      }
    }
    return null;
  }

  Future<void> _salva() async {
    final numero = int.tryParse(_numeroController.text.trim());
    if (numero == null || numero <= 0) {
      setState(() => _errore = 'Numero di calottina non valido');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    final repository = ref.read(distintaRepositoryProvider);
    final altro = _conQuelNumero;
    try {
      if (altro != null) {
        await repository.rinumera(widget.partita.id, {
          widget.convocato.id: numero,
          altro.id: widget.convocato.numeroCalottina,
        });
      }
      await repository.aggiornaConvocato(
        id: widget.convocato.id,
        numeroCalottina: numero,
        capitano: widget.convocato.capitano,
        viceCapitano: widget.convocato.viceCapitano,
        portiere: _portiere,
        fuoriquota: _fuoriquota,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _rimuovi() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(distintaRepositoryProvider)
          .rimuoviConvocato(widget.convocato.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errore = messaggioErrore(e);
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final altro = _conQuelNumero;
    final nomeAltro = altro == null
        ? null
        : widget.atletiPerId[altro.atletaId]?.nomeCompleto ?? 'un altro';
    return AlertDialog(
      title: Text(
        widget.atletiPerId[widget.convocato.atletaId]?.nomeCompleto ??
            'Convocato',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _numeroController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'N. calottina'),
            ),
            if (nomeAltro != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Il ${_numeroController.text.trim()} ce l\'ha $nomeAltro: '
                'si scambiano i numeri.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Portiere'),
              value: _portiere,
              onChanged: (v) => setState(() => _portiere = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fuoriquota'),
              value: _fuoriquota,
              onChanged: (v) => setState(() => _fuoriquota = v ?? false),
            ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                _errore!,
                style: AppTypography.piccolo.copyWith(color: colori.rosso),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : _rimuovi,
          style: TextButton.styleFrom(foregroundColor: colori.rosso),
          child: const Text('Rimuovi'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _salva,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salva'),
        ),
      ],
    );
  }
}
