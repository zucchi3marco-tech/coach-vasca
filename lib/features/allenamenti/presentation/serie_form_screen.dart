import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';
import '../data/serie_repository.dart';
import '../domain/serie.dart';
import 'avviso_seduta_aperta.dart';
import 'per_chi_serie.dart';
import 'serie_labels.dart';

// "C" (zona storica prima dello split in C1/C2/C3) non e' piu' tra le
// scelte proposte: resta pero' un valore valido dell'enum, quindi se una
// serie gia' salvata la usa va comunque rappresentabile (vedi
// _voceZonaCorrente sotto, altrimenti DropdownButtonFormField va in
// assert perche' il valore attuale non e' tra gli item).
const _zoneDisponibili = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'C3', 'D'];

class SerieFormScreen extends ConsumerStatefulWidget {
  const SerieFormScreen({
    required this.allenamentoId,
    required this.ordineSuccessivo,
    this.serie,
    this.atleti = const [],
    super.key,
  });

  final String allenamentoId;
  final int ordineSuccessivo;
  final Serie? serie;

  /// Gli atleti del gruppo, per "solo alcuni" e "tutti tranne" (vedi
  /// `atletiDellAllenamento`).
  final List<Atleta> atleti;

  @override
  ConsumerState<SerieFormScreen> createState() => _SerieFormScreenState();
}

