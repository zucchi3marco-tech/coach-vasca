import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/attesa_ai_hint.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../application/corsie_service.dart';
import '../application/settimana_ai_providers.dart';
import '../data/generazione_ai_repository.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/focus_lavoro.dart';
import '../domain/parametri_generazione.dart';
import '../domain/scheda_generata.dart';
import '../domain/settimana_generata.dart';

const _tipiSettimana = ['carico', 'scarico', 'gara', 'recupero', 'test'];
const _abbreviazioniGiorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
const _nomiGiorni = [
  'Lunedì',
  'Martedì',
  'Mercoledì',
  'Giovedì',
  'Venerdì',
  'Sabato',
  'Domenica',
];
const _attrezzaturaLavoroCentraleDisponibile = [
  'pull',
  'palette',
  'boccaglio',
  'pinne',
];

String _capitalizza(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _etichettaAttrezzo(String a) => switch (a) {
  'pull' => 'Pull',
  'palette' => 'Palette',
  'boccaglio' => 'Boccaglio',
  'pinne' => 'Pinne',
  _ => _capitalizza(a),
};

/// Pianifica una settimana intera (FASE 10, punto 5): prima uno scheletro
/// leggero (codice, volume) via `genera-settimana`, poi il dettaglio delle
/// serie di ogni seduta via `genera-allenamento` — stessi passi/corsie
/// calcolati una sola volta per il gruppo.
///
/// Disponibile solo se il gruppo selezionato ha almeno 60 giorni di
/// allenamenti già programmati (`gateSettimanaAiProvider`): la
/// generazione analizza quello storico per imitare lo stile del coach,
/// non parte da zero.
class GeneraSettimanaFormScreen extends ConsumerStatefulWidget {
  const GeneraSettimanaFormScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<GeneraSettimanaFormScreen> createState() =>
      _GeneraSettimanaFormScreenState();
}

class _GeneraSettimanaFormScreenState
    extends ConsumerState<GeneraSettimanaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vincoliController = TextEditingController();

  late DateTime _dataInizio = DateTime.now();
  late final TextEditingController _dataInizioController =
      TextEditingController(text: _formattaData(_dataInizio));
  String? _tipoSettimana;
  // Offset (0-6) da _dataInizio dei giorni scelti dal coach, invece di un
  // numero di sedute lasciato decidere all'AI: le corsie in piscina sono
  // spesso fisse per giorno, il coach sa già quando si allena.
  final List<int> _giorniSelezionati = [0, 2, 4, 5];
  double _volumeSettimanale = 12000;
  double? _volumeLavoroCentraleSettimanale;
  double _minutiMax = 60;
  int _vascaM = 25;
  final Set<String> _attrezzaturaLavoroCentraleSelezionata = {};
  List<String> _focusPerSeduta = List.filled(4, focusLavoro.first);
  bool _generazioneInCorso = false;
  String? _fasePassaggio;
  String? _erroreGiorni;

  @override
  void dispose() {
    _vincoliController.dispose();
    _dataInizioController.dispose();
    super.dispose();
  }

  void _alternaGiorno(int offset, bool selezionato) {
    setState(() {
      if (selezionato) {
        _giorniSelezionati.add(offset);
      } else {
        _giorniSelezionati.remove(offset);
      }
      _giorniSelezionati.sort();
      final numero = _giorniSelezionati.length;
      if (numero > _focusPerSeduta.length) {
        _focusPerSeduta = [
          ..._focusPerSeduta,
          for (var i = _focusPerSeduta.length; i < numero; i++)
            focusLavoro.first,
        ];
      } else if (numero < _focusPerSeduta.length) {
        _focusPerSeduta = _focusPerSeduta.sublist(0, numero);
      }
      if (_giorniSelezionati.isNotEmpty) _erroreGiorni = null;
    });
  }

  Future<void> _pickDataInizio() async {
    final selezionata = await showDatePicker(
      context: context,
      initialDate: _dataInizio,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (selezionata != null) {
      setState(() {
        _dataInizio = selezionata;
        _dataInizioController.text = _formattaData(selezionata);
      });
    }
  }

  String _etichettaGiornoBreve(int offset) {
    final data = _dataInizio.add(Duration(days: offset));
    return '${_abbreviazioniGiorni[data.weekday - 1]} '
        '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}';
  }

  String _etichettaGiornoCompleta(int offset) {
    final data = _dataInizio.add(Duration(days: offset));
    return '${_nomiGiorni[data.weekday - 1]} '
        '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}';
  }

  Future<void> _conferma(String? gruppoId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_giorniSelezionati.isEmpty) {
      setState(() => _erroreGiorni = 'Scegli almeno un giorno');
      return;
    }

    setState(() {
      _generazioneInCorso = true;
      _fasePassaggio = 'Pianificazione della settimana...';
    });

    final riassunto = ref
        .read(
          gateSettimanaAiProvider((clubId: widget.clubId, gruppoId: gruppoId)),
        )
        .value
        ?.riassunto;

    var corsie = const <CorsiaGenerazione>[];
    try {
      final tuttiGliAtleti = await ref.read(
        atletiListProvider((clubId: widget.clubId, includeInactive: false))
            .future,
      );
      final atletiDelGruppo = gruppoId == null
          ? tuttiGliAtleti
          : tuttiGliAtleti.where((a) => a.gruppoId == gruppoId).toList();
      corsie = await calcolaCorsie(ref, atletiDelGruppo);
    } catch (_) {
      // Le corsie migliorano la generazione, ma non sono indispensabili.
    }

    final Map<String, String> nomiGruppi = {
      for (final g in ref.read(gruppiListProvider(widget.clubId)).value ?? [])
        g.id: g.nome,
    };
    final gruppoLabel = nomiGruppi[gruppoId] ?? 'Tutti gli atleti';
    final vincoliUtente = _vincoliController.text.trim();
    final giorniOrdinati = List<int>.of(_giorniSelezionati)..sort();
    final attrezzaturaCentrale = _attrezzaturaLavoroCentraleSelezionata
        .toList();
    final minutiMax = _minutiMax.round();
    final parametriStorico = {
      'modalita': 'settimana',
      'gruppo': gruppoLabel,
      'volumeSettimanaleMetri': _volumeSettimanale.round(),
    };

    try {
      final settimana = await ref
          .read(generazioneAiRepositoryProvider)
          .generaSettimana(
            ParametriSettimana(
              gruppo: gruppoLabel,
              giorniSettimana: [
                for (final g in giorniOrdinati) _etichettaGiornoCompleta(g),
              ],
              volumeSettimanaleMetri: _volumeSettimanale.round(),
              volumeLavoroCentraleSettimanaleM: _volumeLavoroCentraleSettimanale
                  ?.round(),
              focusPerSeduta: _focusPerSeduta,
              attrezzaturaLavoroCentrale: attrezzaturaCentrale,
              minutiMax: minutiMax,
              vascaM: _vascaM,
              tipoSettimana: _tipoSettimana,
              vincoli: vincoliUtente.isEmpty ? null : vincoliUtente,
              corsie: corsie,
              riassuntoProgrammazione: riassunto?.toMap(),
            ),
          );

      // Lo storico e' un di piu' per rivedere/migliorare i prompt: un suo
      // fallimento non deve mai bloccare una generazione riuscita. Una sola
      // voce per l'intera settimana, non una per seduta.
      String? generazioneId;
      try {
        generazioneId = await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.clubId,
              parametri: {
                ...parametriStorico,
                'sedute': settimana.sedute.length,
              },
              esito: 'successo',
              scheda: {
                'sedute': [
                  for (final s in settimana.sedute)
                    {'codice': s.codice, 'volumeMetri': s.volumeMetri},
                ],
              },
            );
      } catch (_) {}

      final volumeSkeletroTotale = settimana.sedute.fold<int>(
        0,
        (t, s) => t + s.volumeMetri,
      );

      final sedute = <SedutaConScheda>[];
      for (var i = 0; i < settimana.sedute.length; i++) {
        final seduta = settimana.sedute[i];
        final focusSeduta = i < _focusPerSeduta.length
            ? _focusPerSeduta[i]
            : _focusPerSeduta.last;
        if (mounted) {
          setState(
            () => _fasePassaggio =
                'Dettaglio seduta ${i + 1} di ${settimana.sedute.length}...',
          );
        }
        final vincoliGiorno = [
          'Enfasi di questa seduta: ${seduta.codice}.',
          if (vincoliUtente.isNotEmpty) vincoliUtente,
        ].join(' ');
        final volumeLavoroCentraleSeduta =
            _volumeLavoroCentraleSettimanale != null && volumeSkeletroTotale > 0
            ? (_volumeLavoroCentraleSettimanale! *
                      seduta.volumeMetri /
                      volumeSkeletroTotale)
                  .round()
            : null;
        final scheda = await ref
            .read(generazioneAiRepositoryProvider)
            .generaAllenamento(
              ParametriGenerazione(
                gruppo: gruppoLabel,
                volumeMetri: seduta.volumeMetri,
                volumeLavoroCentraleM: volumeLavoroCentraleSeduta,
                focus: [focusSeduta],
                attrezzaturaLavoroCentrale: attrezzaturaCentrale,
                minutiMax: minutiMax,
                vascaM: _vascaM,
                regimiAmmessi: const [
                  'A1',
                  'A2',
                  'B1',
                  'B2',
                  'C1',
                  'C2',
                  'C3',
                  'D',
                ],
                vincoli: vincoliGiorno,
                corsie: corsie,
              ),
            );
        final offset = i < giorniOrdinati.length
            ? giorniOrdinati[i]
            : giorniOrdinati.last;
        sedute.add(
          SedutaConScheda(
            seduta: seduta,
            scheda: scheda,
            data: _dataInizio.add(Duration(days: offset)),
            focus: focusSeduta,
            volumeLavoroCentraleM: volumeLavoroCentraleSeduta,
          ),
        );
      }

      if (!mounted) return;
      final salvata = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _RevisioneSettimanaScreen(
            clubId: widget.clubId,
            gruppoId: gruppoId,
            gruppoLabel: gruppoLabel,
            corsie: corsie,
            vincoliUtente: vincoliUtente,
            attrezzaturaLavoroCentrale: attrezzaturaCentrale,
            minutiMax: minutiMax,
            vascaM: _vascaM,
            generazioneId: generazioneId,
            sedute: sedute,
          ),
        ),
      );
      if (salvata == true && mounted) Navigator.of(context).pop(true);
    } catch (e) {
      try {
        await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.clubId,
              parametri: parametriStorico,
              esito: 'errore',
              messaggioErrore: e.toString(),
            );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella generazione: ${messaggioErrore(e)}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Riprova',
            onPressed: () => _conferma(gruppoId),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generazioneInCorso = false;
          _fasePassaggio = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gruppoId = ref.watch(selezioneGruppoProvider)?.gruppoId;
    final gateAsync = ref.watch(
      gateSettimanaAiProvider((clubId: widget.clubId, gruppoId: gruppoId)),
    );

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Genera settimana con AI')),
      body: gateAsync.when(
        data: (gate) => gate.sbloccato
            ? _corpoForm(context, gruppoId)
            : EmptyState(
                icona: Icons.calendar_month_outlined,
                titolo: 'Servono più dati storici',
                descrizione:
                    'La pianificazione settimanale AI impara dallo stile di '
                    'programmazione del gruppo: servono almeno 60 giorni di '
                    'allenamenti già registrati, con le loro serie.',
                azionePrincipale: 'Torna ad Allenamenti',
                onAzionePrincipale: () => Navigator.of(context).pop(),
              ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 4),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio:
                'Non è stato possibile controllare lo storico del '
                'gruppo.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }

  Widget _corpoForm(BuildContext context, String? gruppoId) {
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final nomeGruppo =
        gruppi.where((g) => g.id == gruppoId).firstOrNull?.nome ??
        'Tutti gli atleti';
    final colori = context.colori;
    final volumeLavoroCentraleClampato = (_volumeLavoroCentraleSettimanale ?? 0)
        .clamp(0, _volumeSettimanale)
        .toDouble();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pianifica le sedute della settimana, seguendo lo stile con '
            'cui il gruppo è già stato allenato. Il dettaglio di ogni '
            'seduta si genera subito dopo lo scheletro: la revisione '
            'richiede qualche secondo in più di una singola generazione.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          FormGroup(
            titolo: 'Parametri',
            campi: [
              AppTextField(
                etichetta: 'Data di inizio',
                controller: _dataInizioController,
                readOnly: true,
                onTap: _pickDataInizio,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gruppo',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    nomeGruppo,
                    style: AppTypography.corpo.copyWith(color: colori.testo),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSelect<String?>(
                    etichetta: 'Tipo di settimana (facoltativo)',
                    value: _tipoSettimana,
                    hint: 'Nessuno',
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Nessuno'),
                      ),
                      for (final t in _tipiSettimana)
                        DropdownMenuItem(
                          value: t,
                          child: Text(_capitalizza(t)),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _tipoSettimana = value),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Regola volume e intensità della settimana generata: '
                    'una settimana di scarico avrà volumi più bassi di '
                    'una di carico, una di gara punterà su freschezza e '
                    'ritmo gara.',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giorni della settimana',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (var offset = 0; offset < 7; offset++)
                        TonalChip(
                          etichetta: _etichettaGiornoBreve(offset),
                          selezionato: _giorniSelezionati.contains(offset),
                          onSelezionato: (selezionato) =>
                              _alternaGiorno(offset, selezionato),
                        ),
                    ],
                  ),
                  if (_erroreGiorni != null) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      _erroreGiorni!,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.rosso,
                      ),
                    ),
                  ],
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volume settimanale: ${_volumeSettimanale.round()} m',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  Slider(
                    value: _volumeSettimanale,
                    min: 2000,
                    max: 20000,
                    divisions: 36,
                    label: '${_volumeSettimanale.round()} m',
                    onChanged: (value) => setState(() {
                      _volumeSettimanale = value;
                      if ((_volumeLavoroCentraleSettimanale ?? 0) > value) {
                        _volumeLavoroCentraleSettimanale = value;
                      }
                    }),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _volumeLavoroCentraleSettimanale == null
                        ? 'Volume lavoro centrale settimanale: decide l\'AI'
                        : 'Volume lavoro centrale settimanale: '
                              '${volumeLavoroCentraleClampato.round()} m',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  Slider(
                    value: volumeLavoroCentraleClampato,
                    min: 0,
                    max: _volumeSettimanale,
                    divisions: (_volumeSettimanale / 200).round().clamp(1, 999),
                    label: '${volumeLavoroCentraleClampato.round()} m',
                    onChanged: (value) => setState(
                      () => _volumeLavoroCentraleSettimanale = value,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Minuti max di lavoro: ${_minutiMax.round()} min',
                          style: AppTypography.etichetta.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                      ),
                      const PulsanteSpiegazione(
                        titolo: 'Minuti max di lavoro',
                        spiegazione:
                            'Vale per ogni seduta della settimana: nessuna '
                            'deve superare questo tempo, stimato su nuoto + '
                            "recuperi dell'atleta più lento del gruppo. La "
                            'stima non tiene conto dei tempi di virata né '
                            'della lunghezza della vasca.',
                      ),
                    ],
                  ),
                  Slider(
                    value: _minutiMax,
                    min: 20,
                    max: 180,
                    divisions: 32,
                    label: '${_minutiMax.round()} min',
                    onChanged: (value) => setState(() => _minutiMax = value),
                  ),
                ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attrezzi lavoro centrale',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: AppSpacing.s8,
                    children: [
                      for (final a in _attrezzaturaLavoroCentraleDisponibile)
                        TonalChip(
                          etichetta: _etichettaAttrezzo(a),
                          selezionato: _attrezzaturaLavoroCentraleSelezionata
                              .contains(a),
                          onSelezionato: (selezionato) => setState(() {
                            if (selezionato) {
                              _attrezzaturaLavoroCentraleSelezionata.add(a);
                            } else {
                              _attrezzaturaLavoroCentraleSelezionata.remove(a);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus di ogni seduta',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  for (var i = 0; i < _focusPerSeduta.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: AppSelect<String>(
                        etichetta: i < _giorniSelezionati.length
                            ? _etichettaGiornoBreve(_giorniSelezionati[i])
                            : 'Seduta ${i + 1}',
                        value: _focusPerSeduta[i],
                        items: [
                          for (final f in focusLavoro)
                            DropdownMenuItem(
                              value: f,
                              child: Text(etichettaFocusLavoro(f)),
                            ),
                        ],
                        onChanged: (value) => setState(
                          () => _focusPerSeduta[i] = value ?? focusLavoro.first,
                        ),
                      ),
                    ),
                ],
              ),
              AppTextField(
                etichetta: 'Vincoli (facoltativo)',
                controller: _vincoliController,
                maxLines: 3,
                aiuto: 'Es. niente pinne di gomma, riscaldamento breve',
              ),
            ],
          ),
          if (_fasePassaggio != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              _fasePassaggio!,
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          PrimaryButton(
            label: 'Genera settimana',
            isLoading: _generazioneInCorso,
            onPressed: _generazioneInCorso ? null : () => _conferma(gruppoId),
          ),
          if (_generazioneInCorso) const AttesaAiHint(),
        ],
      ),
    );
  }

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';
}

