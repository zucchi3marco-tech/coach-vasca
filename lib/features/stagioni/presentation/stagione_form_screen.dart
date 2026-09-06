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
import '../data/stagioni_repository.dart';
import '../domain/stagione.dart';

class StagioneFormScreen extends ConsumerStatefulWidget {
  const StagioneFormScreen({required this.clubId, this.stagione, super.key});

  final String clubId;
  final Stagione? stagione;

  @override
  ConsumerState<StagioneFormScreen> createState() =>
      _StagioneFormScreenState();
}

class _StagioneFormScreenState extends ConsumerState<StagioneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _obiettivoController;
  late final TextEditingController _gruppoController;
  late final TextEditingController _dataInizioController;
  late final TextEditingController _dataFineController;
  late DateTime _dataInizio;
  late DateTime _dataFine;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.stagione != null;

  @override
  void initState() {
    super.initState();
    final s = widget.stagione;
    _nomeController = TextEditingController(text: s?.nome ?? '');
    _obiettivoController = TextEditingController(text: s?.obiettivo ?? '');
    _gruppoController = TextEditingController(text: s?.gruppo ?? '');
    final oggi = DateTime.now();
    _dataInizio = s?.dataInizio ?? DateTime(oggi.year, 9);
    _dataFine = s?.dataFine ?? DateTime(oggi.year + 1, 6, 30);
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
    _obiettivoController.dispose();
    _gruppoController.dispose();
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

    final repository = ref.read(stagioniRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.updateStagione(
          id: widget.stagione!.id,
          nome: _nomeController.text.trim(),
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          obiettivo: _obiettivoController.text.trim(),
          gruppo: _gruppoController.text.trim(),
        );
      } else {
        await repository.createStagione(
          clubId: widget.clubId,
          nome: _nomeController.text.trim(),
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          obiettivo: _obiettivoController.text.trim(),
          gruppo: _gruppoController.text.trim(),
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
        title: const Text('Eliminare la stagione?'),
        content: const Text(
          'Verranno eliminati anche macrocicli, mesocicli e microcicli '
          'collegati.',
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
          .read(stagioniRepositoryProvider)
          .deleteStagione(widget.stagione!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica stagione' : 'Nuova stagione'),
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
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Gruppo (facoltativo)',
              controller: _gruppoController,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errorMessage!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Salva stagione',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
