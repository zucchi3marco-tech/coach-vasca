import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/scarica_file.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../application/atleti_providers.dart';
import '../application/excel_atleti.dart';
import '../data/atleti_repository.dart';
import '../domain/atleta.dart';
import '../domain/foglio_atleti.dart';
import 'foglio_codici_screen.dart';

/// Il file scelto dal coach: nome e contenuto.
typedef FileScelto = ({String nome, Uint8List bytes});

enum _Passo { scegli, anteprima, salvataggio, fatto }

const _mimeXlsx =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

const _nomiRuoli = {
  'portiere': 'Portiere',
  'movimento': 'Movimento',
  'centroboa': 'Centroboa',
  'marcatore': 'Marcatore',
  'esterno': 'Esterno',
};

/// «Atleti da un foglio Excel»: il coach sceglie un .xlsx o .csv con gli
/// atleti del club, vede l'anteprima e li aggiunge tutti insieme. Chi c'e'
/// gia' nell'app (stesso cognome, nome e data di nascita) non si duplica:
/// si riempiono solo i campi che nell'app sono vuoti. Il file lo legge
/// l'app sul dispositivo, non viene mandato a nessuno.
class AtletiDaExcelScreen extends ConsumerStatefulWidget {
  const AtletiDaExcelScreen({super.key, required this.clubId, this.scegliFile});

  final String clubId;

  /// Per i test: al posto del selettore di file del sistema.
  final Future<FileScelto?> Function()? scegliFile;

  @override
  ConsumerState<AtletiDaExcelScreen> createState() =>
      _AtletiDaExcelScreenState();
}

class _AtletiDaExcelScreenState extends ConsumerState<AtletiDaExcelScreen> {
  _Passo _passo = _Passo.scegli;
  bool _leggendo = false;
  String? _errore;
  String? _nomeFile;
  List<List<Object?>>? _tabella;
  FoglioAtleti? _foglio;

  /// Squadra scelta per ogni nome sconosciuto: chiave `chiaveSquadra`,
  /// valore l'id della squadra (null = senza squadra).
  final Map<String, String?> _mappa = {};

  // Salvataggio.
  int _fatti = 0;
  int _totale = 0;
  String? _erroreSalvataggio;
  final List<Atleta> _creati = [];
  final Map<String, Atleta> _aggiornati = {};
  int _completati = 0;

  AtletiFilter get _filtro => (clubId: widget.clubId, includeInactive: true);

  List<Gruppo> get _squadre =>
      ref.read(gruppiListProvider(widget.clubId)).value ?? const [];

  /// Gli atleti del club, con quelli appena aggiunti o completati da questa
  /// schermata (la copia locale puo' metterci un attimo ad aggiornarsi).
  List<Atleta> get _esistenti {
    final base = ref.read(atletiListProvider(_filtro)).value ?? const [];
    final ids = {for (final a in base) a.id};
    return [
      for (final a in base) _aggiornati[a.id] ?? a,
      for (final a in _creati)
        if (!ids.contains(a.id)) _aggiornati[a.id] ?? a,
    ];
  }

