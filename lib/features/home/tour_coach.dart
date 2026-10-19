import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/onboarding/onboarding_coach.dart';
import '../../theme/app_typography.dart';
import '../../theme/colori_app.dart';
import 'atleta/grafica_pallanuoto.dart';
import 'voci_home.dart';

/// Il tour di benvenuto dell'allenatore: una breve presentazione a
/// pagine (benvenuto, una per voce della barra di navigazione, il menu ☰).
/// Si mostra da solo al primo accesso e si rivede a comando dal menu
/// ("Rivedi la guida"). [context] deve stare sotto il Navigator.
///
/// Il riquadro sta in basso e dietro resta la home vera: a ogni pagina
/// [vaiAllaScheda] riceve la scheda da mostrare (indice in [vociHome]), così
/// l'allenatore vede la schermata di cui si parla. Alla chiusura la home
/// torna su "Oggi" (scheda 0).
Future<void> mostraTourCoach(
  BuildContext context,
  String? sport, {
  ValueChanged<int>? vaiAllaScheda,
}) async {
  // Segnato come visto subito, prima del tocco su "Iniziamo": anche
  // chiudendo il tour con "indietro" non deve ripresentarsi al prossimo
  // avvio.
  await segnaOnboardingCoachVisto();
  if (!context.mounted) return;
  final colori = context.colori;
  final ridotto = MediaQuery.disableAnimationsOf(context);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Guida',
    // Velo leggero: la home dietro deve restare ben visibile.
    barrierColor: colori.testo.withValues(alpha: 0.14),
    transitionDuration: ridotto
        ? Duration.zero
        : const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) =>
        _TourCoach(sport: sport, vaiAllaScheda: vaiAllaScheda),
    transitionBuilder: (_, animazione, _, child) {
      final curva = CurvedAnimation(
        parent: animazione,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curva,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curva),
          child: child,
        ),
      );
    },
  );
  // Qualunque sia il modo di chiuderlo (Salta, ultimo pulsante, "indietro"),
  // si lascia la home su "Oggi".
  if (context.mounted) vaiAllaScheda?.call(0);
}

typedef _Pagina = ({
  IconData icona,
  String etichetta,
  String titolo,
  String? testo,
  List<({IconData icona, String nome, String resto})>? elenco,
  Color colore,
});

class _TourCoach extends StatefulWidget {
  const _TourCoach({required this.sport, required this.vaiAllaScheda});

  final String? sport;
  final ValueChanged<int>? vaiAllaScheda;

  @override
  State<_TourCoach> createState() => _TourCoachState();
}

class _TourCoachState extends State<_TourCoach> {
  final _pagine = PageController();
  int _indice = 0;

  /// Vero mentre una animazione scavalca pagine intermedie (tocco su un
  /// pallino lontano): quelle non devono cambiare la scheda dietro.
  bool _animando = false;

  late final List<VoceHome> _voci = vociHome(widget.sport);

