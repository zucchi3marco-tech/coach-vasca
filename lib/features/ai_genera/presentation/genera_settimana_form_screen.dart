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
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../stagioni/domain/microciclo.dart';
import '../application/corsie_service.dart';
import '../data/generazione_ai_repository.dart';
import '../domain/parametri_generazione.dart';
import '../domain/scheda_generata.dart';
import '../domain/settimana_generata.dart';

const _livelli = ['principiante', 'intermedio', 'avanzato', 'agonista'];
const _focus = ['aerobico', 'soglia', 'velocita', 'tecnica', 'misto'];

String _capitalizza(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Pianifica una settimana intera (FASE 10, punto 5): prima uno scheletro
/// leggero (numero di sedute, codice, volume) via `genera-settimana`, poi
/// il dettaglio delle serie di ogni seduta via `genera-allenamento` —
/// stessi passi/corsie calcolati una sola volta per il gruppo. Non tiene
/// ancora conto delle settimane precedenti né del calendario gare
/// (rimandato, vedi ROADMAP.md).
class GeneraSettimanaFormScreen extends ConsumerStatefulWidget {
  const GeneraSettimanaFormScreen({required this.microciclo, super.key});

  final Microciclo microciclo;

  @override
  ConsumerState<GeneraSettimanaFormScreen> createState() =>
      _GeneraSettimanaFormScreenState();
}

class _GeneraSettimanaFormScreenState
    extends ConsumerState<GeneraSettimanaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vincoliController = TextEditingController();

  String? _gruppoId;
  String _livello = _livelli.first;
  String _focusSelezionato = _focus.first;
  double _numeroSedute = 4;
  double _volumeSettimanale = 12000;
  bool _generazioneInCorso = false;
  String? _fasePassaggio;

  @override
  void dispose() {
    _vincoliController.dispose();
    super.dispose();
  }

  DateTime _dataPerGiorno(int giorno) {
    final data = widget.microciclo.dataInizio.add(Duration(days: giorno - 1));
    if (data.isAfter(widget.microciclo.dataFine)) {
      return widget.microciclo.dataFine;
    }
    return data;
  }

  Future<void> _conferma() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _generazioneInCorso = true;
      _fasePassaggio = 'Pianificazione della settimana...';
    });

    var corsie = const <CorsiaGenerazione>[];
    try {
      final tuttiGliAtleti = await ref.read(
        atletiListProvider((
          clubId: widget.microciclo.clubId,
          includeInactive: false,
        )).future,
      );
      final atletiDelGruppo = _gruppoId == null
          ? tuttiGliAtleti
          : tuttiGliAtleti.where((a) => a.gruppoId == _gruppoId).toList();
      corsie = await calcolaCorsie(ref, atletiDelGruppo);
    } catch (_) {
      // Le corsie migliorano la generazione, ma non sono indispensabili.
    }

    final Map<String, String> nomiGruppi = {
      for (final g
          in ref.read(gruppiListProvider(widget.microciclo.clubId)).value ??
              [])
        g.id: g.nome,
    };
    final gruppoLabel = nomiGruppi[_gruppoId] ?? 'Tutti gli atleti';
    final vincoliUtente = _vincoliController.text.trim();

    try {
      final settimana = await ref
          .read(generazioneAiRepositoryProvider)
          .generaSettimana(
            ParametriSettimana(
              gruppo: gruppoLabel,
              numeroSedute: _numeroSedute.round(),
              volumeSettimanaleMetri: _volumeSettimanale.round(),
              focus: _focusSelezionato,
              tipoMicrociclo: widget.microciclo.tipo,
              vincoli: vincoliUtente.isEmpty ? null : vincoliUtente,
              corsie: corsie,
            ),
          );

      final sedute = <SedutaConScheda>[];
      for (var i = 0; i < settimana.sedute.length; i++) {
        final seduta = settimana.sedute[i];
        if (mounted) {
          setState(
            () => _fasePassaggio =
                'Dettaglio seduta ${i + 1} di ${settimana.sedute.length}...',
          );
        }
        final vincoliGiorno = [
          'Enfasi di questa seduta: ${seduta.codice}.',
          if (vincoliUtente.isNotEmpty) vincoliUtente,
        ].join(' ');
        final scheda = await ref
            .read(generazioneAiRepositoryProvider)
            .generaAllenamento(
              ParametriGenerazione(
                gruppo: gruppoLabel,
                livello: _livello,
                volumeMetri: seduta.volumeMetri,
                focus: _focusSelezionato,
                regimiAmmessi: const [
                  'A1',
                  'A2',
                  'B1',
                  'B2',
                  'C1',
                  'C2',
                  'C3',
                  'D',
                ],
                vincoli: vincoliGiorno,
                corsie: corsie,
              ),
            );
        sedute.add(
          SedutaConScheda(
            seduta: seduta,
            scheda: scheda,
            data: _dataPerGiorno(seduta.giorno),
          ),
        );
      }

      if (!mounted) return;
      final salvata = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _RevisioneSettimanaScreen(
            clubId: widget.microciclo.clubId,
            microcicloId: widget.microciclo.id,
            gruppoId: _gruppoId,
            sedute: sedute,
          ),
        ),
      );
      if (salvata == true && mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella generazione: ${messaggioErrore(e)}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generazioneInCorso = false;
          _fasePassaggio = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gruppi =
        ref.watch(gruppiListProvider(widget.microciclo.clubId)).value ?? [];

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Genera settimana con AI')),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pianifica le sedute di questa settimana '
              '(${_formattaData(widget.microciclo.dataInizio)} - '
              '${_formattaData(widget.microciclo.dataFine)}). Il dettaglio '
              'di ogni seduta si genera subito dopo lo scheletro: la '
              'revisione richiede qualche secondo in più di una singola '
              'generazione.',
              style: AppTypography.piccolo,
            ),
            const SizedBox(height: AppSpacing.s16),
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
                      'Numero di sedute: ${_numeroSedute.round()}',
                      style: AppTypography.etichetta,
                    ),
                    Slider(
                      value: _numeroSedute,
                      min: 2,
                      max: 7,
                      divisions: 5,
                      label: '${_numeroSedute.round()}',
                      onChanged: (value) =>
                          setState(() => _numeroSedute = value),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volume settimanale: ${_volumeSettimanale.round()} m',
                      style: AppTypography.etichetta,
                    ),
                    Slider(
                      value: _volumeSettimanale,
                      min: 2000,
                      max: 20000,
                      divisions: 36,
                      label: '${_volumeSettimanale.round()} m',
                      onChanged: (value) =>
                          setState(() => _volumeSettimanale = value),
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
                AppTextField(
                  etichetta: 'Vincoli (facoltativo)',
                  controller: _vincoliController,
                  maxLines: 3,
                  aiuto: 'Es. niente pinne, max 75 minuti, vasca 25m',
                ),
              ],
            ),
            if (_fasePassaggio != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(_fasePassaggio!, style: AppTypography.piccolo),
            ],
            const SizedBox(height: AppSpacing.s16),
            PrimaryButton(
              label: 'Genera settimana',
              isLoading: _generazioneInCorso,
              onPressed: _generazioneInCorso ? null : _conferma,
            ),
          ],
        ),
      ),
    );
  }

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';
}

