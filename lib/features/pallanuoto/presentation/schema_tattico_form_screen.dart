import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/schemi_tattici_providers.dart';
import '../data/schemi_tattici_repository.dart';
import '../domain/schema_tattico.dart';
import 'water_polo_tactics_board.dart';

/// Crea (o modifica) uno schema tattico: titolo + una sequenza di passi
/// (al più [SchemaTattico.massimoPassi]), ciascuno con la propria
/// lavagna modificabile — es. passo 1 le posizioni di partenza, passo 2
/// le frecce di movimento, passo 3 le posizioni finali. Ogni
/// tocco/trascinamento sulla lavagna aggiorna solo lo stato di questo
/// form (in memoria); il salvataggio vero e proprio avviene al tocco di
/// "Salva schema".
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
  String? _gruppoId;

  late List<PassoSchema> _passi;
  int _passoAttuale = 0;
  late CampoLavagna _campo;
  bool _bloccata = false;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.schema != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schema;
    _titoloController = TextEditingController(text: s?.titolo ?? '');
    _categoriaController = TextEditingController(text: s?.categoria ?? '');
    _gruppoId = s?.gruppoId;
    _passi = List.of(s?.passi ?? const [(giocatori: [], frecce: [])]);
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
    _passi[_passoAttuale] = (
      giocatori: [
        for (final g in giocatori)
          (punto: (g.posizione.dx, g.posizione.dy), colore: g.colore.name),
      ],
      frecce: [
        for (final f in frecce)
          (
            inizio: (f.inizio.dx, f.inizio.dy),
            fine: (f.fine.dx, f.fine.dy),
            colore: f.colore.name,
          ),
      ],
    );
  }

  void _cambiaCampo(CampoLavagna nuovo) => setState(() => _campo = nuovo);

  void _vaiAPasso(int indice) => setState(() => _passoAttuale = indice);

  PassoLavagna _passoAWidget(PassoSchema p) => (
    giocatori: [
      for (final g in p.giocatori)
        GiocatoreLavagna(
          posizione: Offset(g.punto.$1, g.punto.$2),
          colore: ColoreLavagna.values.byName(g.colore),
        ),
    ],
    frecce: [
      for (final f in p.frecce)
        FrecciaLavagna(
          inizio: Offset(f.inizio.$1, f.inizio.$2),
          fine: Offset(f.fine.$1, f.fine.$2),
          colore: ColoreLavagna.values.byName(f.colore),
        ),
    ],
  );

  void _apriAnteprima() {
    final titolo = _titoloController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppScaffold(
          scrollabile: true,
          appBar: AppBar(title: Text(titolo.isEmpty ? 'Anteprima' : titolo)),
          body: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            child: SchemaTatticoPlayer(
              campo: _campo,
              passi: [for (final p in _passi) _passoAWidget(p)],
            ),
          ),
        ),
      ),
    );
  }

  void _aggiungiPasso() {
    if (_passi.length >= SchemaTattico.massimoPassi) return;
    setState(() {
      // Il nuovo passo parte da una copia dell'attuale: di solito il
      // passo successivo (es. le posizioni finali) riparte da dove sta
      // il precedente (es. le posizioni di partenza), non da zero.
      _passi.add(_passi[_passoAttuale]);
      _passoAttuale = _passi.length - 1;
    });
  }

  Future<void> _eliminaPasso(int indice) async {
    final passo = _passi[indice];
    if (passo.giocatori.isNotEmpty || passo.frecce.isNotEmpty) {
      final conferma = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Eliminare il passo ${indice + 1}?'),
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
      if (conferma != true) return;
    }
    setState(() {
      _passi.removeAt(indice);
      if (_passoAttuale >= _passi.length) _passoAttuale = _passi.length - 1;
    });
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
          gruppoId: _gruppoId,
          titolo: _titoloController.text.trim(),
          categoria: _categoriaController.text.trim(),
          campo: _campo.name,
          passi: _passi,
        );
      } else {
        await repository.creaSchema(
          clubId: widget.clubId,
          gruppoId: _gruppoId,
          titolo: _titoloController.text.trim(),
          categoria: _categoriaController.text.trim(),
          campo: _campo.name,
          passi: _passi,
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
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final passoAttuale = _passoAWidget(_passi[_passoAttuale]);
    final passoFantasma = _passoAttuale > 0
        ? _passoAWidget(_passi[_passoAttuale - 1])
        : null;

    return AppScaffold(
      scrollabile: true,
      physics: _bloccata ? const NeverScrollableScrollPhysics() : null,
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
                AppSelect<String?>(
                  etichetta: 'Gruppo (facoltativo)',
                  value: _gruppoId,
                  hint: 'Nessun gruppo',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Nessun gruppo'),
                    ),
                    for (final g in gruppi)
                      DropdownMenuItem(value: g.id, child: Text(g.nome)),
                    if (_gruppoId != null &&
                        !gruppi.any((g) => g.id == _gruppoId))
                      DropdownMenuItem(
                        value: _gruppoId,
                        child: const Text('Gruppo non trovato'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _gruppoId = value),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Passi (${_passi.length}/${SchemaTattico.massimoPassi})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _apriAnteprima,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Anteprima'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Ogni passo è una schermata a sé: es. passo 1 le posizioni '
              'di partenza, passo 2 le frecce di movimento, passo 3 le '
              'posizioni finali. Non serve usarli tutti.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (var i = 0; i < _passi.length; i++)
                  TonalChip(
                    etichetta: '${i + 1}',
                    selezionato: i == _passoAttuale,
                    onSelezionato: (_) => _vaiAPasso(i),
                    onEliminato: _passi.length > 1
                        ? () => _eliminaPasso(i)
                        : null,
                  ),
                if (_passi.length < SchemaTattico.massimoPassi)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Passo'),
                    onPressed: _aggiungiPasso,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            WaterPoloTacticsBoard(
              key: ValueKey(_passoAttuale),
              giocatoriIniziali: passoAttuale.giocatori,
              frecceIniziali: passoAttuale.frecce,
              passoFantasma: passoFantasma,
              campo: _campo,
              bloccata: _bloccata,
              onCampoCambiato: _cambiaCampo,
              onBloccataCambiato: (b) => setState(() => _bloccata = b),
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