  @override
  void initState() {
    super.initState();
    // Non dentro la costruzione: il callback modifica lo stato della home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.vaiAllaScheda?.call(_schedaDellaPagina(0));
    });
  }

  @override
  void dispose() {
    _pagine.dispose();
    super.dispose();
  }

  /// Benvenuto e menu ☰ parlano della home: scheda 0 ("Oggi").
  int _schedaDellaPagina(int pagina) {
    if (pagina <= 0 || pagina > _voci.length) return 0;
    return pagina - 1;
  }

  List<_Pagina> _contenuti(BuildContext context) => [
    (
      icona: Icons.waving_hand_outlined,
      etichetta: 'Iniziamo',
      titolo: 'Benvenuto, coach',
      testo:
          'Questa guida ti mostra le schede vere: guarda dietro mentre la '
          'scorri. In alto c\'è sempre il nome del tuo club: il logo ti '
          'riporta alla home, il menu ☰ ha tutto il resto.',
      elenco: null,
      colore: context.colori.azione,
    ),
    for (final (k, voce) in _voci.indexed)
      (
        icona: destinazioneHome(voce, widget.sport).iconaSelezionata,
        etichetta: 'Scheda ${k + 1} di ${_voci.length}',
        titolo: destinazioneHome(
          voce,
          widget.sport,
        ).etichetta.replaceAll('­', ''),
        testo: destinazioneHome(voce, widget.sport).guida,
        elenco: null,
        colore: coloreVoceHome(context, voce),
      ),
    (
      icona: Icons.menu,
      etichetta: 'Il menu',
      titolo: 'Dal menu ☰',
      testo: null,
      elenco: const [
        (
          icona: Icons.groups_outlined,
          nome: 'Il mio club',
          resto: ': allenatori, codici d\'invito e dati del club',
        ),
        (
          icona: Icons.event_available_outlined,
          nome: 'Partite',
          resto: ' nel calendario del telefono',
        ),
        (
          icona: Icons.new_releases_outlined,
          nome: 'Novità',
          resto: ': cosa è cambiato',
        ),
        (
          icona: Icons.chat_bubble_outline,
          nome: 'Scrivimi',
          resto: ': segnala un problema, con la schermata',
        ),
        (icona: Icons.help_outline, nome: 'Rivedi la guida', resto: ''),
      ],
      colore: context.colori.azione,
    ),
  ];

  /// Porta la guida alla pagina [indice] e la scheda vera dietro con lei.
  void _cambia(int indice) {
    if (indice == _indice) return;
    setState(() => _indice = indice);
    widget.vaiAllaScheda?.call(_schedaDellaPagina(indice));
  }

  Future<void> _vai(int indice) async {
    if (indice == _indice) return;
    HapticFeedback.selectionClick();
    _cambia(indice);
    final ridotto = MediaQuery.disableAnimationsOf(context);
    if (ridotto) {
      _pagine.jumpToPage(indice);
      return;
    }
    _animando = true;
    await _pagine.animateToPage(
      indice,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    _animando = false;
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final dim = MediaQuery.sizeOf(context);
    final telefono = dim.width < 900;
    final pagine = _contenuti(context);
    final ultima = _indice == pagine.length - 1;
    final corrente = pagine[_indice];

    // Sul telefono il riquadro lascia scoperta la barra delle schede in
    // basso (68 px + area sicura), così si vede quale si accende.
    final margineBasso = telefono
        ? 68 + MediaQuery.paddingOf(context).bottom + 8
        : 16.0;
    // Altezza del testo: segue il testo di sistema ingrandito, ma non
    // mangia più di un terzo dello schermo; il resto scorre.
    final altezzaTesto = math.max(
      120.0,
      math.min(MediaQuery.textScalerOf(context).scale(170), dim.height * 0.36),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, margineBasso),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            color: colori.superficie,
            elevation: 8,
            shadowColor: colori.testo.withValues(alpha: 0.4),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Testata(
                  primaPagina: _indice == 0,
                  pagina: corrente,
                  indice: _indice,
                ),
                SizedBox(
                  height: altezzaTesto,
                  child: PageView.builder(
                    controller: _pagine,
                    itemCount: pagine.length,
                    onPageChanged: (i) {
                      if (!_animando) _cambia(i);
                    },
                    itemBuilder: (context, i) =>
                        _ContenutoPagina(pagina: pagine[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 16),
                  child: Row(
                    children: [
                      // Pallini di avanzamento: quello attivo si allunga.
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
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
        ),
      ),
    );
  }
}

/// La striscia colorata in cima al riquadro: un po' d'acqua, l'icona della
/// pagina (le calottine al benvenuto) e "Salta". Bassa, perché dietro deve
/// restare il più possibile della scheda vera.
class _Testata extends StatelessWidget {
  const _Testata({
    required this.primaPagina,
    required this.pagina,
    required this.indice,
  });

  final bool primaPagina;
  final _Pagina pagina;
  final int indice;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
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
                    pagina.colore.withValues(alpha: 0.55),
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
              child: primaPagina
                  ? SizedBox(
                      key: const ValueKey('calottine'),
                      width: 96,
                      height: 44,
                      child: Stack(
                        children: [
                          for (final (k, c) in const [
                            ColoreCalottina.bianca,
                            ColoreCalottina.blu,
                            ColoreCalottina.rossa,
                          ].indexed)
                            Positioned(
                              left: k * 26.0,
                              child: Calottina(colore: c, dimensione: 44),
                            ),
                        ],
                      ),
                    )
                  : Container(
                      key: ValueKey(indice),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AcquaPalette.bianco.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AcquaPalette.bianco.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        pagina.icona,
                        size: 24,
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
              style: TextButton.styleFrom(foregroundColor: AcquaPalette.bianco),
              child: const Text('Salta'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Il testo di una pagina; se è più lungo dello spazio scorre.
class _ContenutoPagina extends StatelessWidget {
  const _ContenutoPagina({required this.pagina});

  final _Pagina pagina;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final stileTesto = AppTypography.corpo.copyWith(
      color: colori.testoSecondario,
      height: 1.45,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pagina.etichetta,
            style: AppTypography.etichetta.copyWith(
              color: pagina.colore,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pagina.titolo,
            style: AppTypography.titoloXl.copyWith(
              color: colori.testo,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (pagina.testo != null) Text(pagina.testo!, style: stileTesto),
          if (pagina.elenco != null)
            for (final voce in pagina.elenco!)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(voce.icona, size: 20, color: pagina.colore),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: voce.nome,
                              style: TextStyle(
                                color: colori.testo,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (voce.resto.isNotEmpty)
                              TextSpan(text: voce.resto),
                          ],
                        ),
                        style: stileTesto,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