/// Una seduta della settimana proposta, con il dettaglio già generato.
class SedutaConScheda {
  const SedutaConScheda({
    required this.seduta,
    required this.scheda,
    required this.data,
    required this.focus,
    this.volumeLavoroCentraleM,
  });

  final SedutaGenerata seduta;
  final SchedaGenerata scheda;
  final DateTime data;

  /// Il focus usato per generare questa seduta — serve a poterla
  /// rigenerare singolarmente nella revisione, con lo stesso focus.
  final String focus;

  /// La quota di volume lavoro centrale di questa seduta (ripartita
  /// proporzionalmente dal totale settimanale) — riusata se si rigenera
  /// la seduta, così il vincolo resta coerente.
  final int? volumeLavoroCentraleM;
}

class _RevisioneSettimanaScreen extends ConsumerStatefulWidget {
  const _RevisioneSettimanaScreen({
    required this.clubId,
    required this.gruppoId,
    required this.gruppoLabel,
    required this.corsie,
    required this.vincoliUtente,
    required this.attrezzaturaLavoroCentrale,
    required this.minutiMax,
    required this.vascaM,
    this.generazioneId,
    required this.sedute,
  });

  final String clubId;
  final String? gruppoId;
  final String gruppoLabel;
  final List<CorsiaGenerazione> corsie;
  final String vincoliUtente;
  final List<String> attrezzaturaLavoroCentrale;
  final int minutiMax;
  final int vascaM;

