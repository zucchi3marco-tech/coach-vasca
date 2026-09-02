import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../data/serie_repository.dart';
import '../domain/serie.dart';

class SerieFormScreen extends ConsumerStatefulWidget {
  const SerieFormScreen({
    required this.allenamentoId,
    required this.ordineSuccessivo,
    this.serie,
    super.key,
  });

  final String allenamentoId;
  final int ordineSuccessivo;
  final Serie? serie;

  @override
  ConsumerState<SerieFormScreen> createState() => _SerieFormScreenState();
}

class _SerieFormScreenState extends ConsumerState<SerieFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ordineController;
  late final TextEditingController _ripeteController;
  late final TextEditingController _distanzaController;
  late final TextEditingController _passoMinutiController;
  late final TextEditingController _passoSecondiController;
  late final TextEditingController _recuperoController;
  late final TextEditingController _ripartenzaMinutiController;
  late final TextEditingController _ripartenzaSecondiController;
  late final TextEditingController _attrezzaturaController;
  late final TextEditingController _noteController;

  late String _blocco;
  late String _stile;
  late String _esecuzione;
  String? _zona;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.serie != null;

  @override
  void initState() {
    super.initState();
    final s = widget.serie;
    _ordineController = TextEditingController(
      text: (s?.ordine ?? widget.ordineSuccessivo).toString(),
    );
    _ripeteController = TextEditingController(
      text: (s?.ripetute ?? 1).toString(),
    );
    _distanzaController = TextEditingController(
      text: s?.distanzaM.toString() ?? '',
    );
    final passo = s?.passoObiettivoS;
    _passoMinutiController = TextEditingController(
      text: passo == null ? '' : (passo ~/ 60).toString(),
    );
    _passoSecondiController = TextEditingController(
      text: passo == null
          ? ''
          : (passo - (passo ~/ 60) * 60).toStringAsFixed(2),
    );
    _recuperoController = TextEditingController(
      text: s?.recuperoS?.toString() ?? '',
    );
    final ripartenza = s?.ripartenzaS;
    _ripartenzaMinutiController = TextEditingController(
      text: ripartenza == null ? '' : (ripartenza ~/ 60).toString(),
    );
    _ripartenzaSecondiController = TextEditingController(
      text: ripartenza == null
          ? ''
          : (ripartenza - (ripartenza ~/ 60) * 60).toStringAsFixed(2),
    );
    _attrezzaturaController = TextEditingController(
      text: s?.attrezzatura ?? '',
    );
    _noteController = TextEditingController(text: s?.note ?? '');
    _blocco = s?.blocco ?? 'principale';
    _stile = s?.stile ?? 'libero';
    _esecuzione = s?.esecuzione ?? 'nuoto';
    _zona = s?.zona;
  }

  @override
  void dispose() {
    _ordineController.dispose();
    _ripeteController.dispose();
    _distanzaController.dispose();
    _passoMinutiController.dispose();
    _passoSecondiController.dispose();
    _recuperoController.dispose();
    _ripartenzaMinutiController.dispose();
    _ripartenzaSecondiController.dispose();
    _attrezzaturaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _parseTempo(
    TextEditingController minutiController,
    TextEditingController secondiController,
  ) {
    final minuti = int.tryParse(minutiController.text.trim());
    final secondi = double.tryParse(secondiController.text.trim());
    if (minuti == null && secondi == null) return null;
    return (minuti ?? 0) * 60 + (secondi ?? 0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(serieRepositoryProvider);
    final ordine = int.parse(_ordineController.text.trim());
    final ripetute = int.parse(_ripeteController.text.trim());
    final distanzaM = int.parse(_distanzaController.text.trim());
    final passoObiettivoS = _parseTempo(
      _passoMinutiController,
      _passoSecondiController,
    );
    final recuperoS = int.tryParse(_recuperoController.text.trim());
    final ripartenzaS = _parseTempo(
      _ripartenzaMinutiController,
      _ripartenzaSecondiController,
    );
    final attrezzatura = _attrezzaturaController.text.trim();
    final note = _noteController.text.trim();

    try {
      if (_isEditing) {
        await repository.updateSerie(
          id: widget.serie!.id,
          ordine: ordine,
          blocco: _blocco,
          ripetute: ripetute,
          distanzaM: distanzaM,
          stile: _stile,
          esecuzione: _esecuzione,
          zona: _zona,
          passoObiettivoS: passoObiettivoS,
          recuperoS: recuperoS,
          ripartenzaS: ripartenzaS,
          attrezzatura: attrezzatura.isEmpty ? null : attrezzatura,
          note: note.isEmpty ? null : note,
        );
      } else {
        await repository.createSerie(
          allenamentoId: widget.allenamentoId,
          ordine: ordine,
          blocco: _blocco,
          ripetute: ripetute,
          distanzaM: distanzaM,
          stile: _stile,
          esecuzione: _esecuzione,
          zona: _zona,
          passoObiettivoS: passoObiettivoS,
          recuperoS: recuperoS,
          ripartenzaS: ripartenzaS,
          attrezzatura: attrezzatura.isEmpty ? null : attrezzatura,
          note: note.isEmpty ? null : note,
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
        title: const Text('Eliminare la serie?'),
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
      await ref.read(serieRepositoryProvider).deleteSerie(widget.serie!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica serie' : 'Nuova serie'),
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
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _blocco,
                  decoration: const InputDecoration(labelText: 'Blocco'),
                  items: const [
                    DropdownMenuItem(
                      value: 'riscaldamento',
                      child: Text('Riscaldamento'),
                    ),
                    DropdownMenuItem(
                      value: 'principale',
                      child: Text('Principale'),
                    ),
                    DropdownMenuItem(
                      value: 'defaticamento',
                      child: Text('Defaticamento'),
                    ),
                    DropdownMenuItem(value: 'altro', child: Text('Altro')),
                  ],
                  onChanged: (value) =>
                      setState(() => _blocco = value ?? 'principale'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ordineController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ordine',
                        ),
                        validator: (v) =>
                            int.tryParse(v?.trim() ?? '') == null
                            ? 'N.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ripeteController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ripetute',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          return (n == null || n <= 0) ? '> 0' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _distanzaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Distanza (m)',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          return (n == null || n <= 0) ? '> 0' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _stile,
                  decoration: const InputDecoration(labelText: 'Stile'),
                  items: const [
                    DropdownMenuItem(value: 'libero', child: Text('Libero')),
                    DropdownMenuItem(value: 'dorso', child: Text('Dorso')),
                    DropdownMenuItem(value: 'rana', child: Text('Rana')),
                    DropdownMenuItem(
                      value: 'delfino',
                      child: Text('Delfino'),
                    ),
                    DropdownMenuItem(value: 'misti', child: Text('Misti')),
                  ],
                  onChanged: (value) =>
                      setState(() => _stile = value ?? 'libero'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _esecuzione,
                  decoration: const InputDecoration(labelText: 'Esecuzione'),
                  items: const [
                    DropdownMenuItem(
                      value: 'nuoto',
                      child: Text('Nuoto completo'),
                    ),
                    DropdownMenuItem(value: 'gambe', child: Text('Gambe')),
                    DropdownMenuItem(
                      value: 'braccia',
                      child: Text('Braccia'),
                    ),
                    DropdownMenuItem(value: 'pull', child: Text('Pull')),
                    DropdownMenuItem(
                      value: 'tecnica',
                      child: Text('Tecnica'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _esecuzione = value ?? 'nuoto'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _zona,
                  decoration: const InputDecoration(
                    labelText: 'Zona (opzionale)',
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Nessuna')),
                    DropdownMenuItem(value: 'A1', child: Text('A1')),
                    DropdownMenuItem(value: 'A2', child: Text('A2')),
                    DropdownMenuItem(value: 'B1', child: Text('B1')),
                    DropdownMenuItem(value: 'B2', child: Text('B2')),
                    DropdownMenuItem(value: 'C', child: Text('C')),
                    DropdownMenuItem(value: 'D', child: Text('D')),
                  ],
                  onChanged: (value) => setState(() => _zona = value),
                ),
                const SizedBox(height: 16),
                Text(
                  'Passo obiettivo /100m (opzionale)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passoMinutiController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minuti',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _passoSecondiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Secondi',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recuperoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Recupero, secondi (opzionale)',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ripartenza / interval (opzionale)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ripartenzaMinutiController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minuti',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ripartenzaSecondiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Secondi',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _attrezzaturaController,
                  decoration: const InputDecoration(
                    labelText: 'Attrezzatura (opzionale)',
                  ),
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
