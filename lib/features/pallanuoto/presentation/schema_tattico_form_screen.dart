import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../data/schemi_tattici_repository.dart';
import '../domain/schema_tattico.dart';
import 'water_polo_tactics_board.dart';

/// Crea (o modifica) uno schema tattico: titolo + lavagna modificabile.
/// Ogni tocco/trascinamento sulla lavagna aggiorna solo lo stato di
/// questo form (in memoria); il salvataggio vero e proprio avviene al
/// tocco di "Salva schema".
class SchemaTatticoFormScreen extends ConsumerStatefulWidget {
  const SchemaTatticoFormScreen({required this.clubId, this.schema, super.key});

  final String clubId;
  final SchemaTattico? schema;

  @override
  ConsumerState<SchemaTatticoFormScreen> createState() =>
      _SchemaTatticoFormScreenState();
}

class _SchemaTatticoFormScreenState
    extends ConsumerState<SchemaTatticoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titoloController;

  late List<PuntoSchema> _giocatori;
  late List<(PuntoSchema, PuntoSchema)> _frecce;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.schema != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schema;
    _titoloController = TextEditingController(text: s?.titolo ?? '');
    _giocatori = List.of(s?.giocatori ?? const []);
    _frecce = List.of(s?.frecce ?? const []);
  }

  @override
  void dispose() {
    _titoloController.dispose();
    super.dispose();
  }

  void _onCambiato(List<Offset> giocatori, List<(Offset, Offset)> frecce) {
    _giocatori = [for (final o in giocatori) (o.dx, o.dy)];
    _frecce = [
      for (final f in frecce) ((f.$1.dx, f.$1.dy), (f.$2.dx, f.$2.dy)),
    ];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(schemiTatticiRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.aggiornaSchema(
          id: widget.schema!.id,
          titolo: _titoloController.text.trim(),
          giocatori: _giocatori,
          frecce: _frecce,
        );
      } else {
        await repository.creaSchema(
          clubId: widget.clubId,
          titolo: _titoloController.text.trim(),
          giocatori: _giocatori,
          frecce: _frecce,
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
      builder: (context) => AlertDialog(
        title: const Text('Eliminare questo schema?'),
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
          .read(schemiTatticiRepositoryProvider)
          .eliminaSchema(widget.schema!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica schema' : 'Nuovo schema'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Schema',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Titolo',
                  controller: _titoloController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci un titolo'
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            WaterPoloTacticsBoard(
              giocatoriIniziali: [
                for (final p in _giocatori) Offset(p.$1, p.$2),
              ],
              frecceIniziali: [
                for (final f in _frecce)
                  (Offset(f.$1.$1, f.$1.$2), Offset(f.$2.$1, f.$2.$2)),
              ],
              onCambiato: _onCambiato,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.s16),
              ErrorBanner(messaggio: _errorMessage!),
            ],
            const SizedBox(height: AppSpacing.s16),
            PrimaryButton(
              label: 'Salva schema',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
            if (_isEditing) ...[
              const SizedBox(height: AppSpacing.s12),
              DangerButton(label: 'Elimina', onPressed: _elimina),
            ],
          ],
        ),
      ),
    );
  }
}
