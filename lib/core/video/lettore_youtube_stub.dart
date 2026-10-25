import 'package:flutter/material.dart';

import '../../theme/palette_acqua.dart';
import 'controllore_video.dart';

/// Per i test: le richieste di accettare o no i tocchi, in ordine.
@visibleForTesting
final tocchiRichiesti = <bool>[];

/// Fuori dal web (e nei test) non c'è un lettore YouTube: un riquadro
/// nero al suo posto, con un motore finto che obbedisce ai comandi, così
/// la schermata del video si prova lo stesso.
class LettoreYoutube extends StatefulWidget {
  const LettoreYoutube({
    required this.videoId,
    required this.controllore,
    this.inizio,
    super.key,
  });

  final String videoId;
  final ControlloreVideo controllore;

  /// Il secondo da cui parte il video (null: dall'inizio).
  final int? inizio;

  @override
  State<LettoreYoutube> createState() => _LettoreYoutubeState();
}

class _LettoreYoutubeState extends State<LettoreYoutube>
    implements MotoreVideo {
  @override
  void initState() {
    super.initState();
    widget.controllore.collega(this);
    // Come il lettore vero, è pronto dopo essere apparso (non durante la
    // costruzione della schermata, che ascolta il controllore).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controllore.aggiorna(pronto: true, durata: 3600);
    });
  }

  @override
  void dispose() {
    widget.controllore.collega(null);
    super.dispose();
  }

  @override
  void vaiA(double secondi) {}

  @override
  void riproduci() {}

  @override
  void pausa() {}

  @override
  void impostaVelocita(double velocita) {}

  @override
  void accettaTocchi(bool accetta) => tocchiRichiesti.add(accetta);

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: AcquaPalette.nero, child: SizedBox.expand());
}
