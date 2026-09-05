import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
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
  late final TextEditingController _dataNascitaController;
  late final TextEditingController _gruppoController;
  late final TextEditingController _emailGenitoreController;
  late final TextEditingController _telefonoGenitoreController;
  late final TextEditingController _noteController;
  late final TextEditingController _numeroTesseraFinController;

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
    _dataNascita = atleta?.dataNascita;
    _dataNascitaController = TextEditingController(
      text: _formattaData(_dataNascita),
    );
    _gruppoController = TextEditingController(text: atleta?.gruppo ?? '');
    _emailGenitoreController = TextEditingController(
      text: atleta?.emailGenitore ?? '',
    );
    _telefonoGenitoreController = TextEditingController(
      text: atleta?.telefonoGenitore ?? '',
    );
    _noteController = TextEditingController(text: atleta?.note ?? '');
    _numeroTesseraFinController = TextEditingController(
      text: atleta?.numeroTesseraFin ?? '',
    );
    _sesso = atleta?.sesso;
    _sport = atleta?.sport ?? 'nuoto';
    _consensoPrivacy = atleta?.consensoPrivacyFirmato ?? false;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _dataNascitaController.dispose();
    _gruppoController.dispose();
    _emailGenitoreController.dispose();
    _telefonoGenitoreController.dispose();
    _noteController.dispose();
    _numeroTesseraFinController.dispose();
    super.dispose();
  }

  String _formattaData(DateTime? data) {
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
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
      setState(() {
        _dataNascita = selected;
        _dataNascitaController.text = _formattaData(selected);
      });
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
          numeroTesseraFin: _numeroTesseraFinController.text.trim(),
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
          numeroTesseraFin: _numeroTesseraFinController.text.trim(),
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

  Future<void> _confermaArchiviazione() async {
    final atleta = widget.atleta!;
    final archivia = atleta.attivo;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          archivia
              ? 'Archiviare ${atleta.nomeCompleto}?'
              : 'Riattivare ${atleta.nomeCompleto}?',
        ),
        content: Text(
          archivia
              ? 'Non comparirà più nell\'elenco attivo, ma lo storico resta.'
              : 'Tornerà a comparire nell\'elenco attivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          if (archivia)
            DangerButton(
              label: 'Archivia',
              expanded: false,
              onPressed: () => Navigator.of(context).pop(true),
            )
          else
            PrimaryButton(
              label: 'Riattiva',
              expanded: false,
              onPressed: () => Navigator.of(context).pop(true),
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
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica atleta' : 'Nuovo atleta'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Anagrafica',
              campi: [
                AppTextField(
                  etichetta: 'Nome',
                  controller: _nomeController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Obbligatorio'
                      : null,
                ),
                AppTextField(
                  etichetta: 'Cognome',
                  controller: _cognomeController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Obbligatorio'
                      : null,
                ),
                AppTextField(
                  etichetta: 'Data di nascita',
                  controller: _dataNascitaController,
                  readOnly: true,
                  onTap: _pickDataNascita,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  validator: (_) =>
                      _dataNascita == null ? 'Obbligatoria' : null,
                ),
                AppSelect<String>(
                  etichetta: 'Sesso (facoltativo)',
                  value: _sesso,
                  hint: 'Non specificato',
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('M')),
                    DropdownMenuItem(value: 'F', child: Text('F')),
                  ],
                  onChanged: (value) => setState(() => _sesso = value),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Attività',
              campi: [
                AppSelect<String>(
                  etichetta: 'Sport',
                  value: _sport,
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
                if (_sport == 'pallanuoto')
                  AppTextField(
                    etichetta: 'N. tessera FIN (facoltativo)',
                    controller: _numeroTesseraFinController,
                  ),
                AppTextField(
                  etichetta: 'Gruppo (facoltativo)',
                  controller: _gruppoController,
                ),
              ],
            ),
            FormGroup(
              titolo: 'Contatti e consenso',
              campi: [
                AppTextField(
                  etichetta: 'Email genitore (facoltativo)',
                  controller: _emailGenitoreController,
                  keyboardType: TextInputType.emailAddress,
                ),
                AppTextField(
                  etichetta: 'Telefono genitore (facoltativo)',
                  controller: _telefonoGenitoreController,
                  keyboardType: TextInputType.phone,
                ),
                _ConsensoPrivacyRow(
                  valore: _consensoPrivacy,
                  onChanged: (value) =>
                      setState(() => _consensoPrivacy = value),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Note',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Note (facoltativo)',
                  controller: _noteController,
                  maxLines: 3,
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              ErrorBanner(messaggio: _errorMessage!),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              label: 'Salva atleta',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              DangerButton(
                label: widget.atleta!.attivo
                    ? 'Archivia atleta'
                    : 'Riattiva atleta',
                onPressed: _confermaArchiviazione,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Non è un componente della libreria (DESIGN.md sezione 14 non ne
/// elenca uno per gli switch): resta locale a questo form, ma segue
/// comunque i token di colore/tipografia dell'app.
class _ConsensoPrivacyRow extends StatelessWidget {
  const _ConsensoPrivacyRow({required this.valore, required this.onChanged});

  final bool valore;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!valore),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consenso privacy firmato',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vedi docs/privacy/ per il modulo da far firmare al genitore',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(value: valore, onChanged: onChanged),
        ],
      ),
    );
  }
}
