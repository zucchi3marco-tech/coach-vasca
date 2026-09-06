import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../data/macrocicli_repository.dart';
import '../domain/macrociclo.dart';

class MacrocicloFormScreen extends ConsumerStatefulWidget {
  const MacrocicloFormScreen({
    required this.stagioneId,
    required this.ordineSuccessivo,
    this.macrociclo,
    super.key,
  });

  final String stagioneId;
  final int ordineSuccessivo;
  final Macrociclo? macrociclo;

  @override
  ConsumerState<MacrocicloFormScreen> createState() =>
      _MacrocicloFormScreenState();
}

class _MacrocicloFormScreenState extends ConsumerState<MacrocicloFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _ordineController;
  late final TextEditingController _obiettivoController;
  late final TextEditingController _dataInizioController;
  late final TextEditingController _dataFineController;
  late DateTime _dataInizio;
  late DateTime _dataFine;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.macrociclo != null;

  @override
  void initState() {
    super.initState();
    final m = widget.macrociclo;
    _nomeController = TextEditingController(text: m?.nome ?? '');
    _ordineController = TextEditingController(
      text: (m?.ordine ?? widget.ordineSuccessivo).toString(),
    );
    _obiettivoController = TextEditingController(text: m?.obiettivo ?? '');
    final oggi = DateTime.now();
    _dataInizio = m?.dataInizio ?? oggi;
    _dataFine = m?.dataFine ?? oggi.add(const Duration(days: 27));
    _dataInizioController = TextEditingController(
      text: _formattaData(_dataInizio),
    );
    _dataFineController = TextEditingController(
      text: _formattaData(_dataFine),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _ordineController.dispose();
    _obiettivoController.dispose();
    _dataInizioController.dispose();
    _dataFineController.dispose();
    super.dispose();
  }

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  Future<void> _pickDataInizio() async {
    final selezionata = await showDatePicker(
      context: context,
      initialDate: _dataInizio,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (selezionata != null) {
      setState(() {
        _dataInizio = selezionata;
        _dataInizioController.text = _formattaData(selezionata);
      });
    }
  }

  Future<void> _pickDataFine() async {
    final selezionata = await showDatePicker(
      context: context,
      initialDate: _dataFine.isBefore(_dataInizio) ? _dataInizio : _dataFine,
      firstDate: _dataInizio,
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (selezionata != null) {
      setState(() {
        _dataFine = selezionata;
        _dataFineController.text = _formattaData(selezionata);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataFine.isBefore(_dataInizio)) {
      setState(
        () => _errorMessage =
            'La data di fine non può essere prima della data di inizio.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(macrocicliRepositoryProvider);
    final ordine = int.parse(_ordineController.text.trim());
    try {
      if (_isEditing) {
        await repository.updateMacrociclo(
          id: widget.macrociclo!.id,
          nome: _nomeController.text.trim(),
          ordine: ordine,
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          obiettivo: _obiettivoController.text.trim(),
        );
      } else {
        await repository.createMacrociclo(
          stagioneId: widget.stagioneId,
          nome: _nomeController.text.trim(),
          ordine: ordine,
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          obiettivo: _obiettivoController.text.trim(),
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
        title: const Text('Eliminare il macrociclo?'),
        content: const Text(
          'Verranno eliminati anche mesocicli e microcicli collegati.',
        ),
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
          .read(macrocicliRepositoryProvider)
          .deleteMacrociclo(widget.macrociclo!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica macrociclo' : 'Nuovo macrociclo'),
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
            AppTextField(
              etichetta: 'Nome',
              controller: _nomeController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Ordine',
              controller: _ordineController,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v?.trim() ?? '') == null ? 'N.' : null,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Data inizio',
              controller: _dataInizioController,
              readOnly: true,
              onTap: _pickDataInizio,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Data fine',
              controller: _dataFineController,
              readOnly: true,
              onTap: _pickDataFine,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Obiettivo (facoltativo)',
              controller: _obiettivoController,
              maxLines: 2,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errorMessage!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Salva macrociclo',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
