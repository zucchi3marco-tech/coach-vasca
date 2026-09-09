import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../stagioni/application/microcicli_providers.dart';
import '../../stagioni/domain/microciclo.dart';
import '../application/corsie_service.dart';
import '../data/generazione_ai_repository.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/parametri_generazione.dart';
import '../domain/scheda_generata.dart';
import 'storico_generazioni_screen.dart';

const _livelli = ['principiante', 'intermedio', 'avanzato', 'agonista'];
const _focus = ['aerobico', 'soglia', 'velocita', 'tecnica', 'misto'];
const _regimi = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'C3', 'D'];

String _capitalizza(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class GeneraAllenamentoFormScreen extends ConsumerStatefulWidget {
  const GeneraAllenamentoFormScreen({
    required this.clubId,
    this.microcicloId,
    this.dataPredefinita,
    super.key,
  });

  final String clubId;

  /// Se valorizzato (es. aperto dal dettaglio di una settimana), la scheda
  /// generata viene proposta già collegata a quel microciclo.
  final String? microcicloId;
  final DateTime? dataPredefinita;

  @override
  ConsumerState<GeneraAllenamentoFormScreen> createState() =>
      _GeneraAllenamentoFormScreenState();
}

class _GeneraAllenamentoFormScreenState
    extends ConsumerState<GeneraAllenamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vincoliController = TextEditingController();

  String? _gruppoId;
  double _volumeMetri = 3000;
  String _livello = _livelli.first;
  String _focusSelezionato = _focus.first;
  final Set<String> _regimiSelezionati = {};
  bool _generazioneInCorso = false;

  @override
  void dispose() {
    _vincoliController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: const Text('Genera con AI'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoricoGenerazioniScreen(clubId: widget.clubId),
              ),
            ),
            icon: const Icon(Icons.history, size: 20),
            label: const Text('Storico'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Parametri',
              campi: [
                AppSelect<String?>(
                  etichetta: 'Gruppo',
                  value: _gruppoId,
                  hint: 'Tutti gli atleti',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tutti gli atleti'),
                    ),
                    for (final g in gruppi)
                      DropdownMenuItem(value: g.id, child: Text(g.nome)),
                  ],
                  onChanged: (value) => setState(() => _gruppoId = value),
                ),
                AppSelect<String>(
                  etichetta: 'Livello',
                  value: _livello,
                  items: [
                    for (final l in _livelli)
                      DropdownMenuItem(value: l, child: Text(_capitalizza(l))),
                  ],
                  onChanged: (value) =>
                      setState(() => _livello = value ?? _livelli.first),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volume totale: ${_volumeMetri.round()} m',
                      style: AppTypography.etichetta,
                    ),
                    Slider(
                      value: _volumeMetri,
                      min: 500,
                      max: 6000,
                      divisions: 55,
                      label: '${_volumeMetri.round()} m',
                      onChanged: (value) =>
                          setState(() => _volumeMetri = value),
                    ),
                  ],
                ),
                AppSelect<String>(
                  etichetta: 'Focus',
                  value: _focusSelezionato,
                  items: [
                    for (final f in _focus)
                      DropdownMenuItem(value: f, child: Text(_capitalizza(f))),
                  ],
                  onChanged: (value) =>
                      setState(() => _focusSelezionato = value ?? _focus.first),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Regimi e vincoli',
              isUltimo: true,
              campi: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Regimi ammessi', style: AppTypography.etichetta),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      children: [
                        for (final r in _regimi)
                          FilterChip(
                            label: Text(r),
                            selected: _regimiSelezionati.contains(r),
                            onSelected: (selezionato) => setState(() {
                              if (selezionato) {
                                _regimiSelezionati.add(r);
                              } else {
                                _regimiSelezionati.remove(r);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
                AppTextField(
                  etichetta: 'Vincoli (facoltativo)',
                  controller: _vincoliController,
                  maxLines: 3,
                  aiuto: 'Es. niente pinne, max 75 minuti, vasca 25m',
                ),
              ],
            ),
            PrimaryButton(
              label: 'Genera',
              isLoading: _generazioneInCorso,
              onPressed: _generazioneInCorso ? null : _conferma,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _conferma() async {
    if (!_formKey.currentState!.validate()) return;
    if (_regimiSelezionati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un regime ammesso')),
      );
      return;
    }

    setState(() => _generazioneInCorso = true);

    var corsie = const <CorsiaGenerazione>[];
    try {
      final tuttiGliAtleti = await ref.read(
        atletiListProvider((clubId: widget.clubId, includeInactive: false))
            .future,
      );
      final atletiDelGruppo = _gruppoId == null
          ? tuttiGliAtleti
          : tuttiGliAtleti.where((a) => a.gruppoId == _gruppoId).toList();
      corsie = await calcolaCorsie(ref, atletiDelGruppo);
    } catch (_) {
      // Le corsie migliorano la generazione (ripartenze sui passi reali),
      // ma non sono indispensabili: se il calcolo fallisce si procede
      // comunque, senza passi di riferimento.
    }

    final Map<String, String> nomiGruppi = {
      for (final g in ref.read(gruppiListProvider(widget.clubId)).value ?? [])
        g.id: g.nome,
    };

    final parametri = ParametriGenerazione(
      gruppo: nomiGruppi[_gruppoId] ?? 'Tutti gli atleti',
      livello: _livello,
      volumeMetri: _volumeMetri.round(),
      focus: _focusSelezionato,
      regimiAmmessi: _regimiSelezionati.toList(),
      vincoli: _vincoliController.text.trim().isEmpty
          ? null
          : _vincoliController.text.trim(),
      corsie: corsie,
    );

    try {
      final scheda = await ref
          .read(generazioneAiRepositoryProvider)
          .generaAllenamento(parametri);

      // Lo storico e' un di piu' per rivedere/migliorare i prompt: un suo
      // fallimento non deve mai bloccare una generazione riuscita.
      String? generazioneId;
      try {
        generazioneId = await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.clubId,
              parametri: parametri,
              esito: 'successo',
              scheda: scheda.toMap(),
            );
      } catch (_) {}

      if (!mounted) return;
      final allenamentoSalvato = await showDialog<Allenamento>(
        context: context,
        builder: (context) => _DialogSchedaGenerata(
          scheda: scheda,
          clubId: widget.clubId,
          gruppoId: _gruppoId,
          microcicloIniziale: widget.microcicloId,
          dataIniziale: widget.dataPredefinita,
          generazioneId: generazioneId,
        ),
      );
      if (allenamentoSalvato != null && mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                AllenamentoDetailScreen(allenamento: allenamentoSalvato),
          ),
        );
      }
    } catch (e) {
      try {
        await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.clubId,
              parametri: parametri,
              esito: 'errore',
              messaggioErrore: e.toString(),
            );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella generazione: ${messaggioErrore(e)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _generazioneInCorso = false);
    }
  }
}

