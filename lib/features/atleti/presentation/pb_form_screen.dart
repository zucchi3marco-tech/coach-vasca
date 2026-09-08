import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../data/personal_best_repository.dart';
import '../domain/atleta.dart';
import '../domain/pb_slots.dart';
import '../domain/personal_best.dart';

/// Inserisce (o modifica) il tempo per uno slot stile+distanza già scelto
/// dalla lista (FASE 10, punto 3): qui non si sceglie più né lo stile né
/// la distanza, solo il tempo — sono fissati dallo slot su cui si è
/// toccato in [PbListScreen].
class PbFormScreen extends ConsumerStatefulWidget {
  const PbFormScreen({
    required this.atleta,
    required this.stile,
    required this.distanzaM,
    this.personalBest,
    super.key,
  });

  final Atleta atleta;
  final String stile;
  final int distanzaM;
  final PersonalBest? personalBest;

  @override
  ConsumerState<PbFormScreen> createState() => _PbFormScreenState();
}

class _PbFormScreenState extends ConsumerState<PbFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minutiController;
  late final TextEditingController _secondiController;
  late final TextEditingController _dataController;
  late final TextEditingController _noteController;

  DateTime? _data;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.personalBest != null;

  @override
  void initState() {
    super.initState();
    final pb = widget.personalBest;
    final tempo = pb?.tempoS;
    _minutiController = TextEditingController(
      text: tempo == null ? '0' : (tempo ~/ 60).toString(),
    );
    _secondiController = TextEditingController(
      text: tempo == null
          ? ''
          : (tempo - (tempo ~/ 60) * 60).toStringAsFixed(2),
    );
    _data = pb?.data;
    _dataController = TextEditingController(text: _formattaData(_data));
    _noteController = TextEditingController(text: pb?.note ?? '');
  }

  @override
  void dispose() {
    _minutiController.dispose();
    _secondiController.dispose();
    _dataController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formattaData(DateTime? data) {
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Future<void> _pickData() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _data ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (selected != null) {
      setState(() {
        _data = selected;
        _dataController.text = _formattaData(selected);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final minuti = int.tryParse(_minutiController.text.trim()) ?? 0;
    final secondi = double.tryParse(_secondiController.text.trim()) ?? 0;
    final tempoS = minuti * 60 + secondi;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(personalBestRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.aggiornaPersonalBest(
          id: widget.personalBest!.id,
          stile: widget.stile,
          distanzaM: widget.distanzaM,
          tempoS: tempoS,
          data: _data,
          note: _noteController.text.trim(),
        );
      } else {
        await repository.creaPersonalBest(
          atletaId: widget.atleta.id,
          stile: widget.stile,
          distanzaM: widget.distanzaM,
          tempoS: tempoS,
          data: _data,
          note: _noteController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _elimina() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare questo personal best?'),
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
          .read(personalBestRepositoryProvider)
          .eliminaPersonalBest(widget.personalBest!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text('${widget.distanzaM}m ${capitalizzaParola(widget.stile)}'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Prestazione',
              campi: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        etichetta: 'Minuti',
                        controller: _minutiController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: AppTextField(
                        etichetta: 'Secondi',
                        controller: _secondiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          final minuti =
                              int.tryParse(_minutiController.text.trim()) ?? 0;
                          final secondi = double.tryParse(v?.trim() ?? '');
                          if (minuti == 0 &&
                              (secondi == null || secondi <= 0)) {
                            return 'Inserisci il tempo';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Altro',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Data (facoltativo)',
                  controller: _dataController,
                  readOnly: true,
                  onTap: _pickData,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                AppTextField(
                  etichetta: 'Note (facoltativo)',
                  controller: _noteController,
                  maxLines: 2,
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              ErrorBanner(messaggio: _errorMessage!),
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: 'Salva personal best',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
            if (_isEditing) ...[
              const SizedBox(height: AppSpacing.s12),
              DangerButton(label: 'Elimina', onPressed: _elimina),
            ],
          ],
        ),
      ),
    );
  }
}
