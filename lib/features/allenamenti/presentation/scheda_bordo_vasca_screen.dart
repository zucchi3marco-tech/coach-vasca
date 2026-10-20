import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tema_provider.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/bottone_tema_bordo_vasca.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/lane_rule.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/nascondi_barra_club.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/schermo_acceso.dart';
import '../../../widgets/zone_chip.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../application/passo_riferimento_provider.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/com_e_andata.dart';
import '../domain/serie.dart';
import '../domain/volume_allenamento.dart';
import 'com_e_andata.dart';
import 'momento_parallelo.dart';
import 'pannello_orologio.dart';
import 'per_chi_serie.dart';
import 'riepilogo_volumi.dart';
import 'serie_labels.dart';
import 'nota_serie.dart';

/// Vista per il tablet a bordo vasca — DESIGN.md sezione 14: tipografia
/// enorme, colori ridotti all'osso, bersagli da 64-72, orizzontale e — a
/// scelta dell'allenatore — sfondo scuro. Solo lettura: la scheda si
/// modifica nel dettaglio "da ufficio".
///
/// Due modi: **una serie alla volta** (il modo dell'allenamento in corso:
/// la serie al centro in grande, avanzamento a sinistra, "Avanti" e
/// "Indietro" a destra, scorrimento col dito) e **tutte le serie** (per
/// leggerla da capo a fondo). Lo schermo resta acceso finché è aperta.
///
/// Nel modo "una alla volta" l'allenatore ha anche l'orologio di vasca
/// ([PannelloOrologio]) sotto la serie e i pulsanti "Fatta" / "In parte" /
/// "Saltata" (idee prese da Swimtraxx Hub): segnata la serie si passa alla
/// successiva, e quando l'orologio finisce una serie la segna fatta da
/// solo. Le saltate non contano nel carico degli atleti, le fatte in
/// parte solo per quanto se n'è fatto.
///
/// Con [perAtleta] la stessa vista serve all'atleta che apre il suo
/// prossimo allenamento dalla dashboard: le serie arrivano dalla funzione
/// che nasconde le note dell'allenatore, il titolo non dipende dai gruppi
/// (che l'atleta non legge) e non c'è "Presenze", che è dell'allenatore.
class SchedaBordoVascaScreen extends ConsumerStatefulWidget {
  const SchedaBordoVascaScreen({
    required this.allenamento,
    this.perAtleta = false,
    super.key,
  });

  final Allenamento allenamento;
  final bool perAtleta;

  @override
  ConsumerState<SchedaBordoVascaScreen> createState() =>
      _SchedaBordoVascaScreenState();
}

