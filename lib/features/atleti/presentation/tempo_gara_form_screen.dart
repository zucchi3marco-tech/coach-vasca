import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../gare/application/risultato_gara_service.dart';
import '../data/tempi_gara_repository.dart';
import '../domain/atleta.dart';
import '../domain/pb_slots.dart';
import '../domain/tempo_gara.dart';

/// Inserisce (o modifica) una voce dello storico tempi nuoto: a
/// differenza di [PbFormScreen] (tempo per uno slot già fissato), qui si
/// scelgono anche stile, distanza e vasca, perché ogni tempo inserito
/// resta una voce separata nello storico (non sovrascrive un primato).
class TempoGaraFormScreen extends ConsumerStatefulWidget {
  const TempoGaraFormScreen({
    required this.atleta,
    this.tempoGara,
    this.stileIniziale,
    this.distanzaMIniziale,
    this.vascaMIniziale,
    this.garaId,
    this.nomeGara,
    this.dataIniziale,
    super.key,
  });

  final Atleta atleta;
  final TempoGara? tempoGara;

  /// Usati solo per pre-selezionare i campi di un nuovo inserimento
  /// (es. dallo stile/distanza/vasca già scelti nella schermata storico);
  /// ignorati quando si modifica un tempo esistente.
  final String? stileIniziale;
  final int? distanzaMIniziale;
  final int? vascaMIniziale;

  /// Se il tempo è il risultato di una gara: la gara a cui collegarlo
  /// (il personal best si aggiorna da solo se battuto), il suo nome per
  /// la nota del PB e la data suggerita.
  final String? garaId;
  final String? nomeGara;
  final DateTime? dataIniziale;

  @override
  ConsumerState<TempoGaraFormScreen> createState() =>
      _TempoGaraFormScreenState();
}

class _TempoGaraFormScreenState extends ConsumerState<TempoGaraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minutiController;
  late final TextEditingController _secondiController;
  late final TextEditingController _dataController;
  late final TextEditingController _noteController;

  late String _stile;
  late int _distanzaM;
  late int _vascaM;
  late DateTime _data;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.tempoGara != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tempoGara;
    _stile = t?.stile ?? widget.stileIniziale ?? stiliNuoto.first;
    _distanzaM =
        t?.distanzaM ??
        widget.distanzaMIniziale ??
        distanzePerStileNuoto[_stile]!.first;
    _vascaM = t?.vascaM ?? widget.vascaMIniziale ?? 25;
    final oggi = DateTime.now();
    final suggerita = widget.dataIniziale ?? oggi;
    // Un risultato si registra a gara fatta: mai una data futura.
    _data = t?.data ?? (suggerita.isAfter(oggi) ? oggi : suggerita);
    final tempo = t?.tempoS;
    _minutiController = TextEditingController(
      text: tempo == null ? '0' : (tempo ~/ 60).toString(),
    );
    _secondiController = TextEditingController(
      text: tempo == null
          ? ''
          : (tempo - (tempo ~/ 60) * 60).toStringAsFixed(2),
    );
    _dataController = TextEditingController(text: _formattaData(_data));
    _noteController = TextEditingController(text: t?.note ?? '');
  }

  @override
  void dispose() {
    _minutiController.dispose();
    _secondiController.dispose();
    _dataController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formattaData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  void _cambiaStile(String? stile) {
    if (stile == null) return;
    setState(() {
      _stile = stile;
      final distanze = distanzePerStileNuoto[_stile]!;
      if (!distanze.contains(_distanzaM)) _distanzaM = distanze.first;
    });
  }

  Future<void> _pickData() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (selected != null) {
      setState(() {
        _data = selected;
        _dataController.text = _formattaData(selected);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final minuti = int.tryParse(_minutiController.text.trim()) ?? 0;
    final secondi = double.tryParse(_secondiController.text.trim()) ?? 0;
    final tempoS = minuti * 60 + secondi;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(tempiGaraRepositoryProvider);
    var nuovoPb = false;
    try {
      if (_isEditing) {
        await repository.aggiornaTempoGara(
          id: widget.tempoGara!.id,
          stile: _stile,
          distanzaM: _distanzaM,
          vascaM: _vascaM,
          tempoS: tempoS,
          data: _data,
          note: _noteController.text.trim(),
        );
      } else {
        await repository.creaTempoGara(
          atletaId: widget.atleta.id,
          stile: _stile,
          distanzaM: _distanzaM,
          vascaM: _vascaM,
          tempoS: tempoS,
          data: _data,
          note: _noteController.text.trim(),
          garaId: widget.garaId,
        );
        if (widget.garaId != null) {
          try {
            nuovoPb = await ref
                .read(risultatoGaraServiceProvider)
                .aggiornaPbSeMigliore(
                  atletaId: widget.atleta.id,
                  stile: _stile,
                  distanzaM: _distanzaM,
                  tempoS: tempoS,
                  data: _data,
                  nomeGara: widget.nomeGara,
                );
          } catch (_) {
            // Il tempo è già salvato: un PB non aggiornato non deve
            // far fallire il salvataggio.
          }
        }
      }
      if (mounted) {
        if (nuovoPb) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Nuovo personal best!')));
        }
        Navigator.of(context).pop(true);
      }
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
        title: const Text('Eliminare questo tempo?'),
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
          .read(tempiGaraRepositoryProvider)
          .eliminaTempoGara(widget.tempoGara!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final distanze = distanzePerStileNuoto[_stile]!;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica tempo' : 'Nuovo tempo'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Gara',
              campi: [
                AppSelect<String>(
                  etichetta: 'Stile',
                  value: _stile,
                  items: [
                    for (final s in stiliNuoto)
                      DropdownMenuItem(
                        value: s,
                        child: Text(capitalizzaParola(s)),
                      ),
                  ],
                  onChanged: _cambiaStile,
                ),
                AppSelect<int>(
                  etichetta: 'Distanza',
                  value: _distanzaM,
                  items: [
                    for (final d in distanze)
                      DropdownMenuItem(value: d, child: Text('${d}m')),
                  ],
                  onChanged: (d) => setState(() => _distanzaM = d!),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vasca',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<int>(
                      // Senza spunta: la scelta e' gia' evidenziata dal
                      // colore, e la spunta toglieva spazio all'etichetta
                      // che su telefono andava a capo a meta' parola.
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 25, label: Text('25m')),
                        ButtonSegment(value: 50, label: Text('50m')),
                      ],
                      selected: {_vascaM},
                      onSelectionChanged: (s) =>
                          setState(() => _vascaM = s.first),
                    ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Prestazione',
              campi: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        etichetta: 'Minuti',
                        controller: _minutiController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: AppTextField(
                        etichetta: 'Secondi',
                        controller: _secondiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          final minuti =
                              int.tryParse(_minutiController.text.trim()) ?? 0;
                          final secondi = double.tryParse(v?.trim() ?? '');
                          if (minuti == 0 &&
                              (secondi == null || secondi <= 0)) {
                            return 'Inserisci il tempo';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                AppTextField(
                  etichetta: 'Data',
                  controller: _dataController,
                  readOnly: true,
                  onTap: _pickData,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Altro',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Note (facoltativo)',
                  controller: _noteController,
                  maxLines: 2,
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              ErrorBanner(messaggio: _errorMessage!),
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: 'Salva tempo',
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
