import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/lane_rule.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../application/pallanuoto_providers.dart';
import '../data/eventi_partita_repository.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';
import 'eventi_labels.dart';
import 'registra_espulsione_screen.dart';
import 'registra_tiro_screen.dart';
import 'selettore_giocatore_partita.dart';

/// Schermata da bordo vasca (DESIGN.md sezione 9): usata durante la
/// partita per registrare tiri, espulsioni e superiorità in tempo reale.
/// "Tiro" ed "Espulsione" aprono schermate a tutto schermo con bersagli
/// grandi (`RegistraTiroScreen`/`RegistraEspulsioneScreen`), non più un
/// dialog con menu a tendina.
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
        return e.squadra == 'nostra'
            ? Icons.trending_up
            : Icons.trending_down;
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
      await showDialog<void>(
        context: context,
        builder: (_) => _DialogConcludiSuperiorita(evento: evento),
      );
      return;
    }
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare l\'evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma == true) {
      try {
        await ref
            .read(eventiPartitaRepositoryProvider)
            .eliminaEvento(evento.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventiAsync = ref.watch(eventiPartitaListProvider(partita.id));
    final convocatiAsync = ref.watch(distintaListProvider(partita.id));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: partita.clubId, includeInactive: false)),
    );

    final atletiPerId = {
      for (final a in atletiAsync.value ?? const <Atleta>[]) a.id: a,
    };
    final convocatiConAtleta = <ConvocatoConAtleta>[
      for (final g in convocatiAsync.value ?? const [])
        if (atletiPerId[g.atletaId] != null)
          (giocatore: g, atleta: atletiPerId[g.atletaId]!),
    ]..sort(
      (a, b) => a.atleta.cognome.compareTo(b.atleta.cognome),
    );
    final eventi = eventiAsync.value ?? const <EventoPartita>[];

    void apriRegistraTiro() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistraTiroScreen(
          partita: partita,
          convocati: convocatiConAtleta,
          eventi: eventi,
        ),
      ),
    );

    void apriRegistraEspulsione() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistraEspulsioneScreen(
          partita: partita,
          convocati: convocatiConAtleta,
          eventi: eventi,
        ),
      ),
    );

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          'Eventi — ${partita.squadraCasa} - ${partita.squadraTrasferta}',
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
                          'Usa i pulsanti qui sotto per registrare tiri, '
                          'espulsioni e superiorità numeriche.',
                      azionePrincipale: 'Registra un tiro',
                      onAzionePrincipale: convocatiConAtleta.isEmpty
                          ? null
                          : apriRegistraTiro,
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
                          colore: inCorso
                              ? AppColors.rosso
                              : AppColors.linea,
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
                                    color: AppColors.testoSecondario,
                                  ),
                                  const SizedBox(width: AppSpacing.s12),
                                  Expanded(
                                    child: Text(
                                      _descrizione(e, atletiPerId),
                                      style: AppTypography.corpoForte
                                          .copyWith(color: AppColors.testo),
                                    ),
                                  ),
                                  if (inCorso) ...[
                                    const SizedBox(width: AppSpacing.s12),
                                    Text(
                                      'Concludi',
                                      style: AppTypography.piccolo.copyWith(
                                        color: AppColors.blu,
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
                    child: PrimaryButton(
                      label: 'Tiro',
                      icon: Icons.sports_handball_outlined,
                      expanded: false,
                      onPressed: convocatiConAtleta.isEmpty
                          ? null
                          : apriRegistraTiro,
                    ),
                  ),
                  SizedBox(
                    height: AppSpacing.altezzaMinimaBersaglioVasca,
                    child: SecondaryButton(
                      label: 'Espulsione',
                      icon: Icons.warning_amber_outlined,
                      expanded: false,
                      onPressed: apriRegistraEspulsione,
                    ),
                  ),
                  SizedBox(
                    height: AppSpacing.altezzaMinimaBersaglioVasca,
                    child: SecondaryButton(
                      label: 'Sup. nostra',
                      icon: Icons.trending_up,
                      expanded: false,
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _DialogRegistraSuperiorita(
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
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _DialogRegistraSuperiorita(
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

/// Selettore di tempo (1-4), mostrato solo se la partita traccia il tempo.
class _SelettorePeriodo extends StatelessWidget {
  const _SelettorePeriodo({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Tempo'),
      items: [
        for (var t = 1; t <= 4; t++)
          DropdownMenuItem(value: t, child: Text('Tempo $t')),
      ],
      onChanged: onChanged,
    );
  }
}

class _DialogRegistraSuperiorita extends ConsumerStatefulWidget {
  const _DialogRegistraSuperiorita({
    required this.partita,
    required this.squadra,
  });

  final Partita partita;
  final String squadra; // nostra | avversaria

  @override
  ConsumerState<_DialogRegistraSuperiorita> createState() =>
      _DialogRegistraSuperioritaState();
}

class _DialogRegistraSuperioritaState
    extends ConsumerState<_DialogRegistraSuperiorita> {
  String? _esito;
  int? _periodo;
  bool _isSubmitting = false;
  String? _errore;

  bool get _esitoSubito => widget.partita.modalitaSuperiorita == 'singolo';

  Future<void> _salva() async {
    if (_esitoSubito && _esito == null) {
      setState(() => _errore = 'Seleziona l\'esito');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .registraSuperiorita(
            partitaId: widget.partita.id,
            squadra: widget.squadra,
            esito: _esitoSubito ? _esito : null,
            periodo: _periodo,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titolo = widget.squadra == 'nostra'
        ? 'Superiorità nostra'
        : 'Superiorità avversaria';
    return AlertDialog(
      title: Text(titolo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_esitoSubito)
              Wrap(
                spacing: 8,
                children: [
                  for (final (valore, etichetta) in esitiSuperiorita)
                    ChoiceChip(
                      label: Text(etichetta),
                      selected: _esito == valore,
                      onSelected: (_) => setState(() => _esito = valore),
                    ),
                ],
              )
            else
              const Text(
                'Registrata come "in corso": la concludi più tardi '
                'toccandola nella lista.',
              ),
            if (widget.partita.tracciaTempo) ...[
              const SizedBox(height: 12),
              _SelettorePeriodo(
                value: _periodo,
                onChanged: (v) => setState(() => _periodo = v),
              ),
            ],
            if (_errore != null) ...[
              const SizedBox(height: 8),
              Text(
                _errore!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _salva,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

class _DialogConcludiSuperiorita extends ConsumerStatefulWidget {
  const _DialogConcludiSuperiorita({required this.evento});

  final EventoPartita evento;

  @override
  ConsumerState<_DialogConcludiSuperiorita> createState() =>
      _DialogConcludiSuperioritaState();
}

class _DialogConcludiSuperioritaState
    extends ConsumerState<_DialogConcludiSuperiorita> {
  String? _esito;
  bool _isSubmitting = false;
  String? _errore;

  Future<void> _salva() async {
    if (_esito == null) {
      setState(() => _errore = 'Seleziona l\'esito');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .concludiSuperiorita(id: widget.evento.id, esito: _esito!);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Concludi superiorità'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final (valore, etichetta) in esitiSuperiorita)
                ChoiceChip(
                  label: Text(etichetta),
                  selected: _esito == valore,
                  onSelected: (_) => setState(() => _esito = valore),
                ),
            ],
          ),
          if (_errore != null) ...[
            const SizedBox(height: 8),
            Text(
              _errore!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _salva,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
