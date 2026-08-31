import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _obiettivoController.dispose();
    _gruppoController.dispose();
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
    if (selezionata != null) setState(() => _dataInizio = selezionata);
  }

  Future<void> _pickDataFine() async {
    final selezionata = await showDatePicker(
      context: context,
      initialDate: _dataFine.isBefore(_dataInizio) ? _dataInizio : _dataFine,
      firstDate: _dataInizio,
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (selezionata != null) setState(() => _dataFine = selezionata);
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
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Salvataggio non riuscito. Riprova.');
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
          'Verranno eliminati anche macrocicli, mesocicli e microcicli collegati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica stagione' : 'Nuova stagione'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Elimina',
              onPressed: _elimina,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data inizio'),
                  subtitle: Text(_formattaData(_dataInizio)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDataInizio,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data fine'),
                  subtitle: Text(_formattaData(_dataFine)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDataFine,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _obiettivoController,
                  decoration: const InputDecoration(
                    labelText: 'Obiettivo (opzionale)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gruppoController,
                  decoration: const InputDecoration(
                    labelText: 'Gruppo (opzionale)',
                  ),
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
