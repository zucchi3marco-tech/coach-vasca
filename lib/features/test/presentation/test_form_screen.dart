import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/titolo_due_righe.dart';
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
  late final TextEditingController _dataController;

  DateTime _dataTest = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dataController = TextEditingController(text: _formattaData(_dataTest));
  }

  @override
  void dispose() {
    _distanzaController.dispose();
    _minutiController.dispose();
    _secondiController.dispose();
    _noteController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  Future<void> _pickData() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dataTest,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        _dataTest = selected;
        _dataController.text = _formattaData(selected);
      });
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
            tipo: 'BVS',
            dataTest: _dataTest,
            distanzaTotaleM: int.parse(_distanzaController.text.trim()),
            tempoTotaleS: tempoTotaleS,
            note: _noteController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test salvato — passo medio: '
            '${formatPaceSeconds(test.passoMedio100S)}/100m',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = messaggioErrore(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: TitoloDueRighe(
          titolo: 'Nuovo test BVS',
          sottotitolo: widget.atleta.nomeCompleto,
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Quando',
              campi: [
                AppTextField(
                  etichetta: 'Data del test',
                  controller: _dataController,
                  readOnly: true,
                  onTap: _pickData,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Risultato',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Distanza totale (m)',
                  controller: _distanzaController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final n = int.tryParse(value?.trim() ?? '');
                    if (n == null || n <= 0) {
                      return 'Inserisci una distanza valida';
                    }
                    return null;
                  },
                ),
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
                        validator: (value) {
                          final minuti =
                              int.tryParse(_minutiController.text.trim()) ?? 0;
                          final secondi = double.tryParse(value?.trim() ?? '');
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
              label: 'Salva test',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