  /// Id della voce di storico creata per l'intera settimana (nullo se la
  /// registrazione stessa era fallita): se presente, dopo il primo
  /// salvataggio ci si collega l'allenamento creato.
  final String? generazioneId;
  final List<SedutaConScheda> sedute;

  @override
  ConsumerState<_RevisioneSettimanaScreen> createState() =>
      _RevisioneSettimanaScreenState();
}

class _RevisioneSettimanaScreenState
    extends ConsumerState<_RevisioneSettimanaScreen> {
  late final List<SedutaConScheda> _sedute = List.of(widget.sedute);
  bool _salvataggioInCorso = false;
  int? _rigenerandoIndice;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  String _sottotitoloSerie(SerieGenerata s) {
    final parti = <String>[labelBlocco(s.blocco)];
    if (s.zona != null) parti.add('zona ${s.zona}');
    if (s.recuperoS != null) parti.add("rec ${s.recuperoS}''");
    if (s.attrezzatura != null && s.attrezzatura!.isNotEmpty) {
      parti.add(s.attrezzatura!);
    }
    return parti.join(' · ');
  }

  Future<void> _cambiaData(int indice) async {
    final corrente = _sedute[indice];
    final scelta = await showDatePicker(
      context: context,
      initialDate: corrente.data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (scelta != null) {
      setState(() {
        _sedute[indice] = SedutaConScheda(
          seduta: corrente.seduta,
          scheda: corrente.scheda,
          data: scelta,
          focus: corrente.focus,
          volumeLavoroCentraleM: corrente.volumeLavoroCentraleM,
        );
      });
    }
  }

  Future<void> _rigenera(int indice) async {
    setState(() => _rigenerandoIndice = indice);
    final voce = _sedute[indice];
    try {
      final vincoliGiorno = [
        'Enfasi di questa seduta: ${voce.seduta.codice}.',
        if (widget.vincoliUtente.isNotEmpty) widget.vincoliUtente,
      ].join(' ');
      final nuovaScheda = await ref
          .read(generazioneAiRepositoryProvider)
          .generaAllenamento(
            ParametriGenerazione(
              gruppo: widget.gruppoLabel,
              volumeMetri: voce.seduta.volumeMetri,
              volumeLavoroCentraleM: voce.volumeLavoroCentraleM,
              focus: [voce.focus],
              attrezzaturaLavoroCentrale: widget.attrezzaturaLavoroCentrale,
              minutiMax: widget.minutiMax,
              vascaM: widget.vascaM,
              regimiAmmessi: const [
                'A1',
                'A2',
                'B1',
                'B2',
                'C1',
                'C2',
                'C3',
                'D',
              ],
              vincoli: vincoliGiorno,
              corsie: widget.corsie,
            ),
          );
      if (!mounted) return;
      setState(() {
        _sedute[indice] = SedutaConScheda(
          seduta: voce.seduta,
          scheda: nuovaScheda,
          data: voce.data,
          focus: voce.focus,
          volumeLavoroCentraleM: voce.volumeLavoroCentraleM,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella rigenerazione: ${messaggioErrore(e)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _rigenerandoIndice = null);
    }
  }

  Future<void> _salva() async {
    setState(() => _salvataggioInCorso = true);
    try {
      final allenamentiRepository = ref.read(allenamentiRepositoryProvider);
      final serieRepository = ref.read(serieRepositoryProvider);
      var primoAllenamentoCollegato = false;
      for (final voce in _sedute) {
        final allenamento = await allenamentiRepository.createAllenamento(
          clubId: widget.clubId,
          data: voce.data,
          titolo: voce.scheda.titolo,
          gruppoId: widget.gruppoId,
          note: voce.scheda.note,
        );
        if (!primoAllenamentoCollegato && widget.generazioneId != null) {
          primoAllenamentoCollegato = true;
          try {
            await ref
                .read(generazioniAiRepositoryProvider)
                .collegaAllenamento(
                  generazioneId: widget.generazioneId!,
                  allenamentoId: allenamento.id,
                );
          } catch (_) {}
        }
        for (final s in voce.scheda.serie) {
          final risolto = risolviRipartenza(s.ripartenzePerCorsia, s.note);
          await serieRepository.createSerie(
            allenamentoId: allenamento.id,
            ordine: s.ordine,
            blocco: s.blocco,
            ripetute: s.ripetute,
            distanzaM: s.distanzaM,
            stile: s.stile,
            esecuzione: s.esecuzione,
            zona: s.zona,
            recuperoS: s.recuperoS,
            ripartenzaS: risolto.ripartenzaS,
            attrezzatura: s.attrezzatura,
            note: risolto.note,
          );
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel salvataggio: ${messaggioErrore(e)}'),
        ),
      );
      setState(() => _salvataggioInCorso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totaleMetri = _sedute.fold<int>(
      0,
      (tot, v) => tot + v.scheda.volumeTotaleM,
    );
    final colori = context.colori;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text('Settimana proposta (${_sedute.length} sedute)'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Totale settimanale: $totaleMetri m',
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.s16),
          for (var i = 0; i < _sedute.length; i++) ...[
            _CardSeduta(
              voce: _sedute[i],
              formattaData: _formattaData,
              sottotitoloSerie: _sottotitoloSerie,
              onCambiaData: () => _cambiaData(i),
              onRigenera: _rigenerandoIndice == null
                  ? () => _rigenera(i)
                  : null,
              rigenerandoQuesta: _rigenerandoIndice == i,
              onRimuovi: _sedute.length > 1
                  ? () => setState(() => _sedute.removeAt(i))
                  : null,
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          PrimaryButton(
            label: 'Salva ${_sedute.length} sedute',
            isLoading: _salvataggioInCorso,
            onPressed: _salvataggioInCorso ? null : _salva,
          ),
        ],
      ),
    );
  }
}

class _CardSeduta extends StatelessWidget {
  const _CardSeduta({
    required this.voce,
    required this.formattaData,
    required this.sottotitoloSerie,
    required this.onCambiaData,
    required this.onRigenera,
    required this.rigenerandoQuesta,
    required this.onRimuovi,
  });

  final SedutaConScheda voce;
  final String Function(DateTime) formattaData;
  final String Function(SerieGenerata) sottotitoloSerie;
  final VoidCallback onCambiaData;
  final VoidCallback? onRigenera;
  final bool rigenerandoQuesta;
  final VoidCallback? onRimuovi;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      padding: const EdgeInsets.all(AppSpacing.paddingPannello),
      child: Opacity(
        opacity: rigenerandoQuesta ? 0.5 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    voce.scheda.titolo,
                    style: AppTypography.titolo.copyWith(color: colori.testo),
                  ),
                ),
                IconButton(
                  icon: rigenerandoQuesta
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh, color: colori.azione),
                  tooltip: 'Rigenera questa seduta',
                  onPressed: onRigenera,
                ),
                if (onRimuovi != null)
                  IconButton(
                    icon: Icon(Icons.close, color: colori.testoSecondario),
                    tooltip: 'Rimuovi questa seduta dal piano',
                    onPressed: rigenerandoQuesta ? null : onRimuovi,
                  ),
              ],
            ),
            InkWell(
              onTap: rigenerandoQuesta ? null : onCambiaData,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: colori.azione,
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    formattaData(voce.data),
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.azione,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '${voce.seduta.codice} · ${voce.scheda.volumeTotaleM} m · '
              'centrale ${voce.scheda.volumeLavoroCentraleM} m',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const Divider(height: AppSpacing.s24),
            for (final s in voce.scheda.serie)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.ordine}. ${s.ripetute}×${s.distanzaM}m '
                      '${labelStile(s.stile)} ${labelEsecuzione(s.esecuzione)}',
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    Text(
                      sottotitoloSerie(s),
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    if (s.ripartenzePerCorsia.isNotEmpty)
                      Text(
                        formattaRipartenzeCorsia(s.ripartenzePerCorsia),
                        style: AppTypography.piccolo.copyWith(
                          color: colori.azione,
                        ),
                      ),
                    if (s.note != null && s.note!.isNotEmpty)
                      Text(
                        s.note!,
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