class _SchedaBordoVascaScreenState
    extends ConsumerState<SchedaBordoVascaScreen> {
  /// L'allenatore a bordo vasca la segue serie per serie; l'atleta che la
  /// apre da casa la legge tutta.
  late bool _unaAllaVolta = !widget.perAtleta;
  int _corrente = 0;

  /// Partenze sfalsate dell'orologio: valgono per tutte le serie della
  /// seduta, finché non si cambiano.
  int _gruppi = 1;
  int _distaccoS = 10;
  bool _suono = true;

  /// Una chiave globale per l'orologio di ogni serie: girando il telefono
  /// l'orologio passa da una colonna a una riga di tre bande, e senza
  /// questa ripartirebbe da zero a metà serie.
  final _chiaviOrologio = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _vai(int indice, int totale) {
    if (indice < 0 || indice >= totale) return;
    HapticFeedback.selectionClick();
    setState(() => _corrente = indice);
  }

  /// Segna [s] come fatta (tutta) o saltata e passa alla successiva; lo
  /// stesso tocco su un esito già segnato così lo toglie. «Fatta» su una
  /// serie fatta in parte la fa diventare fatta tutta (vedi
  /// [esitoDopoTocco]).
  Future<void> _segna(Serie s, String esito, int indice, int totale) async {
    final nuovo = esitoDopoTocco(s, esito);
    HapticFeedback.selectionClick();
    try {
      await ref.read(serieRepositoryProvider).segnaEsito(s.id, nuovo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      return;
    }
    if (nuovo != null && mounted) _vai(indice + 1, totale);
  }

  /// «In parte»: il foglio chiede quanto se n'è fatto, poi si segna e si
  /// passa alla successiva; «Togli "In parte"» rimette la serie non segnata
  /// e si resta lì. [contesto] è quello dei bottoni, dentro il tema scelto
  /// per il bordo vasca.
  Future<void> _segnaInParte(
    BuildContext contesto,
    Serie s,
    int indice,
    int totale,
  ) async {
    final risposta = await mostraSceltaInParte(contesto, s, bordoVasca: true);
    if (risposta == null || !mounted) return;
    HapticFeedback.selectionClick();
    try {
      await applicaInParte(ref.read(serieRepositoryProvider), s, risposta);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      return;
    }
    if (!risposta.togli && mounted) _vai(indice + 1, totale);
  }

  /// L'orologio ha finito la serie: fatta (se non era già segnata), e si
  /// passa alla successiva, con l'orologio fermo ad aspettare il "Via".
  Future<void> _finitaDallOrologio(Serie s, int indice, int totale) async {
    if (s.esito == null) {
      try {
        await ref.read(serieRepositoryProvider).segnaEsito(s.id, 'fatta');
      } catch (_) {
        // Resta da segnare a mano: l'orologio intanto va avanti.
      }
    }
    if (mounted) _vai(indice + 1, totale);
  }

  void _apriPresenze() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PresenzeScreen(allenamento: widget.allenamento),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      NascondiBarraClub(child: SchermoAcceso(child: _costruisci(context)));

  Widget _costruisci(BuildContext context) {
    final allenamento = widget.allenamento;
    final perAtleta = widget.perAtleta;
    final serieAsync = perAtleta
        ? ref.watch(serieAtletaProvider(allenamento.id))
        : ref.watch(serieListProvider(allenamento.id));
    final temaVasca = temaBordoVascaDa(
      ref.watch(temaBordoVascaOverrideProvider),
    );
    final gruppi = perAtleta
        ? const <Gruppo>[]
        : ref.watch(gruppiListProvider(allenamento.clubId)).value ?? [];
    final contesto = perAtleta
        ? allenamento.titolo
        : {for (final g in gruppi) g.id: g.nome}[allenamento.gruppoId];

    // Per chi è ogni serie (l'atleta vede solo le sue: non serve).
    final atleti = perAtleta
        ? const <Atleta>[]
        : atletiDellAllenamento(
            ref
                    .watch(
                      atletiListProvider((
                        clubId: allenamento.clubId,
                        includeInactive: true,
                      )),
                    )
                    .value ??
                const [],
            gruppoId: allenamento.gruppoId,
            serie: serieAsync.value ?? const [],
          );
    // In un momento in parallelo anche la colonna di tutti lo dice: accanto
    // c'è il lavoro dei portieri.
    final serieCaricate = serieAsync.value ?? const <Serie>[];
    String? perChi(Serie s) {
      if (perAtleta) return null;
      final chi = labelPerChi(s.destinatari, atleti);
      if (chi != null || s.momentoId == null) return chi;
      return eMomento([
            for (final x in serieCaricate)
              if (x.momentoId == s.momentoId) x,
          ])
          ? 'Tutti'
          : null;
    }

    final telefono = Breakpoint.of(context) == Breakpoint.compatto;
    Widget content = AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      appBar: AppBar(
        title: Text([dataCompatta(allenamento.data), ?contesto].join(' · ')),
        actions: [
          // Sul telefono "Presenze" sta qui: in basso lo spazio è della
          // serie e dell'orologio.
          if (telefono && _unaAllaVolta && !perAtleta)
            IconButton(
              tooltip: 'Presenze',
              icon: const Icon(Icons.how_to_reg_outlined),
              onPressed: _apriPresenze,
            ),
          IconButton(
            tooltip: _unaAllaVolta
                ? 'Mostra tutte le serie'
                : 'Una serie alla volta',
            icon: Icon(
              _unaAllaVolta ? Icons.view_agenda_outlined : Icons.crop_square,
            ),
            onPressed: () => setState(() => _unaAllaVolta = !_unaAllaVolta),
          ),
          const BottoneTemaBordoVasca(),
        ],
      ),
      body: serieAsync.when(
        data: (serie) {
          if (serie.isEmpty) {
            return EmptyState(
              icona: Icons.pool_outlined,
              titolo: 'Nessuna serie in questo allenamento',
              descrizione: perAtleta
                  ? 'L\'allenatore non ha ancora inserito le serie di '
                        'questo allenamento.'
                  : 'Aggiungi le serie dalla scheda allenamento per '
                        'vederle qui a bordo vasca.',
              azionePrincipale: 'Torna indietro',
              onAzionePrincipale: () => Navigator.of(context).pop(),
            );
          }
          final indice = _corrente.clamp(0, serie.length - 1);
          return _unaAllaVolta
              ? _UnaAllaVolta(
                  serie: serie,
                  perChi: perChi,
                  nome: (d) => labelPerChi(d, atleti) ?? 'Tutti',
                  indice: indice,
                  onVai: (i) => _vai(i, serie.length),
                  onPresenze: perAtleta ? null : _apriPresenze,
                  onSegna: perAtleta
                      ? null
                      : (esito) =>
                            _segna(serie[indice], esito, indice, serie.length),
                  onInParte: perAtleta
                      ? null
                      : (contesto) => _segnaInParte(
                          contesto,
                          serie[indice],
                          indice,
                          serie.length,
                        ),
                  orologio: perAtleta
                      ? null
                      : PannelloOrologio(
                          key: _chiaviOrologio.putIfAbsent(
                            serie[indice].id,
                            GlobalKey.new,
                          ),
                          serie: serie[indice],
                          riferimento: ref.watch(
                            passoRiferimentoProvider((
                              clubId: allenamento.clubId,
                              gruppoId: allenamento.gruppoId,
                            )),
                          ),
                          gruppi: _gruppi,
                          distaccoS: _distaccoS,
                          onGruppi: (g) => setState(() => _gruppi = g),
                          onDistacco: (d) => setState(() => _distaccoS = d),
                          suono: _suono,
                          onSuono: (s) => setState(() => _suono = s),
                          onFinita: () => _finitaDallOrologio(
                            serie[indice],
                            indice,
                            serie.length,
                          ),
                        ),
                )
              : _TutteLeSerie(
                  serie: serie,
                  perChi: perChi,
                  nome: perAtleta
                      ? (_) => 'Tutti'
                      : (d) => labelPerChi(d, atleti) ?? 'Tutti',
                  onApri: (i) => setState(() {
                    _corrente = i;
                    _unaAllaVolta = true;
                  }),
                );
        },
        loading: () => const LoadingSkeletonList(righe: 5),
        error: (error, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare la scheda.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ),
      bottomNavigationBar: perAtleta || _unaAllaVolta
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: _BottoneVasca(
                  etichetta: 'Segna presenze',
                  icona: Icons.how_to_reg,
                  principale: true,
                  onTap: _apriPresenze,
                ),
              ),
            ),
    );

    if (temaVasca != null) {
      content = Theme(data: temaVasca, child: content);
    }
    return content;
  }
}