class _DialogSchedaGenerata extends ConsumerStatefulWidget {
  const _DialogSchedaGenerata({
    required this.scheda,
    required this.clubId,
    required this.gruppoId,
    this.microcicloIniziale,
    this.dataIniziale,
    this.generazioneId,
  });

  final SchedaGenerata scheda;
  final String clubId;
  final String? gruppoId;
  final String? microcicloIniziale;
  final DateTime? dataIniziale;

  /// Id della voce di storico creata per questa generazione (nullo se la
  /// registrazione dello storico stessa era fallita): se presente, dopo il
  /// salvataggio ci si collega l'allenamento creato.
  final String? generazioneId;

  @override
  ConsumerState<_DialogSchedaGenerata> createState() =>
      _DialogSchedaGeneratedState();
}

class _DialogSchedaGeneratedState extends ConsumerState<_DialogSchedaGenerata> {
  late DateTime _data = widget.dataIniziale ?? DateTime.now();
  late String? _microcicloId = widget.microcicloIniziale;
  bool _salvataggioInCorso = false;

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

  String _etichettaMicrociclo(Microciclo m) {
    if (m.nome != null && m.nome!.isNotEmpty) return m.nome!;
    if (m.numeroSettimana != null) return 'Settimana ${m.numeroSettimana}';
    return 'Microciclo';
  }

  @override
  Widget build(BuildContext context) {
    final scheda = widget.scheda;
    final microcicliAsync = ref.watch(microcicliDelClubProvider(widget.clubId));
    return AlertDialog(
      title: Text(scheda.titolo),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Volume totale: ${scheda.volumeTotaleM} m',
                style: AppTypography.piccolo,
              ),
              if (scheda.note != null && scheda.note!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                Text(scheda.note!, style: AppTypography.corpo),
              ],
              const SizedBox(height: AppSpacing.s12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(_formattaData(_data)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _salvataggioInCorso ? null : _scegliData,
              ),
              const SizedBox(height: AppSpacing.s8),
              microcicliAsync.when(
                data: (microcicli) => DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _microcicloId,
                  decoration: const InputDecoration(
                    labelText: 'Settimana (opzionale)',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Nessun microciclo'),
                    ),
                    for (final m in microcicli)
                      DropdownMenuItem(
                        value: m.id,
                        child: Text(_etichettaMicrociclo(m)),
                      ),
                  ],
                  onChanged: _salvataggioInCorso
                      ? null
                      : (value) => setState(() => _microcicloId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'Errore nel caricamento settimane: '
                  '${messaggioErrore(error)}',
                  style: AppTypography.piccolo,
                ),
              ),
              const Divider(height: AppSpacing.s24),
              for (final s in scheda.serie)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.ordine}. ${s.ripetute}×${s.distanzaM}m '
                        '${labelStile(s.stile)} ${labelEsecuzione(s.esecuzione)}',
                        style: AppTypography.corpoForte,
                      ),
                      Text(_sottotitoloSerie(s), style: AppTypography.piccolo),
                      if (s.ripartenzePerCorsia.isNotEmpty)
                        Text(
                          _ripartenzeSerie(s),
                          style: AppTypography.piccolo.copyWith(
                            color: AppColors.blu,
                          ),
                        ),
                      if (s.note != null && s.note!.isNotEmpty)
                        Text(s.note!, style: AppTypography.piccolo),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvataggioInCorso
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _salvataggioInCorso ? null : _salva,
          child: _salvataggioInCorso
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salva'),
        ),
      ],
    );
  }

  Future<void> _scegliData() async {
    final scelta = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (scelta != null) setState(() => _data = scelta);
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
            microcicloId: _microcicloId,
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
}
