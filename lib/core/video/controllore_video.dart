import 'package:flutter/foundation.dart';

/// Chi muove davvero il video: il lettore YouTube nel browser
/// (`lettore_youtube_web.dart`) o, nei test e fuori dal web, quello finto
/// (`lettore_youtube_stub.dart`).
abstract interface class MotoreVideo {
  void vaiA(double secondi);
  void riproduci();
  void pausa();
  void impostaVelocita(double velocita);

  /// false: i tocchi passano oltre il video, all'app (per disegnare
  /// sopra il fotogramma fermo).
  void accettaTocchi(bool accetta);
}

/// Lo stato del video e i comandi, uguali per il lettore vero e per
/// quello dei test: la schermata ascolta questo e non sa chi c'è sotto.
class ControlloreVideo extends ChangeNotifier {
  MotoreVideo? _motore;
  double _secondo = 0;
  double? _durata;
  bool _inRiproduzione = false;
  bool _pronto = false;
  String? _errore;
  double _velocita = 1;
  bool _tocchi = true;

  /// Il secondo del video in questo momento.
  double get secondo => _secondo;

  /// La durata del video, quando il lettore la conosce.
  double? get durata => _durata;
  bool get inRiproduzione => _inRiproduzione;
  bool get pronto => _pronto;
  String? get errore => _errore;
  double get velocita => _velocita;

  /// Il lettore si aggancia (e si stacca con null) quando è costruito.
  void collega(MotoreVideo? motore) {
    _motore = motore;
    if (motore != null) motore.accettaTocchi(_tocchi);
  }

  void vaiA(double secondi) {
    final s = secondi < 0
        ? 0.0
        : (_durata != null && secondi > _durata! ? _durata! : secondi);
    _secondo = s;
    _motore?.vaiA(s);
    notifyListeners();
  }

  void avanti(double secondi) => vaiA(_secondo + secondi);

  void riproduci() {
    _motore?.riproduci();
    _inRiproduzione = true;
    notifyListeners();
  }

  void pausa() {
    _motore?.pausa();
    _inRiproduzione = false;
    notifyListeners();
  }

  void impostaVelocita(double velocita) {
    _velocita = velocita;
    _motore?.impostaVelocita(velocita);
    notifyListeners();
  }

  void accettaTocchi(bool accetta) {
    _tocchi = accetta;
    _motore?.accettaTocchi(accetta);
  }

  /// Dal lettore: cosa è cambiato.
  void aggiorna({
    double? secondo,
    double? durata,
    bool? inRiproduzione,
    bool? pronto,
    String? errore,
  }) {
    var cambiato = false;
    if (secondo != null && (secondo - _secondo).abs() > 0.01) {
      _secondo = secondo;
      cambiato = true;
    }
    if (durata != null && durata > 0 && durata != _durata) {
      _durata = durata;
      cambiato = true;
    }
    if (inRiproduzione != null && inRiproduzione != _inRiproduzione) {
      _inRiproduzione = inRiproduzione;
      cambiato = true;
    }
    if (pronto != null && pronto != _pronto) {
      _pronto = pronto;
      cambiato = true;
    }
    if (errore != null && errore != _errore) {
      _errore = errore;
      cambiato = true;
    }
    if (cambiato) notifyListeners();
  }
}
