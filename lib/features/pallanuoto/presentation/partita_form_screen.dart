import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../club/application/current_club_provider.dart';
import '../data/partite_repository.dart';
import '../domain/partita.dart';

class PartitaFormScreen extends ConsumerStatefulWidget {
  const PartitaFormScreen({required this.clubId, this.partita, super.key});

  final String clubId;
  final Partita? partita;

  @override
  ConsumerState<PartitaFormScreen> createState() => _PartitaFormScreenState();
}

class _PartitaFormScreenState extends ConsumerState<PartitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _oraController;
  late final TextEditingController _luogoController;
  late final TextEditingController _campionatoController;
  late final TextEditingController _coloreCalottinaController;
  late final TextEditingController _squadraCasaController;
  late final TextEditingController _squadraTrasfertaController;
  late final TextEditingController _noteController;
  late DateTime _data;
  late int _numeroMaxConvocati;

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _clubPrefillFatto = false;

  bool get _isEditing => widget.partita != null;

  @override
  void initState() {
    super.initState();
    final p = widget.partita;
    _oraController = TextEditingController(text: p?.ora ?? '');
    _luogoController = TextEditingController(text: p?.luogo ?? '');
    _campionatoController = TextEditingController(text: p?.campionato ?? '');
    _coloreCalottinaController = TextEditingController(
      text: p?.coloreCalottina ?? '',
    );
    _squadraCasaController = TextEditingController(text: p?.squadraCasa ?? '');
    _squadraTrasfertaController = TextEditingController(
      text: p?.squadraTrasferta ?? '',
    );
    _noteController = TextEditingController(text: p?.note ?? '');
    _data = p?.data ?? DateTime.now();
    _numeroMaxConvocati = p?.numeroMaxConvocati ?? 15;
    if (!_isEditing) {
      ref.read(currentClubProvider.future).then((club) {
        if (mounted) _prefillClubSeVuoto(club?.nome);
      });
    }
  }

  @override
  void dispose() {
    _oraController.dispose();
    _luogoController.dispose();
    _campionatoController.dispose();
    _coloreCalottinaController.dispose();
    _squadraCasaController.dispose();
    _squadraTrasfertaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// In creazione, precompila "Squadra Casa" col nome del club: puo' essere
  /// cambiato a mano se la partita e' in trasferta.
  void _prefillClubSeVuoto(String? nomeClub) {
    if (_clubPrefillFatto || _isEditing || nomeClub == null) return;
    _squadraCasaController.text = nomeClub;
    _clubPrefillFatto = true;
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

  Future<void> _pickOra() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selected != null) {
      setState(
        () => _oraController.text =
            '${selected.hour.toString().padLeft(2, '0')}:'
            '${selected.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(partiteRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.updatePartita(
          id: widget.partita!.id,
          data: _data,
          ora: _oraController.text.trim(),
          luogo: _luogoController.text.trim(),
          campionato: _campionatoController.text.trim(),
          coloreCalottina: _coloreCalottinaController.text.trim(),
          squadraCasa: _squadraCasaController.text.trim(),
          squadraTrasferta: _squadraTrasfertaController.text.trim(),
          numeroMaxConvocati: _numeroMaxConvocati,
          note: _noteController.text.trim(),
        );
      } else {
        await repository.createPartita(
          clubId: widget.clubId,
          data: _data,
          ora: _oraController.text.trim(),
          luogo: _luogoController.text.trim(),
          campionato: _campionatoController.text.trim(),
          coloreCalottina: _coloreCalottinaController.text.trim(),
          squadraCasa: _squadraCasaController.text.trim(),
          squadraTrasferta: _squadraTrasfertaController.text.trim(),
          numeroMaxConvocati: _numeroMaxConvocati,
          note: _noteController.text.trim(),
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
        title: const Text('Eliminare la partita?'),
        content: const Text('Verrà eliminata anche la relativa distinta.'),
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
          .read(partiteRepositoryProvider)
          .deletePartita(widget.partita!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica partita' : 'Nuova partita'),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ora (opzionale)'),
                  subtitle: Text(
                    _oraController.text.isEmpty
                        ? 'Nessuna'
                        : _oraController.text,
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickOra,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _squadraCasaController,
                  decoration: const InputDecoration(labelText: 'Squadra casa'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _squadraTrasfertaController,
                  decoration: const InputDecoration(
                    labelText: 'Squadra trasferta',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _luogoController,
                  decoration: const InputDecoration(
                    labelText: 'Luogo (opzionale)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _campionatoController,
                  decoration: const InputDecoration(
                    labelText: 'Campionato (opzionale)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _coloreCalottinaController,
                  decoration: const InputDecoration(
                    labelText: 'Colore calottina (opzionale)',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Numero massimo convocati',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 13, label: Text('13')),
                    ButtonSegment(value: 15, label: Text('15')),
                  ],
                  selected: {_numeroMaxConvocati},
                  onSelectionChanged: (selezione) =>
                      setState(() => _numeroMaxConvocati = selezione.first),
                ),
                const SizedBox(height: 16),
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
