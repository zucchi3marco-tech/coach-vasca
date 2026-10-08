import 'package:web/web.dart' as web;

web.AudioContext? _contesto;

/// Il browser lascia suonare una pagina solo dopo un tocco: va chiamata
/// dentro un gesto (il "Via"), poi [suonaBip] funziona anche da sola.
void preparaSuono() {
  try {
    final contesto = _contesto ??= web.AudioContext();
    if (contesto.state == 'suspended') contesto.resume();
  } catch (_) {
    // Browser senza Web Audio: l'orologio resta muto.
  }
}

/// Un bip breve (il conto alla rovescia) o lungo (la partenza): onda
/// quadra, che si sente anche in una piscina rumorosa, con una salita e
/// una discesa rapide per non far "schioccare" l'altoparlante.
void suonaBip({bool lungo = false}) {
  final contesto = _contesto;
  if (contesto == null) return;
  try {
    final adesso = contesto.currentTime;
    final durata = lungo ? 0.7 : 0.15;
    final oscillatore = contesto.createOscillator()
      ..type = 'square'
      ..frequency.value = lungo ? 1046 : 784;
    final volume = contesto.createGain();
    volume.gain
      ..setValueAtTime(0.0001, adesso)
      ..exponentialRampToValueAtTime(0.35, adesso + 0.01)
      ..setValueAtTime(0.35, adesso + durata - 0.05)
      ..exponentialRampToValueAtTime(0.0001, adesso + durata);
    oscillatore.connect(volume);
    volume.connect(contesto.destination);
    oscillatore.start(adesso);
    oscillatore.stop(adesso + durata);
  } catch (_) {
    // Un bip perso non deve fermare l'orologio.
  }
}
