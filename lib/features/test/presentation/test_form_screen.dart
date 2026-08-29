import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pace_format.dart';
import '../../atleti/domain/atleta.dart';
import '../data/test_repository.dart';

class TestFormScreen extends ConsumerStatefulWidget {
  const TestFormScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  ConsumerState<TestFormScreen> createState() => _TestFormScreenState();
}

class _TestFormScreenState extends ConsumerState<TestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _distanzaController = TextEditingController();
  final _minutiController = TextEditingController(text: '0');
  final _secondiController = TextEditingController();
  final _noteController = TextEditingController();

  String _tipo = 'BVS';
  DateTime _dataTest = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _distanzaController.dispose();
    _minutiController.dispose();
    _secondiController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickData() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dataTest,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() => _dataTest = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final minuti = int.tryParse(_minutiController.text.trim()) ?? 0;
    final secondi = double.tryParse(_secondiController.text.trim()) ?? 0;
    final tempoTotaleS = minuti * 60 + secondi;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final test = await ref
          .read(testRepositoryProvider)
          .createTest(
            atletaId: widget.atleta.id,
            tipo: _tipo,
            dataTest: _dataTest,
            distanzaTotaleM: int.parse(_distanzaController.text.trim()),
            tempoTotaleS: tempoTotaleS,
            note: _noteController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test salvato — passo medio: ${formatPaceSeconds(test.passoMedio100S)}/100m',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Salvataggio non riuscito. Riprova.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuovo test — ${widget.atleta.nomeCompleto}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'BVS', label: Text('BVS')),
                    ButtonSegment(value: 'T30', label: Text('T30')),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (selection) =>
                      setState(() => _tipo = selection.first),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data del test'),
                  subtitle: Text(
                    '${_dataTest.day.toString().padLeft(2, '0')}/'
                    '${_dataTest.month.toString().padLeft(2, '0')}/'
                    '${_dataTest.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickData,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _distanzaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Distanza totale (m)',
                  ),
                  validator: (value) {
                    final n = int.tryParse(value?.trim() ?? '');
                    if (n == null || n <= 0) return 'Inserisci una distanza valida';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minutiController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minuti',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _secondiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Secondi',
                        ),
                        validator: (value) {
                          final minuti =
                              int.tryParse(_minutiController.text.trim()) ??
                              0;
                          final secondi = double.tryParse(
                            value?.trim() ?? '',
                          );
                          if (minuti == 0 &&
                              (secondi == null || secondi <= 0)) {
                            return 'Inserisci il tempo totale';
                          }
                          if (secondi != null &&
                              (secondi < 0 || secondi >= 60)) {
                            return '0-59.99';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (opzionale)',
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
                      : const Text('Salva test'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
