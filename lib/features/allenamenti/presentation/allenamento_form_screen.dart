import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/allenamenti_repository.dart';
import '../domain/allenamento.dart';

class AllenamentoFormScreen extends ConsumerStatefulWidget {
  const AllenamentoFormScreen({required this.clubId, this.allenamento, super.key});

  final String clubId;
  final Allenamento? allenamento;

  @override
  ConsumerState<AllenamentoFormScreen> createState() =>
      _AllenamentoFormScreenState();
}

class _AllenamentoFormScreenState extends ConsumerState<AllenamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titoloController;
  late final TextEditingController _gruppoController;
  late final TextEditingController _noteController;
  late DateTime _data;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.allenamento != null;

  @override
  void initState() {
    super.initState();
    final a = widget.allenamento;
    _titoloController = TextEditingController(text: a?.titolo ?? '');
    _gruppoController = TextEditingController(text: a?.gruppo ?? '');
    _noteController = TextEditingController(text: a?.note ?? '');
    _data = a?.data ?? DateTime.now();
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _gruppoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickData() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (selected != null) setState(() => _data = selected);
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
          gruppo: _gruppoController.text.trim(),
          note: _noteController.text.trim(),
        );
      } else {
        await repository.createAllenamento(
          clubId: widget.clubId,
          data: _data,
          titolo: _titoloController.text.trim(),
          gruppo: _gruppoController.text.trim(),
          note: _noteController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      setState(() => _errorMessage = 'Salvataggio non riuscito. Riprova.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica allenamento' : 'Nuovo allenamento'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data'),
                  subtitle: Text(
                    '${_data.day.toString().padLeft(2, '0')}/'
                    '${_data.month.toString().padLeft(2, '0')}/'
                    '${_data.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickData,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titoloController,
                  decoration: const InputDecoration(
                    labelText: 'Titolo (opzionale)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gruppoController,
                  decoration: const InputDecoration(
                    labelText: 'Gruppo (opzionale)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (opzionale)',
                  ),
                  maxLines: 3,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salva'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
