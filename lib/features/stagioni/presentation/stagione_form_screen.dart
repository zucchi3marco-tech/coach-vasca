import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../../gruppi/domain/gruppo.dart';
import '../data/stagioni_repository.dart';
import '../domain/stagione.dart';
import 'elimina_dialogs.dart';

class StagioneFormScreen extends ConsumerStatefulWidget {
  const StagioneFormScreen({required this.clubId, this.stagione, super.key});

  final String clubId;
  final Stagione? stagione;

  @override
  ConsumerState<StagioneFormScreen> createState() => _StagioneFormScreenState();
}

class _StagioneFormScreenState extends ConsumerState<StagioneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _obiettivoController;
  String? _gruppoId;
  late final TextEditingController _campionatoController;
  late final TextEditingController _dataInizioController;
  late final TextEditingController _dataFineController;
  late DateTime _dataInizio;
  late DateTime _dataFine;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.stagione != null;

  @override
  void initState() {
    super.initState();
    final s = widget.stagione;
    _obiettivoController = TextEditingController(text: s?.obiettivo ?? '');
    // In creazione la stagione prende il gruppo su cui si sta lavorando
    // (null = "Tutti gli atleti": stagione di club); in modifica lo mantiene.
    _gruppoId = s != null
        ? s.gruppoId
        : ref.read(selezioneGruppoProvider)?.gruppoId;
    _campionatoController = TextEditingController(text: s?.campionato ?? '');
    final oggi = DateTime.now();
    _dataInizio = s?.dataInizio ?? DateTime(oggi.year, 9);
    _dataFine = s?.dataFine ?? DateTime(oggi.year + 1, 6, 30);
    _dataInizioController = TextEditingController(
      text: _formattaData(_dataInizio),
    );
    _dataFineController = TextEditingController(text: _formattaData(_dataFine));
  }

  @override
  void dispose() {
    _obiettivoController.dispose();
    _campionatoController.dispose();
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

  /// La "categoria" della stagione: il nome del gruppo in uso, oppure
  /// "Tutti gli atleti" per una stagione di club (nessun gruppo).
  String _categoria(List<Gruppo> gruppi) {
    if (_gruppoId == null) return etichettaTuttiGliAtleti;
    for (final g in gruppi) {
      if (g.id == _gruppoId) return g.nome;
    }
    return '';
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

    final repository = ref.read(stagioniRepositoryProvider);
    try {
      final gruppi = await ref.read(gruppiListProvider(widget.clubId).future);
      final nome = titoloStagione(
        categoria: _categoria(gruppi),
        dataInizio: _dataInizio,
        dataFine: _dataFine,
      );
      if (_isEditing) {
        await repository.updateStagione(
          id: widget.stagione!.id,
          nome: nome,
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          obiettivo: _obiettivoController.text.trim(),
          gruppoId: _gruppoId,
          campionato: _campionatoController.text.trim(),
        );
      } else {
        await repository.createStagione(
          clubId: widget.clubId,
          nome: nome,
          dataInizio: _dataInizio,
          dataFine: _dataFine,
          obiettivo: _obiettivoController.text.trim(),
          gruppoId: _gruppoId,
          campionato: _campionatoController.text.trim(),
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
    final conferma = await confermaEliminaStagione(context);
    if (conferma) {
      await ref
          .read(stagioniRepositoryProvider)
          .deleteStagione(widget.stagione!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final colori = context.colori;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica stagione' : 'Nuova stagione'),
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
            AppTextField(
              etichetta: 'Data inizio',
              controller: _dataInizioController,
              readOnly: true,
              onTap: _pickDataInizio,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Data fine',
              controller: _dataFineController,
              readOnly: true,
              onTap: _pickDataFine,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Obiettivo (facoltativo)',
              controller: _obiettivoController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Campionato (facoltativo)',
              controller: _campionatoController,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              key: ValueKey('categoria-${_categoria(gruppi)}'),
              etichetta: 'Categoria',
              valoreIniziale: _categoria(gruppi),
              readOnly: true,
              abilitato: false,
              aiuto:
                  'È il gruppo su cui stai lavorando: il titolo della '
                  'stagione si compone da solo.',
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errorMessage!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Salva stagione',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
