import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../data/allenamenti_repository.dart';
import '../domain/allenamento.dart';

class AllenamentoFormScreen extends ConsumerStatefulWidget {
  const AllenamentoFormScreen({
    required this.clubId,
    this.allenamento,
    this.dataPredefinita,
    super.key,
  });

  final String clubId;
  final Allenamento? allenamento;

  /// Data iniziale suggerita in creazione, invece di "oggi".
  final DateTime? dataPredefinita;

  @override
  ConsumerState<AllenamentoFormScreen> createState() =>
      _AllenamentoFormScreenState();
}

class _AllenamentoFormScreenState extends ConsumerState<AllenamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titoloController;
  String? _gruppoId;
  late final TextEditingController _noteController;
  late final TextEditingController _dataController;
  late DateTime _data;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.allenamento != null;

  @override
  void initState() {
    super.initState();
    final a = widget.allenamento;
    _titoloController = TextEditingController(text: a?.titolo ?? '');
    _gruppoId = a?.gruppoId;
    _noteController = TextEditingController(text: a?.note ?? '');
    _data = a?.data ?? widget.dataPredefinita ?? DateTime.now();
    _dataController = TextEditingController(text: _formattaData(_data));
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _noteController.dispose();
    _dataController.dispose();
    super.dispose();
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(allenamentiRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.updateAllenamento(
          id: widget.allenamento!.id,
          data: _data,
          titolo: _titoloController.text.trim(),
          gruppoId: _gruppoId,
          note: _noteController.text.trim(),
        );
      } else {
        await repository.createAllenamento(
          clubId: widget.clubId,
          data: _data,
          titolo: _titoloController.text.trim(),
          gruppoId: _gruppoId,
          note: _noteController.text.trim(),
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

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context) {
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica allenamento' : 'Nuovo allenamento'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              etichetta: 'Data',
              controller: _dataController,
              readOnly: true,
              onTap: _pickData,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Titolo (facoltativo)',
              controller: _titoloController,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppSelect<String?>(
              etichetta: 'Gruppo (facoltativo)',
              value: _gruppoId,
              hint: 'Nessun gruppo',
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Nessun gruppo'),
                ),
                for (final g in gruppi)
                  DropdownMenuItem(value: g.id, child: Text(g.nome)),
                if (_gruppoId != null && !gruppi.any((g) => g.id == _gruppoId))
                  DropdownMenuItem(
                    value: _gruppoId,
                    child: const Text('Gruppo non trovato'),
                  ),
              ],
              onChanged: (value) => setState(() => _gruppoId = value),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Note (facoltativo)',
              controller: _noteController,
              maxLines: 3,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errorMessage!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Salva allenamento',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
