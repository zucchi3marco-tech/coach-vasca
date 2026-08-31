import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mesocicli_repository.dart';
import '../domain/mesociclo.dart';

class MesocicloFormScreen extends ConsumerStatefulWidget {
  const MesocicloFormScreen({
    required this.macrocicloId,
    required this.ordineSuccessivo,
    this.mesociclo,
    super.key,
  });

  final String macrocicloId;
  final int ordineSuccessivo;
  final Mesociclo? mesociclo;

  @override
  ConsumerState<MesocicloFormScreen> createState() =>
      _MesocicloFormScreenState();
}

class _MesocicloFormScreenState extends ConsumerState<MesocicloFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _ordineController;
  late final TextEditingController _obiettivoController;
  late DateTime _dataInizio;
  late DateTime _dataFine;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.mesociclo != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mesociclo;
    _nomeController = TextEditingController(text: m?.nome ?? '');
    _ordineController = TextEditingController(
      text: (m?.ordine ?? widget.ordineSuccessivo).toString(),
    );
    _obiettivoController = TextEditingController(text: m?.obiettivo ?? '');
    final oggi = DateTime.now();
    _dataInizio = m?.dataInizio ?? oggi;
    _dataFine = m?.dataFine ?? oggi.add(const Duration(days: 20));
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _ordineController.dispose();
    _obiettivoController.dispose();
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

    final repository = ref.read(mesocicliRepositoryProvider);
    final ordine = int.parse(_ordineController.text.trim());
    try {
      if (_isEditing) {
        await repository.updateMesociclo(
          id: widget.mesociclo!.id,
          nome: _nomeController.text.trim(),
          ordine: ordine,
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          obiettivo: _obiettivoController.text.trim(),
        );
      } else {
        await repository.createMesociclo(
          macrocicloId: widget.macrocicloId,
          nome: _nomeController.text.trim(),
          ordine: ordine,
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          obiettivo: _obiettivoController.text.trim(),
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
        title: const Text('Eliminare il mesociclo?'),
        content: const Text('Verranno eliminati anche i microcicli collegati.'),
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
          .read(mesocicliRepositoryProvider)
          .deleteMesociclo(widget.mesociclo!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica mesociclo' : 'Nuovo mesociclo'),
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
                TextFormField(
                  controller: _ordineController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ordine'),
                  validator: (v) =>
                      int.tryParse(v?.trim() ?? '') == null ? 'N.' : null,
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
