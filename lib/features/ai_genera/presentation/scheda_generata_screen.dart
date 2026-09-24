import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/application/atleti_providers.dart';
import '../application/corsie_service.dart';
import '../application/tempo_stimato_service.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/scheda_generata.dart';
import 'campi_generatore.dart';

/// Anteprima della scheda proposta dall'AI, prima del salvataggio: data
/// modificabile, elenco delle serie generate in sola lettura. Schermata
/// intera invece di un dialog (FASE 10, punto 1): contiene un form vero e
/// proprio più un elenco potenzialmente lungo di serie, non una semplice
/// conferma.
class SchedaGenerataScreen extends ConsumerStatefulWidget {
  const SchedaGenerataScreen({
    required this.scheda,
    required this.clubId,
    required this.gruppoId,
    this.dataIniziale,
    this.generazioneId,
    this.assegnazione,
    super.key,
  });

  final SchedaGenerata scheda;
  final String clubId;
  final String? gruppoId;
  final DateTime? dataIniziale;

  /// Id della voce di storico creata per questa generazione (nullo se la
  /// registrazione dello storico stessa era fallita): se presente, dopo il
  /// salvataggio ci si collega l'allenamento creato.
  final String? generazioneId;

  /// Come il gruppo è stato diviso in corsie di ripartenza (nullo se non
  /// calcolato, es. scheda trascritta dalla dettatura).
  final AssegnazioneCorsie? assegnazione;

  @override
  ConsumerState<SchedaGenerataScreen> createState() =>
      _SchedaGenerataScreenState();
}

class _SchedaGenerataScreenState extends ConsumerState<SchedaGenerataScreen> {
  late DateTime _data = widget.dataIniziale ?? DateTime.now();
  late final TextEditingController _dataController = TextEditingController(
    text: _formattaData(_data),
  );
  bool _salvataggioInCorso = false;

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  String _sottotitoloSerie(SerieGenerata s) {
    final parti = <String>[labelBlocco(s.blocco)];
    if (s.zona != null) parti.add('zona ${s.zona}');
    if (s.recuperoS != null) parti.add("rec ${s.recuperoS}''");
    if (s.attrezzatura != null && s.attrezzatura!.isNotEmpty) {
      parti.add(s.attrezzatura!);
    }
    return parti.join(' · ');
  }

  String _ripartenzeSerie(SerieGenerata s) =>
      formattaRipartenzeCorsia(s.ripartenzePerCorsia);

  Future<void> _scegliData() async {
    final scelta = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (scelta != null) {
      setState(() {
        _data = scelta;
        _dataController.text = _formattaData(scelta);
      });
    }
  }

  Future<void> _salva() async {
    setState(() => _salvataggioInCorso = true);
    try {
      final scheda = widget.scheda;
      final allenamento = await ref
          .read(allenamentiRepositoryProvider)
          .createAllenamento(
            clubId: widget.clubId,
            data: _data,
            titolo: scheda.titolo,
            gruppoId: widget.gruppoId,
            note: scheda.note,
          );
      final serieRepository = ref.read(serieRepositoryProvider);
      for (final s in scheda.serie) {
        final risolto = risolviRipartenza(s.ripartenzePerCorsia, s.note);
        await serieRepository.createSerie(
          allenamentoId: allenamento.id,
          ordine: s.ordine,
          blocco: s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          stile: s.stile,
          esecuzione: s.esecuzione,
          zona: s.zona,
          recuperoS: s.recuperoS,
          ripartenzaS: risolto.ripartenzaS,
          attrezzatura: s.attrezzatura,
          note: risolto.note,
        );
      }
      if (widget.generazioneId != null) {
        try {
          await ref
              .read(generazioniAiRepositoryProvider)
              .collegaAllenamento(
                generazioneId: widget.generazioneId!,
                allenamentoId: allenamento.id,
              );
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.of(context).pop(allenamento);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel salvataggio: ${messaggioErrore(e)}'),
        ),
      );
      setState(() => _salvataggioInCorso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheda = widget.scheda;
    final colori = context.colori;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: Text(scheda.titolo)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Volume totale: ${scheda.volumeTotaleM} m · '
            'Lavoro centrale: ${scheda.volumeLavoroCentraleM} m · '
            'Stima: ${stimaMinutiSessione(scheda.serie)} min',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          if (scheda.note != null && scheda.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              scheda.note!,
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ],
          if (widget.assegnazione != null &&
              widget.assegnazione!.divisoInDue) ...[
            const SizedBox(height: AppSpacing.s16),
            _PannelloCorsie(
              assegnazione: widget.assegnazione!,
              clubId: widget.clubId,
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          FormGroup(
            titolo: 'Quando',
            isUltimo: true,
            campi: [
              AppTextField(
                etichetta: 'Data',
                controller: _dataController,
                readOnly: true,
                onTap: _salvataggioInCorso ? null : _scegliData,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          for (final s in scheda.serie)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.ordine}. ${s.ripetute}×${s.distanzaM}m '
                    '${labelStile(s.stile)} ${labelEsecuzione(s.esecuzione)}',
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                  ),
                  Text(
                    _sottotitoloSerie(s),
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  if (s.ripartenzePerCorsia.isNotEmpty)
                    Text(
                      _ripartenzeSerie(s),
                      style: AppTypography.piccolo.copyWith(
                        color: colori.azione,
                      ),
                    ),
                  if (s.note != null && s.note!.isNotEmpty)
                    Text(
                      s.note!,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.s24),
          PrimaryButton(
            label: 'Salva',
            isLoading: _salvataggioInCorso,
            onPressed: _salvataggioInCorso ? null : _salva,
          ),
        ],
      ),
    );
  }
}

/// I due gruppi di ripartenza con i nomi degli atleti, per dividerli in
/// vasca (in Presenze ogni atleta ha lo stesso numero, 1 o 2).
class _PannelloCorsie extends ConsumerWidget {
  const _PannelloCorsie({required this.assegnazione, required this.clubId});

  final AssegnazioneCorsie assegnazione;
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final atleti =
        ref
            .watch(atletiListProvider((clubId: clubId, includeInactive: false)))
            .value ??
        const [];
    final nomi = {for (final a in atleti) a.id: a.nomeCompleto};
    String elenco(Iterable<String> ids) {
      final n = ids.map((id) => nomi[id]).whereType<String>().toList()..sort();
      return n.isEmpty ? '—' : n.join(', ');
    }

    return PannelloCampi(
      titolo: 'Il gruppo si divide in due corsie',
      figli: [
        Text(
          'I tempi del gruppo sono molto diversi: le ripartenze sono '
          'calcolate separatamente. In Presenze ogni atleta ha il numero '
          'della sua corsia.',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        for (var i = 0; i < assegnazione.corsie.length; i++)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${assegnazione.corsie[i].nome}: ',
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
                TextSpan(
                  text: elenco(assegnazione.corsie[i].atletiIds),
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                ),
              ],
            ),
          ),
        if (assegnazione.senzaTempo.isNotEmpty)
          Text(
            'Senza tempo sui 100 stile libero (da assegnare tu): '
            '${elenco(assegnazione.senzaTempo)}',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
      ],
    );
  }
}
