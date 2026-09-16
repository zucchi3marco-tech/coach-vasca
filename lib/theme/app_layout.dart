import 'package:flutter/widgets.dart';

/// Punti di rottura — DESIGN.md sezione 10. **Nessuna schermata scrive
/// `MediaQuery.of(context).size.width > 600` a mano**: si usa
/// `Breakpoint.of(context)`.
enum Breakpoint {
  /// < 600 — telefono verticale.
  compatto,

  /// 600–839 — tablet verticale, telefono orizzontale.
  medio,

  /// 840–1199 — tablet orizzontale.
  esteso,

  /// ≥ 1200 — browser da scrivania (il build web su Vercel).
  largo;

  static const _sogliaMedio = 600.0;
  static const _sogliaEsteso = 840.0;
  static const _sogliaLargo = 1200.0;

  static Breakpoint of(BuildContext context) =>
      daLarghezza(MediaQuery.sizeOf(context).width);

  static Breakpoint daLarghezza(double larghezza) {
    if (larghezza >= _sogliaLargo) return Breakpoint.largo;
    if (larghezza >= _sogliaEsteso) return Breakpoint.esteso;
    if (larghezza >= _sogliaMedio) return Breakpoint.medio;
    return Breakpoint.compatto;
  }
}

/// Griglia e margini per punto di rottura — DESIGN.md sezione 10.
abstract final class AppLayout {
  static double margineLaterale(Breakpoint b) => switch (b) {
    Breakpoint.compatto => 16,
    Breakpoint.medio => 24,
    Breakpoint.esteso => 32,
    Breakpoint.largo => 32,
  };

  static int colonne(Breakpoint b) => switch (b) {
    Breakpoint.compatto => 4,
    Breakpoint.medio => 8,
    Breakpoint.esteso => 12,
    Breakpoint.largo => 12,
  };

  static double grondaColonne(Breakpoint b) => switch (b) {
    Breakpoint.compatto => 16,
    Breakpoint.medio => 24,
    Breakpoint.esteso => 24,
    Breakpoint.largo => 24,
  };

  /// Oltre questa larghezza il contenuto non si allarga: si centra e ai
  /// lati resta `sfondo`. Solo da `largo` in su (`—` per gli altri punti
  /// di rottura, dove il contenuto occupa la larghezza disponibile).
  static const larghezzaMassimaContenuto = 1200.0;

  // Larghezze massime per tipo di contenuto (sezione 10, indipendenti
  // dal punto di rottura: sono un tetto, non una regola per fascia).
  static const larghezzaMassimaForm = 640.0;
  static const larghezzaMassimaTestoDiscorsivo = 560.0;
  static const larghezzaMassimaPannelloDettaglio = 880.0;
  static const larghezzaElencoDuePannelli = 360.0;
  static const larghezzaMassimaCruscotto = 1200.0;

  // Densità — altezza riga per contesto (sezione 10).
  static double altezzaRigaElenco(Breakpoint b) =>
      b == Breakpoint.compatto ? 56 : 64;
  static const altezzaRigaTabellaDati = 48.0;
  static const altezzaRigaVasca = 72.0;
  static const altezzaMinimaRigaVasca = 64.0;

  /// Pannelli per riga nel cruscotto (archetipo D, sezione 10).
  static int pannelliPerRigaCruscotto(Breakpoint b) => switch (b) {
    Breakpoint.compatto => 1,
    Breakpoint.medio => 2,
    Breakpoint.esteso => 3,
    Breakpoint.largo => 4,
  };
}
