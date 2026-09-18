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
import '../application/schemi_tattici_providers.dart';
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
  late final TextEditingController _categoriaController;

  late List<GiocatoreSchema> _giocatori;
  late List<FrecciaSchema> _frecce;
  late CampoLavagna _campo;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.schema != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schema;
    _titoloController = TextEditingController(text: s?.titolo ?? '');
    _categoriaController = TextEditingController(text: s?.categoria ?? '');
    _giocatori = List.of(s?.giocatori ?? const []);
    _frecce = List.of(s?.frecce ?? const []);
    _campo = CampoLavagna.values.byName(s?.campo ?? 'intero');
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  void _onCambiato(
    List<GiocatoreLavagna> giocatori,
    List<FrecciaLavagna> frecce,
  ) {
    _giocatori = [
      for (final g in giocatori)
        (punto: (g.posizione.dx, g.posizione.dy), colore: g.colore.name),
    ];
    _frecce = [
      for (final f in frecce)
        (
          inizio: (f.inizio.dx, f.inizio.dy),
          fine: (f.fine.dx, f.fine.dy),
          colore: f.colore.name,
        ),
    ];
  }

  void _cambiaCampo(CampoLavagna nuovo) => setState(() => _campo = nuovo);

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
          categoria: _categoriaController.text.trim(),
          campo: _campo.name,
          giocatori: _giocatori,
          frecce: _frecce,
        );
      } else {
        await repository.creaSchema(
          clubId: widget.clubId,
          titolo: _titoloController.text.trim(),
          categoria: _categoriaController.text.trim(),
          campo: _campo.name,
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
    final categorieEsistenti =
        (ref.watch(schemiTatticiListProvider(widget.clubId)).value ?? [])
            .map((s) => s.categoria)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

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
                AppTextField(
                  etichetta: 'Categoria',
                  controller: _categoriaController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci una categoria (es. Transizioni, '
                            'Superiorità, Difesa...)'
                      : null,
                ),
                if (categorieEsistenti.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (final categoria in categorieEsistenti)
                        ActionChip(
                          label: Text(categoria),
                          onPressed: () => setState(
                            () => _categoriaController.text = categoria,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            WaterPoloTacticsBoard(
              giocatoriIniziali: [
                for (final g in _giocatori)
                  GiocatoreLavagna(
                    posizione: Offset(g.punto.$1, g.punto.$2),
                    colore: ColoreLavagna.values.byName(g.colore),
                  ),
              ],
              frecceIniziali: [
                for (final f in _frecce)
                  FrecciaLavagna(
                    inizio: Offset(f.inizio.$1, f.inizio.$2),
                    fine: Offset(f.fine.$1, f.fine.$2),
                    colore: ColoreLavagna.values.byName(f.colore),
                  ),
              ],
              campo: _campo,
              onCampoCambiato: _cambiaCampo,
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
