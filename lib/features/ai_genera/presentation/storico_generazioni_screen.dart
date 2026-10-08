import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/generazione_ai_registrata.dart';
import '../domain/scheda_generata.dart';
import '../domain/riassunto_parametri.dart';

const _voxPerPagina = 30;

class StoricoGenerazioniScreen extends ConsumerStatefulWidget {
  const StoricoGenerazioniScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<StoricoGenerazioniScreen> createState() =>
      _StoricoGenerazioniScreenState();
}

class _StoricoGenerazioniScreenState
    extends ConsumerState<StoricoGenerazioniScreen> {
  final _voci = <GenerazioneAiRegistrata>[];
  bool _caricamentoIniziale = true;
  bool _caricamentoAltre = false;
  bool _altrePagine = true;
  Object? _errore;

  @override
  void initState() {
    super.initState();
    _caricaPagina();
  }

  Future<void> _caricaPagina() async {
    try {
      final pagina = await ref
          .read(generazioniAiRepositoryProvider)
          .fetchStorico(
            widget.clubId,
            offset: _voci.length,
            limite: _voxPerPagina,
          );
      if (!mounted) return;
      setState(() {
        _voci.addAll(pagina);
        _altrePagine = pagina.length == _voxPerPagina;
        _caricamentoIniziale = false;
        _caricamentoAltre = false;
        _errore = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _caricamentoIniziale = false;
        _caricamentoAltre = false;
        _errore = e;
      });
    }
  }

  void _caricaAltre() {
    setState(() => _caricamentoAltre = true);
    _caricaPagina();
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final Widget corpo;
    if (_caricamentoIniziale) {
      corpo = const Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: LoadingSkeletonList(righe: 6),
      );
    } else if (_errore != null && _voci.isEmpty) {
      corpo = Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: ErrorBanner(
          messaggio: 'Non è stato possibile caricare lo storico.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(_errore!),
        ),
      );
    } else if (_voci.isEmpty) {
      corpo = EmptyState(
        icona: Icons.auto_awesome_outlined,
        titolo: 'Nessuna generazione ancora effettuata',
        descrizione:
            'Le proposte generate con l\'AI compariranno qui, anche '
            'quelle non salvate come allenamento.',
        azionePrincipale: 'Torna indietro',
        onAzionePrincipale: () => Navigator.of(context).maybePop(),
      );
    } else {
      // Una sezione per giorno ("Oggi", "Ieri", "martedì 6 ott"): l'ora
      // sta sulla scheda, la data non si ripete su ogni riga.
      final perGiorno = <DateTime, List<GenerazioneAiRegistrata>>{};
      for (final voce in _voci) {
        perGiorno
            .putIfAbsent(soloData(voce.creatoIl.toLocal()), () => [])
            .add(voce);
      }
      String titoloGiorno(DateTime giorno) {
        final quando = traQuanto(giorno);
        return quando == 'Oggi' || quando == 'Ieri'
            ? quando
            : dataEstesa(giorno);
      }

      Widget scheda(GenerazioneAiRegistrata voce) {
        final salvata = voce.allenamentoId != null;
        final ora = voce.creatoIl.toLocal();
        return SchedaElenco(
          leading: IconaRiquadro(
            !voce.successo
                ? Icons.error_outline
                : salvata
                ? Icons.check_circle
                : Icons.auto_awesome_outlined,
            colore: !voce.successo
                ? colori.rosso
                : salvata
                ? colori.ok
                : colori.testoSecondario,
            dimensione: 44,
          ),
          titolo: riassuntoParametriGenerazione(voce.parametri),
          sottotitolo:
              '${ora.hour.toString().padLeft(2, '0')}:'
              '${ora.minute.toString().padLeft(2, '0')} · '
              '${!voce.successo
                  ? 'generazione fallita'
                  : salvata
                  ? 'salvata come allenamento'
                  : 'generata, non salvata'}',
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) =>
                _DialogDettaglioVoce(voce: voce, clubId: widget.clubId),
          ),
        );
      }

      corpo = ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          Column(
            children: [
              for (final giorno in perGiorno.keys) ...[
                TitoloSezione(
                  titoloGiorno(giorno),
                  conteggio: perGiorno[giorno]!.length,
                ),
                GrigliaSchede(
                  colonneMassime: 1,
                  figli: [for (final v in perGiorno[giorno]!) scheda(v)],
                ),
                const SizedBox(height: AppSpacing.s24),
              ],
              const SizedBox(height: AppSpacing.s16),
              if (_caricamentoAltre)
                const CircularProgressIndicator()
              else if (_errore != null)
                Column(
                  children: [
                    Text(
                      'Non è stato possibile caricare altre voci: '
                      '${messaggioErrore(_errore!)}',
                      style: TextStyle(color: colori.rosso),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    TextButton(
                      onPressed: _caricaAltre,
                      child: const Text('Riprova'),
                    ),
                  ],
                )
              else if (_altrePagine)
                TextButton(
                  onPressed: _caricaAltre,
                  child: const Text('Carica altre'),
                ),
            ],
          ),
        ],
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Storico generazioni AI')),
      body: corpo,
    );
  }
}

class _DialogDettaglioVoce extends ConsumerWidget {
  const _DialogDettaglioVoce({required this.voce, required this.clubId});

  final GenerazioneAiRegistrata voce;
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // L'allenamento nato da questa generazione, se esiste ancora: si apre
    // da qui invece di andarlo a cercare nel calendario.
    final allenamento = voce.allenamentoId == null
        ? null
        : (ref.watch(allenamentiListProvider(clubId)).value ?? const [])
              .where((a) => a.id == voce.allenamentoId)
              .firstOrNull;
    final scheda = voce.scheda;
    final salvata = voce.allenamentoId != null;
    final colori = context.colori;
    return AlertDialog(
      title: Text(
        !voce.successo
            ? 'Generazione fallita'
            : salvata
            ? 'Salvata come allenamento'
            : 'Generata, non salvata',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parametri',
                style: AppTypography.etichetta.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              for (final voceParam in voce.parametri.entries)
                Text(
                  '${voceParam.key}: ${voceParam.value}',
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                ),
              const SizedBox(height: AppSpacing.s16),
              if (voce.messaggioErrore != null) ...[
                Text(
                  'Errore',
                  style: AppTypography.etichetta.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  voce.messaggioErrore!,
                  style: AppTypography.piccolo.copyWith(color: colori.rosso),
                ),
              ],
              if (scheda != null) ...[
                Text(
                  scheda['titolo'] as String? ?? 'Scheda generata',
                  style: AppTypography.etichetta.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                for (final s in (scheda['serie'] as List? ?? []))
                  Text(
                    '${s['ordine']}. ${titoloSerieProposta(SerieGenerata.fromMap(Map<String, dynamic>.from(s as Map)))}',
                    style: AppTypography.corpo.copyWith(color: colori.testo),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (allenamento != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AllenamentoDetailScreen(allenamento: allenamento),
                ),
              );
            },
            child: const Text('Apri l\'allenamento'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}
