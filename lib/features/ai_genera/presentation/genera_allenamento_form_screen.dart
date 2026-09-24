import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/attesa_ai_hint.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../application/corsie_service.dart';
import '../data/generazione_ai_repository.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/focus_lavoro.dart';
import '../domain/modulo_compilato.dart';
import '../domain/parametri_generazione.dart';
import 'campi_generatore.dart';
import 'casella_dettatura.dart';
import 'scheda_generata_screen.dart';
import 'storico_generazioni_screen.dart';

const _attrezzaturaBraccia = ['pull', 'palette'];
const _attrezzaturaGambe = ['pinne', 'tavola', 'boccaglio'];
const _attrezzaturaLavoroCentraleDisponibile = [
  'pull',
  'palette',
  'boccaglio',
  'pinne',
];

class GeneraAllenamentoFormScreen extends ConsumerStatefulWidget {
  const GeneraAllenamentoFormScreen({
    required this.clubId,
    this.dataPredefinita,
    super.key,
  });

  final String clubId;
  final DateTime? dataPredefinita;

  @override
  ConsumerState<GeneraAllenamentoFormScreen> createState() =>
      _GeneraAllenamentoFormScreenState();
}

class _GeneraAllenamentoFormScreenState
    extends ConsumerState<GeneraAllenamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vincoliController = TextEditingController();
  final _testoController = TextEditingController();
  final _casellaKey = GlobalKey<CasellaDettaturaState>();
  late DateTime _data = widget.dataPredefinita ?? DateTime.now();
  late final TextEditingController _dataController = TextEditingController(
    text: _formattaData(_data),
  );
  bool _serieDaTestoInCorso = false;
  bool _creazioneVuotaInCorso = false;

  double _volumeMetri = 3000;
  double? _volumeLavoroCentraleMetri;
  double _minutiMax = 60;
  int _vascaM = 25;

  final Set<String> _focusSelezionati = {'completo'};
  double? _metriBraccia;
  final Set<String> _attrezziBraccia = {};
  String? _stileBraccia;
  double? _metriGambe;
  final Set<String> _attrezziGambe = {};
  String? _stileGambe;
  String? _stileTecnica;

  final Set<String> _attrezzaturaLavoroCentraleSelezionata = {};
  bool _mostraCodiciTipoLavoro = true;
  final Set<String> _regimiSelezionati = {};
  bool _generazioneInCorso = false;
  bool _compilazioneInCorso = false;

  bool _haFocus(String f) => _focusSelezionati.contains(f);

  bool get _occupato =>
      _generazioneInCorso ||
      _compilazioneInCorso ||
      _serieDaTestoInCorso ||
      _creazioneVuotaInCorso;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  Future<void> _scegliData() async {
    final scelta = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (scelta != null) {
      setState(() {
        _data = scelta;
        _dataController.text = _formattaData(scelta);
      });
    }
  }

  /// Il coach ha scritto (o detto) le serie: si trascrivono fedelmente
  /// (`detta-allenamento`) invece di inventarle dai parametri.
  Future<void> _creaSerieDaTesto() async {
    final testo = _testoController.text.trim();
    if (testo.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scrivi o detta prima le serie')),
      );
      return;
    }
    _casellaKey.currentState?.ferma();
    final gruppoId = ref.read(selezioneGruppoProvider)?.gruppoId;
    final nomeGruppo = (ref.read(gruppiListProvider(widget.clubId)).value ?? [])
        .where((g) => g.id == gruppoId)
        .firstOrNull
        ?.nome;
    setState(() => _serieDaTestoInCorso = true);

    final parametriStorico = {
      'modalita': 'dettatura',
      'testo': testo,
      'gruppo': ?nomeGruppo,
    };

    try {
      final scheda = await ref
          .read(generazioneAiRepositoryProvider)
          .generaDaDettatura(testo: testo, gruppo: nomeGruppo);

      String? generazioneId;
      try {
        generazioneId = await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.clubId,
              parametri: parametriStorico,
              esito: 'successo',
              scheda: scheda.toMap(),
            );
      } catch (_) {}

      if (!mounted) return;
      await _mostraSchedaEApriDettaglio(
        SchedaGenerataScreen(
          scheda: scheda,
          clubId: widget.clubId,
          gruppoId: gruppoId,
          dataIniziale: _data,
          generazioneId: generazioneId,
        ),
      );
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
          content: Text(
            'Errore nella lettura delle serie: ${messaggioErrore(e)}',
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Riprova',
            onPressed: _creaSerieDaTesto,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _serieDaTestoInCorso = false);
    }
  }

  Future<void> _mostraSchedaEApriDettaglio(Widget schermataScheda) async {
    final allenamentoSalvato = await Navigator.of(context)
        .push<Allenamento>(MaterialPageRoute(builder: (_) => schermataScheda));
    if (allenamentoSalvato != null && mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              AllenamentoDetailScreen(allenamento: allenamentoSalvato),
        ),
      );
    }
  }

  /// Nessuna generazione: si crea l'allenamento vuoto nella data scelta e
  /// si apre il dettaglio, dove le serie si aggiungono a mano.
  Future<void> _creaVuoto() async {
    final gruppoId = ref.read(selezioneGruppoProvider)?.gruppoId;
    setState(() => _creazioneVuotaInCorso = true);
    try {
      final allenamento = await ref
          .read(allenamentiRepositoryProvider)
          .createAllenamento(
            clubId: widget.clubId,
            data: _data,
            gruppoId: gruppoId,
          );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AllenamentoDetailScreen(allenamento: allenamento),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella creazione: ${messaggioErrore(e)}'),
        ),
      );
      setState(() => _creazioneVuotaInCorso = false);
    }
  }

  @override
  void dispose() {
    _vincoliController.dispose();
    _testoController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  void _alternaFocus(String f) {
    setState(() {
      if (f == 'completo') {
        _focusSelezionati
          ..clear()
          ..add('completo');
        return;
      }
      _focusSelezionati.remove('completo');
      if (!_focusSelezionati.remove(f)) _focusSelezionati.add(f);
      if (_focusSelezionati.isEmpty) _focusSelezionati.add('completo');
    });
  }

  void _cambiaVolumeTotale(double value) {
    setState(() => _impostaVolumeTotale(value));
  }

  void _impostaVolumeTotale(double value) {
    _volumeMetri = value;
    if ((_volumeLavoroCentraleMetri ?? 0) > value) {
      _volumeLavoroCentraleMetri = value;
    }
    if ((_metriBraccia ?? 0) > value) _metriBraccia = value;
    if ((_metriGambe ?? 0) > value) _metriGambe = value;
  }

  Future<void> _compilaDalTesto() async {
    final testo = _testoController.text.trim();
    if (testo.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scrivi prima cosa vuoi allenare')),
      );
      return;
    }
    setState(() => _compilazioneInCorso = true);
    try {
      final modulo = await ref
          .read(generazioneAiRepositoryProvider)
          .compilaModulo(testo);
      if (!mounted) return;
      if (modulo.vuoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Non ho trovato nel testo niente da compilare: '
              'prova a essere più preciso, o imposta i campi qui sotto.',
            ),
          ),
        );
      } else {
        _applicaModulo(modulo);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Modulo compilato: controlla i campi e poi premi Genera.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore nella lettura del testo: ${messaggioErrore(e)}',
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Riprova', onPressed: _compilaDalTesto),
        ),
      );
    } finally {
      if (mounted) setState(() => _compilazioneInCorso = false);
    }
  }

  void _applicaModulo(ModuloCompilato m) {
    setState(() {
      if (m.vascaM != null) _vascaM = m.vascaM!;
      if (m.minutiMax != null) {
        _minutiMax = m.minutiMax!.clamp(20, 180).toDouble();
      }
      if (m.volumeMetri != null) {
        _impostaVolumeTotale(m.volumeMetri!.clamp(500, 6000).toDouble());
      }
      if (m.volumeLavoroCentraleMetri != null) {
        _volumeLavoroCentraleMetri = m.volumeLavoroCentraleMetri!
            .clamp(0, _volumeMetri)
            .toDouble();
      }
      if (m.tipiLavoro.isNotEmpty) {
        _regimiSelezionati
          ..clear()
          ..addAll(m.tipiLavoro);
      }
      if (m.focus.isNotEmpty) {
        _focusSelezionati
          ..clear()
          ..addAll(m.focus);
      }
      final braccia = m.braccia;
      if (braccia != null) {
        if (braccia.metri != null) {
          _metriBraccia = braccia.metri!.clamp(0, _volumeMetri).toDouble();
        }
        if (braccia.attrezzatura.isNotEmpty) {
          _attrezziBraccia
            ..clear()
            ..addAll(braccia.attrezzatura);
        }
        if (braccia.stile != null) _stileBraccia = braccia.stile;
      }
      final gambe = m.gambe;
      if (gambe != null) {
        if (gambe.metri != null) {
          _metriGambe = gambe.metri!.clamp(0, _volumeMetri).toDouble();
        }
        if (gambe.attrezzatura.isNotEmpty) {
          _attrezziGambe
            ..clear()
            ..addAll(gambe.attrezzatura);
        }
        if (gambe.stile != null) _stileGambe = gambe.stile;
      }
      if (m.stileTecnica != null) _stileTecnica = m.stileTecnica;
      if (m.attrezzaturaLavoroCentrale.isNotEmpty) {
        _attrezzaturaLavoroCentraleSelezionata
          ..clear()
          ..addAll(m.attrezzaturaLavoroCentrale);
      }
      final vincoli = m.vincoli;
      if (vincoli != null) {
        final attuali = _vincoliController.text.trim();
        if (attuali.isEmpty) {
          _vincoliController.text = vincoli;
        } else if (!attuali.contains(vincoli)) {
          _vincoliController.text = '$attuali. $vincoli';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gruppoId = ref.watch(selezioneGruppoProvider)?.gruppoId;
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final nomeGruppo =
        gruppi.where((g) => g.id == gruppoId).firstOrNull?.nome ??
        'Tutti gli atleti';
    final colori = context.colori;
    final volumeLavoroCentraleClampato = (_volumeLavoroCentraleMetri ?? 0)
        .clamp(0, _volumeMetri)
        .toDouble();

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: const Text('Genera con AI'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoricoGenerazioniScreen(clubId: widget.clubId),
              ),
            ),
            icon: const Icon(Icons.history, size: 20),
            label: const Text('Storico'),
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
                  etichetta: 'Data dell\'allenamento',
                  controller: _dataController,
                  readOnly: true,
                  onTap: _occupato ? null : _scegliData,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Scrivi o detta il tuo allenamento',
              campi: [
                CasellaDettatura(
                  key: _casellaKey,
                  controller: _testoController,
                  etichetta: 'Descrivilo a parole',
                  aiuto:
                      'Se scrivi le serie (es. "400 riscaldamento, 8x100 sl '
                      'soglia rec 20, 200 defaticamento") premi "Crea le '
                      'serie". Se descrivi solo cosa vuoi (es. "5 km con 3 '
                      'km di aerobico, no rana") premi "Compila il '
                      'modulo": poi lo rivedi e generi.',
                ),
                PrimaryButton(
                  label: _serieDaTestoInCorso
                      ? 'Sto leggendo...'
                      : 'Crea le serie da questo testo',
                  isLoading: _serieDaTestoInCorso,
                  onPressed: _occupato ? null : _creaSerieDaTesto,
                ),
                SecondaryButton(
                  label: _compilazioneInCorso
                      ? 'Sto leggendo...'
                      : 'Compila il modulo',
                  icon: Icons.auto_fix_high,
                  onPressed: _occupato ? null : _compilaDalTesto,
                ),
                if (_serieDaTestoInCorso) const AttesaAiHint(),
              ],
            ),
            FormGroup(
              titolo: 'Sessione',
              campi: [
                Text(
                  'Gruppo: $nomeGruppo',
                  style: AppTypography.corpo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EtichettaCampo('Vasca'),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 25, label: Text('25 m')),
                        ButtonSegment(value: 50, label: Text('50 m')),
                      ],
                      selected: {_vascaM},
                      onSelectionChanged: (s) =>
                          setState(() => _vascaM = s.first),
                    ),
                  ],
                ),
                SliderConValore(
                  etichetta: 'Minuti max di lavoro',
                  valore: _minutiMax,
                  min: 20,
                  max: 180,
                  divisioni: 32,
                  testoValore: '${_minutiMax.round()} min',
                  onChanged: (value) => setState(() => _minutiMax = value),
                  azione: const PulsanteSpiegazione(
                    titolo: 'Minuti max di lavoro',
                    spiegazione:
                        'La scheda generata non deve superare questo '
                        "tempo, stimato su nuoto + recuperi dell'atleta "
                        'più lento del gruppo (è quello che finisce per '
                        'ultimo). La stima non tiene conto dei tempi di '
                        'virata né della lunghezza della vasca: è '
                        "un'approssimazione, non un cronometro.",
                  ),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Tipo di lavoro',
              campi: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(
                      () => _mostraCodiciTipoLavoro = !_mostraCodiciTipoLavoro,
                    ),
                    child: Text(
                      _mostraCodiciTipoLavoro ? 'Mostra nomi' : 'Mostra sigle',
                    ),
                  ),
                ),
                GrigliaTipiLavoro(
                  selezionati: _regimiSelezionati,
                  mostraCodici: _mostraCodiciTipoLavoro,
                  onCambia: (zona, selezionato) => setState(() {
                    if (selezionato) {
                      _regimiSelezionati.add(zona);
                    } else {
                      _regimiSelezionati.remove(zona);
                    }
                  }),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Focus',
              campi: [
                GruppoChip(
                  etichetta: 'Su cosa si concentra la seduta (più scelte)',
                  chip: [
                    for (final f in focusLavoro)
                      TonalChip(
                        etichetta: etichettaFocusLavoro(f),
                        selezionato: _haFocus(f),
                        onSelezionato: (_) => _alternaFocus(f),
                      ),
                  ],
                ),
                if (_haFocus('tecnica'))
                  PannelloCampi(
                    titolo: 'Stile tecnica principale',
                    figli: [
                      GruppoChip(
                        etichetta: 'Facoltativo: se non scegli, decide l\'AI',
                        chip: [
                          for (final s in stiliNuoto)
                            TonalChip(
                              etichetta: labelStile(s),
                              selezionato: _stileTecnica == s,
                              onSelezionato: (selezionato) => setState(
                                () => _stileTecnica = selezionato ? s : null,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                if (_haFocus('braccia'))
                  PannelloFocusDettaglio(
                    titolo: 'Braccia',
                    etichettaMetri: 'Braccia — metri',
                    metri: _metriBraccia,
                    maxMetri: _volumeMetri,
                    onMetri: (v) => setState(() => _metriBraccia = v),
                    attrezziDisponibili: _attrezzaturaBraccia,
                    attrezziSelezionati: _attrezziBraccia,
                    onAttrezzo: (a, sel) => setState(() {
                      if (sel) {
                        _attrezziBraccia.add(a);
                      } else {
                        _attrezziBraccia.remove(a);
                      }
                    }),
                    stile: _stileBraccia,
                    onStile: (st) => setState(() => _stileBraccia = st),
                  ),
                if (_haFocus('gambe'))
                  PannelloFocusDettaglio(
                    titolo: 'Gambe',
                    etichettaMetri: 'Gambe — metri',
                    metri: _metriGambe,
                    maxMetri: _volumeMetri,
                    onMetri: (v) => setState(() => _metriGambe = v),
                    attrezziDisponibili: _attrezzaturaGambe,
                    attrezziSelezionati: _attrezziGambe,
                    onAttrezzo: (a, sel) => setState(() {
                      if (sel) {
                        _attrezziGambe.add(a);
                      } else {
                        _attrezziGambe.remove(a);
                      }
                    }),
                    stile: _stileGambe,
                    onStile: (st) => setState(() => _stileGambe = st),
                  ),
              ],
            ),
            FormGroup(
              titolo: 'Volume e attrezzi',
              isUltimo: true,
              campi: [
                PannelloCampi(
                  titolo: 'Attrezzi lavoro centrale',
                  figli: [
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final a in _attrezzaturaLavoroCentraleDisponibile)
                          TonalChip(
                            etichetta: etichettaAttrezzo(a),
                            selezionato: _attrezzaturaLavoroCentraleSelezionata
                                .contains(a),
                            onSelezionato: (selezionato) => setState(() {
                              if (selezionato) {
                                _attrezzaturaLavoroCentraleSelezionata.add(a);
                              } else {
                                _attrezzaturaLavoroCentraleSelezionata.remove(
                                  a,
                                );
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
                SliderConValore(
                  etichetta: 'Volume totale (m)',
                  valore: _volumeMetri,
                  min: 500,
                  max: 6000,
                  divisioni: 55,
                  onChanged: _cambiaVolumeTotale,
                ),
                SliderConValore(
                  etichetta: _volumeLavoroCentraleMetri == null
                      ? "Volume lavoro centrale (m) — se non lo muovi decide l'AI"
                      : 'Volume lavoro centrale (m)',
                  valore: volumeLavoroCentraleClampato,
                  min: 0,
                  max: _volumeMetri,
                  divisioni: (_volumeMetri / 100).round().clamp(1, 999),
                  testoValore: _volumeLavoroCentraleMetri == null
                      ? 'Auto'
                      : null,
                  onChanged: (value) =>
                      setState(() => _volumeLavoroCentraleMetri = value),
                ),
                AppTextField(
                  etichetta: 'Vincoli (facoltativo)',
                  controller: _vincoliController,
                  maxLines: 3,
                  aiuto: 'Es. niente pinne di gomma, riscaldamento breve',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s28),
            PrimaryButton(
              label: _generazioneInCorso ? 'Sto generando...' : 'Genera',
              isLoading: _generazioneInCorso,
              onPressed: _occupato ? null : _conferma,
            ),
            if (_generazioneInCorso) const AttesaAiHint(),
            const SizedBox(height: AppSpacing.s12),
            SecondaryButton(
              label: _creazioneVuotaInCorso
                  ? 'Sto creando...'
                  : 'Crea vuoto e aggiungo le serie a mano',
              icon: Icons.edit_outlined,
              onPressed: _occupato ? null : _creaVuoto,
            ),
          ],
        ),
      ),
    );
  }

  DettaglioFocus _dettaglio(
    double? metri,
    Set<String> attrezzi,
    String? stile,
  ) => DettaglioFocus(
    metri: metri?.round(),
    attrezzatura: attrezzi.toList(),
    stile: stile,
  );

  Future<void> _conferma() async {
    if (!_formKey.currentState!.validate()) return;
    if (_regimiSelezionati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un tipo di lavoro')),
      );
      return;
    }
    final metriDedicati =
        (_haFocus('braccia') ? (_metriBraccia ?? 0) : 0) +
        (_haFocus('gambe') ? (_metriGambe ?? 0) : 0);
    if (metriDedicati > _volumeMetri) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'I metri di braccia e gambe insieme (${metriDedicati.round()} m) '
            'superano il volume totale (${_volumeMetri.round()} m).',
          ),
        ),
      );
      return;
    }

    final gruppoId = ref.read(selezioneGruppoProvider)?.gruppoId;
    setState(() => _generazioneInCorso = true);

    var assegnazione = const AssegnazioneCorsie(corsie: []);
    try {
      final tuttiGliAtleti = await ref.read(
        atletiListProvider((clubId: widget.clubId, includeInactive: false))
            .future,
      );
      final atletiDelGruppo = gruppoId == null
          ? tuttiGliAtleti
          : tuttiGliAtleti.where((a) => a.gruppoId == gruppoId).toList();
      assegnazione = await calcolaAssegnazioneCorsie(ref, atletiDelGruppo);
    } catch (_) {
      // Le corsie migliorano la generazione (ripartenze sui passi reali),
      // ma non sono indispensabili: se il calcolo fallisce si procede
      // comunque, senza passi di riferimento.
    }

    final Map<String, String> nomiGruppi = {
      for (final g in ref.read(gruppiListProvider(widget.clubId)).value ?? [])
        g.id: g.nome,
    };

    final parametri = ParametriGenerazione(
      gruppo: nomiGruppi[gruppoId] ?? 'Tutti gli atleti',
      volumeMetri: _volumeMetri.round(),
      volumeLavoroCentraleM: _volumeLavoroCentraleMetri?.round(),
      focus: focusLavoro.where(_haFocus).toList(),
      dettaglioBraccia: _haFocus('braccia')
          ? _dettaglio(_metriBraccia, _attrezziBraccia, _stileBraccia)
          : null,
      dettaglioGambe: _haFocus('gambe')
          ? _dettaglio(_metriGambe, _attrezziGambe, _stileGambe)
          : null,
      stileTecnica: _haFocus('tecnica') ? _stileTecnica : null,
      attrezzaturaLavoroCentrale: _attrezzaturaLavoroCentraleSelezionata
          .toList(),
      minutiMax: _minutiMax.round(),
      vascaM: _vascaM,
      regimiAmmessi: _regimiSelezionati.toList(),
      vincoli: _vincoliController.text.trim().isEmpty
          ? null
          : _vincoliController.text.trim(),
      corsie: assegnazione.corsie,
    );

    try {
      final scheda = await ref
          .read(generazioneAiRepositoryProvider)
          .generaAllenamento(parametri);

      // Lo storico e' un di piu' per rivedere/migliorare i prompt: un suo
      // fallimento non deve mai bloccare una generazione riuscita.
      String? generazioneId;
      try {
        generazioneId = await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.clubId,
              parametri: parametri.toMap(),
              esito: 'successo',
              scheda: scheda.toMap(),
            );
      } catch (_) {}

      if (!mounted) return;
      final allenamentoSalvato = await Navigator.of(context).push<Allenamento>(
        MaterialPageRoute(
          builder: (_) => SchedaGenerataScreen(
            scheda: scheda,
            clubId: widget.clubId,
            gruppoId: gruppoId,
            dataIniziale: _data,
            generazioneId: generazioneId,
            assegnazione: assegnazione,
          ),
        ),
      );
      if (allenamentoSalvato != null && mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                AllenamentoDetailScreen(allenamento: allenamentoSalvato),
          ),
        );
      }
    } catch (e) {
      try {
        await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.clubId,
              parametri: parametri.toMap(),
              esito: 'errore',
              messaggioErrore: e.toString(),
            );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella generazione: ${messaggioErrore(e)}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Riprova', onPressed: _conferma),
        ),
      );
    } finally {
      if (mounted) setState(() => _generazioneInCorso = false);
    }
  }
}
