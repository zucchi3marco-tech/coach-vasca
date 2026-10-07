import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
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
import '../pdf/distinta_pdf.dart';
import 'partita_form_screen.dart';
import 'partita_live_screen.dart';
import 'statistiche_partita_screen.dart';

/// La scheda di una partita: dati e azioni del giorno della partita in
/// testata, sotto la distinta dei convocati.
class DistintaScreen extends ConsumerWidget {
  const DistintaScreen({required this.partita, super.key});

  final Partita partita;

  Future<void> _esporta(
    BuildContext context,
    WidgetRef ref,
    List<DistintaGiocatore> convocati,
    Map<String, Atleta> atletiPerId,
  ) async {
    final righe = [
      for (final g in convocati)
        (giocatore: g, atleta: atletiPerId[g.atletaId]),
    ]..removeWhere((r) => r.atleta == null);
    await Printing.layoutPdf(
      onLayout: (_) => generaDistintaPdf(
        partita: partita,
        convocati: [
          for (final r in righe) (giocatore: r.giocatore, atleta: r.atleta!),
        ],
      ),
    );
  }

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

    void aggiungiConvocato(List<DistintaGiocatore> esistenti) =>
        showDialog<void>(
          context: context,
          builder: (_) => _DialogSelezionaAtleta(
            partita: partita,
            convocatiEsistenti: esistenti,
          ),
        );

    // La scheda della partita: le azioni del giorno della partita (dal
    // vivo, statistiche, referto) stanno in vista nella testata — prima
    // erano nel menu ⋮ — e sotto c'e' la distinta.
    final testata = TestataPagina(
      occhiello: [
        traQuanto(partita.data),
        dataEstesa(partita.data),
        if (partita.ora != null && partita.ora!.isNotEmpty) partita.ora!,
      ].join(' · '),
      titolo: '${partita.squadraCasa} – ${partita.squadraTrasferta}',
      sottotitolo: [
        if (partita.luogo != null && partita.luogo!.isNotEmpty) partita.luogo!,
        if (partita.campionato != null && partita.campionato!.isNotEmpty)
          partita.campionato!,
        if (partita.coloreCalottina != null &&
            partita.coloreCalottina!.isNotEmpty)
          'calottina ${partita.coloreCalottina == 'blu' ? 'blu' : 'bianca'}',
      ].join(' · '),
      azioni: [
        AzioneTestata(
          icona: Icons.play_circle_fill,
          etichetta: 'Dal vivo',
          principale: true,
          onTap: () => apri(PartitaLiveScreen(partita: partita)),
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
                    'Aggiungi il primo convocato per costruire la '
                    'distinta di questa partita.',
                azionePrincipale: 'Aggiungi convocato',
                onAzionePrincipale: () => aggiungiConvocato(convocati),
              ),
            ];
          }
          return [
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
                      ),
                    ),
                  ),
              ],
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
            tooltip: 'Esporta distinta',
            icon: const Icon(Icons.ios_share),
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
      floatingActionButton: distintaAsync.maybeWhen(
        data: (convocati) => convocati.length >= partita.numeroMaxConvocati
            ? null
            : FloatingActionButton(
                heroTag: 'fab-distinta',
                tooltip: 'Aggiungi convocato',
                onPressed: () => aggiungiConvocato(convocati),
                child: const Icon(Icons.add),
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
    final ruoli = <String>[
      if (giocatore.capitano) 'Capitano',
      if (giocatore.viceCapitano) 'Vice capitano',
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
                    Text(
                      atleta?.nomeCompleto ?? 'Atleta rimosso',
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
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

class _DialogSelezionaAtleta extends ConsumerWidget {
  const _DialogSelezionaAtleta({
    required this.partita,
    required this.convocatiEsistenti,
  });

  final Partita partita;
  final List<DistintaGiocatore> convocatiEsistenti;

  /// Il piu' piccolo numero di calottina (da 1 in su) non ancora usato in
  /// questa distinta: solo un suggerimento di partenza, l'allenatore puo'
  /// sempre cambiarlo dopo dal dettaglio del convocato.
  int get _prossimoNumeroLibero {
    final usati = convocatiEsistenti.map((g) => g.numeroCalottina).toSet();
    var numero = 1;
    while (usati.contains(numero)) {
      numero++;
    }
    return numero;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: partita.clubId, includeInactive: false)),
    );
    final idGiaConvocati = convocatiEsistenti.map((g) => g.atletaId).toSet();
    return AlertDialog(
      title: const Text('Aggiungi convocato'),
      content: SizedBox(
        width: double.maxFinite,
        child: atletiAsync.when(
          data: (atleti) {
            final disponibili =
                atleti
                    .where(
                      (a) =>
                          a.sport == 'pallanuoto' &&
                          !idGiaConvocati.contains(a.id),
                    )
                    .toList()
                  ..sort((a, b) => a.cognome.compareTo(b.cognome));
            if (disponibili.isEmpty) {
              return Text(
                'Nessun atleta di pallanuoto disponibile da convocare.',
                style: AppTypography.corpo.copyWith(
                  color: context.colori.testo,
                ),
              );
            }
            return SizedBox(
              height: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: disponibili.length,
                itemBuilder: (context, index) {
                  final atleta = disponibili[index];
                  return ListTile(
                    title: Text(atleta.nomeCompleto),
                    onTap: () async {
                      final numero = _prossimoNumeroLibero;
                      Navigator.of(context).pop();
                      try {
                        await ref
                            .read(distintaRepositoryProvider)
                            .aggiungiConvocato(
                              partitaId: partita.id,
                              atletaId: atleta.id,
                              numeroCalottina: numero,
                            );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Errore nell'aggiunta: ${messaggioErrore(e)}",
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(messaggioErrore(error)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}

class _DialogModificaConvocato extends ConsumerStatefulWidget {
  const _DialogModificaConvocato({
    required this.partita,
    required this.convocato,
  });

  final Partita partita;
  final DistintaGiocatore convocato;

  @override
  ConsumerState<_DialogModificaConvocato> createState() =>
      _DialogModificaConvocatoState();
}

class _DialogModificaConvocatoState
    extends ConsumerState<_DialogModificaConvocato> {
  late final TextEditingController _numeroController;
  late bool _capitano;
  late bool _viceCapitano;
  late bool _portiere;
  late bool _fuoriquota;
  bool _isSubmitting = false;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(
      text: '${widget.convocato.numeroCalottina}',
    );
    _capitano = widget.convocato.capitano;
    _viceCapitano = widget.convocato.viceCapitano;
    _portiere = widget.convocato.portiere;
    _fuoriquota = widget.convocato.fuoriquota;
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
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
    try {
      await ref
          .read(distintaRepositoryProvider)
          .aggiornaConvocato(
            id: widget.convocato.id,
            numeroCalottina: numero,
            capitano: _capitano,
            viceCapitano: _viceCapitano,
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
    return AlertDialog(
      title: const Text('Convocato'),
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
            const SizedBox(height: AppSpacing.s8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Capitano'),
              value: _capitano,
              onChanged: (v) => setState(() {
                _capitano = v ?? false;
                if (_capitano) _viceCapitano = false;
              }),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vice capitano'),
              value: _viceCapitano,
              onChanged: (v) => setState(() {
                _viceCapitano = v ?? false;
                if (_viceCapitano) _capitano = false;
              }),
            ),
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
