import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/prossimo_allenamento.dart';
import '../../allenamenti/presentation/scheda_bordo_vasca_screen.dart';
import '../../atleti/domain/atleta.dart';
import '../../club/application/current_club_provider.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../pallanuoto/domain/partita.dart';
import 'dati_home_atleta.dart';
import 'grafica_pallanuoto.dart';

const _giorni = [
  'lunedì',
  'martedì',
  'mercoledì',
  'giovedì',
  'venerdì',
  'sabato',
  'domenica',
];
const _mesi = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];

String dataEstesa(DateTime d) =>
    '${_giorni[d.weekday - 1]} ${d.day} ${_mesi[d.month - 1]}';

/// "Oggi", "Domani", "Tra 5 giorni".
String traQuanto(DateTime d, {DateTime? oggi}) {
  final giorni = giorniTra(oggi ?? DateTime.now(), d);
  return switch (giorni) {
    <= 0 => 'Oggi',
    1 => 'Domani',
    _ => 'Tra $giorni giorni',
  };
}

// ---------------------------------------------------------------------------
// Entrata a cascata: ogni blocco sale e compare con un piccolo ritardo.
// ---------------------------------------------------------------------------

class EntrataACascata extends StatelessWidget {
  const EntrataACascata({required this.indice, required this.child, super.key});

