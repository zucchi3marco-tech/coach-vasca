import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/palette_acqua.dart';
import '../../../theme/tokens_dominio.dart';
import '../../atleti/domain/atleta.dart';
import '../../home/atleta/home_atleta_widgets.dart';
import '../application/benessere_providers.dart';
import '../domain/scheda_benessere.dart';
import 'punteggio_widgets.dart';
import 'scheda_benessere_screen.dart';

/// Riquadro "Scheda benessere" della home atleta.
/// - Atleta, scheda di oggi da fare: invito evidente a compilarla.
/// - Atleta, gia' fatta: riepilogo e "Modifica".
/// - Allenatore (che apre l'atleta dal proprio elenco): sola lettura, la
///   scheda di oggi e gli ultimi 7 giorni.
class CardBenessere extends ConsumerWidget {
  const CardBenessere({
    required this.atleta,
    this.impegno,
    this.vistaAllenatore = false,
    super.key,
  });

  final Atleta atleta;
  final ImpegnoBenessere? impegno;
  final bool vistaAllenatore;

  void _apri(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SchedaBenessereScreen(atleta: atleta, impegno: impegno),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final accento = context.dominio.evidenzaViola;
    final schede = ref.watch(schedeBenessereAtletaProvider(atleta.id)).value;
    final oggi = ref.watch(schedaBenessereOggiProvider(atleta.id));

    if (!vistaAllenatore && oggi == null) {
      return _Invito(impegno: impegno, onTap: () => _apri(context));
    }
    final punteggio = oggi == null
        ? null
        : calcolaPunteggio(
            oggi,
            dataNascita: atleta.dataNascita,
            storico: schede ?? const [],
          );

    return Premibile(
      onTap: vistaAllenatore ? null : () => _apri(context),
      etichetta: vistaAllenatore
          ? 'Scheda benessere dell\'atleta'
          : 'Scheda benessere di oggi: tocca per modificarla',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (punteggio != null)
                  AnelloPunteggio(
                    valore: punteggio.valore,
                    livello: punteggio.livello,
                    dimensione: 52,
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accento.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.favorite_outline, color: accento),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        punteggio == null
                            ? 'Scheda benessere'
                            : 'Prontezza ${punteggio.valore}/100',
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.testo,
                        ),
                      ),
                      Text(
                        oggi == null
                            ? 'Oggi non ancora compilata'
                            : vistaAllenatore
                            ? 'Compilata oggi dall\'atleta'
                            : 'Inviata al tuo allenatore',
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                  ),
                ),
                if (punteggio != null)
                  SemaforoAllerta(livello: punteggio.livello),
                IconButton(
                  tooltip: 'Come si calcola',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => mostraSpiegazionePunteggio(context),
                  icon: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colori.testoSecondario,
                  ),
                ),
                if (!vistaAllenatore) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Modifica',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.azione,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            if (oggi != null && punteggio != null) ...[
              const SizedBox(height: 14),
              RiepilogoScheda(scheda: oggi),
              const SizedBox(height: 12),
              MotiviPunteggio(punteggio: punteggio, massimo: 4),
              if (punteggio.scartoDalSolito != null) ...[
                const SizedBox(height: 4),
                Text(
                  punteggio.scartoDalSolito! >= 0
                      ? 'In linea con il suo solito '
                            '(${punteggio.mediaPersonale!.round()})'
                      : '${-punteggio.scartoDalSolito!} sotto il suo solito '
                            '(${punteggio.mediaPersonale!.round()})',
                  style: AppTypography.etichetta.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ],
            ],
            if (vistaAllenatore && schede != null) ...[
              const SizedBox(height: 16),
              StoricoSettimana(schede: schede),
            ],
          ],
        ),
      ),
    );
  }
}

class _Invito extends StatelessWidget {
  const _Invito({required this.impegno, required this.onTap});

