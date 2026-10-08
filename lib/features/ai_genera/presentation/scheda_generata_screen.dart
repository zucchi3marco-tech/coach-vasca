import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/presentation/riepilogo_volumi.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../libreria_blocchi/data/training_blocks_repository.dart';
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
      formattaRipartenzeCorsia(_ripartenzePerSerie(s));

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

  /// Ripartenze "vere" per questa serie, ricalcolate dal codice invece di
  /// quelle proposte dall'AI (RIPROGETTAZIONE AI, FASE 3): per ogni
  /// corsia, il passo del test di soglia (A1/A2/B1, quando c'è) o il
  /// modello dai primati nello stile della serie (le altre zone). Se per
  /// una corsia non c'è alcun dato, resta quella eventualmente proposta
  /// dall'AI per quella stessa corsia — mai un buco silenzioso.
  List<RipartenzaCorsia> _ripartenzePerSerie(SerieGenerata s) {
    final assegnazione = widget.assegnazione;
    final distanzaM = s.distanzaM;
    // A tempo: nessuna ripartenza.
    if (distanzaM == null) return const [];
    if (assegnazione == null || s.zona == null) return s.ripartenzePerCorsia;

    final risultato = <RipartenzaCorsia>[];
    for (final c in assegnazione.corsie) {
      final calcolato = ripartenzaPerSerie(
        zona: s.zona!,
        stile: s.stile,
        distanzaM: distanzaM,
        atletiIds: c.atletiIds,
        assegnazione: assegnazione,
      );
      if (calcolato.ripartenzaS != null) {
        risultato.add(
          RipartenzaCorsia(nome: c.nome, ripartenzaS: calcolato.ripartenzaS!),
        );
        continue;
      }
      final daAi = s.ripartenzePerCorsia.where((r) => r.nome == c.nome);
      if (daAi.isNotEmpty) risultato.add(daAi.first);
    }
    return risultato;
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
        final risolto = risolviRipartenza(_ripartenzePerSerie(s), s.note);
        final serieCreata = await serieRepository.createSerie(
          allenamentoId: allenamento.id,
          ordine: s.ordine,
          blocco: s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          durataS: s.durataS,
          stile: s.stile,
          esecuzione: s.esecuzione,
          zona: s.zona,
          recuperoS: s.recuperoS,
          ripartenzaS: risolto.ripartenzaS,
          attrezzatura: s.attrezzatura,
          note: risolto.note,
        );
        // L'AI non ha trovato un blocco di libreria adatto e ne ha
        // inventato uno (FASE 3): lo archivio come bozza, da approvare
        // prima che possa essere riproposto ad altri. Un fallimento qui
        // non deve bloccare un salvataggio già riuscito.
        if (s.nuovo) {
          try {
            await ref
                .read(trainingBlocksRepositoryProvider)
                .salvaSerieComeBlocco(
                  clubId: widget.clubId,
                  codice: 'IA-${serieCreata.id.substring(0, 8)}',
                  sport: 'entrambi',
                  titolo: scheda.titolo,
                  serieGruppo: [serieCreata],
                );
          } catch (_) {}
        }
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
      appBar: AppBar(title: const Text('Proposta dell\'AI')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TestataPagina(
            titolo: scheda.titolo,
            sottotitolo: scheda.note != null && scheda.note!.isNotEmpty
                ? scheda.note
                : null,
            numeri: [
              NumeroTestata(
                valore: formattaMetri(scheda.volumeTotaleM),
                etichetta: 'Metri',
              ),
              NumeroTestata(
                valore: formattaMetri(scheda.volumeLavoroCentraleM),
                etichetta: 'Lavoro centrale',
              ),
              NumeroTestata(
                valore:
                    '~${scheda.minutiStimati ?? stimaMinutiSessione(scheda.serie)}',
                etichetta: 'Minuti',
              ),
            ],
          ),
          if (widget.assegnazione != null &&
              widget.assegnazione!.senzaTestSoglia.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s16),
            _AvvisoSenzaTestSoglia(
              atletiIds: widget.assegnazione!.senzaTestSoglia,
              clubId: widget.clubId,
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
          const SizedBox(height: AppSpacing.s24),
          TitoloSezione('Serie', conteggio: scheda.serie.length),
          AppListPanel(
            righe: [
              for (final s in scheda.serie)
                AppListRow(
                  leading: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colori.superficieAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${s.ordine}',
                      style: AppTypography.numerica(
                        AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  titolo: titoloSerieProposta(s),
                  sottotitolo: [
                    _sottotitoloSerie(s),
                    if (s.ripartenzePerCorsia.isNotEmpty) _ripartenzeSerie(s),
                    if (s.note != null && s.note!.isNotEmpty) s.note!,
                  ].join('\n'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          // Prima si legge la proposta, poi si sceglie il giorno e si salva.
          FormGroup(
            titolo: 'Salva come allenamento',
            isUltimo: true,
            campi: [
              AppTextField(
                etichetta: 'Data',
                controller: _dataController,
                readOnly: true,
                onTap: _salvataggioInCorso ? null : _scegliData,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              PrimaryButton(
                label: 'Salva',
                isLoading: _salvataggioInCorso,
                onPressed: _salvataggioInCorso ? null : _salva,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avviso (FASE 3): per gli atleti elencati, le zone A1/A2/B1 di questa
/// scheda usano il modello dai primati invece del passo del test di
/// soglia (nessun test BVS/T30 valido registrato) — niente blocca la
/// generazione, ma il coach deve saperlo.
class _AvvisoSenzaTestSoglia extends ConsumerWidget {
  const _AvvisoSenzaTestSoglia({required this.atletiIds, required this.clubId});

  final List<String> atletiIds;
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
    final elenco = atletiIds.map((id) => nomi[id]).whereType<String>().toList()
      ..sort();
    final messaggio = elenco.isEmpty
        ? 'Nessun test di soglia registrato: uso i primati per le zone A1/A2/B1.'
        : 'Nessun test di soglia registrato per ${elenco.join(', ')}: '
              'per loro uso i primati per le zone A1/A2/B1.';
    return Container(
      decoration: BoxDecoration(
        color: colori.attenzioneTenue,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border(left: BorderSide(color: colori.attenzione, width: 3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Text(
        messaggio,
        style: AppTypography.corpo.copyWith(color: colori.testo),
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
