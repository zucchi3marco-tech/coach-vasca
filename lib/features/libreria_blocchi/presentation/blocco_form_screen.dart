import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../data/training_blocks_repository.dart';
import '../domain/training_block.dart';

/// Crea o modifica solo l'intestazione di un blocco (codice, titolo,
/// sport, fase, obiettivo, note) — le parti si popolano importando il
/// file Excel o con "Salva come blocco" da una serie vera.
class BloccoFormScreen extends ConsumerStatefulWidget {
  const BloccoFormScreen({required this.clubId, this.blocco, super.key});

  final String clubId;
  final TrainingBlock? blocco;

  @override
  ConsumerState<BloccoFormScreen> createState() => _BloccoFormScreenState();
}

class _BloccoFormScreenState extends ConsumerState<BloccoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codiceController;
  late final TextEditingController _titoloController;
  late final TextEditingController _faseController;
  late final TextEditingController _obiettivoController;
  late final TextEditingController _noteController;
  late String _sport;
  late String _stato;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.blocco != null;

  @override
  void initState() {
    super.initState();
    final b = widget.blocco;
    _codiceController = TextEditingController(text: b?.codice ?? '');
    _titoloController = TextEditingController(text: b?.titolo ?? '');
    _faseController = TextEditingController(text: b?.fase ?? '');
    _obiettivoController = TextEditingController(text: b?.obiettivo ?? '');
    _noteController = TextEditingController(text: b?.note ?? '');
    _sport = b?.sport ?? 'entrambi';
    _stato = b?.stato ?? 'bozza';
  }

  @override
  void dispose() {
    _codiceController.dispose();
    _titoloController.dispose();
    _faseController.dispose();
    _obiettivoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final repository = ref.read(trainingBlocksRepositoryProvider);
    final note = _noteController.text.trim();
    try {
      if (_isEditing) {
        await repository.updateBlocco(widget.blocco!.id, {
          'codice': _codiceController.text.trim(),
          'titolo': _titoloController.text.trim(),
          'sport': _sport,
          'fase': _faseController.text.trim(),
          'obiettivo': _obiettivoController.text.trim(),
          'stato': _stato,
          'note': note.isEmpty ? null : note,
        });
      } else {
        await repository.createBlocco(
          clubId: widget.clubId,
          codice: _codiceController.text.trim(),
          sport: _sport,
          fase: _faseController.text.trim(),
          obiettivo: _obiettivoController.text.trim(),
          titolo: _titoloController.text.trim(),
          stato: _stato,
          note: note.isEmpty ? null : note,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica blocco' : 'Nuovo blocco'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              ErrorBanner(messaggio: _errorMessage!),
              const SizedBox(height: AppSpacing.s16),
            ],
            FormGroup(
              titolo: 'Blocco',
              campi: [
                AppTextField(
                  etichetta: 'Codice (es. N-001)',
                  controller: _codiceController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                AppTextField(
                  etichetta: 'Titolo',
                  controller: _titoloController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                AppSelect<String>(
                  etichetta: 'Sport',
                  value: _sport,
                  items: const [
                    DropdownMenuItem(value: 'nuoto', child: Text('Nuoto')),
                    DropdownMenuItem(
                      value: 'pallanuoto',
                      child: Text('Pallanuoto'),
                    ),
                    DropdownMenuItem(
                      value: 'entrambi',
                      child: Text('Entrambi'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _sport = value ?? 'entrambi'),
                ),
                AppTextField(
                  etichetta: 'Fase (es. Riscaldamento)',
                  controller: _faseController,
                ),
                AppTextField(
                  etichetta: 'Obiettivo (es. Aerobico)',
                  controller: _obiettivoController,
                ),
                AppSelect<String>(
                  etichetta: 'Stato',
                  value: _stato,
                  items: const [
                    DropdownMenuItem(value: 'bozza', child: Text('Bozza')),
                    DropdownMenuItem(
                      value: 'approvato',
                      child: Text('Approvato'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _stato = value ?? 'bozza'),
                ),
                AppTextField(
                  etichetta: 'Note (facoltativo)',
                  controller: _noteController,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: _isEditing ? 'Salva modifiche' : 'Crea blocco',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