  final ImpegnoBenessere? impegno;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final accento = context.dominio.evidenzaViola;
    return Premibile(
      onTap: onTap,
      etichetta: 'Compila la scheda benessere',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accento.withValues(alpha: 0.28),
              accento.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: accento.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            _CuorePulsante(colore: accento),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Come stai oggi?',
                    style: AppTypography.sezione.copyWith(
                      color: colori.testo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    impegno == null
                        ? 'Compila la scheda benessere: due domande, meno di un minuto.'
                        : 'Compilala prima ${impegno!.descrizione}.',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accento,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Compila',
                style: AppTypography.etichetta.copyWith(
                  color: AcquaPalette.bianco,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuore che "batte" piano finche' la scheda non e' compilata; fermo con
/// "riduci movimento".
class _CuorePulsante extends StatefulWidget {
  const _CuorePulsante({required this.colore});

  final Color colore;

  @override
  State<_CuorePulsante> createState() => _CuorePulsanteState();
}

class _CuorePulsanteState extends State<_CuorePulsante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Due battiti ravvicinati, poi pausa.
        final t = _c.value;
        final battito = t < 0.15
            ? Curves.easeOut.transform(t / 0.15)
            : t < 0.3
            ? 1 - Curves.easeIn.transform((t - 0.15) / 0.15) * 0.6
            : t < 0.45
            ? 0.4 + Curves.easeOut.transform((t - 0.3) / 0.15) * 0.6
            : 1 - Curves.easeInOut.transform(((t - 0.45) / 0.55).clamp(0, 1));
        return Transform.scale(scale: 1 + battito * 0.12, child: child);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: widget.colore.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.favorite, color: widget.colore, size: 28),
      ),
    );
  }
}

class SemaforoAllerta extends StatelessWidget {
  const SemaforoAllerta({required this.livello, super.key});

  final int livello;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final (testo, colore) = switch (livello) {
      0 => ('Pronto', colori.ok),
      1 => ('Da seguire', colori.attenzione),
      _ => ('Da sentire', colori.rosso),
    };
    return Tooltip(
      message: livello == 2
          ? 'Prontezza sotto 40, dolore forte, febbre o meno di 5 ore di sonno'
          : livello == 1
          ? 'Prontezza fra 40 e 59, o molto sotto il suo solito'
          : 'Prontezza da 60 in su',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colore.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              testo,
              style: AppTypography.etichetta.copyWith(
                color: colore,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiepilogoScheda extends StatelessWidget {
  const RiepilogoScheda({required this.scheda, super.key});

  final SchedaBenessere scheda;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    Widget voce(IconData icona, String etichetta, String valore, Color c) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colori.superficieAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icona, size: 20, color: c),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etichetta,
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                      Text(
                        valore,
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
        );
    final dolore = scheda.dolori
        ? '${scheda.zoneDolore.map(etichettaZona).join(', ')}'
              '${scheda.intensitaDolore == null ? '' : ' · ${scheda.intensitaDolore}/10'}'
        : 'Nessuno';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          voce(
            Icons.healing_outlined,
            'Dolori',
            dolore,
            scheda.dolori ? colori.attenzione : colori.ok,
          ),
          const SizedBox(width: 10),
          voce(
            Icons.bedtime_outlined,
            'Sonno',
            formattaOre(scheda.oreSonno),
            scheda.oreSonno < 6 ? colori.attenzione : colori.ok,
          ),
        ],
      ),
    );
  }
}

/// Gli ultimi 7 giorni per l'allenatore: una colonna per giorno, alta
/// quanto le ore di sonno, con il pallino se c'era dolore.
class StoricoSettimana extends StatelessWidget {
  const StoricoSettimana({
    required this.schede,
    this.compatto = false,
    super.key,
  });

  final List<SchedaBenessere> schede;

  /// Senza titolo e piu' basso, per le righe della vista squadra.
  final bool compatto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final oggi = DateTime.now();
    final giorni = [
      for (var i = 6; i >= 0; i--)
        DateTime(oggi.year, oggi.month, oggi.day - i),
    ];
    const iniziali = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compatto) ...[
          Text(
            'Ultimi 7 giorni',
            style: AppTypography.etichetta.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: compatto ? 64 : 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final g in giorni)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final s = schede
                          .where(
                            (x) =>
                                x.data.year == g.year &&
                                x.data.month == g.month &&
                                x.data.day == g.day,
                          )
                          .firstOrNull;
                      // Altezza = Prontezza del giorno (0-100).
                      final p = s == null ? null : calcolaPunteggio(s);
                      final altezza = p == null
                          ? 4.0
                          : 6 + (p.valore / 100) * (compatto ? 28 : 52);
                      final colore = s == null
                          ? colori.linea
                          : coloreLivello(context, p!.livello);
                      return Tooltip(
                        message: s == null
                            ? 'Non compilata'
                            : 'Prontezza ${p!.valore} · sonno '
                                  '${formattaOre(s.oreSonno)} · '
                                  '${s.dolori ? 'dolore ${s.intensitaDolore ?? ''}/10' : 'nessun dolore'}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (s?.dolori ?? false)
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: colori.attenzione,
                              ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              width: 18,
                              height: altezza,
                              decoration: BoxDecoration(
                                color: colore.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              iniziali[g.weekday - 1],
                              style: AppTypography.etichetta.copyWith(
                                color: colori.testoSecondario,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