/// Recupero, ripartenza e passo: i numeri che l'allenatore legge da
/// bordo vasca, in grande.
List<({String etichetta, String valore})> _numeriSerie(Serie s) => [
  if (s.ripartenzaS != null)
    (etichetta: 'Ripartenza', valore: _comeAlCronometro(s.ripartenzaS!)),
  if (s.recuperoS != null)
    (etichetta: 'Recupero', valore: _comeAlCronometro(s.recuperoS!)),
  if (s.passoObiettivoS != null)
    (etichetta: 'Passo /100m', valore: formatPaceSeconds(s.passoObiettivoS!)),
];

/// Una ripartenza o un recupero come li dice l'allenatore guardando il
/// pace clock: 1'40" o 40", senza centesimi (0:40.00 non si legge da
/// lontano e i centesimi non servono a nessuno).
String _comeAlCronometro(num secondi) {
  final s = secondi.round();
  final m = s ~/ 60;
  final resto = (s % 60).toString().padLeft(m > 0 ? 2 : 1, '0');
  return m > 0 ? '$m\'$resto"' : '$resto"';
}

String _testoSerie(Serie s) => [
  labelVolumeSerie(s),
  ?labelStileSerie(s),
  labelEsecuzione(s.esecuzione),
].join(' ');

/// Il modo "allenamento in corso" — tre bande su schermo largo
/// (avanzamento · serie · azioni), una colonna su telefono.
class _UnaAllaVolta extends StatelessWidget {
  const _UnaAllaVolta({
    required this.serie,
    required this.perChi,
    required this.nome,
    required this.indice,
    required this.onVai,
    required this.onPresenze,
    this.onSegna,
    this.onInParte,
    this.orologio,
  });

