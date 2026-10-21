import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tema_provider.dart';
import '../../../widgets/bottone_tema_bordo_vasca.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/nascondi_barra_club.dart';
import '../../../widgets/schermo_acceso.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/per_chi_serie.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../presenze/application/presenze_providers.dart';
import '../../presenze/data/presenze_repository.dart';
import '../../presenze/domain/presenza.dart';
import '../application/secco_providers.dart';
import '../data/serie_fatte_repository.dart';
import '../domain/esercizio_secco.dart';
import '../domain/serie_fatta.dart';
import '../domain/varianti_secco.dart';
import 'registra_secco_screen.dart';

/// Quanto si tiene premuto «Esci» per uscire dal tablet.
const durataTenutaEsci = Duration(seconds: 2);

/// Il tablet della squadra: un tablet in palestra che passa di mano in
/// mano. Chi non ha il telefono tocca il proprio nome, registra la sua
/// seduta a secco serie per serie e passa il tablet al prossimo.
///
/// Gira con l'account dell'allenatore, quindi è chiuso a chiave: niente
/// freccia indietro, il gesto «indietro» non esce, e per uscire si tiene
/// premuto «Esci» per due secondi e si conferma. Così nessuno finisce per
/// sbaglio nel resto dell'app, dove ci sono i dati di salute di tutti.
///
/// È una schermata da bordo vasca (DESIGN.md, sezione 14): bersagli da 64,
/// schermo sempre acceso.
class TabletSquadraScreen extends ConsumerStatefulWidget {
  const TabletSquadraScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  ConsumerState<TabletSquadraScreen> createState() =>
      _TabletSquadraScreenState();
}

class _TabletSquadraScreenState extends ConsumerState<TabletSquadraScreen> {
  String get _seduta => widget.allenamento.id;

