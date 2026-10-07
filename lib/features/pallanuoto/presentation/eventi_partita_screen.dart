import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/lane_rule.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/schermo_acceso.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/titolo_due_righe.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../application/pallanuoto_providers.dart';
import '../data/eventi_partita_repository.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';
import 'eventi_labels.dart';
import '../../../widgets/nascondi_barra_club.dart';

/// Cronologia degli eventi partita: sola lettura (con modifica/cancellazione
/// di un evento tramite tocco) e registrazione delle superiorità a inizio/
/// fine. La registrazione di tiri ed espulsioni avviene nella schermata
/// "campo live" (`PartitaLiveScreen`), da cui questa si raggiunge col
/// pulsante "Cronologia".
class EventiPartitaScreen extends ConsumerWidget {
  const EventiPartitaScreen({required this.partita, super.key});

  final Partita partita;

  String _descrizione(EventoPartita e, Map<String, Atleta> atletiPerId) {
    final tempo = e.periodo != null ? ' (T${e.periodo})' : '';
    switch (e.tipo) {
      case 'tiro':
        final nome = atletiPerId[e.atletaId]?.nomeCompleto ?? 'Atleta rimosso';
        final contesto = etichettaContesto(e.contestoTiro);
        final suffisso = contesto.isEmpty ? '' : ' ($contesto)';
        return 'Tiro — $nome — ${etichettaEsito(e.esito)}$suffisso$tempo';
      case 'espulsione':
        final nome = e.atletaId != null
            ? (atletiPerId[e.atletaId]?.nomeCompleto ?? 'Atleta rimosso')
            : 'Avversario n. ${e.numeroCalottinaAvversario}';
        final rigore = e.espulsioneDaRigore ? ' (fallo da rigore)' : '';
        return 'Espulsione — $nome$rigore$tempo';
      case 'superiorita':
        final squadra = e.squadra == 'nostra' ? 'nostra' : 'avversaria';
        return 'Superiorità $squadra — ${etichettaEsito(e.esito)}$tempo';
      default:
        return e.tipo;
    }
  }

  IconData _icona(EventoPartita e) {
    switch (e.tipo) {
      case 'tiro':
        return Icons.sports_handball_outlined;
      case 'espulsione':
        return Icons.warning_amber_outlined;
      case 'superiorita':
        return e.squadra == 'nostra' ? Icons.trending_up : Icons.trending_down;
      default:
        return Icons.circle_outlined;
    }
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    EventoPartita evento,
  ) async {
    if (evento.tipo == 'superiorita' && evento.esito == null) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (_) => _FoglioSuperiorita(
          partita: partita,
          squadra: evento.squadra,
          daConcludere: evento,
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => _AzioniEvento(evento: evento, partita: partita),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      NascondiBarraClub(child: SchermoAcceso(child: _costruisci(context, ref)));

  Widget _costruisci(BuildContext context, WidgetRef ref) {
    final eventiAsync = ref.watch(eventiPartitaListProvider(partita.id));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: partita.clubId, includeInactive: false)),
    );

    final atletiPerId = {
      for (final a in atletiAsync.value ?? const <Atleta>[]) a.id: a,
    };
    final colori = context.colori;

