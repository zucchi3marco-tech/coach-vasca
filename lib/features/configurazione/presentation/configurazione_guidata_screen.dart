import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/barra_passi.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/presentation/atleta_form_screen.dart';
import '../../atleti/presentation/atleti_da_excel_screen.dart';
import '../../atleti/presentation/foglio_codici_screen.dart';
import '../../club/application/membri_club_providers.dart';
import '../../club/domain/club.dart';
import '../../club/domain/ruolo_club.dart';
import '../../club/presentation/invita_staff.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/data/gruppi_repository.dart';
import '../../gruppi/domain/categorie_squadre.dart';
import '../../gruppi/domain/gruppo.dart';
import '../application/configurazione_providers.dart';
import '../data/configurazione_repository.dart';
import '../domain/stato_configurazione.dart';

/// La configurazione guidata di un club nuovo, dal passo 2 al 5: le squadre,
/// gli allenatori, gli atleti e i loro codici. Il passo 1 (il club) è
/// `ClubSetupScreen`. Ogni passo si può lasciare per dopo, tranne le squadre:
/// senza una squadra l'app non va avanti.
///
/// [comePagina] false: sta nel corpo di HomeScreen (che ha già Scaffold e
/// barra in alto), come `ClubSetupScreen`. True: è una pagina aperta sopra
/// le altre, con la freccia per chiuderla.
class ConfigurazioneGuidataScreen extends ConsumerStatefulWidget {
  const ConfigurazioneGuidataScreen({
    required this.club,
    required this.onFine,
    this.daPasso = PassoConfigurazione.squadre,
    this.comePagina = false,
    super.key,
  });

  final Club club;

  /// Il passo da cui si parte; prima delle squadre non si va mai.
  final PassoConfigurazione daPasso;

  /// Chiamata quando si finisce l'ultimo passo (con "Fine" o "Lo faccio
  /// dopo").
  final VoidCallback onFine;
  final bool comePagina;

  @override
  ConsumerState<ConfigurazioneGuidataScreen> createState() =>
      _ConfigurazioneGuidataScreenState();
}