  void _avviso(String testo) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(testo),
        persist: false,
        duration: const Duration(seconds: 4),
      ),
    );

  void _suggerisciEsci() => _avviso('Tieni premuto «Esci» per uscire');

  Future<void> _chiediUscita() async {
    final esci = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uscire dal tablet della squadra?'),
        content: const Text(
          'Tornerai alla seduta, dove ci sono i dati di tutti.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(
                88,
                AppSpacing.altezzaMinimaBersaglioVasca,
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Resta'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                88,
                AppSpacing.altezzaMinimaBersaglioVasca,
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
    if (esci == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _apri(
    Atleta atleta,
    List<EsercizioSeduta> righe,
    Map<String, EsercizioSecco> catalogo,
  ) async {
    // Le note sono per l'allenatore: sul tablet non si leggono.
    final esercizi = [
      for (final r in eserciziDellAtleta(righe, atleta.id))
        if (catalogo[r.esercizioId] case final e?)
          EsercizioSedutaAtleta(esercizio: e, riga: r.senzaNote()),
    ];
    if (esercizi.isEmpty) {
      _avviso('Gli esercizi non sono ancora pronti. Riprova fra un momento.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistraSeccoScreen(
          allenamento: widget.allenamento,
          atleta: atleta,
          esercizi: esercizi,
          daTablet: true,
        ),
      ),
    );
    if (mounted) await _segnaPresente(atleta);
  }

  /// Chi ha fatto almeno una serie c'era: se non ha ancora una presenza in
  /// questa seduta la si segna. Quella già scritta (anche «assente») non
  /// si tocca.
  ///
  /// Si leggono i dati del telefono, non i provider di questa schermata:
  /// mentre l'atleta registra, la lista è coperta e i suoi provider sono
  /// in pausa, quindi al ritorno hanno ancora i valori di prima.
  Future<void> _segnaPresente(Atleta atleta) async {
    final serie = ref.read(serieFatteRepositoryProvider);
    final presenze = ref.read(presenzeRepositoryProvider);
    try {
      final fatte = await serie.watchPerAtleta(atleta.id).first;
      if (!fatte.any((f) => f.allenamentoId == _seduta)) return;
      final segnate = await presenze.watchPerAllenamento(_seduta).first;
      if (segnate.any((p) => p.atletaId == atleta.id)) return;
      await presenze.segnaPresenza(
        allenamentoId: _seduta,
        atletaId: atleta.id,
        stato: statoPresente,
      );
    } catch (e) {
      if (mounted) _avviso('Presenza non segnata. ${messaggioErrore(e)}');
    }
  }

  @override
  Widget build(BuildContext context) =>
      NascondiBarraClub(child: SchermoAcceso(child: _costruisci(context)));

  Widget _costruisci(BuildContext context) {
    final a = widget.allenamento;
    final temaVasca = temaBordoVascaDa(
      ref.watch(temaBordoVascaOverrideProvider),
    );
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: a.clubId, includeInactive: false)),
    );
    final righeAsync = ref.watch(eserciziSedutaProvider(_seduta));
    final catalogo = {
      for (final e
          in ref.watch(eserciziSeccoProvider(a.clubId)).value ??
              const <EsercizioSecco>[])
        e.id: e,
    };
    final fatte =
        ref.watch(serieFatteSedutaProvider(_seduta)).value ??
        const <SerieFatta>[];
    final stati = {
      for (final p
          in ref.watch(presenzeListProvider(_seduta)).value ??
              const <Presenza>[])
        p.atletaId: p.stato,
    };

    final Widget corpo;
    if (atletiAsync.hasError || righeAsync.hasError) {
      corpo = ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          ErrorBanner(
            messaggio: 'Non è stato possibile caricare la seduta.',
            suggerimento: 'Chiedi all\'allenatore di riaprire il tablet.',
            dettaglioTecnico: messaggioErrore(
              atletiAsync.error ?? righeAsync.error!,
            ),
          ),
        ],
      );
    } else if (!atletiAsync.hasValue || !righeAsync.hasValue) {
      corpo = const Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: LoadingSkeletonList(righe: 4),
      );
    } else if (righeAsync.requireValue.isEmpty) {
      corpo = const EmptyState(
        icona: Icons.fitness_center,
        titolo: 'Nessun esercizio nella seduta',
        descrizione:
            'L\'allenatore deve prima scegliere gli esercizi della seduta.',
        azionePrincipale: '',
      );
    } else {
      final righe = righeAsync.requireValue;
      final atleti = _ordinati(
        atletiDellAllenamento(
          atletiAsync.requireValue,
          gruppoId: a.gruppoId,
          serie: const [],
        ),
        stati,
      );
      if (atleti.isEmpty) {
        corpo = const EmptyState(
          icona: Icons.groups_outlined,
          titolo: 'Nessun atleta nel gruppo',
          descrizione:
              'L\'allenatore deve prima aggiungere gli atleti al gruppo.',
          azionePrincipale: '',
        );
      } else {
        final tessere = [
          for (final atleta in atleti)
            _tessera(atleta, righe, fatte, stati[atleta.id], catalogo),
        ];
        corpo = _GrigliaTessere(tessere: tessere);
      }
    }

    Widget pagina = PopScope(
      canPop: false,
      onPopInvokedWithResult: (esce, _) {
        if (!esce) _avviso('Per uscire tieni premuto «Esci»');
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 72,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tablet della squadra',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Dentro il tema da bordo vasca: i colori sono i suoi.
              Builder(
                builder: (temaContext) => Text(
                  '${quandoEsteso(a.data)} · ${a.titoloMostrato}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.piccolo.copyWith(
                    color: temaContext.colori.testoSecondario,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            _BottoneEsci(
              onSuggerimento: _suggerisciEsci,
              onCompletato: _chiediUscita,
            ),
            const BottoneTemaBordoVasca(),
            const SizedBox(width: AppSpacing.s4),
          ],
        ),
        body: SafeArea(child: corpo),
      ),
    );
    if (temaVasca != null) pagina = Theme(data: temaVasca, child: pagina);
    return pagina;
  }

  /// Prima chi c'è (presente o in ritardo), poi chi non è ancora segnato,
  /// in fondo chi è assente o giustificato; in ogni gruppo per cognome.
  List<Atleta> _ordinati(List<Atleta> atleti, Map<String, String> stati) {
    int gruppo(Atleta a) {
      final stato = stati[a.id];
      if (stato == null) return 1;
      return contaComePresente(stato) ? 0 : 2;
    }

    return [...atleti]..sort((x, y) {
      final g = gruppo(x).compareTo(gruppo(y));
      if (g != 0) return g;
      final c = x.cognome.toLowerCase().compareTo(y.cognome.toLowerCase());
      return c != 0 ? c : x.nome.toLowerCase().compareTo(y.nome.toLowerCase());
    });
  }

  Widget _tessera(
    Atleta atleta,
    List<EsercizioSeduta> righe,
    List<SerieFatta> fatte,
    String? stato,
    Map<String, EsercizioSecco> catalogo,
  ) {
    final sue = eserciziDellAtleta(righe, atleta.id);
    final conto = contaSerie(sue, [
      for (final f in fatte)
        if (f.atletaId == atleta.id) f,
    ]);
    return _TesseraAtleta(
      nome: atleta.nomeCompleto,
      fatte: conto.fatte,
      totali: conto.totali,
      // Chi non c'è si vede, ma resta toccabile: può essere arrivato dopo.
      stato: stato == null || contaComePresente(stato)
          ? null
          : etichettaStatoPresenza(stato),
      onTap: sue.isEmpty ? null : () => _apri(atleta, righe, catalogo),
    );
  }
}