    return AppScaffold(
      appBar: AppBar(
        toolbarHeight: TitoloDueRighe.altezzaBarraDueRighe,
        title: TitoloDueRighe(
          titolo: 'Cronologia',
          sottotitolo: '${partita.squadraCasa} - ${partita.squadraTrasferta}',
          righeSottotitolo: 2,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: eventiAsync.when(
              data: (eventi) => eventi.isEmpty
                  ? EmptyState(
                      icona: Icons.sports_handball_outlined,
                      titolo: 'Nessun evento registrato',
                      descrizione:
                          'Tiri, espulsioni e rigori si registrano nel campo '
                          'live; qui trovi solo la superiorità e la '
                          'cronologia.',
                      azionePrincipale: 'Torna al campo',
                      onAzionePrincipale: () => Navigator.of(context).pop(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      itemCount: eventi.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.s8),
                      itemBuilder: (context, index) {
                        final e = eventi[index];
                        final inCorso =
                            e.tipo == 'superiorita' && e.esito == null;
                        return LaneRule(
                          colore: inCorso ? colori.rosso : colori.linea,
                          child: PoolCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s16,
                              vertical: AppSpacing.s12,
                            ),
                            child: InkWell(
                              onTap: () => _onTap(context, ref, e),
                              child: Row(
                                children: [
                                  Icon(
                                    _icona(e),
                                    size: 20,
                                    color: colori.testoSecondario,
                                  ),
                                  const SizedBox(width: AppSpacing.s12),
                                  Expanded(
                                    child: Text(
                                      _descrizione(e, atletiPerId),
                                      style: AppTypography.corpoForte.copyWith(
                                        color: colori.testo,
                                      ),
                                    ),
                                  ),
                                  if (inCorso) ...[
                                    const SizedBox(width: AppSpacing.s12),
                                    Text(
                                      'Concludi',
                                      style: AppTypography.piccolo.copyWith(
                                        color: colori.azione,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: LoadingSkeletonList(righe: 5),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: ErrorBanner(
                  messaggio: 'Non è stato possibile caricare gli eventi.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri '
                      'l\'app.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Wrap(
                spacing: AppSpacing.s12,
                runSpacing: AppSpacing.s12,
                children: [
                  SizedBox(
                    height: AppSpacing.altezzaMinimaBersaglioVasca,
                    child: SecondaryButton(
                      label: 'Sup. nostra',
                      icon: Icons.trending_up,
                      expanded: false,
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        builder: (_) => _FoglioSuperiorita(
                          partita: partita,
                          squadra: 'nostra',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: AppSpacing.altezzaMinimaBersaglioVasca,
                    child: SecondaryButton(
                      label: 'Sup. avversaria',
                      icon: Icons.trending_down,
                      expanded: false,
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        builder: (_) => _FoglioSuperiorita(
                          partita: partita,
                          squadra: 'avversaria',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// L'ultimo tempo scelto: resta per la superiorità successiva, che quasi
/// sempre è nello stesso tempo.
int? _ultimoPeriodo;

/// Registrare o concludere una superiorità a bordo vasca (DESIGN.md 14):
/// niente form né menu a tendina, bottoni grandi e un tocco sull'esito
/// salva subito.
class _FoglioSuperiorita extends ConsumerStatefulWidget {
  const _FoglioSuperiorita({
    required this.partita,
    required this.squadra,
    this.daConcludere,
  });

  final Partita partita;
  final String squadra; // nostra | avversaria

  /// La superiorità "in corso" da concludere; null = se ne registra una.
  final EventoPartita? daConcludere;

  @override
  ConsumerState<_FoglioSuperiorita> createState() => _FoglioSuperioritaState();
}

class _FoglioSuperioritaState extends ConsumerState<_FoglioSuperiorita> {
  int? _periodo = _ultimoPeriodo;
  bool _inCorso = false;
  String? _errore;

  /// Esito subito (modalità "singolo") o da dare alla fine.
  bool get _chiediEsito =>
      widget.daConcludere != null ||
      widget.partita.modalitaSuperiorita == 'singolo';

  Future<void> _registra(String? esito) async {
    setState(() {
      _inCorso = true;
      _errore = null;
    });
    try {
      final repository = ref.read(eventiPartitaRepositoryProvider);
      final evento = widget.daConcludere;
      if (evento != null) {
        await repository.concludiSuperiorita(id: evento.id, esito: esito!);
      } else {
        _ultimoPeriodo = _periodo;
        await repository.registraSuperiorita(
          partitaId: widget.partita.id,
          squadra: widget.squadra,
          esito: esito,
          periodo: _periodo,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _inCorso = false;
          _errore = messaggioErrore(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final titolo = widget.daConcludere != null
        ? 'Com\'è finita la superiorità?'
        : widget.squadra == 'nostra'
        ? 'Superiorità nostra'
        : 'Superiorità avversaria';
    Widget bottone(String etichetta, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: SizedBox(
        height: AppSpacing.altezzaMinimaBersaglioVasca,
        child: PrimaryButton(
          label: etichetta,
          isLoading: _inCorso,
          onPressed: _inCorso ? null : onTap,
        ),
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titolo,
              style: AppTypography.sezione.copyWith(
                color: colori.testo,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.daConcludere == null && widget.partita.tracciaTempo) ...[
              const SizedBox(height: AppSpacing.s12),
              SegmentedButton<int>(
                showSelectedIcon: false,
                emptySelectionAllowed: true,
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(
                    Size.fromHeight(AppSpacing.altezzaMinimaBersaglioVasca),
                  ),
                ),
                segments: [
                  for (var t = 1; t <= 4; t++)
                    ButtonSegment(value: t, label: Text('T$t')),
                ],
                selected: {?_periodo},
                onSelectionChanged: (scelta) =>
                    setState(() => _periodo = scelta.firstOrNull),
              ),
            ],
            if (_chiediEsito)
              for (final (valore, etichetta) in esitiSuperiorita)
                bottone(etichetta, () => _registra(valore))
            else ...[
              bottone('Inizia la superiorità', () => _registra(null)),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'La concludi toccandola nella cronologia.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet aperto toccando un evento già registrato: correggere
/// l'esito di un tiro/superiorità, attribuire/togliere il fallo da rigore
/// a un'espulsione, o eliminare l'evento — le uniche modifiche possibili
/// a un evento già salvato.
class _AzioniEvento extends ConsumerWidget {
  const _AzioniEvento({required this.evento, required this.partita});

  final EventoPartita evento;
  final Partita partita;

  Future<void> _modificaEsito(
    BuildContext context,
    WidgetRef ref,
    String esito,
  ) async {
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .modificaEsito(id: evento.id, esito: esito);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    }
  }

  Future<void> _toggleRigore(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .modificaEspulsioneDaRigore(
            id: evento.id,
            daRigore: !evento.espulsioneDaRigore,
          );
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    }
  }

  Future<void> _elimina(BuildContext context, WidgetRef ref) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare l\'evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    try {
      await ref.read(eventiPartitaRepositoryProvider).eliminaEvento(evento.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opzioniEsito = switch (evento.tipo) {
      'tiro' when evento.squadra == 'nostra' =>
        evento.contestoTiro == 'rigore' ||
                partita.dettaglioTiro == 'dettagliato'
            ? esitiTiroDettagliato
            : esitiTiroSemplice,
      'tiro' => esitiTiroSemplice,
      'superiorita' => esitiSuperiorita,
      _ => const <(String, String)>[],
    };
    final colori = context.colori;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (opzioniEsito.isNotEmpty) ...[
              Text(
                'Modifica esito',
                style: AppTypography.etichetta.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              for (final (valore, etichetta) in opzioniEsito) ...[
                SizedBox(
                  height: AppSpacing.altezzaMinimaBersaglioVasca,
                  child: PrimaryButton(
                    label: etichetta,
                    onPressed: valore == evento.esito
                        ? null
                        : () => _modificaEsito(context, ref, valore),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
              ],
              const SizedBox(height: AppSpacing.s8),
            ],
            if (evento.tipo == 'espulsione') ...[
              SizedBox(
                height: AppSpacing.altezzaMinimaBersaglioVasca,
                child: SecondaryButton(
                  label: evento.espulsioneDaRigore
                      ? 'Togli fallo da rigore'
                      : 'Segna come fallo da rigore',
                  onPressed: () => _toggleRigore(context, ref),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
            TextButton(
              onPressed: () => _elimina(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Elimina evento'),
            ),
          ],
        ),
      ),
    );
  }
}
