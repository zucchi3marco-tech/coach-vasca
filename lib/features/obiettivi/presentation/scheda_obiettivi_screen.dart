import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/section_header.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../data/obiettivi_repository.dart';
import '../domain/scheda_obiettivi.dart';
import 'risposta_obiettivi_screen.dart';

/// Una scheda obiettivi vista dall'allenatore: le domande e, atleta per
/// atleta, chi ha risposto e chi no. Un tocco su chi ha risposto apre le
/// risposte e le due righe di ritorno.
class SchedaObiettiviScreen extends ConsumerStatefulWidget {
  const SchedaObiettiviScreen({required this.scheda, super.key});

  final SchedaObiettivi scheda;

  @override
  ConsumerState<SchedaObiettiviScreen> createState() =>
      _SchedaObiettiviScreenState();
}

class _SchedaObiettiviScreenState extends ConsumerState<SchedaObiettiviScreen> {
  late bool _chiusa = widget.scheda.chiusa;
  bool _lavoro = false;

  SchedaObiettivi get _scheda => SchedaObiettivi(
    id: widget.scheda.id,
    clubId: widget.scheda.clubId,
    stagioneId: widget.scheda.stagioneId,
    gruppoId: widget.scheda.gruppoId,
    titolo: widget.scheda.titolo,
    domande: widget.scheda.domande,
    chiusa: _chiusa,
    createdAt: widget.scheda.createdAt,
  );

  void _avvisa(String testo) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(testo)));

  Future<void> _chiudiORiapri() async {
    setState(() => _lavoro = true);
    try {
      await ref
          .read(obiettiviRepositoryProvider)
          .chiudi(widget.scheda.id, chiusa: !_chiusa);
      aggiornaObiettivi(ref);
      if (!mounted) return;
      setState(() => _chiusa = !_chiusa);
      _avvisa(
        _chiusa
            ? 'Scheda chiusa: gli atleti la leggono ma non rispondono più'
            : 'Scheda riaperta',
      );
    } catch (e) {
      if (mounted) _avvisa(messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _lavoro = false);
    }
  }

  Future<void> _elimina() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la scheda?'),
        content: const Text(
          'Spariscono anche le risposte degli atleti e le tue due righe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    setState(() => _lavoro = true);
    try {
      await ref.read(obiettiviRepositoryProvider).elimina(widget.scheda.id);
      aggiornaObiettivi(ref);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _avvisa(messaggioErrore(e));
        setState(() => _lavoro = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final scheda = _scheda;
    final atleti =
        ref
            .watch(
              atletiListProvider((
                clubId: scheda.clubId,
                includeInactive: false,
              )),
            )
            .value
            ?.where(scheda.perAtleta)
            .toList() ??
        const <Atleta>[];
    final risposteAsync = ref.watch(risposteSchedaProvider(scheda.id));
    final risposte = {
      for (final r in risposteAsync.value ?? const <RispostaObiettivi>[])
        r.atletaId: r,
    };
    final ordinati = [...atleti]
      ..sort((a, b) {
        // Prima chi ha risposto e aspetta le tue due righe.
        int peso(Atleta x) {
          final r = risposte[x.id];
          if (r == null) return 2;
          return r.ritorno == null ? 0 : 1;
        }

        final p = peso(a).compareTo(peso(b));
        return p != 0 ? p : a.cognome.compareTo(b.cognome);
      });

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(scheda.titolo),
        actions: [
          PopupMenuButton<String>(
            enabled: !_lavoro,
            onSelected: (v) => v == 'elimina' ? _elimina() : _chiudiORiapri(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'chiudi',
                child: Text(_chiusa ? 'Riapri la scheda' : 'Chiudi la scheda'),
              ),
              const PopupMenuItem(value: 'elimina', child: Text('Elimina')),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mandata ${dataEstesa(scheda.createdAt)}',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ),
              Pastiglia(
                _chiusa ? 'Chiusa' : 'Aperta',
                colore: _chiusa ? colori.testoSecondario : colori.ok,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          const TitoloSezione('Domande'),
          for (final (i, d) in scheda.domande.indexed) ...[
            Text(
              '${i + 1}. $d',
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          const SizedBox(height: AppSpacing.s16),
          TitoloSezione(
            'Risposte (${risposte.length} di ${atleti.length})',
            spiegazione:
                'Le leggono allenatori e assistenti del club. Tocca chi ha '
                'risposto per leggere e scrivere le tue due righe.',
          ),
          if (risposteAsync.hasError)
            ErrorBanner(messaggio: messaggioErrore(risposteAsync.error!))
          else if (risposteAsync.isLoading && risposteAsync.value == null)
            const LoadingSkeletonList()
          else if (ordinati.isEmpty)
            Text(
              'Nessun atleta in questo gruppo.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            )
          else
            AppListPanel(
              righe: [
                for (final a in ordinati)
                  AppListRow(
                    titolo: '${a.nome} ${a.cognome}',
                    sottotitolo: switch (risposte[a.id]) {
                      null => 'Non ha ancora risposto',
                      final r when r.ritorno == null =>
                        'Ha risposto ${dataEstesa(r.inviataAt)} · scrivi '
                            'le tue due righe',
                      final r =>
                        'Ha risposto ${dataEstesa(r.inviataAt)} · ritorno '
                            'scritto',
                    },
                    trailing: risposte[a.id] == null
                        ? null
                        : Icon(
                            Icons.chevron_right,
                            color: colori.testoSecondario,
                          ),
                    onTap: risposte[a.id] == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RispostaObiettiviScreen(
                                scheda: scheda,
                                atleta: a,
                                risposta: risposte[a.id],
                                perAllenatore: true,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