/// Le tessere in una griglia che si adatta: una colonna sul telefono
/// stretto, due o tre su tablet, quattro sullo schermo largo. Ogni riga ha
/// l'altezza della sua tessera più alta (testo grande).
class _GrigliaTessere extends StatelessWidget {
  const _GrigliaTessere({required this.tessere});

  final List<Widget> tessere;

  static int colonne(double larghezza) {
    if (larghezza < 420) return 1;
    if (larghezza < 700) return 2;
    if (larghezza < 1000) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, vincoli) {
      final n = colonne(vincoli.maxWidth);
      final righe = [
        for (var i = 0; i < tessere.length; i += n)
          tessere.sublist(i, i + n > tessere.length ? tessere.length : i + n),
      ];
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.s16),
        itemCount: righe.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (_, i) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < n; c++) ...[
                    if (c > 0) const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: c < righe[i].length
                          ? righe[i][c]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Il nome di un atleta, a quante serie è e, se ha finito, «Finito».
class _TesseraAtleta extends StatelessWidget {
  const _TesseraAtleta({
    required this.nome,
    required this.fatte,
    required this.totali,
    required this.stato,
    required this.onTap,
  });

  final String nome;
  final int fatte;
  final int totali;

  /// «Assente», «Giustificato»: solo per chi non c'è.
  final String? stato;

  /// Null: l'atleta non ha esercizi in questa seduta.
  final VoidCallback? onTap;

  bool get _finito => totali > 0 && fatte >= totali;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final avanzamento = totali == 0
        ? 'Nessun esercizio per lui'
        : _finito
        ? 'Finito'
        : '$fatte di $totali serie';
    final riga2 = [?stato, avanzamento].join(' · ');
    return Semantics(
      button: onTap != null,
      label: '$nome. $riga2',
      excludeSemantics: true,
      child: Material(
        color: _finito ? colori.okTenue : colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.altezzaMinimaBersaglioVasca,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pannello),
              border: Border.all(color: _finito ? colori.ok : colori.linea),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titolo.copyWith(
                          color: stato == null
                              ? colori.testo
                              : colori.testoSecondario,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        riga2,
                        style: AppTypography.numerica(AppTypography.corpo)
                            .copyWith(color: colori.testoSecondario),
                      ),
                    ],
                  ),
                ),
                if (_finito) ...[
                  const SizedBox(width: AppSpacing.s8),
                  Icon(Icons.check_circle, size: 32, color: colori.ok),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Esci» si tiene premuto per due secondi: la barra si riempie, e solo
/// alla fine si chiede conferma. Un tocco breve ricorda come si fa.
class _BottoneEsci extends StatefulWidget {
  const _BottoneEsci({
    required this.onSuggerimento,
    required this.onCompletato,
  });

  final VoidCallback onSuggerimento;
  final VoidCallback onCompletato;

  @override
  State<_BottoneEsci> createState() => _BottoneEsciState();
}

class _BottoneEsciState extends State<_BottoneEsci>
    with SingleTickerProviderStateMixin {
  /// Solo la barra che si riempie: chi decide è il timer.
  late final _progresso = AnimationController(
    vsync: this,
    duration: durataTenutaEsci,
  );
  Timer? _tenuta;

  /// La tenuta è arrivata in fondo: il dito che si alza dopo non conta.
  bool _completato = false;

  @override
  void dispose() {
    _tenuta?.cancel();
    _progresso.dispose();
    super.dispose();
  }

  void _premuto() {
    _completato = false;
    _progresso.forward(from: 0);
    _tenuta?.cancel();
    _tenuta = Timer(durataTenutaEsci, () {
      _completato = true;
      _progresso.value = 1;
      widget.onCompletato();
    });
  }

  void _annulla() {
    _tenuta?.cancel();
    _completato = false;
    _progresso.value = 0;
  }

  void _rilasciato() {
    final finito = _completato;
    _annulla();
    if (!finito) widget.onSuggerimento();
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      button: true,
      label: 'Esci. Tieni premuto per uscire',
      excludeSemantics: true,
      onTap: widget.onSuggerimento,
      onLongPress: widget.onCompletato,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _premuto(),
        onPointerUp: (_) => _rilasciato(),
        onPointerCancel: (_) => _annulla(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 96,
            minHeight: AppSpacing.altezzaMinimaBersaglioVasca - 8,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.controllo),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colori.lineaForte),
                borderRadius: BorderRadius.circular(AppRadius.controllo),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _progresso,
                      builder: (_, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progresso.value,
                          heightFactor: 1,
                          child: ColoredBox(color: colori.azioneTenue),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, size: 20, color: colori.testo),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          'Esci',
                          style: AppTypography.corpoForte.copyWith(
                            color: colori.testo,
                          ),
                        ),
                      ],
                    ),
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
