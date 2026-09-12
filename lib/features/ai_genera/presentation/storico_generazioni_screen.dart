import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/generazione_ai_registrata.dart';

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

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year} ${data.hour.toString().padLeft(2, '0')}:'
      '${data.minute.toString().padLeft(2, '0')}';

  String _riassuntoParametri(Map<String, dynamic> p) {
    final parti = <String>[];
    if (p['gruppo'] != null) parti.add(p['gruppo'] as String);
    if (p['livello'] != null) parti.add(p['livello'] as String);
    if (p['volumeMetri'] != null) parti.add('${p['volumeMetri']} m');
    if (p['focus'] != null) parti.add(p['focus'] as String);
    return parti.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
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
      corpo = const EmptyState(
        icona: Icons.auto_awesome_outlined,
        titolo: 'Nessuna generazione ancora effettuata',
        descrizione:
            'Le proposte generate con l\'AI comparirano qui, anche '
            'quelle non salvate come allenamento.',
        azionePrincipale: 'Torna indietro',
      );
    } else {
      corpo = SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          children: [
            AppListPanel(
              righe: [
                for (final voce in _voci)
                  AppListRow(
                    leading: Icon(
                      !voce.successo
                          ? Icons.error_outline
                          : voce.allenamentoId != null
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: !voce.successo
                          ? AppColors.rosso
                          : voce.allenamentoId != null
                          ? AppColors.ok
                          : AppColors.testoTenue,
                    ),
                    titolo: _riassuntoParametri(voce.parametri),
                    sottotitolo:
                        '${_formattaData(voce.creatoIl)} · '
                        '${!voce.successo
                            ? 'generazione fallita'
                            : voce.allenamentoId != null
                            ? 'salvata come allenamento'
                            : 'generata, non salvata'}',
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => _DialogDettaglioVoce(voce: voce),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            if (_caricamentoAltre)
              const CircularProgressIndicator()
            else if (_errore != null)
              Column(
                children: [
                  Text(
                    'Non è stato possibile caricare altre voci: '
                    '${messaggioErrore(_errore!)}',
                    style: const TextStyle(color: AppColors.rosso),
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
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Storico generazioni AI')),
      body: corpo,
    );
  }
}

class _DialogDettaglioVoce extends StatelessWidget {
  const _DialogDettaglioVoce({required this.voce});

  final GenerazioneAiRegistrata voce;

  @override
  Widget build(BuildContext context) {
    final scheda = voce.scheda;
    final salvata = voce.allenamentoId != null;
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
              Text('Parametri', style: AppTypography.etichetta),
              const SizedBox(height: AppSpacing.s4),
              for (final voceParam in voce.parametri.entries)
                Text(
                  '${voceParam.key}: ${voceParam.value}',
                  style: AppTypography.corpo,
                ),
              const SizedBox(height: AppSpacing.s16),
              if (voce.messaggioErrore != null) ...[
                Text('Errore', style: AppTypography.etichetta),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  voce.messaggioErrore!,
                  style: AppTypography.piccolo.copyWith(color: AppColors.rosso),
                ),
              ],
              if (scheda != null) ...[
                Text(
                  scheda['titolo'] as String? ?? 'Scheda generata',
                  style: AppTypography.etichetta,
                ),
                const SizedBox(height: AppSpacing.s4),
                for (final s in (scheda['serie'] as List? ?? []))
                  Text(
                    '${s['ordine']}. ${s['ripetute']}×${s['distanzaM']}m '
                    '${labelStile(s['stile'] as String)} '
                    '${labelEsecuzione(s['esecuzione'] as String)}',
                    style: AppTypography.corpo,
                  ),
              ],
            ],
          ),
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
