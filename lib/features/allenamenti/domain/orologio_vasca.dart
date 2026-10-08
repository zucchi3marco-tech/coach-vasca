import 'dart:math' as math;

import 'durata_serie.dart';
import 'serie.dart';

/// L'orologio di vasca del "Bordo vasca" (idea presa da Swimtraxx Hub):
/// avviato su una serie, dice a che ripetuta si è, il tempo dall'ultima
/// partenza (quello che gli atleti leggono arrivando) e quanto manca alla
/// prossima. Qui solo i conti, a partire dai secondi trascorsi: chi
/// disegna l'orologio tiene il tempo.

/// Ogni quanto parte una ripetuta di [s], in secondi: la ripartenza se
/// c'è, nelle serie a tempo durata più recupero, altrimenti la stima di
/// [secondiPerRipetuta] arrotondata ai 5 secondi, come si dà una
/// partenza a voce ([stimato] vero: l'allenatore può correggerla).
({double secondi, bool stimato}) intervalloPartenze(DatiSerie s) {
  if (s.durataS != null || s.ripartenzaS != null) {
    return (secondi: secondiPerRipetuta(s), stimato: false);
  }
  final stima = (secondiPerRipetuta(s) / 5).round() * 5.0;
  return (secondi: math.max(stima, 5), stimato: true);
}

/// Per quanti secondi dopo una partenza l'orologio la mostra ("Via").
const secondiVia = 2.0;

class PianoPartenze {
  const PianoPartenze({
    required this.ripetute,
    required this.intervalloS,
    this.lavoroS,
    this.gruppi = 1,
    this.distaccoS = 0,
  });

  final int ripetute;
  final double intervalloS;

  /// Serie a tempo: quanto dura il lavoro in ogni intervallo; il resto è
  /// recupero. Null per una serie a distanza.
  final double? lavoroS;

  /// Partenze sfalsate: quanti gruppi (corsie) partono uno dopo l'altro,
  /// a [distaccoS] secondi fra un gruppo e il successivo.
  final int gruppi;
  final double distaccoS;

  /// Da "Via" a quando l'ultimo gruppo finisce l'ultimo intervallo.
  double get durataS => ripetute * intervalloS + (gruppi - 1) * distaccoS;

  /// Come sta l'orologio [t] secondi dopo "Via".
  StatoOrologio a(double t) {
    final tempo = math.max(t, 0.0);
    final i = math.min((tempo / intervalloS).floor(), ripetute - 1);
    final dallaPartenza = tempo - i * intervalloS;
    final ultima = i >= ripetute - 1;

    double? prossimaDelGruppo(int g) {
      final scarto = tempo - g * distaccoS;
      final j = scarto <= 0 ? 0 : (scarto / intervalloS).ceil();
      if (j >= ripetute) return null;
      return j * intervalloS + g * distaccoS - tempo;
    }

    var appenaPartita = false;
    for (var g = 0; g < gruppi && !appenaPartita; g++) {
      final scarto = tempo - g * distaccoS;
      if (scarto < 0) continue;
      final j = (scarto / intervalloS).floor();
      appenaPartita = j < ripetute && scarto - j * intervalloS < secondiVia;
    }

    final lavoro = lavoroS;
    final inRecupero = lavoro != null && dallaPartenza >= lavoro;
    return StatoOrologio(
      ripetuta: i + 1,
      dallaPartenzaS: dallaPartenza,
      allaProssimaS: ultima ? null : (i + 1) * intervalloS - tempo,
      prossimiGruppi: [for (var g = 1; g < gruppi; g++) prossimaDelGruppo(g)],
      finita: tempo >= durataS,
      appenaPartita: appenaPartita,
      inRecupero: inRecupero,
      allaFineFaseS: lavoro == null
          ? null
          : (inRecupero ? intervalloS : lavoro) - dallaPartenza,
    );
  }
}

class StatoOrologio {
  const StatoOrologio({
    required this.ripetuta,
    required this.dallaPartenzaS,
    required this.allaProssimaS,
    required this.prossimiGruppi,
    required this.finita,
    required this.appenaPartita,
    this.inRecupero = false,
    this.allaFineFaseS,
  });

  /// La ripetuta in corso del primo gruppo, da 1.
  final int ripetuta;

  /// Secondi dall'ultima partenza del primo gruppo.
  final double dallaPartenzaS;

  /// Secondi alla prossima partenza del primo gruppo; null all'ultima
  /// ripetuta.
  final double? allaProssimaS;

  /// Dal secondo gruppo in poi: secondi alla prossima partenza di
  /// ciascuno, null quando ha finito.
  final List<double?> prossimiGruppi;

  final bool finita;

  /// Un gruppo è partito da meno di [secondiVia].
  final bool appenaPartita;

  /// Serie a tempo: se si è nel recupero, e quanto manca alla fine della
  /// fase in corso (lavoro o recupero).
  final bool inRecupero;
  final double? allaFineFaseS;
}
