import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../data/impegni_repository.dart';
import '../domain/impegno.dart';

/// Crea o modifica un impegno: collegiale, trasferta, riposo, torneo o
/// altro, dal giorno al giorno. Dal calendario di una stagione arrivano
/// il giorno toccato e la squadra della stagione (null = tutto il club).
class ImpegnoFormScreen extends ConsumerStatefulWidget {
  const ImpegnoFormScreen({
    required this.clubId,
    this.impegno,
    this.giornoIniziale,
    this.gruppoIniziale,
    super.key,
  });

  final String clubId;
  final Impegno? impegno;
  final DateTime? giornoIniziale;
  final String? gruppoIniziale;

  @override
  ConsumerState<ImpegnoFormScreen> createState() => _ImpegnoFormScreenState();
}

class _ImpegnoFormScreenState extends ConsumerState<ImpegnoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _luogo;
  late final TextEditingController _note;
  late final TextEditingController _dalTesto;
  late final TextEditingController _alTesto;
  late TipoImpegno _tipo;
  late DateTime _dal;
  late DateTime _al;
  String? _gruppoId;

  bool _salvando = false;
  String? _errore;

  bool get _modifica => widget.impegno != null;

  @override
  void initState() {
    super.initState();
    final i = widget.impegno;
    _tipo = i?.tipo ?? TipoImpegno.collegiale;
    _nome = TextEditingController(text: i?.nome ?? '');
    _luogo = TextEditingController(text: i?.luogo ?? '');
    _note = TextEditingController(text: i?.note ?? '');
    _dal = soloData(i?.dal ?? widget.giornoIniziale ?? DateTime.now());
    _al = soloData(i?.al ?? _dal);
    _dalTesto = TextEditingController(text: _formatta(_dal));
    _alTesto = TextEditingController(text: _formatta(_al));
    _gruppoId = i != null ? i.gruppoId : widget.gruppoIniziale;
  }

  @override
  void dispose() {
    _nome.dispose();
    _luogo.dispose();
    _note.dispose();
    _dalTesto.dispose();
    _alTesto.dispose();
    super.dispose();
  }

  String _formatta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _scegli({required bool inizio}) async {
    final scelta = await showDatePicker(
      context: context,
      initialDate: inizio ? _dal : _al,
      firstDate: inizio ? DateTime(DateTime.now().year - 2) : _dal,
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (scelta == null) return;
    setState(() {
      if (inizio) {
        // L'ultimo giorno segue il primo, con la stessa durata.
        final durata = giorniTra(_dal, _al);
        _dal = soloData(scelta);
        _al = aggiungiGiorni(_dal, durata);
      } else {
        _al = soloData(scelta);
      }
      _dalTesto.text = _formatta(_dal);
      _alTesto.text = _formatta(_al);
    });
  }

  Future<void> _salva() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _errore = null;
    });
    final repository = ref.read(impegniRepositoryProvider);
    try {
      if (_modifica) {
        await repository.aggiorna(
          id: widget.impegno!.id,
          gruppoId: _gruppoId,
          tipo: _tipo,
          dal: _dal,
          al: _al,
          nome: _nome.text,
          luogo: _luogo.text,
          note: _note.text,
        );
      } else {
        await repository.crea(
          clubId: widget.clubId,
          gruppoId: _gruppoId,
          tipo: _tipo,
          dal: _dal,
          al: _al,
          nome: _nome.text,
          luogo: _luogo.text,
          note: _note.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _elimina() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text('Eliminare «${widget.impegno!.titolo}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(dialogo).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    try {
      await ref.read(impegniRepositoryProvider).elimina(widget.impegno!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    }
  }

  String get _esempioNome => switch (_tipo) {
    TipoImpegno.collegiale => 'es. Collegiale a Lignano',
    TipoImpegno.trasferta => 'es. Trasferta a Napoli',
    TipoImpegno.riposo => 'es. Vacanze di Natale, piscina chiusa',
    TipoImpegno.torneo => 'es. Torneo di Pasqua',
    TipoImpegno.altro => 'es. Visite mediche',
  };

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final giorni = giorniTra(_dal, _al) + 1;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_modifica ? 'Modifica impegno' : 'Nuovo impegno'),
        actions: [
          if (_modifica)
            TextButton.icon(
              onPressed: _salvando ? null : _elimina,
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
            FormGroup(
              titolo: 'Che cosa',
              campi: [
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final tipo in TipoImpegno.values)
                      TonalChip(
                        etichetta: tipo.etichetta,
                        selezionato: _tipo == tipo,
                        onSelezionato: _salvando
                            ? null
                            : (_) => setState(() => _tipo = tipo),
                      ),
                  ],
                ),
                AppTextField(
                  etichetta: _tipo == TipoImpegno.altro
                      ? 'Nome'
                      : 'Nome (facoltativo)',
                  aiuto: _esempioNome,
                  controller: _nome,
                  validator: (v) =>
                      _tipo == TipoImpegno.altro &&
                          (v == null || v.trim().isEmpty)
                      ? 'Scrivi che cos\'è'
                      : (v != null && v.trim().length > 80)
                      ? 'Al massimo 80 caratteri'
                      : null,
                ),
              ],
            ),
            FormGroup(
              titolo: 'Quando',
              campi: [
                AppTextField(
                  etichetta: 'Dal',
                  controller: _dalTesto,
                  readOnly: true,
                  onTap: () => _scegli(inizio: true),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                AppTextField(
                  etichetta: 'Al',
                  controller: _alTesto,
                  aiuto: giorni == 1 ? 'Un giorno' : '$giorni giorni',
                  readOnly: true,
                  onTap: () => _scegli(inizio: false),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Per chi e dove',
              campi: [
                AppSelect<String?>(
                  etichetta: 'Squadra',
                  value: _gruppoId,
                  hint: 'Tutto il club',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tutto il club'),
                    ),
                    for (final g in gruppi)
                      DropdownMenuItem(value: g.id, child: Text(g.nome)),
                    if (_gruppoId != null &&
                        !gruppi.any((g) => g.id == _gruppoId))
                      DropdownMenuItem(
                        value: _gruppoId,
                        child: const Text('Squadra non trovata'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _gruppoId = v),
                ),
                AppTextField(
                  etichetta: 'Luogo (facoltativo)',
                  controller: _luogo,
                ),
              ],
            ),
            FormGroup(
              titolo: 'Note',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Note (facoltativo)',
                  aiuto: 'Le vedono anche gli atleti.',
                  controller: _note,
                  maxLines: 3,
                ),
              ],
            ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Salva',
              isLoading: _salvando,
              onPressed: _salvando ? null : _salva,
            ),
          ],
        ),
      ),
    );
  }
}