  Future<FileScelto?> _scegliFileDelSistema() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv'],
      dialogTitle: 'Scegli il foglio con gli atleti',
    );
    if (file == null) return null;
    return (nome: file.name, bytes: await file.readAsBytes());
  }

  Future<void> _scegli() async {
    if (_leggendo) return;
    setState(() {
      _leggendo = true;
      _errore = null;
    });
    try {
      final file = await (widget.scegliFile ?? _scegliFileDelSistema)();
      if (file == null) return;
      _tabella = leggiTabellaAtleti(file.bytes, nomeFile: file.nome);
      _nomeFile = file.nome;
      _creati.clear();
      _aggiornati.clear();
      _completati = 0;
      _mappa.clear();
      _erroreSalvataggio = null;
      _analizza();
      if (mounted) setState(() => _passo = _Passo.anteprima);
    } on FoglioNonLeggibile catch (e) {
      if (mounted) setState(() => _errore = e.message);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _leggendo = false);
    }
  }

  void _analizza() {
    final foglio = analizzaFoglioAtleti(
      _tabella ?? const [],
      squadre: _squadre,
      esistenti: _esistenti,
    );
    _foglio = foglio;
    final chiavi = {
      for (final n in foglio.squadreSconosciute) chiaveSquadra(n),
    };
    _mappa.removeWhere((k, _) => !chiavi.contains(k));
    for (final k in chiavi) {
      _mappa.putIfAbsent(k, () => null);
    }
  }

  void _scaricaModello() {
    if (!scaricaFileDisponibile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il modello si scarica solo dalla versione web.'),
        ),
      );
      return;
    }
    try {
      final bytes = modelloAtleti(
        nomiSquadre: [for (final g in _squadre) g.nome],
      );
      scaricaFile(bytes, 'modello_atleti.xlsx', mimeType: _mimeXlsx);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    }
  }

  void _altroFile() {
    setState(() {
      _passo = _Passo.scegli;
      _foglio = null;
      _tabella = null;
      _errore = null;
      _erroreSalvataggio = null;
    });
  }

  Future<void> _salva() async {
    final foglio = _foglio;
    if (foglio == null || !foglio.ok) return;
    final repo = ref.read(atletiRepositoryProvider);
    final nuovi = foglio.nuovi;
    final completamenti = [
      for (final r in foglio.giaPresenti)
        if (r.completamento(_mappa) case final c?) (r, c),
    ];
    setState(() {
      _passo = _Passo.salvataggio;
      _fatti = 0;
      _totale = nuovi.length + completamenti.length;
      _erroreSalvataggio = null;
    });
    try {
      for (final r in nuovi) {
        final creato = await repo.createAtleta(
          clubId: widget.clubId,
          nome: r.nome,
          cognome: r.cognome,
          dataNascita: r.dataNascita,
          sesso: r.sesso,
          gruppoId: r.gruppoFinale(_mappa),
          emailGenitore: r.email,
          telefonoGenitore: r.telefono,
          consensoPrivacyFirmato: r.consenso,
          note: r.note,
          numeroTesseraFin: r.tessera,
          visitaMedicaScadenza: r.visitaMedica,
          ruolo: r.ruolo,
        );
        _creati.add(creato);
        if (mounted) setState(() => _fatti++);
      }
      for (final (r, c) in completamenti) {
        final a = r.atleta;
        final aggiornato = await repo.updateAtleta(
          originale: a,
          nome: a.nome,
          cognome: a.cognome,
          dataNascita: a.dataNascita,
          sesso: c.sesso,
          gruppoId: c.gruppoId,
          emailGenitore: c.email,
          telefonoGenitore: c.telefono,
          consensoPrivacyFirmato: c.consenso,
          consensoPrivacyData: a.consensoPrivacyData,
          note: c.note,
          numeroTesseraFin: c.tessera,
          visitaMedicaScadenza: c.visitaMedica,
          ruolo: c.ruolo,
          altroGruppoId: a.altroGruppoId,
          giorniAltroGruppo: a.giorniAltroGruppo,
        );
        _aggiornati[a.id] = aggiornato;
        _completati++;
        if (mounted) setState(() => _fatti++);
      }
      if (mounted) setState(() => _passo = _Passo.fatto);
    } catch (e) {
      if (!mounted) return;
      // Chi e' gia' stato aggiunto si riconosce rileggendo lo stesso file.
      _analizza();
      setState(() {
        _passo = _Passo.anteprima;
        _erroreSalvataggio =
            'Aggiunti $_fatti di $_totale. Poi: ${messaggioErrore(e)}. '
            'Puoi riprovare con lo stesso file: chi è già stato aggiunto '
            'viene riconosciuto.';
      });
    }
  }

  void _foglioDeiCodici() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FoglioCodiciScreen(soloAtletaIds: [for (final a in _creati) a.id]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gruppi = ref.watch(gruppiListProvider(widget.clubId));
    final atleti = ref.watch(atletiListProvider(_filtro));
    final pronto = gruppi.hasValue && atleti.hasValue;

    return PopScope(
      canPop: _passo != _Passo.salvataggio,
      child: AppScaffold(
        // Il titolo sta in grande nella testata: qui solo il ritorno.
        appBar: AppBar(automaticallyImplyLeading: _passo != _Passo.salvataggio),
        larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
        bottomNavigationBar: _barraInBasso(pronto),
        body: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: switch (_passo) {
            _Passo.scegli => _scegliPasso(pronto, atleti.hasError),
            _Passo.anteprima => _anteprimaPasso(),
            _Passo.salvataggio => _salvataggioPasso(),
            _Passo.fatto => _fattoPasso(),
          },
        ),
      ),
    );
  }

  // ---- Passo 1: scegli ---------------------------------------------------

  List<Widget> _scegliPasso(bool pronto, bool erroreAtleti) {
    final colori = context.colori;
    return [
      const TestataPagina(
        titolo: 'Atleti da un foglio Excel',
        sottotitolo: 'Aggiungi tutti gli atleti del club in una volta sola.',
      ),
      const SizedBox(height: AppSpacing.s16),
      _Scheda(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nel foglio servono tre colonne: Cognome, Nome e Data di '
              'nascita.',
              style: AppTypography.corpoForte.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Le altre sono facoltative: Squadra, Ruolo, Sesso, Tessera '
              'FIN, Email e Telefono del genitore, Visita medica, Consenso privacy, Note. '
              'Se parti dal modello, trovi già tutti i titoli giusti.',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Chi c\'è già nell\'app non viene aggiunto due volte: se nel '
              'foglio ha dati che nell\'app mancano, li completo senza '
              'cambiare quello che hai già scritto.',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 18, color: colori.ok),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    'Il file lo legge l\'app qui, non viene mandato a '
                    'nessuno.',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (_errore != null) ...[
        const SizedBox(height: AppSpacing.s16),
        ErrorBanner(messaggio: _errore!),
      ],
      if (erroreAtleti && !pronto) ...[
        const SizedBox(height: AppSpacing.s16),
        const ErrorBanner(
          messaggio: 'Non riesco a leggere gli atleti del club.',
          suggerimento: 'Controlla la connessione e riapri questa pagina.',
        ),
      ],
    ];
  }

  // ---- Passo 2: anteprima ------------------------------------------------

  List<Widget> _anteprimaPasso() {
    final foglio = _foglio;
    if (foglio == null) return const [];
    final colori = context.colori;
    final squadre = _squadre;

    final intestazione = <Widget>[
      TestataPagina(
        titolo: 'Atleti da un foglio Excel',
        sottotitolo: _nomeFile,
        numeri: foglio.ok
            ? [
                NumeroTestata(
                  valore: '${foglio.nuovi.length}',
                  etichetta: 'Nuovi',
                ),
                NumeroTestata(
                  valore: '${foglio.giaPresenti.length}',
                  etichetta: 'Già nell\'app',
                ),
                NumeroTestata(
                  valore: '${foglio.quantiDaCompletare(_mappa)}',
                  etichetta: 'Da completare',
                ),
                NumeroTestata(
                  valore: '${foglio.escluse.length}',
                  etichetta: 'Restano fuori',
                ),
              ]
            : const [],
      ),
      const SizedBox(height: AppSpacing.s16),
      if (_erroreSalvataggio != null) ...[
        ErrorBanner(messaggio: _erroreSalvataggio!),
        const SizedBox(height: AppSpacing.s16),
      ],
    ];

    if (!foglio.ok) {
      return [...intestazione, ErrorBanner(messaggio: foglio.errore!)];
    }

    String? nomeSquadra(String? id) {
      if (id == null) return null;
      for (final g in squadre) {
        if (g.id == id) return g.nome;
      }
      return null;
    }

    return [
      ...intestazione,
      if (foglio.colonneRiconosciute.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s12),
          child: Text(
            'Ho riconosciuto le colonne: '
            '${foglio.colonneRiconosciute.join(', ')}.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ),
      for (final avviso in foglio.avvisi)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s12),
          child: _Fascia(testo: avviso),
        ),
      if (foglio.squadreSconosciute.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s12),
        const TitoloSezione('Squadre che non conosco'),
        _Scheda(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Questi nomi del foglio non sono squadre del club. Scegli '
                'dove mettere gli atleti.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              for (final nome in foglio.squadreSconosciute) ...[
                const SizedBox(height: AppSpacing.s16),
                AppSelect<String>(
                  key: ValueKey('squadra-${chiaveSquadra(nome)}'),
                  etichetta: '«$nome» nel foglio',
                  value: _mappa[chiaveSquadra(nome)] ?? '',
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Senza squadra'),
                    ),
                    for (final g in squadre)
                      DropdownMenuItem(value: g.id, child: Text(g.nome)),
                  ],
                  onChanged: (v) => setState(
                    () => _mappa[chiaveSquadra(nome)] = (v == null || v.isEmpty)
                        ? null
                        : v,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      if (foglio.nuovi.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s24),
        TitoloSezione('Da aggiungere', conteggio: foglio.nuovi.length),
        _Scheda(
          paddingOrizzontale: 0,
          child: _Elenco([
            for (final r in foglio.nuovi)
              _RigaAtleta(
                titolo: r.nomeCompleto,
                dettaglio:
                    'Nato il ${dataIt(r.dataNascita)}'
                    '${_squadraTesto(r, nomeSquadra)}',
                pastiglia: _nomiRuoli[r.ruolo],
                avvisi: r.avvisi,
              ),
          ]),
        ),
      ],
      if (foglio.giaPresenti.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s24),
        TitoloSezione('Già nell\'app', conteggio: foglio.giaPresenti.length),
        _Scheda(
          paddingOrizzontale: 0,
          child: _Elenco([
            for (final r in foglio.giaPresenti)
              _RigaAtleta(
                titolo:
                    '${r.atleta.nomeCompleto}'
                    '${r.atleta.attivo ? '' : ' (non attivo)'}',
                dettaglio: _cosaAggiungo(r.campi(_mappa)),
                avvisi: r.avvisi,
              ),
          ]),
        ),
      ],
      if (foglio.escluse.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s24),
        TitoloSezione('Restano fuori', conteggio: foglio.escluse.length),
        _Scheda(
          paddingOrizzontale: 0,
          child: _Elenco([
            for (final e in foglio.escluse)
              _RigaAtleta(titolo: 'Riga ${e.riga}', dettaglio: e.motivo),
          ]),
        ),
      ],
      if (foglio.colonneNonUsate.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s24),
        Text(
          'Colonne non usate: ${foglio.colonneNonUsate.join(', ')}',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    ];
  }

  String _squadraTesto(RigaFoglio r, String? Function(String?) nomeSquadra) {
    final id = r.gruppoFinale(_mappa);
    final nome = nomeSquadra(id);
    if (nome != null) return ' · $nome';
    if (r.squadraSconosciuta) return ' · Senza squadra';
    return '';
  }

  String _cosaAggiungo(List<CampoAtleta> campi) {
    if (campi.isEmpty) return 'Niente da aggiungere';
    final nomi = [for (final c in campi) c.etichetta];
    final testo = nomi.length == 1
        ? nomi.first
        : '${nomi.sublist(0, nomi.length - 1).join(', ')} e ${nomi.last}';
    return 'Aggiungo $testo';
  }

  Widget? _barraInBasso(bool pronto) {
    if (_passo == _Passo.scegli) {
      return _BarraFissa(
        children: [
          PrimaryButton(
            label: _leggendo
                ? 'Leggo il file...'
                : pronto
                ? 'Scegli il file'
                : 'Un attimo, carico gli atleti...',
            icon: pronto && !_leggendo ? Icons.upload_file_outlined : null,
            onPressed: pronto && !_leggendo ? _scegli : null,
          ),
          const SizedBox(height: AppSpacing.s8),
          SecondaryButton(
            label: 'Scarica il modello',
            icon: Icons.download_outlined,
            onPressed: _scaricaModello,
          ),
        ],
      );
    }
    if (_passo == _Passo.anteprima) {
      final foglio = _foglio;
      final nuovi = foglio?.nuovi.length ?? 0;
      final completati = foglio?.quantiDaCompletare(_mappa) ?? 0;
      final etichetta = _etichettaAggiungi(nuovi, completati);
      final puoi = foglio != null && foglio.ok && (nuovi + completati) > 0;
      return _BarraFissa(
        children: [
          PrimaryButton(label: etichetta, onPressed: puoi ? _salva : null),
          const SizedBox(height: AppSpacing.s8),
          SecondaryButton(label: 'Scegli un altro file', onPressed: _altroFile),
        ],
      );
    }
    if (_passo == _Passo.fatto) {
      final conNuovi = _creati.isNotEmpty;
      return _BarraFissa(
        children: [
          if (conNuovi) ...[
            PrimaryButton(
              label: 'Foglio dei codici per i nuovi',
              onPressed: _foglioDeiCodici,
            ),
            const SizedBox(height: AppSpacing.s8),
            SecondaryButton(
              label: 'Fatto',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] else
            PrimaryButton(
              label: 'Fatto',
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      );
    }
    return null;
  }

  String _etichettaAggiungi(int nuovi, int completati) {
    String atleti(int n) => n == 1 ? '1 atleta' : '$n atleti';
    if (nuovi > 0 && completati > 0) {
      return 'Aggiungi ${atleti(nuovi)} e completane $completati';
    }
    if (nuovi > 0) return 'Aggiungi ${atleti(nuovi)}';
    if (completati > 0) return 'Completa ${atleti(completati)}';
    return 'Niente da aggiungere';
  }

  // ---- Passo 3: salvataggio ----------------------------------------------

  List<Widget> _salvataggioPasso() {
    final colori = context.colori;
    return [
      const TestataPagina(
        titolo: 'Atleti da un foglio Excel',
        sottotitolo: 'Sto aggiungendo gli atleti...',
      ),
      const SizedBox(height: AppSpacing.s16),
      _Scheda(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_fatti di $_totale',
              style: AppTypography.numerica(
                AppTypography.numeroMedio.copyWith(color: colori.testo),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            LinearProgressIndicator(
              value: _totale == 0 ? null : _fatti / _totale,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Non chiudere la pagina finché non ho finito.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ---- Passo 4: fatto ----------------------------------------------------

  List<Widget> _fattoPasso() {
    final colori = context.colori;
    final aggiunti = _creati.length;
    final completati = _completati;
    String atleti(int n) => n == 1 ? '1 atleta' : '$n atleti';
    final frase = switch ((aggiunti > 0, completati > 0)) {
      (true, true) =>
        '${aggiunti == 1 ? 'Aggiunto' : 'Aggiunti'} ${atleti(aggiunti)}, '
            '${completati == 1 ? 'completato' : 'completati'} $completati.',
      (true, false) =>
        '${aggiunti == 1 ? 'Aggiunto' : 'Aggiunti'} ${atleti(aggiunti)}.',
      (false, true) =>
        '${completati == 1 ? 'Completato' : 'Completati'} '
            '${atleti(completati)}.',
      _ => 'Non c\'era niente da aggiungere.',
    };
    return [
      TestataPagina(
        titolo: 'Fatto',
        sottotitolo: _nomeFile,
        numeri: [
          NumeroTestata(valore: '$aggiunti', etichetta: 'Aggiunti'),
          NumeroTestata(valore: '$completati', etichetta: 'Completati'),
        ],
      ),
      const SizedBox(height: AppSpacing.s16),
      _Scheda(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline, color: colori.ok),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    frase,
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                  ),
                  if (aggiunti > 0) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Per far entrare i nuovi atleti nell\'app, stampa il '
                      'foglio dei codici: ognuno riceve il suo.',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Pezzi

class _Scheda extends StatelessWidget {
  const _Scheda({required this.child, this.paddingOrizzontale});

  final Widget child;
  final double? paddingOrizzontale;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingOrizzontale ?? AppSpacing.paddingPannello,
        vertical: paddingOrizzontale == null ? AppSpacing.paddingPannello : 0,
      ),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: child,
    );
  }
}

class _Elenco extends StatelessWidget {
  const _Elenco(this.righe);

  final List<Widget> righe;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      children: [
        for (var i = 0; i < righe.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: colori.linea),
          righe[i],
        ],
      ],
    );
  }
}

class _RigaAtleta extends StatelessWidget {
  const _RigaAtleta({
    required this.titolo,
    required this.dettaglio,
    this.pastiglia,
    this.avvisi = const [],
  });

  final String titolo;
  final String dettaglio;
  final String? pastiglia;
  final List<String> avvisi;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingPannello,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titolo,
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                dettaglio,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              if (pastiglia != null) Pastiglia(pastiglia!),
            ],
          ),
          for (final a in avvisi)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Text(
                a,
                style: AppTypography.etichetta.copyWith(
                  color: colori.attenzione,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Un avviso che vale per tutto il file.
class _Fascia extends StatelessWidget {
  const _Fascia({required this.testo});

  final String testo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colori.attenzioneTenue,
        borderRadius: BorderRadius.circular(AppRadius.controllo),
        border: Border(left: BorderSide(color: colori.attenzione, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: colori.attenzione),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              testo,
              style: AppTypography.piccolo.copyWith(color: colori.testo),
            ),
          ),
        ],
      ),
    );
  }
}

/// La barra fissa in fondo con i pulsanti, centrata e con la stessa
/// larghezza della pagina.
class _BarraFissa extends StatelessWidget {
  const _BarraFissa({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colori.superficie,
        border: Border(top: BorderSide(color: colori.linea)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.larghezzaMassimaCruscotto,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
      ),
    );
  }
}
