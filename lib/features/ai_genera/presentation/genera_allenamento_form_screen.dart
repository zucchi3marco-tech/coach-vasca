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
import '../../../widgets/tonal_chip.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../application/corsie_service.dart';
import '../data/generazione_ai_repository.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/parametri_generazione.dart';
import 'scheda_generata_screen.dart';
import 'storico_generazioni_screen.dart';

const _focus = ['aerobico', 'soglia', 'velocita', 'tecnica', 'misto'];
const _regimi = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'C3', 'D'];

String _capitalizza(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "velocita" resta senza accento come valore interno (identico a quanto
/// manda l'Edge Function): solo l'etichetta mostrata va accentata.
String _etichettaFocus(String f) =>
    f == 'velocita' ? 'Velocità' : _capitalizza(f);

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
    final gruppoId = ref.watch(selezioneGruppoProvider)?.gruppoId;
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final nomeGruppo =
        gruppi.where((g) => g.id == gruppoId).firstOrNull?.nome ??
        'Tutti gli atleti';
    final colori = context.colori;
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
                      DropdownMenuItem(
                        value: f,
                        child: Text(_etichettaFocus(f)),
                      ),
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
                    Text(
                      'Regimi ammessi',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      children: [
                        for (final r in _regimi)
                          TonalChip(
                            etichetta: r,
                            selezionato: _regimiSelezionati.contains(r),
                            onSelezionato: (selezionato) => setState(() {
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
        const SnackBar(content: Text('Seleziona almeno un regime ammesso')),
      );
      return;
    }

    setState(() => _generazioneInCorso = true);

    final gruppoId = ref.read(selezioneGruppoProvider)?.gruppoId;
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