/// Una seduta della settimana proposta, con il dettaglio già generato.
class SedutaConScheda {
  const SedutaConScheda({
    required this.seduta,
    required this.scheda,
    required this.data,
  });

  final SedutaGenerata seduta;
  final SchedaGenerata scheda;
  final DateTime data;
}

class _RevisioneSettimanaScreen extends ConsumerStatefulWidget {
  const _RevisioneSettimanaScreen({
    required this.clubId,
    required this.microcicloId,
    required this.gruppoId,
    required this.sedute,
  });

  final String clubId;
  final String microcicloId;
  final String? gruppoId;
  final List<SedutaConScheda> sedute;

  @override
  ConsumerState<_RevisioneSettimanaScreen> createState() =>
      _RevisioneSettimanaScreenState();
}

class _RevisioneSettimanaScreenState
    extends ConsumerState<_RevisioneSettimanaScreen> {
  late final List<SedutaConScheda> _sedute = List.of(widget.sedute);
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

  Future<void> _cambiaData(int indice) async {
    final corrente = _sedute[indice];
    final scelta = await showDatePicker(
      context: context,
      initialDate: corrente.data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (scelta != null) {
      setState(() {
        _sedute[indice] = SedutaConScheda(
          seduta: corrente.seduta,
          scheda: corrente.scheda,
          data: scelta,
        );
      });
    }
  }

  Future<void> _salva() async {
    setState(() => _salvataggioInCorso = true);
    try {
      final allenamentiRepository = ref.read(allenamentiRepositoryProvider);
      final serieRepository = ref.read(serieRepositoryProvider);
      for (final voce in _sedute) {
        final allenamento = await allenamentiRepository.createAllenamento(
          clubId: widget.clubId,
          data: voce.data,
          microcicloId: widget.microcicloId,
          titolo: voce.scheda.titolo,
          gruppoId: widget.gruppoId,
          note: voce.scheda.note,
        );
        for (final s in voce.scheda.serie) {
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
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text('Settimana proposta (${_sedute.length} sedute)'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _sedute.length; i++) ...[
            _CardSeduta(
              voce: _sedute[i],
              formattaData: _formattaData,
              sottotitoloSerie: _sottotitoloSerie,
              onCambiaData: () => _cambiaData(i),
              onRimuovi: _sedute.length > 1
                  ? () => setState(() => _sedute.removeAt(i))
                  : null,
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          PrimaryButton(
            label: 'Salva ${_sedute.length} sedute',
            isLoading: _salvataggioInCorso,
            onPressed: _salvataggioInCorso ? null : _salva,
          ),
        ],
      ),
    );
  }
}

class _CardSeduta extends StatelessWidget {
  const _CardSeduta({
    required this.voce,
    required this.formattaData,
    required this.sottotitoloSerie,
    required this.onCambiaData,
    required this.onRimuovi,
  });

  final SedutaConScheda voce;
  final String Function(DateTime) formattaData;
  final String Function(SerieGenerata) sottotitoloSerie;
  final VoidCallback onCambiaData;
  final VoidCallback? onRimuovi;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        border: Border.all(color: AppColors.linea),
      ),
      padding: const EdgeInsets.all(AppSpacing.paddingPannello),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(voce.scheda.titolo, style: AppTypography.titolo),
              ),
              if (onRimuovi != null)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.testoSecondario,
                  ),
                  tooltip: 'Rimuovi questa seduta dal piano',
                  onPressed: onRimuovi,
                ),
            ],
          ),
          InkWell(
            onTap: onCambiaData,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.blu,
                ),
                const SizedBox(width: AppSpacing.s4),
                Text(
                  formattaData(voce.data),
                  style: AppTypography.corpoForte.copyWith(
                    color: AppColors.blu,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            '${voce.seduta.codice} · ${voce.scheda.volumeTotaleM} m',
            style: AppTypography.piccolo,
          ),
          const Divider(height: AppSpacing.s24),
          for (final s in voce.scheda.serie)
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
                  Text(sottotitoloSerie(s), style: AppTypography.piccolo),
                  if (s.ripartenzePerCorsia.isNotEmpty)
                    Text(
                      formattaRipartenzeCorsia(s.ripartenzePerCorsia),
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
    );
  }
}
