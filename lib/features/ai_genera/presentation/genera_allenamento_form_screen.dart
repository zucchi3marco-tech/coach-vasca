import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/generazione_ai_repository.dart';
import '../domain/parametri_generazione.dart';

const _livelli = ['principiante', 'intermedio', 'avanzato', 'agonista'];
const _focus = ['aerobico', 'soglia', 'velocita', 'tecnica', 'misto'];
const _regimi = ['A1', 'A2', 'B1', 'B2', 'C', 'D'];

String _capitalizza(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class GeneraAllenamentoFormScreen extends ConsumerStatefulWidget {
  const GeneraAllenamentoFormScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<GeneraAllenamentoFormScreen> createState() =>
      _GeneraAllenamentoFormScreenState();
}

class _GeneraAllenamentoFormScreenState
    extends ConsumerState<GeneraAllenamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gruppoController = TextEditingController();
  final _volumeController = TextEditingController();
  final _vincoliController = TextEditingController();

  String _livello = _livelli.first;
  String _focusSelezionato = _focus.first;
  final Set<String> _regimiSelezionati = {};
  bool _generazioneInCorso = false;

  @override
  void dispose() {
    _gruppoController.dispose();
    _volumeController.dispose();
    _vincoliController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Genera con AI')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _gruppoController,
              decoration: const InputDecoration(
                labelText: 'Gruppo/livello (es. Juniores)',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Campo obbligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _livello,
              decoration: const InputDecoration(labelText: 'Livello'),
              items: [
                for (final l in _livelli)
                  DropdownMenuItem(value: l, child: Text(_capitalizza(l))),
              ],
              onChanged: (value) =>
                  setState(() => _livello = value ?? _livelli.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _volumeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Volume totale (metri)',
              ),
              validator: (value) {
                final n = int.tryParse(value ?? '');
                if (n == null || n <= 0) return 'Inserisci un numero valido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _focusSelezionato,
              decoration: const InputDecoration(labelText: 'Focus'),
              items: [
                for (final f in _focus)
                  DropdownMenuItem(value: f, child: Text(_capitalizza(f))),
              ],
              onChanged: (value) =>
                  setState(() => _focusSelezionato = value ?? _focus.first),
            ),
            const SizedBox(height: 16),
            Text('Regimi ammessi', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final r in _regimi)
                  FilterChip(
                    label: Text(r),
                    selected: _regimiSelezionati.contains(r),
                    onSelected: (selezionato) => setState(() {
                      if (selezionato) {
                        _regimiSelezionati.add(r);
                      } else {
                        _regimiSelezionati.remove(r);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vincoliController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Vincoli (opzionale)',
                hintText: 'Es. niente pinne, max 75 minuti, vasca 25m',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _generazioneInCorso ? null : _conferma,
              child: _generazioneInCorso
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Genera'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _conferma() async {
    if (!_formKey.currentState!.validate()) return;
    if (_regimiSelezionati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un regime ammesso')),
      );
      return;
    }

    final parametri = ParametriGenerazione(
      gruppo: _gruppoController.text.trim(),
      livello: _livello,
      volumeMetri: int.parse(_volumeController.text),
      focus: _focusSelezionato,
      regimiAmmessi: _regimiSelezionati.toList(),
      vincoli: _vincoliController.text.trim().isEmpty
          ? null
          : _vincoliController.text.trim(),
    );

    setState(() => _generazioneInCorso = true);
    try {
      final testo = await ref
          .read(generazioneAiRepositoryProvider)
          .generaAllenamento(parametri);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Scheda generata'),
          content: SingleChildScrollView(child: Text(testo)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella generazione: $e')),
      );
    } finally {
      if (mounted) setState(() => _generazioneInCorso = false);
    }
  }
}
