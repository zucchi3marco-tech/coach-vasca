import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/attesa_ai_hint.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../application/corsie_service.dart';
import '../data/generazione_ai_repository.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/focus_lavoro.dart';
import '../domain/parametri_generazione.dart';
import '../domain/tipo_lavoro.dart';
import 'chip_tipo_lavoro.dart';
import 'scheda_generata_screen.dart';
import 'storico_generazioni_screen.dart';

const _stiliNuoto = ['libero', 'dorso', 'rana', 'delfino', 'misti'];
const _attrezzaturaBraccia = ['pull', 'palette'];
const _attrezzaturaGambe = ['pinne', 'tavola', 'boccaglio'];
const _attrezzaturaLavoroCentraleDisponibile = [
  'pull',
  'palette',
  'boccaglio',
  'pinne',
];

String _capitalizza(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _etichettaAttrezzo(String a) => switch (a) {
  'pull' => 'Pull',
  'palette' => 'Palette',
  'boccaglio' => 'Boccaglio',
  'pinne' => 'Pinne',
  'tavola' => 'Tavola',
  _ => _capitalizza(a),
};

class GeneraAllenamentoFormScreen extends ConsumerStatefulWidget {
  const GeneraAllenamentoFormScreen({
    required this.clubId,
    this.dataPredefinita,
    super.key,
  });

  final String clubId;
  final DateTime? dataPredefinita;

  @override
  ConsumerState<GeneraAllenamentoFormScreen> createState() =>
      _GeneraAllenamentoFormScreenState();
}

class _GeneraAllenamentoFormScreenState
    extends ConsumerState<GeneraAllenamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vincoliController = TextEditingController();

  double _volumeMetri = 3000;
  double? _volumeLavoroCentraleMetri;
  double _minutiMax = 60;
  int _vascaM = 25;
  String _focusSelezionato = focusLavoro.first;
  double? _metriFocusSpecifico;
  final Set<String> _attrezzaturaFocusSelezionata = {};
  String? _stileFocus;
  final Set<String> _attrezzaturaLavoroCentraleSelezionata = {};
  bool _mostraCodiciTipoLavoro = true;
  final Set<String> _regimiSelezionati = {};
  bool _generazioneInCorso = false;

  bool get _focusHaDettaglio =>
      _focusSelezionato == 'braccia' || _focusSelezionato == 'gambe';

  List<String> get _attrezzaturaFocusDisponibile =>
      _focusSelezionato == 'braccia'
      ? _attrezzaturaBraccia
      : _attrezzaturaGambe;

  @override
  void dispose() {
    _vincoliController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gruppoId = ref.watch(selezioneGruppoProvider)?.gruppoId;
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final nomeGruppo =
        gruppi.where((g) => g.id == gruppoId).firstOrNull?.nome ??
        'Tutti gli atleti';
    final colori = context.colori;
    final volumeLavoroCentraleClampato = (_volumeLavoroCentraleMetri ?? 0)
        .clamp(0, _volumeMetri)
        .toDouble();

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gruppo',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      nomeGruppo,
                      style: AppTypography.corpo.copyWith(color: colori.testo),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volume totale: ${_volumeMetri.round()} m',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    Slider(
                      value: _volumeMetri,
                      min: 500,
                      max: 6000,
                      divisions: 55,
                      label: '${_volumeMetri.round()} m',
                      onChanged: (value) => setState(() {
                        _volumeMetri = value;
                        if ((_volumeLavoroCentraleMetri ?? 0) > value) {
                          _volumeLavoroCentraleMetri = value;
                        }
                      }),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _volumeLavoroCentraleMetri == null
                          ? 'Volume lavoro centrale: decide l\'AI'
                          : 'Volume lavoro centrale: '
                                '${volumeLavoroCentraleClampato.round()} m',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    Slider(
                      value: volumeLavoroCentraleClampato,
                      min: 0,
                      max: _volumeMetri,
                      divisions: (_volumeMetri / 100).round().clamp(1, 999),
                      label: '${volumeLavoroCentraleClampato.round()} m',
                      onChanged: (value) =>
                          setState(() => _volumeLavoroCentraleMetri = value),
                    ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Sessione',
              campi: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Minuti max di lavoro: ${_minutiMax.round()} min',
                            style: AppTypography.etichetta.copyWith(
                              color: colori.testoSecondario,
                            ),
                          ),
                        ),
                        const PulsanteSpiegazione(
                          titolo: 'Minuti max di lavoro',
                          spiegazione:
                              'La scheda generata non deve superare questo '
                              "tempo, stimato su nuoto + recuperi dell'atleta "
                              'più lento del gruppo (è quello che finisce per '
                              'ultimo). La stima non tiene conto dei tempi di '
                              'virata né della lunghezza della vasca: è '
                              'un\'approssimazione, non un cronometro.',
                        ),
                      ],
                    ),
                    Slider(
                      value: _minutiMax,
                      min: 20,
                      max: 180,
                      divisions: 32,
                      label: '${_minutiMax.round()} min',
                      onChanged: (value) => setState(() => _minutiMax = value),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vasca',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 25, label: Text('25m')),
                        ButtonSegment(value: 50, label: Text('50m')),
                      ],
                      selected: {_vascaM},
                      onSelectionChanged: (s) =>
                          setState(() => _vascaM = s.first),
                    ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Focus',
              campi: [
                AppSelect<String>(
                  etichetta: 'Focus',
                  value: _focusSelezionato,
                  items: [
                    for (final f in focusLavoro)
                      DropdownMenuItem(
                        value: f,
                        child: Text(etichettaFocusLavoro(f)),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _focusSelezionato = value ?? focusLavoro.first;
                    _attrezzaturaFocusSelezionata.clear();
                    _stileFocus = null;
                  }),
                ),
                if (_focusHaDettaglio) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metri di ${etichettaFocusLavoro(_focusSelezionato).toLowerCase()}: '
                        '${(_metriFocusSpecifico ?? 0).round()} m',
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                      Slider(
                        value: (_metriFocusSpecifico ?? 0).clamp(
                          0,
                          _volumeMetri,
                        ),
                        min: 0,
                        max: _volumeMetri,
                        divisions: (_volumeMetri / 100).round().clamp(1, 999),
                        label: '${(_metriFocusSpecifico ?? 0).round()} m',
                        onChanged: (value) =>
                            setState(() => _metriFocusSpecifico = value),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attrezzatura',
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Wrap(
                        spacing: AppSpacing.s8,
                        children: [
                          for (final a in _attrezzaturaFocusDisponibile)
                            TonalChip(
                              etichetta: _etichettaAttrezzo(a),
                              selezionato: _attrezzaturaFocusSelezionata
                                  .contains(a),
                              onSelezionato: (selezionato) => setState(() {
                                if (selezionato) {
                                  _attrezzaturaFocusSelezionata.add(a);
                                } else {
                                  _attrezzaturaFocusSelezionata.remove(a);
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
                  ),
                  AppSelect<String?>(
                    etichetta: 'Stile (facoltativo)',
                    value: _stileFocus,
                    hint: 'Decide l\'AI',
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Decide l\'AI'),
                      ),
                      for (final s in _stiliNuoto)
                        DropdownMenuItem(value: s, child: Text(labelStile(s))),
                    ],
                    onChanged: (value) => setState(() => _stileFocus = value),
                  ),
                ],
              ],
            ),
            FormGroup(
              titolo: 'Tipo di lavoro e vincoli',
              isUltimo: true,
              campi: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tipo di lavoro ammesso',
                            style: AppTypography.etichetta.copyWith(
                              color: colori.testoSecondario,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(
                            () => _mostraCodiciTipoLavoro =
                                !_mostraCodiciTipoLavoro,
                          ),
                          child: Text(
                            _mostraCodiciTipoLavoro
                                ? 'Mostra nomi'
                                : 'Mostra sigle',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final zona in ordineTipiLavoro)
                          ChipTipoLavoro(
                            zona: zona,
                            selezionato: _regimiSelezionati.contains(zona),
                            mostraCodici: _mostraCodiciTipoLavoro,
                            onSelezionato: (selezionato) => setState(() {
                              if (selezionato) {
                                _regimiSelezionati.add(zona);
                              } else {
                                _regimiSelezionati.remove(zona);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attrezzi lavoro centrale',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      children: [
                        for (final a in _attrezzaturaLavoroCentraleDisponibile)
                          TonalChip(
                            etichetta: _etichettaAttrezzo(a),
                            selezionato: _attrezzaturaLavoroCentraleSelezionata
                                .contains(a),
                            onSelezionato: (selezionato) => setState(() {
                              if (selezionato) {
                                _attrezzaturaLavoroCentraleSelezionata.add(a);
                              } else {
                                _attrezzaturaLavoroCentraleSelezionata.remove(
                                  a,
                                );
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
                  aiuto: 'Es. niente pinne di gomma, riscaldamento breve',
                ),
              ],
            ),
            PrimaryButton(
              label: _generazioneInCorso ? 'Sto generando...' : 'Genera',
              isLoading: _generazioneInCorso,
              onPressed: _generazioneInCorso ? null : _conferma,
            ),
            if (_generazioneInCorso) const AttesaAiHint(),
          ],
        ),
      ),
    );
  }

  Future<void> _conferma() async {
    if (!_formKey.currentState!.validate()) return;
    if (_regimiSelezionati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un tipo di lavoro')),
      );
      return;
    }

    final gruppoId = ref.read(selezioneGruppoProvider)?.gruppoId;
    setState(() => _generazioneInCorso = true);

    var corsie = const <CorsiaGenerazione>[];
    try {
      final tuttiGliAtleti = await ref.read(
        atletiListProvider((clubId: widget.clubId, includeInactive: false))
            .future,
      );
      final atletiDelGruppo = gruppoId == null
          ? tuttiGliAtleti
          : tuttiGliAtleti.where((a) => a.gruppoId == gruppoId).toList();
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
      gruppo: nomiGruppi[gruppoId] ?? 'Tutti gli atleti',
      volumeMetri: _volumeMetri.round(),
      volumeLavoroCentraleM: _volumeLavoroCentraleMetri?.round(),
      focus: _focusSelezionato,
      metriFocusSpecifico: _focusHaDettaglio
          ? _metriFocusSpecifico?.round()
          : null,
      attrezzaturaFocus: _focusHaDettaglio
          ? _attrezzaturaFocusSelezionata.toList()
          : const [],
      stileFocus: _focusHaDettaglio ? _stileFocus : null,
      attrezzaturaLavoroCentrale: _attrezzaturaLavoroCentraleSelezionata
          .toList(),
      minutiMax: _minutiMax.round(),
      vascaM: _vascaM,
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
              parametri: parametri.toMap(),
              esito: 'successo',
              scheda: scheda.toMap(),
            );
      } catch (_) {}

      if (!mounted) return;
      final allenamentoSalvato = await Navigator.of(context).push<Allenamento>(
        MaterialPageRoute(
          builder: (_) => SchedaGenerataScreen(
            scheda: scheda,
            clubId: widget.clubId,
            gruppoId: gruppoId,
            dataIniziale: widget.dataPredefinita,
            generazioneId: generazioneId,
          ),
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
              parametri: parametri.toMap(),
              esito: 'errore',
              messaggioErrore: e.toString(),
            );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella generazione: ${messaggioErrore(e)}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Riprova', onPressed: _conferma),
        ),
      );
    } finally {
      if (mounted) setState(() => _generazioneInCorso = false);
    }
  }
}