  final int indice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + indice * 70),
      curve: Interval(
        (indice * 70) / (360 + indice * 70),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Riquadro che si abbassa leggermente sotto il dito, con vibrazione
/// breve al tocco: si capisce subito che e' premibile.
class Premibile extends StatefulWidget {
  const Premibile({
    required this.child,
    required this.onTap,
    this.raggio = 20,
    this.etichetta,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double raggio;
  final String? etichetta;

  @override
  State<Premibile> createState() => _PremibileState();
}

class _PremibileState extends State<Premibile> {
  bool _premuto = false;
  bool _sopra = false;

  @override
  Widget build(BuildContext context) {
    final ridotto = MediaQuery.disableAnimationsOf(context);
    final scala = _premuto ? 0.97 : (_sopra ? 1.01 : 1.0);
    return Semantics(
      button: widget.onTap != null,
      label: widget.etichetta,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _sopra = true),
        onExit: (_) => setState(() => _sopra = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap == null
              ? null
              : (_) => setState(() => _premuto = true),
          onTapCancel: () => setState(() => _premuto = false),
          onTapUp: (_) => setState(() => _premuto = false),
          onTap: widget.onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          child: AnimatedScale(
            scale: ridotto ? 1 : scala,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Testata: foto della vasca (o acqua disegnata), calottina, nome, numeri.
// ---------------------------------------------------------------------------

/// Foto di sfondo della testata. Se l'immagine non c'e' (o non si carica)
/// resta l'acqua disegnata e animata.
const fotoTestataAtleta = 'assets/images/atleta/testata.jpg';

class TestataAtleta extends ConsumerWidget {
  const TestataAtleta({
    required this.atleta,
    required this.statistiche,
    this.vistaAllenatore = false,
    super.key,
  });

  final Atleta atleta;

  /// Aperta dall'allenatore: niente saluto ("Buon pomeriggio," senza
  /// nessuno a cui dirlo), al suo posto cosa sta guardando.
  final bool vistaAllenatore;

  /// Le "piastrelle" numeriche in basso (etichetta, valore, al tocco).
  final List<({String etichetta, String valore, VoidCallback? onTap})>
  statistiche;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calottina = ref.watch(calottinaAtletaProvider(atleta.id)).value;
    final club = ref.watch(clubAtletaProvider(atleta.clubId)).value;
    final gruppi = ref.watch(gruppiListProvider(atleta.clubId)).value;
    final gruppo = gruppi
        ?.where((g) => g.id == atleta.gruppoId)
        .map((g) => g.nome)
        .firstOrNull;
    final pallanuoto = atleta.sport == 'pallanuoto';
    final larghezza = MediaQuery.sizeOf(context).width;
    final stretto = larghezza < 600;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          const Positioned.fill(child: AcquaAnimata(conCorsia: false)),
          Positioned.fill(child: _FotoTestata()),
          // Velo scuro: a sinistra e in basso il testo resta leggibile
          // anche sulla foto piu' chiara.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AcquaPalette.profonda.withValues(alpha: 0.92),
                    AcquaPalette.profonda.withValues(alpha: 0.55),
                    AcquaPalette.profonda.withValues(alpha: 0.05),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AcquaPalette.profonda.withValues(alpha: 0.85),
                  ],
                  stops: const [0.45, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              stretto ? 18 : 28,
              stretto ? 20 : 28,
              stretto ? 18 : 28,
              stretto ? 16 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._identita(
                  stretto: stretto,
                  pallanuoto: pallanuoto,
                  calottina: calottina,
                  club: club?.nome,
                  gruppo: gruppo,
                ),
                SizedBox(height: stretto ? 18 : 26),
                _FasciaStatistiche(voci: statistiche),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Calottina, saluto, nome e pillole. Su telefono la calottina sta
  /// sopra il nome (accanto al saluto), cosi' il nome ha tutta la
  /// larghezza e non va a capo a meta' cognome; da tablet in su sta a
  /// sinistra, grande.
  List<Widget> _identita({
    required bool stretto,
    required bool pallanuoto,
    required CalottinaAtleta? calottina,
    required String? club,
    required String? gruppo,
  }) {
    final cuffia = pallanuoto
        ? Tooltip(
            message: calottina == null
                ? 'Il tuo numero comparirà alla prima convocazione'
                : calottina.portiere
                ? 'Calottina n° ${calottina.numero} da portiere, '
                      'dall\'ultima convocazione'
                : 'Calottina n° ${calottina.numero}, '
                      'dall\'ultima convocazione',
            child: Calottina(
              colore: ColoreCalottina.da(
                calottina?.colore,
                portiere: calottina?.portiere ?? false,
              ),
              numero: calottina == null ? null : '${calottina.numero}',
              dimensione: stretto ? 56 : 88,
            ),
          )
        : null;
    final saluto = Text(
      vistaAllenatore ? 'Scheda atleta' : _saluto(),
      style: AppTypography.piccolo.copyWith(
        color: AcquaPalette.schiuma.withValues(alpha: 0.75),
      ),
    );
    final nome = Text(
      '${atleta.nome}\n${atleta.cognome}',
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: (stretto ? AppTypography.titoloXl : AppTypography.display)
          .copyWith(
            color: AcquaPalette.bianco,
            height: 1.04,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
    );
    final pillole = Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (club != null) _Pillola(club),
        if (gruppo != null) _Pillola(gruppo),
        _Pillola(pallanuoto ? 'Pallanuoto' : 'Nuoto'),
      ],
    );

    if (stretto) {
      return [
        Row(
          children: [
            if (cuffia != null) ...[cuffia, const SizedBox(width: 12)],
            Expanded(child: saluto),
          ],
        ),
        const SizedBox(height: 10),
        nome,
        const SizedBox(height: 10),
        pillole,
      ];
    }
    return [
      Row(
        children: [
          if (cuffia != null) ...[cuffia, const SizedBox(width: 20)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                saluto,
                const SizedBox(height: 2),
                nome,
                const SizedBox(height: 8),
                pillole,
              ],
            ),
          ),
        ],
      ),
    ];
  }

  static String _saluto() {
    final ora = DateTime.now().hour;
    if (ora < 13) return 'Buongiorno,';
    if (ora < 18) return 'Buon pomeriggio,';
    return 'Buonasera,';
  }
}

class _FotoTestata extends StatefulWidget {
  @override
  State<_FotoTestata> createState() => _FotoTestataState();
}

/// Zoom lentissimo avanti e indietro sulla foto ("effetto Ken Burns"):
/// la testata respira senza distrarre.
class _FotoTestataState extends State<_FotoTestata>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  // La foto si chiede solo se e' davvero tra gli asset: finche' il file
  // non c'e', niente richiesta a vuoto (errore 404 in console).
  static final Future<bool> _fotoPresente =
      AssetManifest.loadFromAssetBundle(rootBundle).then(
        (m) => m.listAssets().contains(fotoTestataAtleta),
        onError: (_) => false,
      );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _fotoPresente,
      builder: (context, presente) =>
          presente.data == true ? _foto() : const SizedBox.shrink(),
    );
  }

  Widget _foto() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1.0 + Curves.easeInOut.transform(_c.value) * 0.06,
        alignment: const Alignment(0.5, 0),
        child: child,
      ),
      child: Image.asset(
        fotoTestataAtleta,
        fit: BoxFit.cover,
        // Su telefono resta in vista il giocatore (lato destro della foto).
        alignment: const Alignment(0.55, 0),
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
        frameBuilder: (context, child, frame, sincrono) => AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          child: child,
        ),
      ),
    );
  }
}

class _Pillola extends StatelessWidget {
  const _Pillola(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AcquaPalette.bianco.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AcquaPalette.bianco.withValues(alpha: 0.18)),
      ),
      child: Text(
        testo,
        style: AppTypography.etichetta.copyWith(color: AcquaPalette.bianco),
      ),
    );
  }
}

