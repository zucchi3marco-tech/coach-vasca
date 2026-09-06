import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../club/application/current_club_provider.dart';
import '../data/partite_repository.dart';
import '../domain/partita.dart';

class PartitaFormScreen extends ConsumerStatefulWidget {
  const PartitaFormScreen({required this.clubId, this.partita, super.key});

  final String clubId;
  final Partita? partita;

  @override
  ConsumerState<PartitaFormScreen> createState() => _PartitaFormScreenState();
}

class _PartitaFormScreenState extends ConsumerState<PartitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dataController;
  late final TextEditingController _oraController;
  late final TextEditingController _luogoController;
  late final TextEditingController _campionatoController;
  late final TextEditingController _coloreCalottinaController;
  late final TextEditingController _squadraCasaController;
  late final TextEditingController _squadraTrasfertaController;
  late final TextEditingController _noteController;
  late DateTime _data;
  late int _numeroMaxConvocati;
  late String _dettaglioTiro;
  late bool _tracciaTempo;
  late String _modalitaSuperiorita;
  late String _nostraSquadra;

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _clubPrefillFatto = false;

  bool get _isEditing => widget.partita != null;

  @override
  void initState() {
    super.initState();
    final p = widget.partita;
    _oraController = TextEditingController(text: p?.ora ?? '');
    _luogoController = TextEditingController(text: p?.luogo ?? '');
    _campionatoController = TextEditingController(text: p?.campionato ?? '');
    _coloreCalottinaController = TextEditingController(
      text: p?.coloreCalottina ?? '',
    );
    _squadraCasaController = TextEditingController(text: p?.squadraCasa ?? '');
    _squadraTrasfertaController = TextEditingController(
      text: p?.squadraTrasferta ?? '',
    );
    _noteController = TextEditingController(text: p?.note ?? '');
    _data = p?.data ?? DateTime.now();
    _dataController = TextEditingController(text: _formattaData(_data));
    _numeroMaxConvocati = p?.numeroMaxConvocati ?? 15;
    _dettaglioTiro = p?.dettaglioTiro ?? 'semplice';
    _tracciaTempo = p?.tracciaTempo ?? true;
    _modalitaSuperiorita = p?.modalitaSuperiorita ?? 'singolo';
    _nostraSquadra = p?.nostraSquadra ?? 'casa';
    if (!_isEditing) {
      ref.read(currentClubProvider.future).then((club) {
        if (mounted) _prefillClubSeVuoto(club?.nome);
      });
      // Precompila le impostazioni eventi copiando l'ultima partita della
      // squadra: di fatto funge da default di club senza bisogno di uno
      // screen impostazioni separato, restando modificabile qui sotto.
      ref.read(partiteRepositoryProvider).ultimaPerClub(widget.clubId).then((
        ultima,
      ) {
        if (mounted && ultima != null) {
          setState(() {
            _dettaglioTiro = ultima.dettaglioTiro;
            _tracciaTempo = ultima.tracciaTempo;
            _modalitaSuperiorita = ultima.modalitaSuperiorita;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    _oraController.dispose();
    _luogoController.dispose();
    _campionatoController.dispose();
    _coloreCalottinaController.dispose();
    _squadraCasaController.dispose();
    _squadraTrasfertaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// In creazione, precompila "Squadra Casa" col nome del club: puo' essere
  /// cambiato a mano se la partita e' in trasferta.
  void _prefillClubSeVuoto(String? nomeClub) {
    if (_clubPrefillFatto || _isEditing || nomeClub == null) return;
    _squadraCasaController.text = nomeClub;
    _clubPrefillFatto = true;
  }

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  Future<void> _pickData() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (selected != null) {
      setState(() {
        _data = selected;
        _dataController.text = _formattaData(selected);
      });
    }
  }

  Future<void> _pickOra() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selected != null) {
      setState(
        () => _oraController.text =
            '${selected.hour.toString().padLeft(2, '0')}:'
            '${selected.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(partiteRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.updatePartita(
          id: widget.partita!.id,
          data: _data,
          ora: _oraController.text.trim(),
          luogo: _luogoController.text.trim(),
          campionato: _campionatoController.text.trim(),
          coloreCalottina: _coloreCalottinaController.text.trim(),
          squadraCasa: _squadraCasaController.text.trim(),
          squadraTrasferta: _squadraTrasfertaController.text.trim(),
          numeroMaxConvocati: _numeroMaxConvocati,
          note: _noteController.text.trim(),
          dettaglioTiro: _dettaglioTiro,
          tracciaTempo: _tracciaTempo,
          modalitaSuperiorita: _modalitaSuperiorita,
          nostraSquadra: _nostraSquadra,
        );
      } else {
        await repository.createPartita(
          clubId: widget.clubId,
          data: _data,
          ora: _oraController.text.trim(),
          luogo: _luogoController.text.trim(),
          campionato: _campionatoController.text.trim(),
          coloreCalottina: _coloreCalottinaController.text.trim(),
          squadraCasa: _squadraCasaController.text.trim(),
          squadraTrasferta: _squadraTrasfertaController.text.trim(),
          numeroMaxConvocati: _numeroMaxConvocati,
          note: _noteController.text.trim(),
          dettaglioTiro: _dettaglioTiro,
          tracciaTempo: _tracciaTempo,
          modalitaSuperiorita: _modalitaSuperiorita,
          nostraSquadra: _nostraSquadra,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = messaggioErrore(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _elimina() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la partita?'),
        content: const Text('Verrà eliminata anche la relativa distinta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (conferma == true) {
      await ref
          .read(partiteRepositoryProvider)
          .deletePartita(widget.partita!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica partita' : 'Nuova partita'),
        actions: [
          if (_isEditing)
            TextButton.icon(
              onPressed: _elimina,
              icon: const Icon(Icons.delete_outline, color: AppColors.rosso),
              label: const Text(
                'Elimina',
                style: TextStyle(color: AppColors.rosso),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Partita',
              campi: [
                AppTextField(
                  etichetta: 'Data',
                  controller: _dataController,
                  readOnly: true,
                  onTap: _pickData,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                AppTextField(
                  etichetta: 'Ora (facoltativo)',
                  controller: _oraController,
                  readOnly: true,
                  onTap: _pickOra,
                  suffixIcon: const Icon(Icons.access_time),
                ),
                AppTextField(
                  etichetta: 'Squadra casa',
                  controller: _squadraCasaController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                AppTextField(
                  etichetta: 'Squadra trasferta',
                  controller: _squadraTrasfertaController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('La mia squadra', style: AppTypography.etichetta),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'casa', label: Text('Casa')),
                        ButtonSegment(
                          value: 'trasferta',
                          label: Text('Trasferta'),
                        ),
                      ],
                      selected: {_nostraSquadra},
                      onSelectionChanged: (s) =>
                          setState(() => _nostraSquadra = s.first),
                    ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Dettagli',
              campi: [
                AppTextField(
                  etichetta: 'Luogo (facoltativo)',
                  controller: _luogoController,
                ),
                AppTextField(
                  etichetta: 'Campionato (facoltativo)',
                  controller: _campionatoController,
                ),
                AppTextField(
                  etichetta: 'Colore calottina (facoltativo)',
                  controller: _coloreCalottinaController,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Numero massimo convocati',
                      style: AppTypography.etichetta,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 13, label: Text('13')),
                        ButtonSegment(value: 15, label: Text('15')),
                      ],
                      selected: {_numeroMaxConvocati},
                      onSelectionChanged: (selezione) => setState(
                        () => _numeroMaxConvocati = selezione.first,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Impostazioni eventi (per questa partita)',
              campi: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dettaglio tiro', style: AppTypography.etichetta),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'semplice',
                          label: Text('Semplice'),
                        ),
                        ButtonSegment(
                          value: 'dettagliato',
                          label: Text('Dettagliato'),
                        ),
                      ],
                      selected: {_dettaglioTiro},
                      onSelectionChanged: (s) =>
                          setState(() => _dettaglioTiro = s.first),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Traccia il tempo di gioco'),
                  subtitle: const Text(
                    'Chiede il numero di tempo (1-4) per ogni evento',
                  ),
                  value: _tracciaTempo,
                  onChanged: (v) => setState(() => _tracciaTempo = v),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Superiorità numerica',
                      style: AppTypography.etichetta,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'singolo',
                          label: Text('Esito subito'),
                        ),
                        ButtonSegment(
                          value: 'inizio_fine',
                          label: Text('Inizio/fine'),
                        ),
                      ],
                      selected: {_modalitaSuperiorita},
                      onSelectionChanged: (s) =>
                          setState(() => _modalitaSuperiorita = s.first),
                    ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Note',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Note (facoltativo)',
                  controller: _noteController,
                  maxLines: 3,
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              ErrorBanner(messaggio: _errorMessage!),
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: 'Salva partita',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
