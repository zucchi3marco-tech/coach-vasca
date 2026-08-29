import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atleti_repository.dart';
import '../domain/atleta.dart';

class AtletaFormScreen extends ConsumerStatefulWidget {
  const AtletaFormScreen({required this.clubId, this.atleta, super.key});

  final String clubId;
  final Atleta? atleta;

  @override
  ConsumerState<AtletaFormScreen> createState() => _AtletaFormScreenState();
}

class _AtletaFormScreenState extends ConsumerState<AtletaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _cognomeController;
  late final TextEditingController _gruppoController;
  late final TextEditingController _emailGenitoreController;
  late final TextEditingController _telefonoGenitoreController;
  late final TextEditingController _noteController;

  DateTime? _dataNascita;
  String? _sesso;
  late String _sport;
  late bool _consensoPrivacy;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.atleta != null;

  @override
  void initState() {
    super.initState();
    final atleta = widget.atleta;
    _nomeController = TextEditingController(text: atleta?.nome ?? '');
    _cognomeController = TextEditingController(text: atleta?.cognome ?? '');
    _gruppoController = TextEditingController(text: atleta?.gruppo ?? '');
    _emailGenitoreController = TextEditingController(
      text: atleta?.emailGenitore ?? '',
    );
    _telefonoGenitoreController = TextEditingController(
      text: atleta?.telefonoGenitore ?? '',
    );
    _noteController = TextEditingController(text: atleta?.note ?? '');
    _dataNascita = atleta?.dataNascita;
    _sesso = atleta?.sesso;
    _sport = atleta?.sport ?? 'nuoto';
    _consensoPrivacy = atleta?.consensoPrivacyFirmato ?? false;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _gruppoController.dispose();
    _emailGenitoreController.dispose();
    _telefonoGenitoreController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDataNascita() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dataNascita ?? DateTime(now.year - 12),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (selected != null) {
      setState(() => _dataNascita = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataNascita == null) {
      setState(() => _errorMessage = 'Seleziona la data di nascita');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(atletiRepositoryProvider);

    try {
      if (_isEditing) {
        await repository.updateAtleta(
          id: widget.atleta!.id,
          nome: _nomeController.text.trim(),
          cognome: _cognomeController.text.trim(),
          dataNascita: _dataNascita!,
          sesso: _sesso,
          sport: _sport,
          gruppo: _gruppoController.text.trim(),
          emailGenitore: _emailGenitoreController.text.trim(),
          telefonoGenitore: _telefonoGenitoreController.text.trim(),
          consensoPrivacyFirmato: _consensoPrivacy,
          consensoPrivacyData: widget.atleta!.consensoPrivacyData,
          note: _noteController.text.trim(),
        );
      } else {
        await repository.createAtleta(
          clubId: widget.clubId,
          nome: _nomeController.text.trim(),
          cognome: _cognomeController.text.trim(),
          dataNascita: _dataNascita!,
          sesso: _sesso,
          sport: _sport,
          gruppo: _gruppoController.text.trim(),
          emailGenitore: _emailGenitoreController.text.trim(),
          telefonoGenitore: _telefonoGenitoreController.text.trim(),
          consensoPrivacyFirmato: _consensoPrivacy,
          note: _noteController.text.trim(),
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

  Future<void> _confermaArchiviazione() async {
    final atleta = widget.atleta!;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(atleta.attivo ? 'Archiviare l\'atleta?' : 'Riattivare l\'atleta?'),
        content: Text(
          atleta.attivo
              ? 'L\'atleta non comparirà più nell\'elenco attivo, ma lo storico resta.'
              : 'L\'atleta tornerà a comparire nell\'elenco attivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );

    if (conferma != true) return;

    await ref
        .read(atletiRepositoryProvider)
        .setAttivo(id: atleta.id, attivo: !atleta.attivo);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica atleta' : 'Nuovo atleta'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(
                widget.atleta!.attivo
                    ? Icons.archive_outlined
                    : Icons.unarchive_outlined,
              ),
              tooltip: widget.atleta!.attivo ? 'Archivia' : 'Riattiva',
              onPressed: _confermaArchiviazione,
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
                  controller: _cognomeController,
                  decoration: const InputDecoration(labelText: 'Cognome'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data di nascita'),
                  subtitle: Text(
                    _dataNascita == null
                        ? 'Seleziona una data'
                        : '${_dataNascita!.day.toString().padLeft(2, '0')}/'
                              '${_dataNascita!.month.toString().padLeft(2, '0')}/'
                              '${_dataNascita!.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDataNascita,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _sesso,
                  decoration: const InputDecoration(
                    labelText: 'Sesso (opzionale)',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('M')),
                    DropdownMenuItem(value: 'F', child: Text('F')),
                  ],
                  onChanged: (value) => setState(() => _sesso = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _sport,
                  decoration: const InputDecoration(labelText: 'Sport'),
                  items: const [
                    DropdownMenuItem(value: 'nuoto', child: Text('Nuoto')),
                    DropdownMenuItem(
                      value: 'pallanuoto',
                      child: Text('Pallanuoto'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _sport = value ?? 'nuoto'),
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
                  controller: _emailGenitoreController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email genitore (opzionale)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoGenitoreController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefono genitore (opzionale)',
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
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Consenso privacy firmato'),
                  subtitle: const Text(
                    'Vedi docs/privacy/ per il modulo da far firmare al genitore',
                  ),
                  value: _consensoPrivacy,
                  onChanged: (value) =>
                      setState(() => _consensoPrivacy = value),
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