class _ConfigurazioneGuidataScreenState
    extends ConsumerState<ConfigurazioneGuidataScreen> {
  final _scroll = ScrollController();
  late PassoConfigurazione _passo =
      widget.daPasso.index < PassoConfigurazione.squadre.index
      ? PassoConfigurazione.squadre
      : widget.daPasso;

  // Le squadre da creare: le categorie toccate e i nomi scritti a mano.
  final Set<String> _categorieScelte = {};
  final List<TextEditingController> _nomi = [TextEditingController()];

  /// Con squadre già create il modulo per aggiungerne si apre a richiesta.
  bool _aggiungendo = false;
  bool _salvando = false;
  String? _errore;

  /// I codici creati in questa sessione, per dirlo sotto il pulsante.
  final List<RuoloClub> _codiciCreati = [];
  bool _alleniDaSolo = false;
  bool _occupato = false;

  String get _clubId => widget.club.id;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in _nomi) {
      c.dispose();
    }
    super.dispose();
  }

  PassoConfigurazione? get _precedente => _passo == PassoConfigurazione.squadre
      ? null
      : PassoConfigurazione.values[_passo.index - 1];

  PassoConfigurazione? get _successivo => _passo == PassoConfigurazione.codici
      ? null
      : PassoConfigurazione.values[_passo.index + 1];

  void _vai(PassoConfigurazione passo) {
    setState(() {
      _passo = passo;
      _errore = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _avanti() {
    final successivo = _successivo;
    if (successivo == null) {
      widget.onFine();
    } else {
      _vai(successivo);
    }
  }

  void _aggiungiNome() => setState(() => _nomi.add(TextEditingController()));

  void _rimuoviNome(int indice) {
    final campo = _nomi[indice];
    setState(() => _nomi.removeAt(indice));
    // Il campo è ancora nell'albero fino al prossimo fotogramma.
    WidgetsBinding.instance.addPostFrameCallback((_) => campo.dispose());
  }

  Future<void> _avantiSquadre() async {
    final esistenti =
        ref.read(gruppiListProvider(_clubId)).value ?? const <Gruppo>[];
    final modulo = esistenti.isEmpty || _aggiungendo;

    // Prima le categorie, nell'ordine dell'elenco, poi i nomi scritti.
    final nuove = <(String, VoidCallback)>[];
    if (modulo) {
      final presenti = {for (final g in esistenti) g.nome.toLowerCase()};
      void aggiungi(String nome, VoidCallback fatto) {
        if (presenti.add(nome.toLowerCase())) nuove.add((nome, fatto));
      }

      for (final categoria in categoriePerSport(widget.club.sport)) {
        if (_categorieScelte.contains(categoria)) {
          aggiungi(categoria, () => _categorieScelte.remove(categoria));
        }
      }
      for (final campo in _nomi) {
        final nome = campo.text.trim();
        if (nome.isNotEmpty) aggiungi(nome, campo.clear);
      }
    }

    if (esistenti.isEmpty && nuove.isEmpty) {
      setState(() => _errore = 'Aggiungi almeno una squadra');
      return;
    }
    if (nuove.isEmpty) {
      setState(() => _aggiungendo = false);
      _avanti();
      return;
    }

    setState(() {
      _salvando = true;
      _errore = null;
      // Il modulo resta in vista anche quando compare la prima squadra: se
      // una delle altre non si crea, ci sono ancora le sue scelte.
      _aggiungendo = true;
    });
    // Appena compare la prima squadra HomeScreen cambierebbe schermata:
    // il percorso guidato è in corso, deve restare questo.
    if (!widget.comePagina) {
      ref.read(configurazioneInCorsoProvider.notifier).inizia(_clubId);
    }
    try {
      final repository = ref.read(gruppiRepositoryProvider);
      var ordine = esistenti.fold(
        0,
        (massimo, g) => math.max(massimo, g.ordine),
      );
      for (final (nome, fatto) in nuove) {
        ordine++;
        await repository.createGruppo(
          clubId: _clubId,
          nome: nome,
          ordine: ordine,
          sport: widget.club.sport,
        );
        if (!mounted) return;
        // Creata: non va riproposta se più avanti qualcosa fallisce.
        fatto();
      }
      if (!mounted) return;
      setState(() => _aggiungendo = false);
      _avanti();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _invita() async {
    if (_occupato) return;
    await invitaStaff(
      context,
      ref,
      clubId: _clubId,
      clubNome: widget.club.nome,
      onOccupato: (occupato) {
        if (mounted) setState(() => _occupato = occupato);
      },
      onCodiceCreato: (ruolo, _) {
        if (!mounted) return;
        ref.invalidate(statoConfigurazioneProvider(_clubId));
        setState(() => _codiciCreati.add(ruolo));
      },
    );
  }

  Future<void> _alleniDaSoloTocca() async {
    if (_occupato) return;
    setState(() {
      _occupato = true;
      _errore = null;
    });
    try {
      await ref
          .read(preferenzeConfigurazioneProvider)
          .segnaAllenaDaSolo(_clubId);
      if (!mounted) return;
      ref.invalidate(statoConfigurazioneProvider(_clubId));
      setState(() => _alleniDaSolo = true);
      _vai(PassoConfigurazione.atleti);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _occupato = false);
    }
  }

  Future<void> _preparaFoglioCodici() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const FoglioCodiciScreen(gruppoId: null),
      ),
    );
    if (!mounted) return;
    ref.invalidate(statoConfigurazioneProvider(_clubId));
  }

  void _apri(Widget pagina) {
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => pagina));
  }

  /// Un passo è fatto per i dati veri; finché lo stato dal server non c'è
  /// (o non si legge) contano solo squadre e atleti, che sono sul telefono.
  bool _fatto(
    PassoConfigurazione passo, {
    required int squadre,
    required int atleti,
    required StatoConfigurazione? stato,
  }) => switch (passo) {
    PassoConfigurazione.club => true,
    PassoConfigurazione.squadre => squadre > 0,
    PassoConfigurazione.atleti => atleti > 0,
    PassoConfigurazione.allenatori =>
      (stato?.fatto(passo) ?? false) ||
          _codiciCreati.isNotEmpty ||
          _alleniDaSolo,
    PassoConfigurazione.codici => stato?.fatto(passo) ?? false,
  };

  String _descrizione(int atleti) => switch (_passo) {
    PassoConfigurazione.club => '',
    PassoConfigurazione.squadre =>
      'Le squadre raggruppano atleti e allenamenti. Ne serve almeno una: le '
          'altre le aggiungi quando vuoi.',
    PassoConfigurazione.allenatori =>
      'Chi allena con te entra nel club con un codice: lo crei qui e glielo '
          'mandi. Tu resti il responsabile: solo tu inviti e togli.',
    PassoConfigurazione.atleti =>
      'Aggiungi gli atleti del club tutti insieme da un foglio Excel, '
          'oppure uno alla volta.',
    PassoConfigurazione.codici =>
      atleti == 0
          ? 'Prima aggiungi gli atleti: poi qui prepari il foglio con il '
                'codice di ognuno.'
          : 'Ogni atleta entra nell\'app con il suo codice personale: '
                'prepari il foglio, lo stampi e dai a ognuno il suo '
                'biglietto. I codici valgono 30 giorni.',
  };

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final gruppi =
        ref.watch(gruppiListProvider(_clubId)).value ?? const <Gruppo>[];
    final elencoAtleti = ref
        .watch(atletiListProvider((clubId: _clubId, includeInactive: false)))
        .value;
    final stato = ref.watch(statoConfigurazioneProvider(_clubId)).value;
    final atleti = elencoAtleti?.length ?? 0;

    bool fatto(PassoConfigurazione p) =>
        _fatto(p, squadre: gruppi.length, atleti: atleti, stato: stato);

    final contenuto = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Passo ${_passo.numero} di ${PassoConfigurazione.totale}',
          style: AppTypography.etichetta.copyWith(
            color: colori.testoSecondario,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        BarraPassi(
          etichetta: 'Passo ${_passo.numero} di ${PassoConfigurazione.totale}',
          passi: [
            for (final p in PassoConfigurazione.values)
              if (p == _passo)
                StatoPassoBarra.corrente
              else if (fatto(p))
                StatoPassoBarra.fatto
              else
                StatoPassoBarra.daFare,
          ],
        ),
        const SizedBox(height: AppSpacing.s20),
        Semantics(
          header: true,
          child: Text(
            _passo.titolo,
            style: AppTypography.titoloXl.copyWith(color: colori.testo),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          _descrizione(atleti),
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        const SizedBox(height: AppSpacing.s24),
        ...switch (_passo) {
          PassoConfigurazione.club ||
          PassoConfigurazione.squadre => _contenutoSquadre(gruppi),
          PassoConfigurazione.allenatori => _contenutoAllenatori(
            fatto(PassoConfigurazione.allenatori),
          ),
          PassoConfigurazione.atleti => _contenutoAtleti(
            elencoAtleti?.length,
            fatto(PassoConfigurazione.atleti),
          ),
          PassoConfigurazione.codici => _contenutoCodici(
            atleti,
            elencoAtleti?.where((a) => a.haAccountCollegato).length ?? 0,
            fatto(PassoConfigurazione.codici),
          ),
        },
        if (_errore != null) ...[
          const SizedBox(height: AppSpacing.s12),
          ErrorBanner(messaggio: _errore!),
        ],
        const SizedBox(height: AppSpacing.s24),
        ..._azioni(fatto(_passo)),
      ],
    );

    if (widget.comePagina) {
      return AppScaffold(
        appBar: AppBar(),
        larghezzaMassima: AppLayout.larghezzaMassimaForm,
        body: SingleChildScrollView(controller: _scroll, child: contenuto),
      );
    }
    // Dentro il corpo di HomeScreen, che ha già Scaffold e barra: colonna
    // centrata come il form del club.
    return SafeArea(
      child: SingleChildScrollView(
        controller: _scroll,
        padding: EdgeInsets.all(
          AppLayout.margineLaterale(Breakpoint.of(context)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.larghezzaMassimaForm,
            ),
            child: contenuto,
          ),
        ),
      ),
    );
  }

  /// "Avanti" quando si può andare, "Lo faccio dopo" quando il passo si può
  /// lasciare, "Indietro" dal secondo passo in poi.
  List<Widget> _azioni(bool passoFatto) {
    final precedente = _precedente;
    final squadre = _passo == PassoConfigurazione.squadre;
    final lasciaPerDopo = !squadre && !passoFatto;
    final ultimo = _passo == PassoConfigurazione.codici;
    return [
      if (squadre)
        PrimaryButton(
          label: 'Avanti',
          isLoading: _salvando,
          onPressed: _salvando ? null : _avantiSquadre,
        )
      else if (passoFatto)
        PrimaryButton(label: ultimo ? 'Fine' : 'Avanti', onPressed: _avanti),
      if (precedente != null) ...[
        const SizedBox(height: AppSpacing.s8),
        // Wrap e non Row: con il testo ingrandito i due pulsanti vanno su
        // due righe invece di uscire dallo schermo.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _occupato ? null : () => _vai(precedente),
              child: const Text('Indietro'),
            ),
            if (lasciaPerDopo)
              TextButton(
                onPressed: _occupato ? null : _avanti,
                child: const Text('Lo faccio dopo'),
              ),
          ],
        ),
      ],
    ];
  }

  /// Il primo pulsante di un passo non fatto è l'azione principale; da fatto
  /// lo è "Avanti" e questi diventano secondari.
  Widget _pulsante({
    required bool principale,
    required String etichetta,
    required IconData icona,
    required VoidCallback? onPressed,
  }) => principale
      ? PrimaryButton(label: etichetta, icon: icona, onPressed: onPressed)
      : SecondaryButton(label: etichetta, icon: icona, onPressed: onPressed);

  Widget _nota(String testo) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.s8),
    child: Text(
      testo,
      style: AppTypography.piccolo.copyWith(
        color: context.colori.testoSecondario,
      ),
    ),
  );

  // --- Le squadre ---------------------------------------------------------

  List<Widget> _contenutoSquadre(List<Gruppo> gruppi) {
    final colori = context.colori;
    final modulo = gruppi.isEmpty || _aggiungendo;
    // Le categorie che hanno già la loro squadra non si riproducono.
    final categorie = [
      for (final c in categoriePerSport(widget.club.sport))
        if (!gruppi.any((g) => g.nome.toLowerCase() == c.toLowerCase())) c,
    ];
    return [
      if (gruppi.isNotEmpty) ...[
        TitoloSezione('Le tue squadre', conteggio: gruppi.length),
        AppListPanel(
          righe: [
            for (final g in gruppi)
              AppListRow(
                titolo: g.nome,
                trailing: Icon(
                  Icons.check_circle_outline,
                  color: colori.ok,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
      if (!modulo)
        SecondaryButton(
          label: 'Aggiungi un\'altra squadra',
          icon: Icons.add,
          onPressed: _salvando
              ? null
              : () => setState(() => _aggiungendo = true),
        )
      else ...[
        if (categorie.isNotEmpty)
          FormGroup(
            titolo: 'Le categorie che alleni',
            campi: [
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final categoria in categorie)
                    TonalChip(
                      etichetta: categoria,
                      selezionato: _categorieScelte.contains(categoria),
                      onSelezionato: _salvando
                          ? null
                          : (scelta) => setState(() {
                              if (scelta) {
                                _categorieScelte.add(categoria);
                              } else {
                                _categorieScelte.remove(categoria);
                              }
                            }),
                    ),
                ],
              ),
            ],
          ),
        FormGroup(
          titolo: categorie.isEmpty ? 'Le squadre' : 'Con un altro nome',
          isUltimo: true,
          campi: [
            for (var i = 0; i < _nomi.length; i++)
              Row(
                key: ObjectKey(_nomi[i]),
                children: [
                  Expanded(
                    child: AppTextField(
                      etichetta: categorie.isEmpty
                          ? 'Nome della squadra'
                          : 'Un\'altra squadra',
                      controller: _nomi[i],
                      abilitato: !_salvando,
                    ),
                  ),
                  if (_nomi.length > 1)
                    IconButton(
                      icon: Icon(Icons.close, color: colori.testoSecondario),
                      tooltip: 'Rimuovi',
                      onPressed: _salvando ? null : () => _rimuoviNome(i),
                    ),
                ],
              ),
            SecondaryButton(
              label: 'Aggiungi un altro nome',
              icon: Icons.add,
              onPressed: _salvando ? null : _aggiungiNome,
            ),
          ],
        ),
      ],
    ];
  }

  // --- Gli allenatori -----------------------------------------------------

  List<Widget> _contenutoAllenatori(bool passoFatto) {
    final colori = context.colori;
    final inDemo = dotenv.isInitialized && modalitaDemo;
    return [
      _pulsante(
        principale: !passoFatto,
        etichetta: 'Invita un allenatore o un assistente',
        icona: Icons.person_add_alt_1_outlined,
        onPressed: (inDemo || _occupato) ? null : _invita,
      ),
      if (inDemo) _nota('Nella demo gli inviti non si creano'),
      for (final ruolo in _codiciCreati)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s8),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: colori.ok, size: 20),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  'Codice per un ${ruolo.etichetta.toLowerCase()} creato',
                  style: AppTypography.piccolo.copyWith(color: colori.testo),
                ),
              ),
            ],
          ),
        ),
      if (!passoFatto) ...[
        const SizedBox(height: AppSpacing.s12),
        SecondaryButton(
          label: 'Alleno da solo',
          icon: Icons.person_outline,
          onPressed: _occupato ? null : _alleniDaSoloTocca,
        ),
      ],
    ];
  }

  // --- Gli atleti ---------------------------------------------------------

  List<Widget> _contenutoAtleti(int? atleti, bool passoFatto) {
    final puoGestire = ref.watch(puoGestireAtletiESquadreProvider(_clubId));
    return [
      if (atleti != null) ...[
        AppListPanel(
          righe: [
            AppListRow(
              leading: const IconaRiquadro(Icons.groups_outlined),
              titolo: switch (atleti) {
                0 => 'Ancora nessun atleta',
                1 => 'Nel club c\'è 1 atleta',
                _ => 'Nel club ci sono $atleti atleti',
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
      ],
      if (puoGestire) ...[
        _pulsante(
          principale: !passoFatto,
          etichetta: 'Da un foglio Excel',
          icona: Icons.table_view_outlined,
          onPressed: () => _apri(AtletiDaExcelScreen(clubId: _clubId)),
        ),
        const SizedBox(height: AppSpacing.s12),
        SecondaryButton(
          label: 'Uno alla volta',
          icon: Icons.person_add_outlined,
          onPressed: () => _apri(AtletaFormScreen(clubId: _clubId)),
        ),
      ],
    ];
  }

  // --- I codici -----------------------------------------------------------

  List<Widget> _contenutoCodici(int atleti, int conAccount, bool passoFatto) {
    if (atleti == 0) {
      return [
        _pulsante(
          principale: true,
          etichetta: 'Torna agli atleti',
          icona: Icons.groups_outlined,
          onPressed: () => _vai(PassoConfigurazione.atleti),
        ),
      ];
    }
    final inDemo = dotenv.isInitialized && modalitaDemo;
    return [
      AppListPanel(
        righe: [
          AppListRow(
            leading: const IconaRiquadro(Icons.vpn_key_outlined),
            titolo: switch (conAccount) {
              0 => 'Nessun atleta ha ancora l\'account',
              1 => '1 atleta ha già l\'account',
              _ => '$conAccount atleti hanno già l\'account',
            },
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.s16),
      _pulsante(
        principale: !passoFatto,
        etichetta: 'Prepara il foglio dei codici',
        icona: Icons.print_outlined,
        onPressed: inDemo ? null : _preparaFoglioCodici,
      ),
      if (inDemo) _nota('Nella demo i codici non si creano'),
    ];
  }
}
