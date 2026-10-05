import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/onboarding/onboarding_coach.dart';
import '../../theme/app_typography.dart';
import '../../theme/colori_app.dart';
import 'atleta/grafica_pallanuoto.dart';
import 'voci_home.dart';

/// Il tour di benvenuto dell'allenatore: una breve presentazione a
/// pagine, una per voce della barra di navigazione. Si mostra da solo al
/// primo accesso e si rivede a comando dal menu ("Rivedi la guida").
/// [context] deve stare sotto il Navigator.
Future<void> mostraTourCoach(BuildContext context, String? sport) async {
  // Segnato come visto subito, prima del tocco su "Iniziamo": anche
  // chiudendo il dialogo toccando fuori o con "indietro" non deve
  // ripresentarsi al prossimo avvio.
  await segnaOnboardingCoachVisto();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _TourCoach(sport: sport),
  );
}

typedef _Pagina = ({IconData icona, String titolo, String testo, Color colore});

class _TourCoach extends StatefulWidget {
  const _TourCoach({required this.sport});

  final String? sport;

  @override
  State<_TourCoach> createState() => _TourCoachState();
}

class _TourCoachState extends State<_TourCoach> {
  final _pagine = PageController();
  int _indice = 0;

  @override
  void dispose() {
    _pagine.dispose();
    super.dispose();
  }

  List<_Pagina> _contenuti(BuildContext context) => [
    (
      icona: Icons.waving_hand_outlined,
      titolo: 'Benvenuto, coach',
      testo:
          'In alto trovi sempre il nome del tuo club: tocca il logo per '
          'tornare alla home. Dal menu ☰ cambi squadra, leggi le notifiche '
          'e rivedi questa guida.',
      colore: context.colori.azione,
    ),
    for (final voce in vociHome(widget.sport))
      (
        icona: destinazioneHome(voce, widget.sport).iconaSelezionata,
        titolo: destinazioneHome(
          voce,
          widget.sport,
        ).etichetta.replaceAll('­', ''),
        testo: destinazioneHome(voce, widget.sport).guida,
        colore: coloreVoceHome(context, voce),
      ),
  ];

  void _vai(int indice) {
    HapticFeedback.selectionClick();
    final ridotto = MediaQuery.disableAnimationsOf(context);
    if (ridotto) {
      _pagine.jumpToPage(indice);
    } else {
      _pagine.animateToPage(
        indice,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final pagine = _contenuti(context);
    final ultima = _indice == pagine.length - 1;
    final corrente = pagine[_indice];

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colori.superficie,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Testata: la vasca, con l'icona della pagina che cambia.
            SizedBox(
              height: 150,
              child: Stack(
                children: [
                  const Positioned.fill(child: AcquaAnimata(conCorsia: false)),
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            corrente.colore.withValues(alpha: 0.55),
                            AcquaPalette.profonda.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: Tween(begin: 0.8, end: 1.0).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _indice == 0
                          ? SizedBox(
                              key: const ValueKey('calottine'),
                              width: 150,
                              height: 64,
                              child: Stack(
                                children: [
                                  for (final (k, c) in const [
                                    ColoreCalottina.bianca,
                                    ColoreCalottina.blu,
                                    ColoreCalottina.rossa,
                                  ].indexed)
                                    Positioned(
                                      left: k * 40.0,
                                      child: Calottina(
                                        colore: c,
                                        dimensione: 70,
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : Container(
                              key: ValueKey(_indice),
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AcquaPalette.bianco.withValues(
                                  alpha: 0.16,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AcquaPalette.bianco.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                corrente.icona,
                                size: 38,
                                color: AcquaPalette.bianco,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AcquaPalette.bianco,
                      ),
                      child: const Text('Salta'),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SizedBox(
                height: 230,
                child: PageView.builder(
                  controller: _pagine,
                  itemCount: pagine.length,
                  onPageChanged: (i) => setState(() => _indice = i),
                  itemBuilder: (context, i) {
                    final p = pagine[i];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i == 0
                                ? 'Iniziamo'
                                : 'Scheda $i di ${pagine.length - 1}',
                            style: AppTypography.etichetta.copyWith(
                              color: p.colore,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.titolo,
                            style: AppTypography.titoloXl.copyWith(
                              color: colori.testo,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.testo,
                            style: AppTypography.corpo.copyWith(
                              color: colori.testoSecondario,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  // Pallini di avanzamento: quello attivo si allunga.
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (var i = 0; i < pagine.length; i++)
                          GestureDetector(
                            onTap: () => _vai(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              width: i == _indice ? 22 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _indice
                                    ? corrente.colore
                                    : colori.linea,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_indice > 0)
                    IconButton(
                      tooltip: 'Indietro',
                      onPressed: () => _vai(_indice - 1),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: corrente.colore,
                      foregroundColor: AcquaPalette.bianco,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: ultima
                        ? () => Navigator.of(context).pop()
                        : () => _vai(_indice + 1),
                    icon: Icon(ultima ? Icons.check : Icons.arrow_forward),
                    label: Text(ultima ? 'Iniziamo' : 'Avanti'),
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
