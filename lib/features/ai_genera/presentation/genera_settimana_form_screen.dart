import '../../../core/utils/giorni.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/attesa_ai_hint.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/presentation/riepilogo_volumi.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../club/application/current_club_provider.dart';
import '../../gare/application/gare_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../../libreria_blocchi/application/selezione_blocchi_service.dart';
import '../../libreria_blocchi/data/training_blocks_repository.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../application/controlli_settimana_service.dart';
import '../application/corsie_service.dart';
import '../application/settimana_ai_providers.dart';
import '../data/generazione_ai_repository.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/focus_lavoro.dart';
import '../domain/modulo_settimana_compilato.dart';
import '../domain/parametri_generazione.dart';
import '../domain/scheda_generata.dart';
import '../domain/settimana_generata.dart';
import 'campi_generatore.dart';

// Oltre questa attesa, un calcolo "di contorno" (corsie, libreria
// blocchi, contesto dei controlli settimanali) smette di bloccare la
// schermata — migliorano la generazione ma non sono indispensabili, mai
// un caricamento infinito per rete lenta o un gruppo con molti atleti.
const _timeoutPreparazione = Duration(seconds: 12);

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
const _attrezzaturaBraccia = ['pull', 'palette'];
const _attrezzaturaGambe = ['pinne', 'tavola', 'boccaglio'];
const _attrezzaturaLavoroCentraleDisponibile = [
  'pull',
  'palette',
  'boccaglio',
  'pinne',
];

