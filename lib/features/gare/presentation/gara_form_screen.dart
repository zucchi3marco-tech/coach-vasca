import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../stagioni/domain/stagione.dart';
import '../data/gare_repository.dart';
import '../domain/gara.dart';

/// Crea o modifica una gara. Dal calendario di una stagione arrivano
/// [stagione] e [dataIniziale]: il gruppo è quello della stagione (nullo =
/// gara di tutto il club).
class GaraFormScreen extends ConsumerStatefulWidget {
  const GaraFormScreen({
    required this.clubId,
    this.gara,
    this.stagione,
    this.dataIniziale,
    super.key,
  });

  final String clubId;
  final Gara? gara;
  final Stagione? stagione;
  final DateTime? dataIniziale;

  /// Valore con cui il form si chiude dopo l'eliminazione della gara.
  static const esitoEliminata = 'eliminata';

  @override
  ConsumerState<GaraFormScreen> createState() => _GaraFormScreenState();
}

class _GaraFormScreenState extends ConsumerState<GaraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _luogoController;
  late final TextEditingController _oraController;
  late final TextEditingController _dataController;
  late final TextEditingController _noteController;
  late DateTime _data;
  String? _gruppoId;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.gara != null;

  @override
  void initState() {
    super.initState();
    final g = widget.gara;
    _nomeController = TextEditingController(text: g?.nome ?? '');
    _luogoController = TextEditingController(text: g?.luogo ?? '');
    _oraController = TextEditingController(text: g?.ora ?? '');
    _noteController = TextEditingController(text: g?.note ?? '');
    _data = g?.data ?? widget.dataIniziale ?? DateTime.now();
    _dataController = TextEditingController(text: _formattaData(_data));
    _gruppoId = g != null ? g.gruppoId : widget.stagione?.gruppoId;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _luogoController.dispose();
    _oraController.dispose();
    _dataController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  Future<void> _pickData() async {
    final selezionata = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (selezionata != null) {
      setState(() {
        _data = selezionata;
        _dataController.text = _formattaData(selezionata);
      });
    }
  }

  Future<void> _pickOra() async {
    final selezionata = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selezionata != null) {
      setState(
        () => _oraController.text =
            '${selezionata.hour.toString().padLeft(2, '0')}:'
            '${selezionata.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final repository = ref.read(gareRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.updateGara(
          id: widget.gara!.id,
          gruppoId: _gruppoId,
          data: _data,
          ora: _oraController.text.trim(),
          luogo: _luogoController.text.trim(),
          nome: _nomeController.text.trim(),
          note: _noteController.text.trim(),
        );
      } else {
        await repository.createGara(
          clubId: widget.clubId,
          gruppoId: _gruppoId,
          data: _data,
          ora: _oraController.text.trim(),
          luogo: _luogoController.text.trim(),
          nome: _nomeController.text.trim(),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare la gara?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (conferma == true) {
      await ref.read(gareRepositoryProvider).deleteGara(widget.gara!.id);
      if (mounted) Navigator.of(context).pop(GaraFormScreen.esitoEliminata);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica gara' : 'Nuova gara'),
        actions: [
          if (_isEditing)
            TextButton.icon(
              onPressed: _elimina,
              icon: Icon(Icons.delete_outline, color: colori.rosso),
              label: Text('Elimina', style: TextStyle(color: colori.rosso)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              etichetta: 'Nome della manifestazione',
              controller: _nomeController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Data',
              controller: _dataController,
              readOnly: true,
              onTap: _pickData,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Ora (facoltativo)',
              controller: _oraController,
              readOnly: true,
              onTap: _pickOra,
              suffixIcon: const Icon(Icons.access_time),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Luogo (facoltativo)',
              controller: _luogoController,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppSelect<String?>(
              etichetta: 'Gruppo',
              value: _gruppoId,
              hint: 'Tutto il club',
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tutto il club'),
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
              label: 'Salva gara',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
