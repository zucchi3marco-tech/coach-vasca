import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/cap_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../application/pallanuoto_providers.dart';
import '../data/distinta_repository.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/numeri_distinta.dart';
import '../domain/partita.dart';

/// La pagina dove l'allenatore spunta tutti i convocati insieme e salva
/// una volta sola (al posto del dialogo "Aggiungi convocato", un atleta
/// alla volta). Chiude con `true` se ha salvato.
class ScegliConvocatiScreen extends ConsumerStatefulWidget {
  const ScegliConvocatiScreen({required this.partita, super.key});

  final Partita partita;

  @override
  ConsumerState<ScegliConvocatiScreen> createState() =>
      _ScegliConvocatiScreenState();
}

/// Cosa succede se si salva adesso: chi entra, chi esce, con quali numeri.
class _Piano {
  const _Piano({
    required this.esistenti,
    required this.scelti,
    required this.numeri,
    required this.capitano,
    required this.vice,
    required this.aggiungi,
    required this.togli,
    required this.modificato,
  });

  /// Chi è già in distinta (id dell'atleta → la sua riga).
  final Map<String, DistintaGiocatore> esistenti;

  /// Gli atleti spuntati, nell'ordine in cui sono stati toccati.
  final List<String> scelti;

  /// Il numero che ogni spuntato avrà: quello che ha già, o quello nuovo.
  final Map<String, int> numeri;

  /// Capitano e vice dell'ultima partita che entrano adesso (id atleta).
  final String? capitano;
  final String? vice;

  final List<NuovoConvocato> aggiungi;

  /// Gli id delle righe della distinta da togliere.
  final List<String> togli;

  final bool modificato;
}

class _ScegliConvocatiScreenState extends ConsumerState<ScegliConvocatiScreen> {
  /// Gli atleti spuntati, nell'ordine in cui il coach li ha toccati (i
  /// numeri dei nuovi si danno in quest'ordine).
  final List<String> _scelti = [];

  /// Chi era già in distinta e ho già visto: la distinta si legge una
  /// volta sola all'arrivo dei dati, poi comanda il coach.
  final Set<String> _visti = {};

  bool _salvando = false;
  String? _errore;

  Partita get _partita => widget.partita;

  /// Porta nella scelta chi è in distinta (la prima volta che lo vedo) e
  /// toglie chi non c'è più fra gli atleti. Si chiama dal build: tocca
  /// solo i campi che il build legge subito dopo, non serve un setState.
  void _allinea(
    List<DistintaGiocatore> distinta,
    Map<String, Atleta> atletiPerId,
  ) {
    for (final g in distinta) {
      if (_visti.add(g.atletaId) && !_scelti.contains(g.atletaId)) {
        _scelti.add(g.atletaId);
      }
    }
    final inDistinta = {for (final g in distinta) g.atletaId};
    _scelti.removeWhere(
      (id) => !atletiPerId.containsKey(id) && !inDistinta.contains(id),
    );
  }

  _Piano _calcola(
    List<DistintaGiocatore> distinta,
    Map<String, Atleta> atletiPerId,
    UltimaDistinta? ultima,
  ) {
    final esistenti = {for (final g in distinta) g.atletaId: g};
    final insieme = _scelti.toSet();
    final restano = [
      for (final g in distinta)
        if (insieme.contains(g.atletaId)) g,
    ];
    final nuovi = <ConvocatoScelto>[
      for (final id in _scelti)
        if (!esistenti.containsKey(id))
          (atletaId: id, portiere: atletiPerId[id]?.portiere ?? false),
    ];
    final ultimaPartita =
        ultima?.perAtleta ?? const <String, NellUltimaPartita>{};
    final proposti = numeriProposti(
      occupati: {for (final g in restano) g.numeroCalottina},
      nuovi: nuovi,
      ultimaPartita: ultimaPartita,
      massimo: _partita.numeroMaxConvocati,
    );
    final capitani = capitaniProposti(
      convocati: _scelti,
      ultimaPartita: ultimaPartita,
      haGiaCapitano: restano.any((g) => g.capitano),
      haGiaVice: restano.any((g) => g.viceCapitano),
    );
    return _Piano(
      esistenti: esistenti,
      scelti: List.of(_scelti),
      numeri: {
        for (final g in restano) g.atletaId: g.numeroCalottina,
        ...proposti,
      },
      capitano: capitani.capitano,
      vice: capitani.vice,
      aggiungi: [
        for (final n in nuovi)
          (
            atletaId: n.atletaId,
            numero: proposti[n.atletaId]!,
            portiere: n.portiere,
            capitano: n.atletaId == capitani.capitano,
            viceCapitano: n.atletaId == capitani.vice,
          ),
      ],
      togli: [
        for (final g in distinta)
          if (!insieme.contains(g.atletaId)) g.id,
      ],
      modificato:
          insieme.length != esistenti.length ||
          !insieme.containsAll(esistenti.keys),
    );
  }