class _SerieFormScreenState extends ConsumerState<SerieFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ripeteController;
  late final TextEditingController _distanzaController;
  late final TextEditingController _durataController;
  late final TextEditingController _passoController;
  late final TextEditingController _recuperoController;
  late final TextEditingController _ripartenzaController;
  late final TextEditingController _attrezzaturaController;
  late final TextEditingController _noteController;

  late String _blocco;
  late String _stile;
  late String _esecuzione;
  String? _zona;
  late bool _aTempo;

  /// Per chi è: 'tutti' | un ruolo (`nomiGruppoRuolo`) | 'solo' | 'tranne'.
  late String _perChi;
  late Set<String> _atletiScelti;

  /// Il ruolo di una serie "Movimento tranne Rossi" scritta a testo: il
  /// modulo mostra solo gli esclusi e lo lascia com'è.
  String? _ruoloTranne;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.serie != null;

  @override
  void initState() {
    super.initState();
    final s = widget.serie;
    _ripeteController = TextEditingController(
      text: (s?.ripetute ?? 1).toString(),
    );
    _aTempo = s?.aTempo ?? false;
    _distanzaController = TextEditingController(
      text: s?.distanzaM?.toString() ?? '',
    );
    _durataController = TextEditingController(
      text: s?.durataS == null ? '' : formatDurataMmSs(s!.durataS!),
    );
    final passo = s?.passoObiettivoS;
    _passoController = TextEditingController(
      text: passo == null ? '' : formatPaceSeconds(passo),
    );
    _recuperoController = TextEditingController(
      text: s?.recuperoS?.toString() ?? '',
    );
    final ripartenza = s?.ripartenzaS;
    _ripartenzaController = TextEditingController(
      text: ripartenza == null ? '' : formatPaceSeconds(ripartenza),
    );
    _attrezzaturaController = TextEditingController(
      text: s?.attrezzatura ?? '',
    );
    _noteController = TextEditingController(text: s?.note ?? '');
    _blocco = s?.blocco ?? 'principale';
    _stile = s?.stile ?? 'libero';
    _esecuzione = s?.esecuzione ?? 'nuoto';
    _zona = s?.zona;
    final d = s?.destinatari ?? Destinatari.tutti;
    _perChi = d.soloAtleti.isNotEmpty
        ? 'solo'
        : d.tranneAtleti.isNotEmpty
        ? 'tranne'
        : (d.ruolo ?? 'tutti');
    _atletiScelti = {...d.soloAtleti, ...d.tranneAtleti};
    _ruoloTranne = d.tranneAtleti.isNotEmpty ? d.ruolo : null;
  }

  @override
  void dispose() {
    _ripeteController.dispose();
    _distanzaController.dispose();
    _durataController.dispose();
    _passoController.dispose();
    _recuperoController.dispose();
    _ripartenzaController.dispose();
    _attrezzaturaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_perChi == 'solo' || _perChi == 'tranne') && _atletiScelti.isEmpty) {
      setState(() => _errorMessage = 'Scegli almeno un atleta in "Per chi".');
      return;
    }
    // Cambiando una serie: un collega ha cambiato la seduta intanto?
    // (Aggiungerne una non toglie niente a nessuno.)
    if (_isEditing && !await _puoSalvare()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(serieRepositoryProvider);
    // L'ordine non si compila piu' a mano: resta quello gia' assegnato in
    // modifica, o si accoda in fondo in creazione (si riordina poi con
    // il trascinamento nell'elenco).
    final ordine = widget.serie?.ordine ?? widget.ordineSuccessivo;
    final ripetute = int.parse(_ripeteController.text.trim());
    final distanzaM = _aTempo
        ? null
        : int.parse(_distanzaController.text.trim());
    final durataS = _aTempo
        ? parsePaceMmSs(_durataController.text)?.round()
        : null;
    final passoObiettivoS = parsePaceMmSs(_passoController.text);
    final recuperoS = int.tryParse(_recuperoController.text.trim());
    final ripartenzaS = parsePaceMmSs(_ripartenzaController.text);
    final attrezzatura = _attrezzaturaController.text.trim();
    final note = _noteController.text.trim();

    try {
      if (_isEditing) {
        await repository.updateSerie(
          id: widget.serie!.id,
          ordine: ordine,
          blocco: _blocco,
          ripetute: ripetute,
          distanzaM: distanzaM,
          durataS: durataS,
          stile: _stile,
          esecuzione: _esecuzione,
          zona: _zona,
          passoObiettivoS: passoObiettivoS,
          recuperoS: recuperoS,
          ripartenzaS: ripartenzaS,
          attrezzatura: attrezzatura.isEmpty ? null : attrezzatura,
          note: note.isEmpty ? null : note,
          destinatari: _destinatari,
        );
      } else {
        await repository.createSerie(
          allenamentoId: widget.allenamentoId,
          ordine: ordine,
          blocco: _blocco,
          ripetute: ripetute,
          distanzaM: distanzaM,
          durataS: durataS,
          stile: _stile,
          esecuzione: _esecuzione,
          zona: _zona,
          passoObiettivoS: passoObiettivoS,
          recuperoS: recuperoS,
          ripartenzaS: ripartenzaS,
          attrezzatura: attrezzatura.isEmpty ? null : attrezzatura,
          note: note.isEmpty ? null : note,
          destinatari: _destinatari,
        );
      }
      unawaited(sedutaSalvata(ref, widget.allenamentoId));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = messaggioErrore(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Vedi [controllaPrimaDiSalvare]: «Vedi la sua versione» chiude il
  /// modulo senza salvare.
  Future<bool> _puoSalvare() async {
    final esito = await controllaPrimaDiSalvare(
      context,
      ref,
      allenamentoId: widget.allenamentoId,
      clubId: widget.serie!.clubId,
    );
    if (esito == false && mounted) Navigator.of(context).pop(false);
    return esito == true;
  }

  Destinatari get _destinatari => switch (_perChi) {
    final ruolo when nomiGruppoRuolo.containsKey(ruolo) => Destinatari(
      ruolo: ruolo,
    ),
    'solo' => Destinatari(soloAtleti: _atletiScelti.toList()),
    'tranne' => Destinatari(
      ruolo: _ruoloTranne,
      tranneAtleti: _atletiScelti.toList(),
    ),
    _ => Destinatari.tutti,
  };

  String get _riassuntoPerChi =>
      labelPerChi(_destinatari, widget.atleti) ?? 'Tutto il gruppo';

  /// Per chi è la serie: si tocca di rado, quindi chiuso con il riassunto
  /// (aperto se la serie è già per qualcuno in particolare).
  Widget _gruppoPerChi(BuildContext context) {
    final pallanuoto =
        widget.atleti.any((a) => a.sport == 'pallanuoto') ||
        nomiGruppoRuolo.containsKey(_perChi);
    final scelte = [
      ('tutti', 'Tutto il gruppo'),
      if (pallanuoto) ...[
        ('portiere', 'Solo i portieri'),
        ('movimento', 'Solo i giocatori di movimento'),
        ('centroboa', 'Solo i centroboa'),
        ('marcatore', 'Solo i marcatori'),
        ('esterno', 'Solo gli esterni'),
      ],
      ('solo', 'Solo alcuni atleti'),
      ('tranne', 'Tutti tranne alcuni'),
    ];
    final conAtleti = _perChi == 'solo' || _perChi == 'tranne';
    return FormGroupComprimibile(
      titolo: 'Per chi',
      riassunto: _riassuntoPerChi,
      inizialmenteAperto: _perChi != 'tutti',
      campi: [
        AppSelect<String>(
          etichetta: 'Chi la fa',
          value: _perChi,
          items: [
            for (final (valore, etichetta) in scelte)
              DropdownMenuItem(value: valore, child: Text(etichetta)),
          ],
          onChanged: (value) => setState(() => _perChi = value ?? 'tutti'),
        ),
        if (conAtleti)
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final a in widget.atleti)
                TonalChip(
                  etichetta: nomeBreve(a, widget.atleti),
                  selezionato: _atletiScelti.contains(a.id),
                  onSelezionato: (scelto) => setState(() {
                    if (scelto) {
                      _atletiScelti.add(a.id);
                    } else {
                      _atletiScelti.remove(a.id);
                    }
                  }),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _elimina() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la serie?'),
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
      if (!await _puoSalvare()) return;
      await ref.read(serieRepositoryProvider).deleteSerie(widget.serie!.id);
      unawaited(sedutaSalvata(ref, widget.allenamentoId));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  DropdownMenuItem<String> _voceZona(BuildContext context, String sigla) {
    final colori = context.colori;
    return DropdownMenuItem(
      value: sigla,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: context.dominio.colorePerZona(
                sigla,
                rispetto: colori.linea,
              ),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(sigla),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica serie' : 'Nuova serie'),
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
              titolo: 'Tipo di serie',
              campi: [
                AppSelect<String>(
                  etichetta: 'Blocco',
                  value: _blocco,
                  items: const [
                    DropdownMenuItem(
                      value: 'riscaldamento',
                      child: Text('Riscaldamento'),
                    ),
                    DropdownMenuItem(
                      value: 'principale',
                      child: Text('Principale'),
                    ),
                    DropdownMenuItem(
                      value: 'defaticamento',
                      child: Text('Defaticamento'),
                    ),
                    DropdownMenuItem(value: 'altro', child: Text('Altro')),
                  ],
                  onChanged: (value) =>
                      setState(() => _blocco = value ?? 'principale'),
                ),
                AppSelect<String>(
                  etichetta: 'Stile',
                  value: _stile,
                  items: const [
                    DropdownMenuItem(value: 'libero', child: Text('Libero')),
                    DropdownMenuItem(value: 'dorso', child: Text('Dorso')),
                    DropdownMenuItem(value: 'rana', child: Text('Rana')),
                    DropdownMenuItem(value: 'delfino', child: Text('Delfino')),
                    DropdownMenuItem(value: 'misti', child: Text('Misti')),
                  ],
                  onChanged: (value) =>
                      setState(() => _stile = value ?? 'libero'),
                ),
                AppSelect<String>(
                  etichetta: 'Esecuzione',
                  value: _esecuzione,
                  items: [
                    for (final e in esecuzioniSerie)
                      DropdownMenuItem(
                        value: e,
                        child: Text(
                          e == 'nuoto' ? 'Nuoto completo' : labelEsecuzione(e),
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _esecuzione = value ?? 'nuoto'),
                ),
                AppSelect<String?>(
                  etichetta: 'Zona (facoltativo)',
                  value: _zona,
                  hint: 'Nessuna',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Nessuna')),
                    for (final z in _zoneDisponibili) _voceZona(context, z),
                    // "C" non e' piu' tra le scelte, ma se questa serie la
                    // usa gia' deve restare rappresentabile nel menu.
                    if (_zona == 'C') _voceZona(context, 'C'),
                  ],
                  onChanged: (value) => setState(() => _zona = value),
                ),
              ],
            ),
            _gruppoPerChi(context),
            FormGroup(
              titolo: 'Volume',
              campi: [
                SegmentedButton<bool>(
                  // Senza spunta: la scelta e' gia' evidenziata dal
                  // colore, e la spunta toglieva spazio all'etichetta
                  // che su telefono andava a capo a meta' parola.
                  showSelectedIcon: false,
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
                        etichetta: 'Ripetute',
                        controller: _ripeteController,
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
              titolo: 'Ritmo',
              campi: [
                LayoutBuilder(
                  builder: (context, vincoli) {
                    // Su telefono tre campi affiancati spezzavano le
                    // etichette: due + uno per riga, e "facoltativo"
                    // passa nel testo d'aiuto sotto il campo.
                    final stretto = vincoli.maxWidth < 560;
                    String? validaMmSs(String? v) =>
                        (v != null &&
                            v.trim().isNotEmpty &&
                            parsePaceMmSs(v) == null)
                        ? 'Formato m:ss'
                        : null;
                    final passo = AppTextField(
                      etichetta: stretto
                          ? 'Passo /100m'
                          : 'Passo /100m (facoltativo)',
                      controller: _passoController,
                      aiuto: stretto ? 'm:ss, facoltativo' : 'm:ss',
                      validator: validaMmSs,
                    );
                    final recupero = AppTextField(
                      etichetta: stretto
                          ? 'Recupero, s'
                          : 'Recupero, s (facoltativo)',
                      controller: _recuperoController,
                      aiuto: stretto ? 'facoltativo' : null,
                      keyboardType: TextInputType.number,
                    );
                    final ripartenza = AppTextField(
                      etichetta: stretto
                          ? 'Ripartenza'
                          : 'Ripartenza (facoltativo)',
                      controller: _ripartenzaController,
                      aiuto: stretto ? 'm:ss, facoltativo' : 'm:ss',
                      validator: validaMmSs,
                    );
                    if (stretto) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: passo),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(child: recupero),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.spazioCampiForm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: ripartenza),
                              const SizedBox(width: AppSpacing.s12),
                              const Spacer(),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: passo),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(child: recupero),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(child: ripartenza),
                      ],
                    );
                  },
                ),
              ],
            ),
            FormGroup(
              titolo: 'Altro',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Attrezzatura (facoltativo)',
                  controller: _attrezzaturaController,
                ),
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
              label: 'Salva serie',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
