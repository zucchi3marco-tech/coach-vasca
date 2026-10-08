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
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/serie.dart';
import 'pannello_orologio.dart';
import 'riepilogo_volumi.dart';
import 'serie_labels.dart';

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
/// ([PannelloOrologio]) sotto la serie e i pulsanti "Fatta" / "Saltata"
/// (idee prese da Swimtraxx Hub): segnata la serie si passa alla
/// successiva, e quando l'orologio finisce una serie la segna fatta da
/// solo. Le saltate non contano nel carico degli atleti.
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

  /// Segna [s] come fatta o saltata e passa alla successiva; lo stesso
  /// tocco su un esito già segnato lo toglie.
  Future<void> _segna(Serie s, String esito, int indice, int totale) async {
    final nuovo = s.esito == esito ? null : esito;
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

    Widget content = AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      appBar: AppBar(
        title: Text([dataCompatta(allenamento.data), ?contesto].join(' · ')),
        actions: [
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
                  indice: indice,
                  onVai: (i) => _vai(i, serie.length),
                  onPresenze: perAtleta ? null : _apriPresenze,
                  onSegna: perAtleta
                      ? null
                      : (esito) =>
                            _segna(serie[indice], esito, indice, serie.length),
                  orologio: perAtleta
                      ? null
                      : PannelloOrologio(
                          key: _chiaviOrologio.putIfAbsent(
                            serie[indice].id,
                            GlobalKey.new,
                          ),
                          serie: serie[indice],
                          gruppi: _gruppi,
                          distaccoS: _distaccoS,
                          onGruppi: (g) => setState(() => _gruppi = g),
                          onDistacco: (d) => setState(() => _distaccoS = d),
                          onFinita: () => _finitaDallOrologio(
                            serie[indice],
                            indice,
                            serie.length,
                          ),
                        ),
                )
              : _TutteLeSerie(
                  serie: serie,
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

String _testoSerie(Serie s) =>
    '${labelVolumeSerie(s)} ${labelStile(s.stile)} '
    '${labelEsecuzione(s.esecuzione)}';

/// Il modo "allenamento in corso" — tre bande su schermo largo
/// (avanzamento · serie · azioni), una colonna su telefono.
class _UnaAllaVolta extends StatelessWidget {
  const _UnaAllaVolta({
    required this.serie,
    required this.indice,
    required this.onVai,
    required this.onPresenze,
    this.onSegna,
    this.orologio,
  });

  final List<Serie> serie;
  final int indice;
  final ValueChanged<int> onVai;
  final VoidCallback? onPresenze;

  /// Segna la serie in corso come 'fatta' o 'saltata' (null per l'atleta).
  final ValueChanged<String>? onSegna;
  final Widget? orologio;

  @override
  Widget build(BuildContext context) {
    final s = serie[indice];
    // I metri fatti: le serie segnate fatte, e quelle già passate senza
    // essere segnate saltate (come le conta il carico).
    final fatti = [
      for (var i = 0; i < serie.length; i++)
        if (serie[i].fatta || (i < indice && !serie[i].saltata)) serie[i],
    ].fold<int>(0, (t, x) => t + x.distanzaTotaleM);
    final saltate = serie.where((x) => x.saltata).length;
    final totale = serie.fold<int>(0, (t, x) => t + x.distanzaTotaleM);
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
      child: _SerieInGrande(serie: s, prossima: prossima),
    );
    // La serie scorre se non ci sta; l'orologio resta sempre in vista.
    final centro = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: SingleChildScrollView(child: scheda)),
        if (orologio != null) ...[
          const SizedBox(height: AppSpacing.s12),
          orologio!,
        ],
      ],
    );

    final avanzamento = _Avanzamento(
      numero: indice + 1,
      di: serie.length,
      metriFatti: fatti,
      metriTotali: totale,
      saltate: saltate,
    );
    final segna = onSegna;
    final fatta = segna == null
        ? null
        : _BottoneEsito(
            etichetta: 'Fatta',
            icona: s.fatta ? Icons.check_circle : Icons.check_circle_outline,
            scelto: s.fatta,
            onTap: () => segna('fatta'),
          );
    final saltata = segna == null
        ? null
        : _BottoneEsito(
            etichetta: 'Saltata',
            icona: Icons.redo,
            scelto: s.saltata,
            onTap: () => segna('saltata'),
          );

    return LayoutBuilder(
      builder: (context, vincoli) {
        if (vincoli.maxWidth >= 700) {
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
                    if (fatta != null && saltata != null) ...[
                      const SizedBox(height: AppSpacing.s24),
                      fatta,
                      const SizedBox(height: AppSpacing.s12),
                      saltata,
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
            avanzamento,
            const SizedBox(height: AppSpacing.s16),
            Expanded(child: centro),
            if (fatta != null && saltata != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(child: fatta),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(child: saltata),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(child: indietro),
                const SizedBox(width: AppSpacing.s12),
                Expanded(flex: 2, child: avanti),
              ],
            ),
            if (presenze != null) ...[
              const SizedBox(height: AppSpacing.s12),
              presenze,
            ],
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
  });

  final int numero;
  final int di;
  final int metriFatti;
  final int metriTotali;
  final int saltate;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
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
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pillola),
          child: LinearProgressIndicator(
            value: di == 0 ? 0 : numero / di,
            minHeight: 8,
            color: colori.azione,
            backgroundColor: colori.superficieAlt,
          ),
        ),
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
  const _SerieInGrande({required this.serie, required this.prossima});

  final Serie serie;
  final Serie? prossima;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final tablet = Breakpoint.of(context) != Breakpoint.compatto;
    final coloreZona = context.dominio.colorePerZona(
      serie.zona,
      rispetto: colori.linea,
    );
    final numeri = _numeriSerie(serie);
    return LaneRule(
      colore: coloreZona,
      child: PoolCard(
        padding: const EdgeInsets.all(AppSpacing.s24),
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
            if (serie.note != null && serie.note!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                serie.note!.trim(),
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
            if (prossima != null) ...[
              const SizedBox(height: AppSpacing.s24),
              Text(
                'Poi: ${_testoSerie(prossima!)}',
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tutte le serie una sotto l'altra; un tocco su una la apre nel modo
/// "una alla volta".
class _TutteLeSerie extends StatelessWidget {
  const _TutteLeSerie({required this.serie, required this.onApri});

  final List<Serie> serie;
  final ValueChanged<int> onApri;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return ListView.separated(
      itemCount: serie.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        final s = serie[index];
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
                      if (s.esito != null) ...[
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "Fatta" / "Saltata": bersaglio da bordo vasca come [_BottoneVasca],
/// evidenziato quando l'esito è quello segnato.
class _BottoneEsito extends StatelessWidget {
  const _BottoneEsito({
    required this.etichetta,
    required this.icona,
    required this.scelto,
    required this.onTap,
  });

  final String etichetta;
  final IconData icona;
  final bool scelto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      selected: scelto,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(
            AppSpacing.altezzaMinimaBersaglioVasca,
          ),
          backgroundColor: scelto ? colori.azioneTenue : null,
          foregroundColor: colori.testo,
          side: BorderSide(color: scelto ? colori.azione : colori.lineaForte),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pannello),
          ),
          textStyle: AppTypography.corpoForte.copyWith(fontSize: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icona, size: 24),
            const SizedBox(width: AppSpacing.s8),
            Flexible(child: Text(etichetta, maxLines: 1)),
          ],
        ),
      ),
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
