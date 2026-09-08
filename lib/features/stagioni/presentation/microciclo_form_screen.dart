import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../data/microcicli_repository.dart';
import '../domain/microciclo.dart';

/// Tipi di microciclo proposti nel menu a tendina (FASE 10): il campo era
/// testo libero con solo un suggerimento in etichetta, ora è una scelta
/// vincolata a un lessico comune di periodizzazione.
const _tipiMicrociclo = ['carico', 'scarico', 'gara', 'recupero', 'test'];

String _labelTipo(String tipo) => tipo[0].toUpperCase() + tipo.substring(1);

class MicrocicloFormScreen extends ConsumerStatefulWidget {
  const MicrocicloFormScreen({
    required this.mesocicloId,
    required this.ordineSuccessivo,
    this.microciclo,
    super.key,
  });

  final String mesocicloId;
  final int ordineSuccessivo;
  final Microciclo? microciclo;

  @override
  ConsumerState<MicrocicloFormScreen> createState() =>
      _MicrocicloFormScreenState();
}

class _MicrocicloFormScreenState extends ConsumerState<MicrocicloFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _numeroSettimanaController;
  late final TextEditingController _ordineController;
  late String? _tipo;
  late final TextEditingController _dataInizioController;
  late final TextEditingController _dataFineController;
  late DateTime _dataInizio;
  late DateTime _dataFine;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.microciclo != null;

  @override
  void initState() {
    super.initState();
    final m = widget.microciclo;
    _nomeController = TextEditingController(text: m?.nome ?? '');
    _numeroSettimanaController = TextEditingController(
      text: m?.numeroSettimana?.toString() ?? '',
    );
    _ordineController = TextEditingController(
      text: (m?.ordine ?? widget.ordineSuccessivo).toString(),
    );
    _tipo = m?.tipo;
    final oggi = DateTime.now();
    _dataInizio = m?.dataInizio ?? oggi;
    _dataFine = m?.dataFine ?? oggi.add(const Duration(days: 6));
    _dataInizioController = TextEditingController(
      text: _formattaData(_dataInizio),
    );
    _dataFineController = TextEditingController(text: _formattaData(_dataFine));
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _numeroSettimanaController.dispose();
    _ordineController.dispose();
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

    final repository = ref.read(microcicliRepositoryProvider);
    final ordine = int.parse(_ordineController.text.trim());
    final numeroSettimana = int.tryParse(
      _numeroSettimanaController.text.trim(),
    );
    try {
      if (_isEditing) {
        await repository.updateMicrociclo(
          id: widget.microciclo!.id,
          nome: _nomeController.text.trim(),
          numeroSettimana: numeroSettimana,
          ordine: ordine,
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          tipo: _tipo,
        );
      } else {
        await repository.createMicrociclo(
          mesocicloId: widget.mesocicloId,
          nome: _nomeController.text.trim(),
          numeroSettimana: numeroSettimana,
          ordine: ordine,
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          tipo: _tipo,
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
        title: const Text('Eliminare il microciclo?'),
        content: const Text(
          'Gli eventuali allenamenti collegati non verranno eliminati, '
          'resteranno solo senza microciclo.',
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
          .read(microcicliRepositoryProvider)
          .deleteMicrociclo(widget.microciclo!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica microciclo' : 'Nuovo microciclo'),
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
            FormGroup(
              titolo: 'Identificazione',
              campi: [
                AppTextField(
                  etichetta: 'Nome (facoltativo)',
                  controller: _nomeController,
                ),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        etichetta: 'N. settimana (facoltativo)',
                        controller: _numeroSettimanaController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: AppTextField(
                        etichetta: 'Ordine',
                        controller: _ordineController,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            int.tryParse(v?.trim() ?? '') == null ? 'N.' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Periodo e tipo',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Data inizio',
                  controller: _dataInizioController,
                  readOnly: true,
                  onTap: _pickDataInizio,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                AppTextField(
                  etichetta: 'Data fine',
                  controller: _dataFineController,
                  readOnly: true,
                  onTap: _pickDataFine,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                AppSelect<String?>(
                  etichetta: 'Tipo (facoltativo)',
                  value: _tipo,
                  hint: 'Non specificato',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Non specificato'),
                    ),
                    for (final t in _tipiMicrociclo)
                      DropdownMenuItem(value: t, child: Text(_labelTipo(t))),
                    // Un valore gia' salvato prima che il campo diventasse
                    // un menu chiuso deve restare rappresentabile.
                    if (_tipo != null && !_tipiMicrociclo.contains(_tipo))
                      DropdownMenuItem(value: _tipo, child: Text(_tipo!)),
                  ],
                  onChanged: (value) => setState(() => _tipo = value),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              ErrorBanner(messaggio: _errorMessage!),
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: 'Salva microciclo',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
