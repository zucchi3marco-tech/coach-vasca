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
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../application/corsie_service.dart';
import '../data/generazione_ai_repository.dart';
import '../domain/parametri_generazione.dart';
import '../domain/scheda_generata.dart';
import '../domain/settimana_generata.dart';

const _focus = ['aerobico', 'soglia', 'velocita', 'tecnica', 'misto'];
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

String _capitalizza(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "velocita" resta senza accento come valore interno (identico a quanto
/// manda l'Edge Function): solo l'etichetta mostrata va accentata.
String _etichettaFocus(String f) =>
    f == 'velocita' ? 'Velocità' : _capitalizza(f);

/// Pianifica una settimana intera (FASE 10, punto 5): prima uno scheletro
/// leggero (codice, volume) via `genera-settimana`, poi il dettaglio delle
/// serie di ogni seduta via `genera-allenamento` — stessi passi/corsie
/// calcolati una sola volta per il gruppo. Non tiene ancora conto delle
/// settimane precedenti né del calendario gare (rimandato, vedi
/// ROADMAP.md).
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
  List<String> _focusPerSeduta = List.filled(4, _focus.first);
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
          for (var i = _focusPerSeduta.length; i < numero; i++) _focus.first,
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

  Future<void> _conferma() async {
    if (!_formKey.currentState!.validate()) return;
    if (_giorniSelezionati.isEmpty) {
      setState(() => _erroreGiorni = 'Scegli almeno un giorno');
      return;
    }

    setState(() {
      _generazioneInCorso = true;
      _fasePassaggio = 'Pianificazione della settimana...';
    });

    final gruppoId = ref.read(selezioneGruppoProvider)?.gruppoId;
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
              focusPerSeduta: _focusPerSeduta,
              tipoSettimana: _tipoSettimana,
              vincoli: vincoliUtente.isEmpty ? null : vincoliUtente,
              corsie: corsie,
            ),
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
        final scheda = await ref
            .read(generazioneAiRepositoryProvider)
            .generaAllenamento(
              ParametriGenerazione(
                gruppo: gruppoLabel,
                volumeMetri: seduta.volumeMetri,
                focus: focusSeduta,
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
            sedute: sedute,
          ),
        ),
      );
      if (salvata == true && mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella generazione: ${messaggioErrore(e)}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Riprova', onPressed: _conferma),
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
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final nomeGruppo =
        gruppi.where((g) => g.id == gruppoId).firstOrNull?.nome ??
        'Tutti gli atleti';
    final colori = context.colori;

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Genera settimana con AI')),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pianifica le sedute della settimana. Il dettaglio di ogni '
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
                      onChanged: (value) =>
                          setState(() => _volumeSettimanale = value),
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
                            for (final f in _focus)
                              DropdownMenuItem(
                                value: f,
                                child: Text(_etichettaFocus(f)),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => _focusPerSeduta[i] = value ?? _focus.first,
                          ),
                        ),
                      ),
                  ],
                ),
                AppTextField(
                  etichetta: 'Vincoli (facoltativo)',
                  controller: _vincoliController,
                  maxLines: 3,
                  aiuto: 'Es. niente pinne, max 75 minuti, vasca 25m',
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
              onPressed: _generazioneInCorso ? null : _conferma,
            ),
            if (_generazioneInCorso) const AttesaAiHint(),
          ],
        ),
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
  });

  final SedutaGenerata seduta;
  final SchedaGenerata scheda;
  final DateTime data;

  /// Il focus usato per generare questa seduta — serve a poterla
  /// rigenerare singolarmente nella revisione, con lo stesso focus.
  final String focus;
}

class _RevisioneSettimanaScreen extends ConsumerStatefulWidget {
  const _RevisioneSettimanaScreen({
    required this.clubId,
    required this.gruppoId,
    required this.gruppoLabel,
    required this.corsie,
    required this.vincoliUtente,
    required this.sedute,
  });

  final String clubId;
  final String? gruppoId;
  final String gruppoLabel;
  final List<CorsiaGenerazione> corsie;
  final String vincoliUtente;
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
              focus: voce.focus,
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
      for (final voce in _sedute) {
        final allenamento = await allenamentiRepository.createAllenamento(
          clubId: widget.clubId,
          data: voce.data,
          titolo: voce.scheda.titolo,
          gruppoId: widget.gruppoId,
          note: voce.scheda.note,
        );
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
              '${voce.seduta.codice} · ${voce.scheda.volumeTotaleM} m',
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
