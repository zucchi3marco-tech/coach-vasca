import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../data/training_blocks_repository.dart';
import '../domain/training_block.dart';

/// Vocabolario esteso dell'Excel (A1/A2/B1/B2/C1/C2 + V/RG/T/TT/TEST, non
/// solo le zone dell'app) — stesso elenco validato in
/// `excel_import.dart`, qui proposto a scelta rapida per una parte
/// scritta a mano.
const _zoneDisponibili = [
  'A1',
  'A2',
  'B1',
  'B2',
  'C1',
  'C2',
  'V',
  'RG',
  'T',
  'TT',
  'TEST',
];

const _esecuzioniDisponibili = [
  'nuoto',
  'gambe',
  'braccia',
  'pull',
  'tecnica',
  'remate',
  'pallanuoto tecnico-tattico',
  'a secco',
];

/// Crea o modifica una parte (serie) di un blocco — rifinitura dopo la
/// Fase 1: prima si popolavano solo da import Excel o "Salva come
/// blocco".
class ParteFormScreen extends ConsumerStatefulWidget {
  const ParteFormScreen({
    required this.bloccoId,
    required this.clubId,
    this.parte,
    this.ordineSuccessivo = 1,
    super.key,
  });

  final String bloccoId;
  final String clubId;
  final TrainingBlockParte? parte;
  final int ordineSuccessivo;

  @override
  ConsumerState<ParteFormScreen> createState() => _ParteFormScreenState();
}