  final List<Serie> serie;
  final int indice;
  final String? Function(Serie s) perChi;
  final String Function(Destinatari d) nome;
  final ValueChanged<int> onVai;
  final VoidCallback? onPresenze;

  /// Segna la serie in corso come 'fatta' (tutta) o 'saltata' (null per
  /// l'atleta).
  final ValueChanged<String>? onSegna;

  /// «In parte» sulla serie in corso, con il contesto dei bottoni (null per
  /// l'atleta).
  final void Function(BuildContext contesto)? onInParte;
  final Widget? orologio;

  @override
  Widget build(BuildContext context) {
    final s = serie[indice];
    // I metri fatti: le serie segnate fatte (di quelle in parte, solo i
    // metri fatti) e quelle già passate senza essere segnate saltate (come
    // le conta il carico).
    final delGruppo = filtroDellAtleta(serie, null, 'movimento');
    final fatti = [
      for (var i = 0; i < serie.length; i++)
        if (delGruppo(serie[i]) &&
            (serie[i].fatta || (i < indice && !serie[i].saltata)))
          serie[i],
    ].fold<int>(0, (t, x) => t + volumeFatto(x).metri);
    // Le serie del momento in parallelo della serie in corso, se c'è.
    final momento = [
      if (s.momentoId != null)
        for (final x in serie)
          if (x.momentoId == s.momentoId) x,
    ];
    final saltate = serie.where((x) => x.saltata).length;
    // I metri del gruppo, come nel dettaglio: non quelli dei soli portieri
    // né delle varianti.
    final totale = volumeDi(serieDelGruppo(serie)).metri;
    final prossima = indice + 1 < serie.length ? serie[indice + 1] : null;

    final avanti = _BottoneVasca(
      etichetta: prossima == null ? 'Ultima serie' : 'Avanti',
      icona: Icons.arrow_forward,
      principale: true,
      alto: true,
      onTap: prossima == null ? null : () => onVai(indice + 1),
    );
    final indietro = _BottoneVasca(
      etichetta: 'Indietro',
      icona: Icons.arrow_back,
      onTap: indice == 0 ? null : () => onVai(indice - 1),
    );
    final presenze = onPresenze == null
        ? null
        : _BottoneVasca(
            etichetta: 'Presenze',
            icona: Icons.how_to_reg_outlined,
            onTap: onPresenze,
          );

    // Il centro non è un bersaglio (DESIGN.md 14), ma si scorre col dito
    // per passare alla serie dopo o prima, come si sfoglia un foglio.
    final scheda = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -200) onVai(indice + 1);
        if (v > 200) onVai(indice - 1);
      },
      child: _SerieInGrande(
        serie: s,
        prossima: prossima,
        perChi: perChi,
        inParallelo: momento.isNotEmpty && eMomento(momento) ? momento : null,
        nome: nome,
      ),
    );
    // La serie scorre se non ci sta; l'orologio resta sempre in vista ma
    // non si prende mai più di metà dello spazio: la serie non deve
    // sparire dietro (segnalazione del coach 2026-10-08, su telefono).
    final centro = LayoutBuilder(
      builder: (context, spazio) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: SingleChildScrollView(child: scheda)),
          if (orologio != null) ...[
            const SizedBox(height: AppSpacing.s12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: spazio.maxHeight * 0.5),
              child: SingleChildScrollView(child: orologio),
            ),
          ],
        ],
      ),
    );

    final avanzamento = _Avanzamento(
      numero: indice + 1,
      di: serie.length,
      metriFatti: fatti,
      metriTotali: totale,
      saltate: saltate,
    );
    final segna = onSegna;
    final inParte = onInParte;
    // «Fatta», «In parte» (solo se la serie ha delle scelte) e «Saltata».
    // Sul telefono stanno in una riga, con l'icona sopra la parola.
    List<Widget> esiti({required bool impilati}) =>
        segna == null || inParte == null
        ? const []
        : bottoniEsito(
            s,
            onEsito: segna,
            onInParte: () => inParte(context),
            impilati: impilati,
          );

    return LayoutBuilder(
      builder: (context, vincoli) {
        if (vincoli.maxWidth >= 700) {
          final colonnaEsiti = esiti(impilati: false);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    avanzamento,
                    if (colonnaEsiti.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s24),
                      for (final (i, b) in colonnaEsiti.indexed) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.s12),
                        b,
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(child: centro),
              const SizedBox(width: AppSpacing.s16),
              SizedBox(
                width: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    avanti,
                    const SizedBox(height: AppSpacing.s12),
                    indietro,
                    if (presenze != null) ...[
                      const SizedBox(height: AppSpacing.s32),
                      presenze,
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Avanzamento(
              numero: indice + 1,
              di: serie.length,
              metriFatti: fatti,
              metriTotali: totale,
              saltate: saltate,
              compatto: true,
            ),
            const SizedBox(height: AppSpacing.s12),
            Expanded(child: centro),
            if (esiti(impilati: true) case final riga when riga.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              rigaDiBottoni(riga),
            ],
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                // Metà e metà: "Indietro" deve starci intero, e "Avanti"
                // si riconosce già dal colore pieno.
                Expanded(child: indietro),
                const SizedBox(width: AppSpacing.s12),
                Expanded(child: avanti),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Avanzamento extends StatelessWidget {
  const _Avanzamento({
    required this.numero,
    required this.di,
    required this.metriFatti,
    required this.metriTotali,
    this.saltate = 0,
    this.compatto = false,
  });

  final int numero;
  final int di;
  final int metriFatti;
  final int metriTotali;
  final int saltate;

  /// Sul telefono: una riga e la barra, per lasciare spazio alla serie.
  final bool compatto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final barra = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pillola),
      child: LinearProgressIndicator(
        value: di == 0 ? 0 : numero / di,
        minHeight: 8,
        color: colori.azione,
        backgroundColor: colori.superficieAlt,
      ),
    );
    if (compatto) {
      final secondario = AppTypography.numerica(
        AppTypography.piccolo.copyWith(color: colori.testoSecondario),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Serie ',
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              Text(
                '$numero di $di',
                style: AppTypography.numerica(
                  AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
              ),
              const Spacer(),
              if (saltate > 0)
                Text(
                  saltate == 1 ? '1 saltata · ' : '$saltate saltate · ',
                  style: secondario,
                ),
              if (metriTotali > 0)
                Text(
                  '${formattaMetri(metriFatti)} di '
                  '${formattaMetri(metriTotali)} m',
                  style: secondario,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          barra,
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serie',
          style: AppTypography.etichetta.copyWith(
            color: colori.testoSecondario,
          ),
        ),
        Text(
          '$numero di $di',
          style: AppTypography.numerica(
            AppTypography.numeroGrande.copyWith(color: colori.testo),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        barra,
        if (metriTotali > 0) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            '${formattaMetri(metriFatti)} di ${formattaMetri(metriTotali)} m',
            style: AppTypography.numerica(
              AppTypography.piccolo.copyWith(color: colori.testoSecondario),
            ),
          ),
        ],
        if (saltate > 0)
          Text(
            saltate == 1 ? '1 serie saltata' : '$saltate serie saltate',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
      ],
    );
  }
}

class _SerieInGrande extends StatelessWidget {
  const _SerieInGrande({
    required this.serie,
    required this.prossima,
    required this.perChi,
    required this.nome,
    this.inParallelo,
  });

  final Serie serie;
  final Serie? prossima;
  final String? Function(Serie s) perChi;
  final String Function(Destinatari d) nome;

  /// Le serie del momento in parallelo di [serie]: sotto, tutte le colonne
  /// (mentre il gruppo fa questa, i portieri fanno quella).
  final List<Serie>? inParallelo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final tablet = Breakpoint.of(context) != Breakpoint.compatto;
    final coloreZona = context.dominio.colorePerZona(
      serie.zona,
      rispetto: colori.linea,
    );
    final numeri = _numeriSerie(serie);
    final scheda = LaneRule(
      colore: coloreZona,
      child: PoolCard(
        padding: EdgeInsets.all(tablet ? AppSpacing.s24 : AppSpacing.s16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  labelBlocco(serie.blocco),
                  style: AppTypography.corpoForte.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                if (serie.zona != null) ...[
                  const SizedBox(width: AppSpacing.s8),
                  ZoneChip(sigla: serie.zona!),
                ],
              ],
            ),
            if (perChi(serie) case final chi?) ...[
              const SizedBox(height: AppSpacing.s12),
              EtichettaPerChi(chi, grande: true),
            ],
            const SizedBox(height: AppSpacing.s12),
            Text(
              _testoSerie(serie),
              style:
                  (tablet ? AppTypography.displayTablet : AppTypography.display)
                      .copyWith(color: colori.testo),
            ),
            if (numeri.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s24),
              Wrap(
                spacing: AppSpacing.s40,
                runSpacing: AppSpacing.s16,
                children: [
                  for (final n in numeri)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          n.etichetta,
                          style: AppTypography.corpo.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                        Text(
                          n.valore,
                          style: AppTypography.numerica(
                            (tablet
                                    ? AppTypography.display
                                    : AppTypography.numeroGrande)
                                .copyWith(color: colori.testo),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
            if (serie.attrezzatura != null &&
                serie.attrezzatura!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Con ${serie.attrezzatura!.trim()}',
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
            ],
            if (notaPiena(serie.note) case final nota?) ...[
              const SizedBox(height: AppSpacing.s12),
              NotaSerie(nota, grande: true),
            ],
            if (serie.recuperoDopoS case final secondi?) ...[
              const SizedBox(height: AppSpacing.s16),
              RecuperoFraSerie(secondi, grande: true),
            ],
            if (prossima != null) ...[
              const SizedBox(height: AppSpacing.s24),
              Text(
                'Poi: ${[?perChi(prossima!), _testoSerie(prossima!)].join(': ')}',
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    final momento = inParallelo;
    if (momento == null) return scheda;
    // In una scheda sua, fuori dal filetto: il filetto misura l'altezza
    // del contenuto, e le colonne si dispongono solo dopo aver visto la
    // larghezza.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        scheda,
        const SizedBox(height: AppSpacing.s12),
        PoolCard(
          padding: EdgeInsets.all(tablet ? AppSpacing.s24 : AppSpacing.s16),
          child: _MomentoInVasca(serie: momento, nome: nome),
        ),
      ],
    );
  }
}

/// Tutte le serie una sotto l'altra; un tocco su una la apre nel modo
/// "una alla volta".
class _TutteLeSerie extends StatelessWidget {
  const _TutteLeSerie({
    required this.serie,
    required this.onApri,
    required this.perChi,
    required this.nome,
  });

  final List<Serie> serie;
  final String? Function(Serie s) perChi;
  final String Function(Destinatari d) nome;
  final ValueChanged<int> onApri;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    // Un momento in parallelo è una scheda sola, con le colonne; le altre
    // serie una per scheda.
    final elementi = <List<Serie>>[
      for (final g in raggruppaPerMomento(serie))
        if (eMomento(g))
          g
        else ...[
          for (final s in g) [s],
        ],
    ];
    return ListView.separated(
      itemCount: elementi.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, posizione) {
        final elemento = elementi[posizione];
        if (elemento.length > 1) {
          return PoolCard(
            padding: const EdgeInsets.all(AppSpacing.s20),
            child: _MomentoInVasca(
              serie: elemento,
              nome: nome,
              onApri: (s) => onApri(serie.indexOf(s)),
            ),
          );
        }
        final s = elemento.single;
        final index = serie.indexOf(s);
        final numeri = _numeriSerie(s);
        return InkWell(
          onTap: () => onApri(index),
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          child: LaneRule(
            colore: context.dominio.colorePerZona(
              s.zona,
              rispetto: colori.linea,
            ),
            child: PoolCard(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${index + 1} · ${labelBlocco(s.blocco)}',
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                      if (s.zona != null) ...[
                        const SizedBox(width: AppSpacing.s8),
                        ZoneChip(sigla: s.zona!),
                      ],
                      // Fatta tutta o saltata: a destra, sulla stessa riga.
                      if (s.esito != null && !s.inParte) ...[
                        const Spacer(),
                        Icon(
                          s.fatta ? Icons.check_circle : Icons.redo,
                          size: 20,
                          color: s.fatta ? colori.ok : colori.testoSecondario,
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        Text(
                          s.fatta ? 'Fatta' : 'Saltata',
                          style: AppTypography.etichetta.copyWith(
                            color: colori.testo,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // In parte: quanto se n'è fatto è più lungo, va a capo.
                  if (s.inParte) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Icon(
                          Icons.timelapse,
                          size: 20,
                          color: colori.testoSecondario,
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        Flexible(
                          child: Text(
                            descriviFatto(s),
                            style: AppTypography.numerica(
                              AppTypography.etichetta.copyWith(
                                color: colori.testo,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (perChi(s) case final chi?) ...[
                    const SizedBox(height: AppSpacing.s8),
                    EtichettaPerChi(chi, grande: true),
                  ],
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    _testoSerie(s),
                    style: AppTypography.display.copyWith(color: colori.testo),
                  ),
                  if (numeri.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s24,
                      runSpacing: AppSpacing.s4,
                      children: [
                        for (final n in numeri)
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${n.etichetta} ',
                                  style: AppTypography.piccolo.copyWith(
                                    color: colori.testoSecondario,
                                  ),
                                ),
                                TextSpan(
                                  text: n.valore,
                                  style: AppTypography.numerica(
                                    AppTypography.numeroMedio.copyWith(
                                      color: colori.testo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (notaPiena(s.note) case final nota?) ...[
                    const SizedBox(height: AppSpacing.s12),
                    NotaSerie(nota, grande: true),
                  ],
                  if (s.recuperoDopoS case final secondi?) ...[
                    const SizedBox(height: AppSpacing.s8),
                    RecuperoFraSerie(secondi),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Un momento in parallelo a bordo vasca: "In parallelo" con i minuti e
/// le colonne affiancate, in grande.
class _MomentoInVasca extends StatelessWidget {
  const _MomentoInVasca({required this.serie, required this.nome, this.onApri});

  final List<Serie> serie;
  final String Function(Destinatari d) nome;
  final void Function(Serie s)? onApri;

  @override
  Widget build(BuildContext context) {
    final colonne = colonneConTempo(serie);
    final minuti = colonne.fold(0, (a, c) => c.minuti > a ? c.minuti : a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TestaMomento(minuti: minuti, grande: true),
        const SizedBox(height: AppSpacing.s8),
        ColonneMomento<Serie>(
          serie: serie,
          nome: nome,
          onApri: onApri,
          grande: true,
        ),
      ],
    );
  }
}

/// Bersaglio da bordo vasca: alto 64 (72 per l'azione principale),
/// icona e testo, pieno solo per l'azione principale.
class _BottoneVasca extends StatelessWidget {
  const _BottoneVasca({
    required this.etichetta,
    required this.icona,
    required this.onTap,
    this.principale = false,
    this.alto = false,
  });

  final String etichetta;
  final IconData icona;
  final VoidCallback? onTap;
  final bool principale;
  final bool alto;

  @override
  Widget build(BuildContext context) {
    final altezza = alto ? 72.0 : AppSpacing.altezzaMinimaBersaglioVasca;
    final stile = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(altezza)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pannello),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        AppTypography.corpoForte.copyWith(fontSize: 18),
      ),
    );
    final contenuto = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icona, size: 24),
        const SizedBox(width: AppSpacing.s8),
        Flexible(child: Text(etichetta, maxLines: 1)),
      ],
    );
    return principale
        ? FilledButton(onPressed: onTap, style: stile, child: contenuto)
        : OutlinedButton(onPressed: onTap, style: stile, child: contenuto);
  }
}