  void _avviso(String testo) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(testo)));
  }

  void _avvisoPieno() => _avviso(
    'Sei a ${_partita.numeroMaxConvocati}: togline uno per aggiungerne '
    'un altro.',
  );

  void _tocca(String atletaId) {
    if (_salvando) return;
    if (_scelti.contains(atletaId)) {
      setState(() => _scelti.remove(atletaId));
      return;
    }
    if (_scelti.length >= _partita.numeroMaxConvocati) {
      _avvisoPieno();
      return;
    }
    setState(() => _scelti.add(atletaId));
  }

  /// Tutti quelli della squadra non ancora spuntati, in ordine alfabetico,
  /// finché c'è posto.
  void _tuttaLaSquadra(List<Atleta> squadra) {
    if (_salvando) return;
    if (_scelti.length >= _partita.numeroMaxConvocati) {
      _avvisoPieno();
      return;
    }
    setState(() {
      for (final a in squadra) {
        if (_scelti.length >= _partita.numeroMaxConvocati) break;
        if (!_scelti.contains(a.id)) _scelti.add(a.id);
      }
    });
  }

  /// La scelta diventa quella dell'ultima partita, in ordine di numero.
  void _comeUltima(UltimaDistinta ultima, Set<String> disponibili) {
    if (_salvando) return;
    setState(() {
      _scelti
        ..clear()
        ..addAll(
          convocatiUltimaPartita(ultima.perAtleta)
              .where(disponibili.contains)
              .take(_partita.numeroMaxConvocati),
        );
    });
  }

  void _togliTutti() {
    if (_salvando) return;
    setState(_scelti.clear);
  }

  Future<void> _salva(_Piano piano) async {
    setState(() {
      _salvando = true;
      _errore = null;
    });
    try {
      await ref
          .read(distintaRepositoryProvider)
          .salvaConvocati(
            partitaId: _partita.id,
            togli: piano.togli,
            aggiungi: piano.aggiungi,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errore = messaggioErrore(e);
          _salvando = false;
        });
      }
    }
  }

  Future<void> _chiediDiUscire() async {
    final esci = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uscire senza salvare?'),
        content: const Text(
          'Le modifiche ai convocati non sono ancora salvate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Resta'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.colori.rosso,
            ),
            child: const Text('Esci senza salvare'),
          ),
        ],
      ),
    );
    if (esci == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final distintaAsync = ref.watch(distintaListProvider(_partita.id));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: _partita.clubId, includeInactive: false)),
    );
    final gruppi =
        ref.watch(gruppiListProvider(_partita.clubId)).value ??
        const <Gruppo>[];
    final ultima = ref
        .watch(ultimaDistintaProvider(chiaveDistinta(_partita)))
        .value;
    final distinta = distintaAsync.value;
    final atleti = atletiAsync.value;

    final _Piano? piano;
    final List<Widget> corpo;
    if (distinta != null && atleti != null) {
      final pallanuoto = [
        for (final a in atleti)
          if (a.sport == 'pallanuoto') a,
      ];
      final atletiPerId = {for (final a in pallanuoto) a.id: a};
      _allinea(distinta, atletiPerId);
      final calcolato = _calcola(distinta, atletiPerId, ultima);
      piano = calcolato;
      corpo = _corpo(
        piano: calcolato,
        atleti: pallanuoto,
        gruppi: gruppi,
        ultima: ultima,
      );
    } else if (distintaAsync.hasError && distinta == null) {
      piano = null;
      corpo = [
        ErrorBanner(
          messaggio: 'Non è stato possibile caricare la distinta.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(distintaAsync.error!),
        ),
      ];
    } else if (atletiAsync.hasError && atleti == null) {
      piano = null;
      corpo = [
        ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli atleti.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(atletiAsync.error!),
        ),
      ];
    } else {
      piano = null;
      corpo = const [LoadingSkeletonList(righe: 6)];
    }

    final modificato = piano?.modificato ?? false;
    final numero = piano?.scelti.length ?? 0;
    return PopScope(
      canPop: !modificato,
      onPopInvokedWithResult: (fatto, _) {
        // Mentre salva non si esce: si aspetta la risposta.
        if (!fatto && !_salvando) _chiediDiUscire();
      },
      child: AppScaffold(
        appBar: AppBar(title: const Text('Scegli i convocati')),
        bottomNavigationBar: _BarraSalva(
          etichetta: numero == 0
              ? 'Salva'
              : 'Salva · $numero ${numero == 1 ? 'convocato' : 'convocati'}',
          errore: _errore,
          salvando: _salvando,
          onSalva: modificato ? () => _salva(piano!) : null,
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.s24),
          children: corpo,
        ),
      ),
    );
  }

  List<Widget> _corpo({
    required _Piano piano,
    required List<Atleta> atleti,
    required List<Gruppo> gruppi,
    required UltimaDistinta? ultima,
  }) {
    final colori = context.colori;
    final massimo = _partita.numeroMaxConvocati;
    final numero = piano.scelti.length;
    final pieno = numero >= massimo;
    final nomiGruppi = {for (final g in gruppi) g.id: g.nome};
    final gruppoPartita = _partita.gruppoId;

    // Prima la squadra della partita, con chi si allena con lei in giorni
    // fissi; poi gli altri del club. Per cognome.
    bool dellaSquadra(Atleta a) =>
        gruppoPartita == null ||
        a.gruppoId == gruppoPartita ||
        a.altroGruppoId == gruppoPartita;
    int perCognome(Atleta a, Atleta b) {
      final cognome = a.cognome.toLowerCase().compareTo(
        b.cognome.toLowerCase(),
      );
      return cognome != 0
          ? cognome
          : a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    }

    final squadra = [
      for (final a in atleti)
        if (dellaSquadra(a)) a,
    ]..sort(perCognome);
    final altre = [
      for (final a in atleti)
        if (!dellaSquadra(a)) a,
    ]..sort(perCognome);
    final idAtleti = {for (final a in atleti) a.id};
    // In distinta ma non più fra gli atleti (archiviati): restano, e si
    // possono togliere da qui.
    final fuoriElenco = [
      for (final g in piano.esistenti.values)
        if (!idAtleti.contains(g.atletaId)) g,
    ];

    if (atleti.isEmpty && fuoriElenco.isEmpty) {
      return [
        EmptyState(
          icona: Icons.groups_outlined,
          titolo: 'Nessun atleta di pallanuoto',
          descrizione:
              'Aggiungi gli atleti dalla tab Atleti: poi li potrai '
              'convocare da qui.',
          azionePrincipale: 'Torna alla distinta',
          onAzionePrincipale: () => Navigator.of(context).maybePop(),
        ),
      ];
    }

    final spuntati = {for (final id in piano.scelti) id};
    final daAggiungere = [
      for (final a in squadra)
        if (!spuntati.contains(a.id)) a,
    ];

    Widget riga(Atleta a, {String? daAltraSquadra}) {
      final spuntato = spuntati.contains(a.id);
      final esistente = piano.esistenti[a.id];
      final portiere = esistente?.portiere ?? a.portiere;
      final inUltima = ultima?.perAtleta[a.id];
      return _RigaScelta(
        key: ValueKey(a.id),
        nome: a.nomeCompleto,
        spuntato: spuntato,
        numero: spuntato ? piano.numeri[a.id] : null,
        colore: portiere
            ? CapColore.rossaPortiere
            : _partita.coloreCalottina == 'blu'
            ? CapColore.blu
            : CapColore.bianca,
        ruoli: [
          if (spuntato &&
              ((esistente?.capitano ?? false) || piano.capitano == a.id))
            'Capitano',
          if (spuntato &&
              ((esistente?.viceCapitano ?? false) || piano.vice == a.id))
            'Vice capitano',
          if (portiere) 'Portiere',
        ],
        note: [
          ?daAltraSquadra,
          if (!spuntato && inUltima != null)
            'Nell\'ultima partita il ${inUltima.numero}',
        ],
        bloccata: pieno && !spuntato,
        onTap: () => _tocca(a.id),
      );
    }

    return [
      const SizedBox(height: AppSpacing.s4),
      Text(
        'Tocca i nomi: chi è spuntato va in distinta.',
        style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
      ),
      const SizedBox(height: AppSpacing.s12),
      Row(
        children: [
          Expanded(
            child: Text(
              '$numero / $massimo convocati',
              style: AppTypography.numerica(
                AppTypography.sezione.copyWith(
                  color: colori.testo,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (numero > 0)
            TextButton(
              onPressed: _salvando ? null : _togliTutti,
              child: const Text('Togli tutti'),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.s8),
      _PulsantiRapidi(
        tuttaLaSquadra: daAggiungere.isEmpty || _salvando
            ? null
            : () => _tuttaLaSquadra(squadra),
        comeUltima: ultima == null || _salvando
            ? null
            : () => _comeUltima(ultima, idAtleti),
        mostraComeUltima: ultima != null,
      ),
      if (ultima != null) ...[
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Ultima partita: contro ${ultima.avversario} '
          '(${ultima.data.day} ${mesiBrevi[ultima.data.month - 1]}).',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
      const SizedBox(height: AppSpacing.s24),
      TitoloSezione(
        gruppoPartita != null && nomiGruppi[gruppoPartita] != null
            ? nomiGruppi[gruppoPartita]!
            : 'La squadra',
      ),
      if (squadra.isEmpty)
        const _SezioneVuota('Nessun atleta di pallanuoto in questa squadra.')
      else
        AppListPanel(righe: [for (final a in squadra) riga(a)]),
      if (altre.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s24),
        const TitoloSezione('Dalle altre squadre'),
        AppListPanel(
          righe: [
            for (final a in altre)
              riga(a, daAltraSquadra: nomiGruppi[a.gruppoId]),
          ],
        ),
      ],
      if (fuoriElenco.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s24),
        const TitoloSezione('Non più fra gli atleti'),
        AppListPanel(
          righe: [
            for (final g in fuoriElenco)
              _RigaScelta(
                key: ValueKey(g.atletaId),
                nome: 'Atleta rimosso',
                spuntato: spuntati.contains(g.atletaId),
                numero: spuntati.contains(g.atletaId)
                    ? g.numeroCalottina
                    : null,
                colore: g.portiere
                    ? CapColore.rossaPortiere
                    : _partita.coloreCalottina == 'blu'
                    ? CapColore.blu
                    : CapColore.bianca,
                ruoli: [if (g.portiere) 'Portiere'],
                note: const [],
                bloccata: pieno && !spuntati.contains(g.atletaId),
                onTap: () => _tocca(g.atletaId),
              ),
          ],
        ),
      ],
    ];
  }
}

/// I due modi veloci di riempire la distinta. Su telefono uno sotto
/// l'altro, su schermo largo affiancati.
class _PulsantiRapidi extends StatelessWidget {
  const _PulsantiRapidi({
    required this.tuttaLaSquadra,
    required this.comeUltima,
    required this.mostraComeUltima,
  });

  final VoidCallback? tuttaLaSquadra;
  final VoidCallback? comeUltima;
  final bool mostraComeUltima;

  @override
  Widget build(BuildContext context) {
    final tutta = SecondaryButton(
      label: 'Tutta la squadra',
      icon: Icons.groups_outlined,
      onPressed: tuttaLaSquadra,
    );
    final ultima = SecondaryButton(
      label: 'Come l\'ultima partita',
      icon: Icons.history,
      onPressed: comeUltima,
    );
    return LayoutBuilder(
      builder: (context, vincoli) {
        if (vincoli.maxWidth >= 520) {
          return Row(
            children: [
              Expanded(child: tutta),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: mostraComeUltima ? ultima : const SizedBox()),
            ],
          );
        }
        return Column(
          children: [
            tutta,
            if (mostraComeUltima) ...[
              const SizedBox(height: AppSpacing.s12),
              ultima,
            ],
          ],
        );
      },
    );
  }
}

/// Una sezione senza nessuno dentro, quando la pagina ne ha altre.
class _SezioneVuota extends StatelessWidget {
  const _SezioneVuota(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingPannello),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: Text(
        testo,
        style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
      ),
    );
  }
}

/// Una riga della lista: tocchi ovunque per spuntare. Con la calottina
/// (col numero che avrà) quando è spuntato, un posto vuoto della stessa
/// misura quando no, così i nomi restano allineati.
class _RigaScelta extends StatelessWidget {
  const _RigaScelta({
    required this.nome,
    required this.spuntato,
    required this.numero,
    required this.colore,
    required this.ruoli,
    required this.note,
    required this.bloccata,
    required this.onTap,
    super.key,
  });

  final String nome;
  final bool spuntato;
  final int? numero;
  final CapColore colore;

  /// Capitano, vice, portiere: in colore azione, come nella distinta.
  final List<String> ruoli;

  /// L'altra squadra, il numero dell'ultima partita.
  final List<String> note;

  /// La distinta è piena e questo non è spuntato: si vede spento.
  final bool bloccata;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      container: true,
      checked: spuntato,
      enabled: !bloccata,
      child: Material(
        color: spuntato ? colori.azioneTenue : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.altezzaMinimaRiga,
            ),
            child: Opacity(
              opacity: bloccata ? 0.38 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s8,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: spuntato && numero != null
                          ? CapBadge(numero: numero!, colore: colore)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: AppTypography.corpoForte.copyWith(
                              color: colori.testo,
                            ),
                          ),
                          if (ruoli.isNotEmpty || note.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: AppSpacing.s12,
                              children: [
                                for (final r in ruoli)
                                  Text(
                                    r,
                                    style: AppTypography.piccolo.copyWith(
                                      color: colori.azione,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                for (final n in note)
                                  Text(
                                    n,
                                    style: AppTypography.piccolo.copyWith(
                                      color: colori.testoSecondario,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    // Solo da guardare: il tocco è quello di tutta la riga.
                    ExcludeSemantics(
                      child: IgnorePointer(
                        child: Checkbox(value: spuntato, onChanged: (_) {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La barra fissa in fondo: l'errore (se c'è) e il pulsante che salva.
class _BarraSalva extends StatelessWidget {
  const _BarraSalva({
    required this.etichetta,
    required this.errore,
    required this.salvando,
    required this.onSalva,
  });

  final String etichetta;
  final String? errore;
  final bool salvando;
  final VoidCallback? onSalva;

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
              maxWidth: AppScaffold.larghezzaPredefinita,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errore != null) ...[
                    ErrorBanner(
                      messaggio: errore!,
                      suggerimento:
                          'Riprova. Se l\'errore continua, chiudi e riapri '
                          'l\'app.',
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                  PrimaryButton(
                    label: etichetta,
                    isLoading: salvando,
                    onPressed: onSalva,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