class _FasciaStatistiche extends StatelessWidget {
  const _FasciaStatistiche({required this.voci});

  final List<({String etichetta, String valore, VoidCallback? onTap})> voci;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AcquaPalette.bianco.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AcquaPalette.bianco.withValues(alpha: 0.14)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < voci.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: AcquaPalette.bianco.withValues(alpha: 0.14),
                ),
              Expanded(
                child: Premibile(
                  raggio: 16,
                  etichetta: '${voci[i].etichetta}: ${voci[i].valore}',
                  onTap: voci[i].onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 6,
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            voci[i].valore,
                            style: AppTypography.numerica(
                              AppTypography.numeroMedio.copyWith(
                                color: AcquaPalette.bianco,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            voci[i].etichetta,
                            maxLines: 1,
                            style: AppTypography.etichetta.copyWith(
                              color: AcquaPalette.schiuma.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Prossima partita: un tabellone con le due squadre.
// ---------------------------------------------------------------------------

class CardProssimaPartita extends StatelessWidget {
  const CardProssimaPartita({required this.partita, this.onTap, super.key});

  final Partita partita;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final noiInCasa = partita.nostraSquadra == 'casa';
    final nostroColore = ColoreCalottina.da(partita.coloreCalottina);
    final loroColore = nostroColore == ColoreCalottina.blu
        ? ColoreCalottina.bianca
        : ColoreCalottina.blu;
    final stretto = MediaQuery.sizeOf(context).width < 600;

    Widget squadra(String nome, ColoreCalottina colore, bool nostra) => Column(
      children: [
        Calottina(colore: colore, dimensione: stretto ? 48 : 60),
        const SizedBox(height: 8),
        Text(
          nome,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: (nostra ? AppTypography.corpoForte : AppTypography.corpo)
              .copyWith(
                color: colori.testo,
                height: 1.2,
                fontSize: stretto ? 14 : null,
              ),
        ),
        if (nostra) ...[
          const SizedBox(height: 4),
          Text(
            'La tua squadra',
            style: AppTypography.etichetta.copyWith(color: colori.azione),
          ),
        ],
      ],
    );

    return Premibile(
      onTap: onTap,
      etichetta:
          'Prossima partita: ${partita.squadraCasa} contro '
          '${partita.squadraTrasferta}, ${dataEstesa(partita.data)}',
      child: Container(
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fascia in alto: quando e dove.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colori.azione.withValues(alpha: 0.18),
                    colori.azione.withValues(alpha: 0.04),
                  ],
                ),
              ),
              // Titolo ed etichette si dividono la riga finche' c'e'
              // spazio; su telefono le etichette scendono sotto e il
              // titolo resta su una riga.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_handball,
                        size: 20,
                        color: colori.azione,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prossima partita',
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.testo,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Chip(
                        testo: traQuanto(partita.data),
                        colore: colori.azione,
                      ),
                      if (partita.importanza == 'alta') ...[
                        const SizedBox(width: 6),
                        _Chip(testo: 'Importante', colore: colori.attenzione),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: squadra(
                      partita.squadraCasa,
                      noiInCasa ? nostroColore : loroColore,
                      noiInCasa,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        SizedBox(height: stretto ? 12 : 18),
                        Text(
                          'VS',
                          style: AppTypography.titolo.copyWith(
                            color: colori.testoTenue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          partita.ora ?? '',
                          style: AppTypography.numerica(
                            AppTypography.corpoForte.copyWith(
                              color: colori.testo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: squadra(
                      partita.squadraTrasferta,
                      noiInCasa ? loroColore : nostroColore,
                      !noiInCasa,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 6,
                children: [
                  _Dettaglio(
                    icona: Icons.event_outlined,
                    testo: dataEstesa(partita.data),
                  ),
                  if (partita.luogo != null)
                    _Dettaglio(
                      icona: Icons.place_outlined,
                      testo: partita.luogo!,
                    ),
                  if (partita.campionato != null)
                    _Dettaglio(
                      icona: Icons.emoji_events_outlined,
                      testo: partita.campionato!,
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

class _Chip extends StatelessWidget {
  const _Chip({required this.testo, required this.colore});

  final String testo;
  final Color colore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        testo,
        style: AppTypography.etichetta.copyWith(
          color: colore,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dettaglio extends StatelessWidget {
  const _Dettaglio({required this.icona, required this.testo});

  final IconData icona;
  final String testo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icona, size: 16, color: colori.testoSecondario),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            testo,
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Prossimo allenamento: data, volume, apertura della scheda.
// ---------------------------------------------------------------------------

class CardProssimoAllenamento extends ConsumerWidget {
  const CardProssimoAllenamento({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final riepilogo = ref.watch(riepilogoAllenamentiAtletaProvider(atleta));
    final prossimo = riepilogo?.prossimo;
    final serie = prossimo == null
        ? null
        : ref.watch(serieAtletaProvider(prossimo.id)).value;
    final metri = serie == null ? null : metriTotaliSerie(serie);

    return Premibile(
      etichetta: prossimo == null
          ? 'Nessun allenamento in programma'
          : 'Prossimo allenamento, ${dataEstesa(prossimo.data)}: apri la scheda',
      onTap: prossimo == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SchedaBordoVascaScreen(
                  allenamento: prossimo,
                  perAtleta: true,
                ),
              ),
            ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colori.azioneTenue,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: prossimo == null
                  ? Icon(Icons.pool, color: colori.azione)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _mesi[prossimo.data.month - 1].toUpperCase(),
                          style: AppTypography.etichetta.copyWith(
                            color: colori.azione,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        Text(
                          '${prossimo.data.day}',
                          style: AppTypography.numerica(
                            AppTypography.titolo.copyWith(
                              color: colori.azione,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prossimo allenamento',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prossimo == null
                        ? 'Nessuno in programma'
                        : prossimo.titolo ?? 'Allenamento',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                  ),
                  if (prossimo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        '${traQuanto(prossimo.data)}, ${dataEstesa(prossimo.data)}',
                        if (metri != null && metri > 0) formattaMetri(metri),
                      ].join(' · '),
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (prossimo != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colori.azione,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Scheda',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.azioneInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: colori.azioneInk,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Riquadri illustrati in griglia.
// ---------------------------------------------------------------------------

class VoceRiquadro {
  const VoceRiquadro({
    required this.soggetto,
    required this.titolo,
    required this.descrizione,
    required this.accento,
    required this.onTap,
    this.valore,
  });

  final SoggettoRiquadro soggetto;
  final String titolo;
  final String descrizione;

  /// Il dato "vivo" in evidenza (es. "3 schemi", "80%"), se c'e'.
  final String? valore;
  final Color accento;
  final VoidCallback onTap;
}

class GrigliaRiquadri extends StatelessWidget {
  const GrigliaRiquadri({required this.voci, super.key});

  final List<VoceRiquadro> voci;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // 2 colonne su telefono, 3 da tablet in su: con 6 riquadri le righe
        // restano piene.
        final colonne = w < 520 ? 2 : 3;
        const spazio = 12.0;
        final larghezza = (w - spazio * (colonne - 1)) / colonne;
        return Wrap(
          spacing: spazio,
          runSpacing: spazio,
          children: [
            for (var i = 0; i < voci.length; i++)
              SizedBox(
                width: larghezza,
                child: EntrataACascata(
                  indice: i,
                  child: _Riquadro(voce: voci[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Riquadro extends StatelessWidget {
  const _Riquadro({required this.voce});

  final VoceRiquadro voce;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Premibile(
      onTap: voce.onTap,
      etichetta: '${voce.titolo}. ${voce.descrizione}',
      child: Container(
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _IllustrazioneAnimata(
                      soggetto: voce.soggetto,
                      accento: voce.accento,
                      fondo: colori.superficie,
                    ),
                  ),
                  if (voce.valore != null)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colori.superficie.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          voce.valore!,
                          style: AppTypography.etichetta.copyWith(
                            color: voce.accento,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voce.titolo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.corpoForte.copyWith(
                            color: colori.testo,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voce.descrizione,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.etichetta.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colori.testoTenue,
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

/// Il disegno si "traccia" all'apparire (linee che si allungano, tiri che
/// compaiono uno dopo l'altro); fermo se "riduci movimento".
class _IllustrazioneAnimata extends StatelessWidget {
  const _IllustrazioneAnimata({
    required this.soggetto,
    required this.accento,
    required this.fondo,
  });

  final SoggettoRiquadro soggetto;
  final Color accento;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    final ridotto = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: ridotto ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        painter: IllustrazioneRiquadroPainter(
          soggetto: soggetto,
          accento: accento,
          fondo: fondo,
          progresso: t,
        ),
      ),
    );
  }
}

/// Titolo di sezione della home atleta.
class TitoloSezione extends StatelessWidget {
  const TitoloSezione(this.testo, {super.key});

  final String testo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.s8),
      child: Text(
        testo,
        style: AppTypography.sezione.copyWith(
          color: context.colori.testo,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