String _capitalizza(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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
  List<Set<String>> _focusPerSeduta = List.generate(
    4,
    (_) => {focusLavoro.first},
  );
  double? _metriBraccia;
  final Set<String> _attrezziBraccia = {};
  String? _stileBraccia;
  double? _metriGambe;
  final Set<String> _attrezziGambe = {};
  String? _stileGambe;
  String? _stileTecnica;
  final _testoController = TextEditingController();
  bool _compilazioneInCorso = false;
  bool _generazioneInCorso = false;
  String? _fasePassaggio;
  String? _erroreGiorni;

  @override
  void dispose() {
    _vincoliController.dispose();
    _testoController.dispose();
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
            {focusLavoro.first},
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
    final data = aggiungiGiorni(_dataInizio, offset);
    return '${_abbreviazioniGiorni[data.weekday - 1]} '
        '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}';
  }

  String _etichettaGiornoCompleta(int offset) {
    final data = aggiungiGiorni(_dataInizio, offset);
    return '${_nomiGiorni[data.weekday - 1]} '
        '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}';
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

  bool _qualcunoHaFocus(String f) => _focusPerSeduta.any((s) => s.contains(f));

  void _alternaFocusSeduta(int indice, String f) {
    setState(() {
      final insieme = _focusPerSeduta[indice];
      if (f == 'completo') {
        insieme
          ..clear()
          ..add('completo');
        return;
      }
      insieme.remove('completo');
      if (!insieme.remove(f)) insieme.add(f);
      if (insieme.isEmpty) insieme.add('completo');
    });
  }

  Future<void> _compilaDalTesto() async {
    final testo = _testoController.text.trim();
    if (testo.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scrivi prima come vuoi la settimana')),
      );
      return;
    }
    setState(() => _compilazioneInCorso = true);
    try {
      final modulo = await ref
          .read(generazioneAiRepositoryProvider)
          .compilaSettimana(testo);
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

  void _applicaModulo(ModuloSettimanaCompilato m) {
    setState(() {
      if (m.volumeSettimanaleMetri != null) {
        _volumeSettimanale = m.volumeSettimanaleMetri!
            .clamp(2000, 20000)
            .toDouble();
        if ((_volumeLavoroCentraleSettimanale ?? 0) > _volumeSettimanale) {
          _volumeLavoroCentraleSettimanale = _volumeSettimanale;
        }
      }
      if (m.volumeLavoroCentraleSettimanaleMetri != null) {
        _volumeLavoroCentraleSettimanale = m
            .volumeLavoroCentraleSettimanaleMetri!
            .clamp(0, _volumeSettimanale)
            .toDouble();
      }
      if (m.minutiMax != null) {
        _minutiMax = m.minutiMax!.clamp(20, 180).toDouble();
      }
      if (m.vascaM != null) _vascaM = m.vascaM!;
      if (m.tipoSettimana != null && _tipiSettimana.contains(m.tipoSettimana)) {
        _tipoSettimana = m.tipoSettimana;
      }

      // Giorni nominati (1 = lunedì) -> distanza in giorni dalla data di
      // inizio, che è ciò che il form tiene.
      if (m.giorni.isNotEmpty) {
        _giorniSelezionati
          ..clear()
          ..addAll({
            for (final g in m.giorni) (g - _dataInizio.weekday + 7) % 7,
          })
          ..sort();
        _erroreGiorni = null;
      }
      final numero = _giorniSelezionati.length;
      _focusPerSeduta = [
        for (var i = 0; i < numero; i++)
          i < _focusPerSeduta.length ? _focusPerSeduta[i] : {focusLavoro.first},
      ];
      if (m.focusComune.isNotEmpty) {
        for (final f in _focusPerSeduta) {
          f
            ..clear()
            ..addAll(m.focusComune);
        }
      }
      for (final voce in m.focusPerGiorno.entries) {
        final offset = (voce.key - _dataInizio.weekday + 7) % 7;
        final indice = _giorniSelezionati.indexOf(offset);
        if (indice >= 0) {
          _focusPerSeduta[indice]
            ..clear()
            ..addAll(voce.value);
        }
      }

      final braccia = m.braccia;
      if (braccia != null) {
        if (braccia.metri != null) _metriBraccia = braccia.metri!.toDouble();
        if (braccia.attrezzatura.isNotEmpty) {
          _attrezziBraccia
            ..clear()
            ..addAll(braccia.attrezzatura);
        }
        if (braccia.stile != null) _stileBraccia = braccia.stile;
      }
      final gambe = m.gambe;
      if (gambe != null) {
        if (gambe.metri != null) _metriGambe = gambe.metri!.toDouble();
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

  /// Dati per i controlli sulla settimana intera (RIPROGETTAZIONE AI,
  /// FASE 3): c'è una gara/partita "alta" entro 10 giorni dalla fine
  /// della settimana generata, la media di volume delle ultime 4
  /// settimane (null se non ce n'è storico) e se il gruppo è di
  /// pallanuoto (per il tetto del 50% di nuoto puro). Un fallimento in
  /// una di queste letture non blocca la generazione: i controlli
  /// restano solo meno precisi, mai bloccanti di per sé.
  Future<
    ({
      bool garaAltaImminente,
      double? mediaUltimeSettimane,
      bool sportPallanuoto,
    })
  >
  _calcolaContestoControlli({
    required String? gruppoId,
    required DateTime dataFineSettimana,
    required String? sportClub,
  }) async {
    var garaAltaImminente = false;
    try {
      final fineFinestra = aggiungiGiorni(dataFineSettimana, 10);
      final gare = await ref.read(gareListProvider(widget.clubId).future);
      final partite = await ref.read(partiteListProvider(widget.clubId).future);
      garaAltaImminente =
          gare.any(
            (g) =>
                g.importanza == 'alta' &&
                !g.data.isBefore(dataFineSettimana) &&
                !g.data.isAfter(fineFinestra) &&
                visibileNelGruppo(
                  gruppoDelRecord: g.gruppoId,
                  gruppoSelezionato: gruppoId,
                ),
          ) ||
          partite.any(
            (p) =>
                p.importanza == 'alta' &&
                !p.data.isBefore(dataFineSettimana) &&
                !p.data.isAfter(fineFinestra) &&
                visibileNelGruppo(
                  gruppoDelRecord: p.gruppoId,
                  gruppoSelezionato: gruppoId,
                ),
          );
    } catch (_) {
      // Nessuna gara/partita trovata: nessuno scarico richiesto.
    }

    double? mediaUltimeSettimane;
    try {
      final oggi = DateTime.now();
      final allenamenti = await ref
          .read(allenamentiRepositoryProvider)
          .fetchPerClubEPeriodo(
            clubId: widget.clubId,
            dataInizio: aggiungiGiorni(oggi, -28),
            dataFine: oggi,
          );
      final delGruppo = gruppoId == null
          ? allenamenti
          : allenamenti.where((a) => a.gruppoId == gruppoId).toList();
      final serie = await ref.read(serieRepositoryProvider).fetchPerAllenamenti(
        [for (final a in delGruppo) a.id],
      );
      if (delGruppo.isNotEmpty) {
        final volumeTotale = serie.fold<int>(
          0,
          (t, s) => t + s.distanzaTotaleM,
        );
        mediaUltimeSettimane = volumeTotale / 4;
      }
    } catch (_) {
      // Nessuno storico: il controllo sul carico resta disattivato.
    }

    final gruppi = ref.read(gruppiListProvider(widget.clubId)).value ?? [];
    final sportGruppo = gruppoId == null
        ? null
        : gruppi.where((g) => g.id == gruppoId).firstOrNull?.sport;
    final sportPallanuoto = (sportGruppo ?? sportClub) == 'pallanuoto';

    return (
      garaAltaImminente: garaAltaImminente,
      mediaUltimeSettimane: mediaUltimeSettimane,
      sportPallanuoto: sportPallanuoto,
    );
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

    var assegnazione = const AssegnazioneCorsie(corsie: []);
    try {
      final tuttiGliAtleti = await ref.read(
        atletiListProvider((clubId: widget.clubId, includeInactive: false))
            .future,
      );
      final atletiDelGruppo = gruppoId == null
          ? tuttiGliAtleti
          : tuttiGliAtleti.where((a) => a.gruppoId == gruppoId).toList();
      assegnazione = await calcolaAssegnazioneCorsie(
        ref,
        atletiDelGruppo,
      ).timeout(_timeoutPreparazione);
    } catch (_) {
      // Le corsie migliorano la generazione, ma non sono indispensabili:
      // se vanno per le lunghe (rete lenta, gruppo numeroso) non devono
      // bloccare la schermata all'infinito.
    }
    final corsie = assegnazione.corsie;

    final Map<String, String> nomiGruppi = {
      for (final g in ref.read(gruppiListProvider(widget.clubId)).value ?? [])
        g.id: g.nome,
    };
    final gruppoLabel = nomiGruppi[gruppoId] ?? 'Tutti gli atleti';

    var blocchi = const <BloccoDisponibile>[];
    String? sportClub;
    try {
      final club = await ref.read(currentClubProvider.future);
      sportClub = club?.sport;
      blocchi = await blocchiCompatibili(
        ref,
        clubId: widget.clubId,
        sportRichiesto: sportRichiestoDaClub(club?.sport),
        nomeGruppo: nomiGruppi[gruppoId],
      ).timeout(_timeoutPreparazione);
    } catch (_) {
      // Come le corsie: migliora la generazione, non è indispensabile.
    }

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
              focusPerSeduta: [
                for (final f in _focusPerSeduta)
                  focusLavoro.where(f.contains).toList(),
              ],
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
        final focusSeduta = focusLavoro
            .where(
              (i < _focusPerSeduta.length
                      ? _focusPerSeduta[i]
                      : _focusPerSeduta.last)
                  .contains,
            )
            .toList();
        final dettagli = dettagliFocusPerSeduta(
          focus: focusSeduta,
          volumeSeduta: seduta.volumeMetri,
          braccia: _dettaglio(_metriBraccia, _attrezziBraccia, _stileBraccia),
          gambe: _dettaglio(_metriGambe, _attrezziGambe, _stileGambe),
        );
        final stileTecnica = focusSeduta.contains('tecnica')
            ? _stileTecnica
            : null;
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
                focus: focusSeduta,
                dettaglioBraccia: dettagli.braccia,
                dettaglioGambe: dettagli.gambe,
                stileTecnica: stileTecnica,
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
                blocchiDisponibili: blocchi,
              ),
            );
        final offset = i < giorniOrdinati.length
            ? giorniOrdinati[i]
            : giorniOrdinati.last;
        sedute.add(
          SedutaConScheda(
            seduta: seduta,
            scheda: scheda,
            data: aggiungiGiorni(_dataInizio, offset),
            focus: focusSeduta,
            dettaglioBraccia: dettagli.braccia,
            dettaglioGambe: dettagli.gambe,
            stileTecnica: stileTecnica,
            volumeLavoroCentraleM: volumeLavoroCentraleSeduta,
          ),
        );
      }

      final dataFineSettimana = aggiungiGiorni(
        _dataInizio,
        giorniOrdinati.last,
      );
      var contesto = (
        garaAltaImminente: false,
        mediaUltimeSettimane: null as double?,
        sportPallanuoto: false,
      );
      try {
        contesto = await _calcolaContestoControlli(
          gruppoId: gruppoId,
          dataFineSettimana: dataFineSettimana,
          sportClub: sportClub,
        ).timeout(_timeoutPreparazione);
      } catch (_) {
        // I controlli settimanali restano solo meno precisi, non devono
        // bloccare la schermata di revisione.
      }

      if (!mounted) return;
      final salvata = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _RevisioneSettimanaScreen(
            clubId: widget.clubId,
            gruppoId: gruppoId,
            gruppoLabel: gruppoLabel,
            corsie: corsie,
            assegnazione: assegnazione,
            blocchi: blocchi,
            volumeSettimanaleRichiesto: _volumeSettimanale.round(),
            garaAltaImminente: contesto.garaAltaImminente,
            mediaUltimeSettimane: contesto.mediaUltimeSettimane,
            sportPallanuoto: contesto.sportPallanuoto,
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
      appBar: AppBar(title: const Text('Genera la settimana')),
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
            titolo: 'Descrivi la settimana',
            campi: [
              AppTextField(
                etichetta: 'Scrivila a parole',
                controller: _testoController,
                maxLines: 3,
                aiuto:
                    'Es. "lunedì, mercoledì e venerdì, 12 km in totale, il '
                    'mercoledì tecnica, il venerdì gambe con pinne, no '
                    'rana". Il modulo si compila da solo: poi lo rivedi. '
                    'Oppure salta e imposta tutto qui sotto.',
              ),
              SecondaryButton(
                label: _compilazioneInCorso
                    ? 'Sto leggendo...'
                    : 'Compila il modulo',
                icon: Icons.auto_fix_high,
                onPressed: _compilazioneInCorso || _generazioneInCorso
                    ? null
                    : _compilaDalTesto,
              ),
            ],
          ),
          FormGroup(
            titolo: 'Settimana',
            campi: [
              AppTextField(
                etichetta: 'Data di inizio',
                controller: _dataInizioController,
                readOnly: true,
                onTap: _pickDataInizio,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              Text(
                'Gruppo: $nomeGruppo',
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GruppoChip(
                    etichetta: 'Tipo di settimana (facoltativo)',
                    chip: [
                      for (final t in _tipiSettimana)
                        TonalChip(
                          etichetta: _capitalizza(t),
                          selezionato: _tipoSettimana == t,
                          onSelezionato: (selezionato) => setState(
                            () => _tipoSettimana = selezionato ? t : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
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
                  GruppoChip(
                    etichetta: 'Giorni della settimana',
                    chip: [
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
            ],
          ),
          FormGroup(
            titolo: 'Sessione',
            campi: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EtichettaCampo('Vasca'),
                  const SizedBox(height: AppSpacing.s8),
                  SegmentedButton<int>(
                    // Senza spunta: la scelta e' gia' evidenziata dal
                    // colore, e la spunta toglieva spazio all'etichetta
                    // che su telefono andava a capo a meta' parola.
                    showSelectedIcon: false,
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
                etichetta: 'Minuti max di lavoro (ogni seduta)',
                valore: _minutiMax,
                min: 20,
                max: 180,
                divisioni: 32,
                testoValore: '${_minutiMax.round()} min',
                onChanged: (value) => setState(() => _minutiMax = value),
                azione: const PulsanteSpiegazione(
                  titolo: 'Minuti max di lavoro',
                  spiegazione:
                      'Vale per ogni seduta della settimana: nessuna '
                      'deve superare questo tempo, stimato su nuoto + '
                      "recuperi dell'atleta più lento del gruppo. La "
                      'stima non tiene conto dei tempi di virata né '
                      'della lunghezza della vasca.',
                ),
              ),
            ],
          ),
          FormGroup(
            titolo: 'Focus di ogni seduta',
            campi: [
              for (var i = 0; i < _focusPerSeduta.length; i++)
                GruppoChip(
                  etichetta:
                      '${i < _giorniSelezionati.length ? _etichettaGiornoBreve(_giorniSelezionati[i]) : 'Seduta ${i + 1}'}'
                      ' (più scelte)',
                  chip: [
                    for (final f in focusLavoro)
                      TonalChip(
                        etichetta: etichettaFocusLavoro(f),
                        selezionato: _focusPerSeduta[i].contains(f),
                        onSelezionato: (_) => _alternaFocusSeduta(i, f),
                      ),
                  ],
                ),
              if (_qualcunoHaFocus('tecnica'))
                PannelloCampi(
                  titolo: 'Stile tecnica principale',
                  figli: [
                    GruppoChip(
                      etichetta: "Facoltativo: se non scegli, decide l'AI",
                      chip: [
                        for (final st in stiliNuoto)
                          TonalChip(
                            etichetta: labelStile(st),
                            selezionato: _stileTecnica == st,
                            onSelezionato: (sel) =>
                                setState(() => _stileTecnica = sel ? st : null),
                          ),
                      ],
                    ),
                  ],
                ),
              if (_qualcunoHaFocus('braccia'))
                PannelloFocusDettaglio(
                  titolo: 'Braccia (in ogni seduta con questo focus)',
                  etichettaMetri: 'Braccia — metri per seduta',
                  metri: _metriBraccia,
                  maxMetri: 3000,
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
              if (_qualcunoHaFocus('gambe'))
                PannelloFocusDettaglio(
                  titolo: 'Gambe (in ogni seduta con questo focus)',
                  etichettaMetri: 'Gambe — metri per seduta',
                  metri: _metriGambe,
                  maxMetri: 3000,
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
                              _attrezzaturaLavoroCentraleSelezionata.remove(a);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              ),
              SliderConValore(
                etichetta: 'Volume settimanale (m)',
                valore: _volumeSettimanale,
                min: 2000,
                max: 20000,
                divisioni: 36,
                onChanged: (value) => setState(() {
                  _volumeSettimanale = value;
                  if ((_volumeLavoroCentraleSettimanale ?? 0) > value) {
                    _volumeLavoroCentraleSettimanale = value;
                  }
                }),
              ),
              SliderConValore(
                etichetta: _volumeLavoroCentraleSettimanale == null
                    ? "Volume lavoro centrale settimanale (m) — se non lo muovi decide l'AI"
                    : 'Volume lavoro centrale settimanale (m)',
                valore: volumeLavoroCentraleClampato,
                min: 0,
                max: _volumeSettimanale,
                divisioni: (_volumeSettimanale / 200).round().clamp(1, 999),
                testoValore: _volumeLavoroCentraleSettimanale == null
                    ? 'Auto'
                    : null,
                onChanged: (value) =>
                    setState(() => _volumeLavoroCentraleSettimanale = value),
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
    this.dettaglioBraccia,
    this.dettaglioGambe,
    this.stileTecnica,
    this.volumeLavoroCentraleM,
  });

  final SedutaGenerata seduta;
  final SchedaGenerata scheda;
  final DateTime data;

  /// Il focus (uno o più) e i dettagli già adattati a questa seduta,
  /// usati per generarla — servono a poterla rigenerare singolarmente
  /// nella revisione, con gli stessi parametri.
  final List<String> focus;
  final DettaglioFocus? dettaglioBraccia;
  final DettaglioFocus? dettaglioGambe;
  final String? stileTecnica;

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
    this.assegnazione = const AssegnazioneCorsie(corsie: []),
    this.blocchi = const [],
    this.volumeSettimanaleRichiesto = 0,
    this.garaAltaImminente = false,
    this.mediaUltimeSettimane,
    this.sportPallanuoto = false,
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
  final AssegnazioneCorsie assegnazione;
  final List<BloccoDisponibile> blocchi;

  /// Per i controlli sulla settimana intera (FASE 3) — vedi
  /// `controlli_settimana_service.dart`.
  final int volumeSettimanaleRichiesto;
  final bool garaAltaImminente;
  final double? mediaUltimeSettimane;
  final bool sportPallanuoto;

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
  List<String> _avvisi = const [];
  bool _controlliFatti = false;

  @override
  void initState() {
    super.initState();
    // Un solo giro di controlli automatici all'apertura della revisione
    // (FASE 3): se emerge un problema attribuibile a UNA seduta, la si
    // rigenera una sola volta con un vincolo che spiega cosa correggere,
    // poi si rivalutano gli avvisi col risultato — mai una seconda
    // rigenerazione automatica.
    WidgetsBinding.instance.addPostFrameCallback((_) => _eseguiControlli());
  }

  List<SedutaPerControllo> get _sedutePerControllo => [
    for (final s in _sedute) (s.data, s.scheda),
  ];

  Future<void> _eseguiControlli() async {
    final esito = controllaSettimana(
      sedute: _sedutePerControllo,
      volumeSettimanaleRichiesto: widget.volumeSettimanaleRichiesto,
      mediaUltimeSettimane: widget.mediaUltimeSettimane,
      garaAltaImminente: widget.garaAltaImminente,
      sportPallanuoto: widget.sportPallanuoto,
    );
    if (!mounted) return;
    if (!_controlliFatti && esito.indiceDaRigenerare != null) {
      _controlliFatti = true;
      await _rigenera(
        esito.indiceDaRigenerare!,
        vincoloExtra: esito.vincoloExtra,
      );
      if (!mounted) return;
      final esitoFinale = controllaSettimana(
        sedute: _sedutePerControllo,
        volumeSettimanaleRichiesto: widget.volumeSettimanaleRichiesto,
        mediaUltimeSettimane: widget.mediaUltimeSettimane,
        garaAltaImminente: widget.garaAltaImminente,
        sportPallanuoto: widget.sportPallanuoto,
      );
      setState(() => _avvisi = esitoFinale.avvisi);
    } else {
      _controlliFatti = true;
      setState(() => _avvisi = esito.avvisi);
    }
  }

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
          dettaglioBraccia: corrente.dettaglioBraccia,
          dettaglioGambe: corrente.dettaglioGambe,
          stileTecnica: corrente.stileTecnica,
          volumeLavoroCentraleM: corrente.volumeLavoroCentraleM,
        );
      });
    }
  }

  Future<void> _rigenera(int indice, {String? vincoloExtra}) async {
    setState(() => _rigenerandoIndice = indice);
    final voce = _sedute[indice];
    try {
      final vincoliGiorno = [
        'Enfasi di questa seduta: ${voce.seduta.codice}.',
        if (widget.vincoliUtente.isNotEmpty) widget.vincoliUtente,
        ?vincoloExtra,
      ].join(' ');
      final nuovaScheda = await ref
          .read(generazioneAiRepositoryProvider)
          .generaAllenamento(
            ParametriGenerazione(
              gruppo: widget.gruppoLabel,
              volumeMetri: voce.seduta.volumeMetri,
              volumeLavoroCentraleM: voce.volumeLavoroCentraleM,
              focus: voce.focus,
              dettaglioBraccia: voce.dettaglioBraccia,
              dettaglioGambe: voce.dettaglioGambe,
              stileTecnica: voce.stileTecnica,
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
              blocchiDisponibili: widget.blocchi,
            ),
          );
      if (!mounted) return;
      setState(() {
        _sedute[indice] = SedutaConScheda(
          seduta: voce.seduta,
          scheda: nuovaScheda,
          data: voce.data,
          focus: voce.focus,
          dettaglioBraccia: voce.dettaglioBraccia,
          dettaglioGambe: voce.dettaglioGambe,
          stileTecnica: voce.stileTecnica,
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

  /// Ripartenze "vere" per questa serie, ricalcolate dal codice invece di
  /// quelle proposte dall'AI (RIPROGETTAZIONE AI, FASE 3) — stessa logica
  /// di `SchedaGenerataScreen._ripartenzePerSerie`, duplicata perché le
  /// due schermate non condividono una classe base.
  List<RipartenzaCorsia> _ripartenzePerSerie(SerieGenerata s) {
    if (s.zona == null) return s.ripartenzePerCorsia;
    final risultato = <RipartenzaCorsia>[];
    for (final c in widget.assegnazione.corsie) {
      final calcolato = ripartenzaPerSerie(
        zona: s.zona!,
        stile: s.stile,
        distanzaM: s.distanzaM,
        atletiIds: c.atletiIds,
        assegnazione: widget.assegnazione,
      );
      if (calcolato.ripartenzaS != null) {
        risultato.add(
          RipartenzaCorsia(nome: c.nome, ripartenzaS: calcolato.ripartenzaS!),
        );
        continue;
      }
      final daAi = s.ripartenzePerCorsia.where((r) => r.nome == c.nome);
      if (daAi.isNotEmpty) risultato.add(daAi.first);
    }
    return risultato;
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
          final risolto = risolviRipartenza(_ripartenzePerSerie(s), s.note);
          final serieCreata = await serieRepository.createSerie(
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
          // Come in SchedaGenerataScreen: una serie "nuovo" (nessun
          // blocco di libreria adatto trovato dall'AI) finisce in
          // libreria come bozza da approvare — un fallimento qui non
          // deve bloccare un salvataggio già riuscito.
          if (s.nuovo) {
            try {
              await ref
                  .read(trainingBlocksRepositoryProvider)
                  .salvaSerieComeBlocco(
                    clubId: widget.clubId,
                    codice: 'IA-${serieCreata.id.substring(0, 8)}',
                    sport: 'entrambi',
                    titolo: voce.scheda.titolo,
                    serieGruppo: [serieCreata],
                  );
            } catch (_) {}
          }
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
      appBar: AppBar(title: const Text('Proposta dell\'AI')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TestataPagina(
            titolo: 'La settimana proposta',
            numeri: [
              NumeroTestata(valore: '${_sedute.length}', etichetta: 'Sedute'),
              NumeroTestata(
                valore: formattaMetri(totaleMetri),
                etichetta: 'Metri in tutto',
              ),
              if (_sedute.isNotEmpty)
                NumeroTestata(
                  valore: formattaMetri((totaleMetri / _sedute.length).round()),
                  etichetta: 'Per seduta',
                ),
            ],
          ),
          if (_avvisi.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s16),
            Container(
              decoration: BoxDecoration(
                color: colori.attenzioneTenue,
                borderRadius: BorderRadius.circular(AppRadius.pannello),
                border: Border(
                  left: BorderSide(color: colori.attenzione, width: 3),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final avviso in _avvisi)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                      child: Text(
                        avviso,
                        style: AppTypography.corpo.copyWith(
                          color: colori.testo,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          TitoloSezione(
            'Le sedute',
            conteggio: _sedute.length,
            spiegazione:
                'Tocca la data di una seduta per spostarla, la freccia per '
                'vederne le serie. Puoi rigenerarne una sola o toglierla '
                'dal piano prima di salvare.',
          ),
          for (var i = 0; i < _sedute.length; i++) ...[
            _CardSeduta(
              voce: _sedute[i],
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
            const SizedBox(height: AppSpacing.s12),
          ],
          const SizedBox(height: AppSpacing.s12),
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

/// Una seduta della settimana proposta: chiusa mostra data, titolo e
/// metri (per confrontare le sedute a colpo d'occhio), aperta le serie.
class _CardSeduta extends StatefulWidget {
  const _CardSeduta({
    required this.voce,
    required this.sottotitoloSerie,
    required this.onCambiaData,
    required this.onRigenera,
    required this.rigenerandoQuesta,
    required this.onRimuovi,
  });

  final SedutaConScheda voce;
  final String Function(SerieGenerata) sottotitoloSerie;
  final VoidCallback onCambiaData;
  final VoidCallback? onRigenera;
  final bool rigenerandoQuesta;
  final VoidCallback? onRimuovi;

  @override
  State<_CardSeduta> createState() => _CardSedutaState();
}

class _CardSedutaState extends State<_CardSeduta> {
  bool _aperta = false;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final voce = widget.voce;
    return Container(
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      clipBehavior: Clip.antiAlias,
      child: Opacity(
        opacity: widget.rigenerandoQuesta ? 0.5 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Row(
                children: [
                  Tooltip(
                    message: 'Cambia giorno',
                    child: InkWell(
                      onTap: widget.rigenerandoQuesta
                          ? null
                          : widget.onCambiaData,
                      borderRadius: BorderRadius.circular(16),
                      child: RiquadroData(voce.data),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voce.scheda.titolo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.corpoForte.copyWith(
                            color: colori.testo,
                          ),
                        ),
                        Text(
                          '${giornoSettimana(voce.data)} · '
                          '${formattaMetri(voce.scheda.volumeTotaleM)} m',
                          style: AppTypography.piccolo.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: widget.rigenerandoQuesta
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh, color: colori.azione),
                    tooltip: 'Rigenera questa seduta',
                    onPressed: widget.onRigenera,
                  ),
                  if (widget.onRimuovi != null)
                    IconButton(
                      icon: Icon(Icons.close, color: colori.testoSecondario),
                      tooltip: 'Togli questa seduta dal piano',
                      onPressed: widget.rigenerandoQuesta
                          ? null
                          : widget.onRimuovi,
                    ),
                  IconButton(
                    icon: Icon(
                      _aperta ? Icons.expand_less : Icons.expand_more,
                      color: colori.testoSecondario,
                    ),
                    tooltip: _aperta ? 'Nascondi le serie' : 'Mostra le serie',
                    onPressed: () => setState(() => _aperta = !_aperta),
                  ),
                ],
              ),
            ),
            if (_aperta) ...[
              Divider(height: 1, color: colori.linea),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s8,
                  AppSpacing.s16,
                  AppSpacing.s4,
                ),
                child: Text(
                  '${voce.seduta.codice} · lavoro centrale '
                  '${formattaMetri(voce.scheda.volumeLavoroCentraleM)} m',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ),
              for (final s in voce.scheda.serie)
                AppListRow(
                  leading: Text(
                    '${s.ordine}',
                    style: AppTypography.numerica(
                      AppTypography.corpoForte.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ),
                  titolo:
                      '${s.ripetute}×${s.distanzaM}m '
                      '${labelStile(s.stile)} ${labelEsecuzione(s.esecuzione)}',
                  sottotitolo: [
                    widget.sottotitoloSerie(s),
                    if (s.ripartenzePerCorsia.isNotEmpty)
                      formattaRipartenzeCorsia(s.ripartenzePerCorsia),
                    if (s.note != null && s.note!.isNotEmpty) s.note!,
                  ].join('\n'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