class _ParteFormScreenState extends ConsumerState<ParteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _giriController;
  late final TextEditingController _ripetizioniController;
  late final TextEditingController _distanzaController;
  late final TextEditingController _durataController;
  late final TextEditingController _stileController;
  late final TextEditingController _esercizioController;
  late final TextEditingController _recuperoController;
  late final TextEditingController _attrezziController;
  late final TextEditingController _noteController;
  late String _zona;
  late String _esecuzione;
  late bool _aTempo;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.parte != null;

  @override
  void initState() {
    super.initState();
    final p = widget.parte;
    _giriController = TextEditingController(text: (p?.giri ?? 1).toString());
    _ripetizioniController = TextEditingController(
      text: (p?.ripetizioni ?? 1).toString(),
    );
    _aTempo = p?.aTempo ?? false;
    _distanzaController = TextEditingController(
      text: p?.distanzaM?.toString() ?? '',
    );
    _durataController = TextEditingController(
      text: p?.durataS == null ? '' : formatDurataMmSs(p!.durataS!),
    );
    _stileController = TextEditingController(text: p?.stile ?? '');
    _esercizioController = TextEditingController(text: p?.esercizio ?? '');
    _recuperoController = TextEditingController(
      text: p?.recuperoS?.toString() ?? '',
    );
    _attrezziController = TextEditingController(text: p?.attrezzi ?? '');
    _noteController = TextEditingController(text: p?.note ?? '');
    _zona = p?.zona ?? 'A1';
    _esecuzione = p?.esecuzione ?? 'nuoto';
  }

  @override
  void dispose() {
    _giriController.dispose();
    _ripetizioniController.dispose();
    _distanzaController.dispose();
    _durataController.dispose();
    _stileController.dispose();
    _esercizioController.dispose();
    _recuperoController.dispose();
    _attrezziController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final repository = ref.read(trainingBlocksRepositoryProvider);
    final giri = int.parse(_giriController.text.trim());
    final ripetizioni = int.parse(_ripetizioniController.text.trim());
    final distanzaM = _aTempo
        ? null
        : int.parse(_distanzaController.text.trim());
    final durataS = _aTempo
        ? parsePaceMmSs(_durataController.text)?.round()
        : null;
    final stile = _stileController.text.trim();
    final esercizio = _esercizioController.text.trim();
    final recuperoS = int.tryParse(_recuperoController.text.trim());
    final attrezzi = _attrezziController.text.trim();
    final note = _noteController.text.trim();
    try {
      if (_isEditing) {
        await repository.updateParte(
          widget.parte!.id,
          bloccoId: widget.bloccoId,
          ordine: widget.parte!.ordine,
          giri: giri,
          ripetizioni: ripetizioni,
          distanzaM: distanzaM,
          durataS: durataS,
          stile: stile.isEmpty ? null : stile,
          esercizio: esercizio.isEmpty ? null : esercizio,
          zona: _zona,
          esecuzione: _esecuzione,
          recuperoS: recuperoS,
          attrezzi: attrezzi.isEmpty ? null : attrezzi,
          note: note.isEmpty ? null : note,
        );
      } else {
        await repository.createParte(
          bloccoId: widget.bloccoId,
          clubId: widget.clubId,
          ordine: widget.ordineSuccessivo,
          giri: giri,
          ripetizioni: ripetizioni,
          distanzaM: distanzaM,
          durataS: durataS,
          stile: stile.isEmpty ? null : stile,
          esercizio: esercizio.isEmpty ? null : esercizio,
          zona: _zona,
          esecuzione: _esecuzione,
          recuperoS: recuperoS,
          attrezzi: attrezzi.isEmpty ? null : attrezzi,
          note: note.isEmpty ? null : note,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _elimina() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare la parte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    try {
      await ref
          .read(trainingBlocksRepositoryProvider)
          .deleteParte(widget.parte!.id, bloccoId: widget.bloccoId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = messaggioErrore(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica parte' : 'Nuova parte'),
        actions: [
          if (_isEditing)
            TextButton.icon(
              onPressed: _elimina,
              icon: Icon(Icons.delete_outline, color: colori.rosso),
              label: Text('Elimina', style: TextStyle(color: colori.rosso)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              ErrorBanner(messaggio: _errorMessage!),
              const SizedBox(height: AppSpacing.s16),
            ],
            FormGroup(
              titolo: 'Volume',
              campi: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Distanza')),
                    ButtonSegment(value: true, label: Text('A tempo')),
                  ],
                  selected: {_aTempo},
                  onSelectionChanged: (s) => setState(() => _aTempo = s.first),
                ),
                const SizedBox(height: AppSpacing.s12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        etichetta: 'Giri',
                        controller: _giriController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          return (n == null || n <= 0) ? '> 0' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: AppTextField(
                        etichetta: 'Ripetizioni',
                        controller: _ripetizioniController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          return (n == null || n <= 0) ? '> 0' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    if (!_aTempo)
                      Expanded(
                        child: AppTextField(
                          etichetta: 'Distanza (m)',
                          controller: _distanzaController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            return (n == null || n <= 0) ? '> 0' : null;
                          },
                        ),
                      )
                    else
                      Expanded(
                        child: AppTextField(
                          etichetta: 'Durata',
                          controller: _durataController,
                          aiuto: 'min:sec',
                          validator: (v) {
                            final s = parsePaceMmSs(v ?? '');
                            return (s == null || s <= 0) ? 'min:sec' : null;
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Tipo di lavoro',
              campi: [
                AppSelect<String>(
                  etichetta: 'Zona',
                  value: _zona,
                  items: [
                    for (final z in _zoneDisponibili)
                      DropdownMenuItem(value: z, child: Text(z)),
                  ],
                  onChanged: (value) => setState(() => _zona = value ?? 'A1'),
                ),
                AppSelect<String>(
                  etichetta: 'Esecuzione',
                  value: _esecuzione,
                  items: [
                    for (final e in _esecuzioniDisponibili)
                      DropdownMenuItem(value: e, child: Text(e)),
                  ],
                  onChanged: (value) =>
                      setState(() => _esecuzione = value ?? 'nuoto'),
                ),
                AppTextField(
                  etichetta: 'Stile (facoltativo, es. "Stile libero")',
                  controller: _stileController,
                ),
                AppTextField(
                  etichetta: 'Esercizio / andatura (facoltativo)',
                  controller: _esercizioController,
                ),
              ],
            ),
            FormGroup(
              titolo: 'Altro',
              campi: [
                AppTextField(
                  etichetta: 'Recupero, s (facoltativo)',
                  controller: _recuperoController,
                  keyboardType: TextInputType.number,
                ),
                AppTextField(
                  etichetta: 'Attrezzi (facoltativo)',
                  controller: _attrezziController,
                ),
                AppTextField(
                  etichetta: 'Note (facoltativo)',
                  controller: _noteController,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: _isEditing ? 'Salva modifiche' : 'Aggiungi parte',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
