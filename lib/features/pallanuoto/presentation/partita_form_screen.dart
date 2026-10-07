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
import '../../club/application/current_club_provider.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/domain/stagione.dart';
import '../../stagioni/presentation/stagione_form_screen.dart';
import '../data/partite_repository.dart';
import '../domain/partita.dart';

class PartitaFormScreen extends ConsumerStatefulWidget {
  const PartitaFormScreen({
    required this.clubId,
    this.partita,
    this.stagione,
    this.dataIniziale,
    super.key,
  });

  final String clubId;
  final Partita? partita;

  /// Stagione dal cui calendario si sta creando la partita: da lei
  /// arrivano il gruppo (nullo = partita di club) e il campionato.
  final Stagione? stagione;

  /// Data suggerita in creazione (il giorno toccato nel calendario).
  final DateTime? dataIniziale;

  @override
  ConsumerState<PartitaFormScreen> createState() => _PartitaFormScreenState();
}

class _PartitaFormScreenState extends ConsumerState<PartitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dataController;
  late final TextEditingController _oraController;
  late final TextEditingController _luogoController;
  late final TextEditingController _squadraCasaController;
  late final TextEditingController _squadraTrasfertaController;
  late final TextEditingController _noteController;
  String? _gruppoId;
  late DateTime _data;
  late int _numeroMaxConvocati;
  late String _dettaglioTiro;
  late bool _tracciaTempo;
  late String _nostraSquadra;
  late String _importanza;

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _clubPrefillFatto = false;

  /// Anteprima di sola lettura: il campionato non si sceglie qui, si
  /// eredita dalla Stagione la cui data comprende quella della partita.
  String? _campionatoAnteprima;

  bool get _isEditing => widget.partita != null;

  @override
  void initState() {
    super.initState();
    final p = widget.partita;
    _oraController = TextEditingController(text: p?.ora ?? '');
    _luogoController = TextEditingController(text: p?.luogo ?? '');
    _squadraCasaController = TextEditingController(text: p?.squadraCasa ?? '');
    _squadraTrasfertaController = TextEditingController(
      text: p?.squadraTrasferta ?? '',
    );
    _noteController = TextEditingController(text: p?.note ?? '');
    _gruppoId = p != null ? p.gruppoId : widget.stagione?.gruppoId;
    _data = p?.data ?? widget.dataIniziale ?? DateTime.now();
    _dataController = TextEditingController(text: _formattaData(_data));
    _numeroMaxConvocati = p?.numeroMaxConvocati ?? 15;
    _dettaglioTiro = p?.dettaglioTiro ?? 'semplice';
    _tracciaTempo = p?.tracciaTempo ?? true;
    _nostraSquadra = p?.nostraSquadra ?? 'casa';
    _importanza = p?.importanza ?? 'media';
    _aggiornaCampionatoAnteprima();
    if (!_isEditing) {
      ref.read(currentClubProvider.future).then((club) {
        if (mounted) _prefillClubSeVuoto(club?.nome);
      });
      // Precompila le impostazioni eventi copiando l'ultima partita della
      // squadra: di fatto funge da default di club senza bisogno di uno
      // screen impostazioni separato, restando modificabile qui sotto.
      ref.read(partiteRepositoryProvider).ultimaPerClub(widget.clubId).then((
        ultima,
      ) {
        if (mounted && ultima != null) {
          setState(() {
            _dettaglioTiro = ultima.dettaglioTiro;
            _tracciaTempo = ultima.tracciaTempo;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    _oraController.dispose();
    _luogoController.dispose();
    _squadraCasaController.dispose();
    _squadraTrasfertaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// In creazione, precompila col nome del club il campo del lato che in
  /// quel momento e' "la mia squadra" (casa o trasferta) — se il coach
  /// cambia lato prima che la risposta del club arrivi, si precompila
  /// comunque quello giusto.
  void _prefillClubSeVuoto(String? nomeClub) {
    if (_clubPrefillFatto || _isEditing || nomeClub == null) return;
    if (_nostraSquadra == 'casa') {
      _squadraCasaController.text = nomeClub;
    } else {
      _squadraTrasfertaController.text = nomeClub;
    }
    _clubPrefillFatto = true;
  }

  /// Cambiare "la mia squadra" scambia i due nomi gia' inseriti, invece di
  /// svuotarli: se casa/trasferta erano gia' compilati, restano entrambi
  /// corretti dopo lo scambio di lato.
  void _cambiaNostraSquadra(String nuovo) {
    if (nuovo == _nostraSquadra) return;
    setState(() {
      _nostraSquadra = nuovo;
      final testoCasa = _squadraCasaController.text;
      _squadraCasaController.text = _squadraTrasfertaController.text;
      _squadraTrasfertaController.text = testoCasa;
    });
  }

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  Future<void> _pickData() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (selected != null) {
      setState(() {
        _data = selected;
        _dataController.text = _formattaData(selected);
      });
      _aggiornaCampionatoAnteprima();
    }
  }

  Future<void> _aggiornaCampionatoAnteprima() async {
    final campionato = await _campionatoPerData(_data);
    if (mounted) setState(() => _campionatoAnteprima = campionato);
  }

  Future<void> _pickOra() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selected != null) {
      setState(
        () => _oraController.text =
            '${selected.hour.toString().padLeft(2, '0')}:'
            '${selected.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  /// Il campionato non si sceglie più partita per partita: si eredita
  /// dalla Stagione la cui data_inizio/data_fine comprende la data della
  /// partita (FASE 10, punto 1). Nessuna corrispondenza -> null, come
  /// prima quando il campo restava vuoto.
  Future<String?> _campionatoPerData(DateTime data) async {
    final daStagione = widget.stagione;
    if (daStagione != null &&
        !data.isBefore(daStagione.dataInizio) &&
        !data.isAfter(daStagione.dataFine) &&
        daStagione.gruppoId == _gruppoId) {
      return daStagione.campionato;
    }
    final stagioni = await ref.read(stagioniListProvider(widget.clubId).future);
    return campionatoPerData(stagioni, data, _gruppoId);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(partiteRepositoryProvider);
    // Regola FIN: la squadra di casa gioca in bianco, gli ospiti in blu —
    // il colore della nostra calottina discende quindi da "la mia
    // squadra", non e' piu' una scelta libera.
    final coloreCalottina = _nostraSquadra == 'casa' ? 'bianca' : 'blu';
    try {
      final campionato = await _campionatoPerData(_data);
      if (_isEditing) {
        await repository.updatePartita(
          id: widget.partita!.id,
          gruppoId: _gruppoId,
          data: _data,
          ora: _oraController.text.trim(),
          luogo: _luogoController.text.trim(),
          campionato: campionato,
          coloreCalottina: coloreCalottina,
          squadraCasa: _squadraCasaController.text.trim(),
          squadraTrasferta: _squadraTrasfertaController.text.trim(),
          numeroMaxConvocati: _numeroMaxConvocati,
          note: _noteController.text.trim(),
          dettaglioTiro: _dettaglioTiro,
          tracciaTempo: _tracciaTempo,
          modalitaSuperiorita: 'singolo',
          nostraSquadra: _nostraSquadra,
          importanza: _importanza,
        );
      } else {
        await repository.createPartita(
          clubId: widget.clubId,
          gruppoId: _gruppoId,
          data: _data,
          ora: _oraController.text.trim(),
          luogo: _luogoController.text.trim(),
          campionato: campionato,
          coloreCalottina: coloreCalottina,
          squadraCasa: _squadraCasaController.text.trim(),
          squadraTrasferta: _squadraTrasfertaController.text.trim(),
          numeroMaxConvocati: _numeroMaxConvocati,
          note: _noteController.text.trim(),
          dettaglioTiro: _dettaglioTiro,
          tracciaTempo: _tracciaTempo,
          modalitaSuperiorita: 'singolo',
          nostraSquadra: _nostraSquadra,
          importanza: _importanza,
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
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la partita?'),
        content: const Text('Verrà eliminata anche la relativa distinta.'),
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
          .read(partiteRepositoryProvider)
          .deletePartita(widget.partita!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica partita' : 'Nuova partita'),
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
            FormGroup(
              titolo: 'Quando',
              campi: [
                AppTextField(
                  etichetta: 'Data',
                  controller: _dataController,
                  readOnly: true,
                  onTap: _pickData,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                AppTextField(
                  etichetta: 'Ora (facoltativo)',
                  controller: _oraController,
                  readOnly: true,
                  onTap: _pickOra,
                  suffixIcon: const Icon(Icons.access_time),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Le squadre',
              campi: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Noi giochiamo',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<String>(
                      // Senza spunta: la scelta e' gia' evidenziata dal
                      // colore, e la spunta toglieva spazio all'etichetta
                      // che su telefono andava a capo a meta' parola.
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'casa', label: Text('In casa')),
                        ButtonSegment(
                          value: 'trasferta',
                          label: Text('In trasferta'),
                        ),
                      ],
                      selected: {_nostraSquadra},
                      onSelectionChanged: (s) => _cambiaNostraSquadra(s.first),
                    ),
                  ],
                ),
                AppTextField(
                  etichetta: 'Squadra casa · calottina bianca',
                  controller: _squadraCasaController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                AppTextField(
                  etichetta: 'Squadra trasferta · calottina blu',
                  controller: _squadraTrasfertaController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
              ],
            ),
            FormGroup(
              titolo: 'Dove e per chi',
              campi: [
                AppTextField(
                  etichetta: 'Luogo (facoltativo)',
                  controller: _luogoController,
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
                  onChanged: (value) {
                    setState(() => _gruppoId = value);
                    _aggiornaCampionatoAnteprima();
                  },
                ),
                if (_campionatoAnteprima != null &&
                    _campionatoAnteprima!.isNotEmpty)
                  Text(
                    'Campionato: $_campionatoAnteprima (dalla stagione in '
                    'corso a questa data)',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nessuna stagione copre questa data: il campionato '
                        'non verrà compilato.',
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StagioneFormScreen(clubId: widget.clubId),
                            ),
                          );
                          _aggiornaCampionatoAnteprima();
                        },
                        child: const Text('Crea una stagione per questa data'),
                      ),
                    ],
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Importanza',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'bassa', label: Text('Bassa')),
                        ButtonSegment(value: 'media', label: Text('Media')),
                        ButtonSegment(value: 'alta', label: Text('Alta')),
                      ],
                      selected: {_importanza},
                      onSelectionChanged: (s) =>
                          setState(() => _importanza = s.first),
                    ),
                  ],
                ),
              ],
            ),
            // Impostazioni che si toccano di rado: chiuse, con il
            // riassunto delle scelte attuali.
            FormGroupComprimibile(
              titolo: 'Distinta e dal vivo',
              riassunto: [
                'max $_numeroMaxConvocati convocati',
                _dettaglioTiro == 'dettagliato'
                    ? 'tiro dettagliato'
                    : 'tiro semplice',
                _tracciaTempo ? 'tempo tracciato' : 'tempo non tracciato',
              ].join(' · '),
              campi: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Numero massimo convocati',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 14, label: Text('14')),
                        ButtonSegment(value: 15, label: Text('15')),
                      ],
                      selected: {_numeroMaxConvocati},
                      onSelectionChanged: (selezione) =>
                          setState(() => _numeroMaxConvocati = selezione.first),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dettaglio tiro',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: 'semplice',
                          label: Text('Semplice'),
                        ),
                        ButtonSegment(
                          value: 'dettagliato',
                          label: Text('Dettagliato'),
                        ),
                      ],
                      selected: {_dettaglioTiro},
                      onSelectionChanged: (s) =>
                          setState(() => _dettaglioTiro = s.first),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Semplice: solo Gol/Non gol. Dettagliato: distingue '
                      'anche un tiro parato da uno andato a vuoto (palo o '
                      'fuori).',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Traccia il tempo di gioco'),
                  subtitle: const Text(
                    'Chiede il numero di tempo (1-4) per ogni evento',
                  ),
                  value: _tracciaTempo,
                  onChanged: (v) => setState(() => _tracciaTempo = v),
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
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: 'Salva partita',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
