import '../../../core/utils/pace_format.dart';
import '../presentation/riepilogo_volumi.dart' show formattaMetri;
import 'serie.dart';
import 'volume_allenamento.dart';

/// «Com'è andata»: la serie si segna «Fatta» (tutta), «In parte» o
/// «Saltata», a bordo vasca e nel dettaglio dell'allenamento. Il
/// programma scritto non cambia mai: «In parte» aggiunge solo quanto se
/// n'è fatto (`metriFatti` / `secondiFatti`, vedi `volumeFatto`).
///
/// Quanto se n'è fatto si dice come lo direbbe l'allenatore: le ripetute
/// per una serie a distanza, i minuti per una a tempo, i metri per una
/// distanza sola.

/// Una scelta di «In parte»: il numero grande del bottone, la riga sotto
/// e quanto vale per la serie.
class SceltaInParte {
  const SceltaInParte({
    required this.etichetta,
    required this.unita,
    this.metriFatti,
    this.secondiFatti,
  });

  /// Il numero grande: «6», «12», «600».
  final String etichetta;

  /// Sotto il numero: «600 m», «min», «m».
  final String unita;

  /// Una sola delle due: i metri per una serie a distanza, i secondi per
  /// una a tempo.
  final int? metriFatti;
  final int? secondiFatti;

  /// È la scelta già segnata su [s]?
  bool eDi(DatiSerie s) =>
      s.metriFatti == metriFatti && s.secondiFatti == secondiFatti;
}

/// Le scelte di «In parte» di una serie e la domanda da fare.
class OpzioniInParte {
  const OpzioniInParte({required this.domanda, required this.scelte});

  static const nessuna = OpzioniInParte(domanda: '', scelte: []);

  /// «Quante ripetute di 10?», «Quanti minuti di 30?», «Quanti metri di
  /// 800?».
  final String domanda;
  final List<SceltaInParte> scelte;

  /// Senza scelte «In parte» non si offre per la serie.
  bool get vuote => scelte.isEmpty;
}

/// Oltre questi minuti le scelte vanno a salti di cinque: una partita di
/// novanta minuti non ha novantanove bottoni.
const _minutiAPassoLungo = 60;

/// Le scelte di «In parte» per [s]:
/// - a distanza con più ripetute: le ripetute fatte, da 1 a N-1;
/// - a tempo di almeno due minuti in tutto: i minuti fatti, da 1 a T-1
///   (a salti di cinque oltre i 60);
/// - a tempo più breve ma con più ripetute: le ripetute fatte;
/// - una distanza sola: i metri a passi di 25 (fino a 200 m), 50 (fino
///   a 800 m) o 100;
/// - altrimenti nessuna: la serie non si fa «in parte».
OpzioniInParte opzioniInParte(DatiSerie s) {
  final ripetute = s.ripetute;
  final durata = s.durataS;
  final distanza = s.distanzaM;

  if (durata != null && durata > 0) {
    final minuti = (ripetute * durata) ~/ 60;
    if (minuti >= 2) {
      final passo = minuti > _minutiAPassoLungo ? 5 : 1;
      return OpzioniInParte(
        domanda: 'Quanti minuti di $minuti?',
        scelte: [
          for (var m = passo; m < minuti; m += passo)
            SceltaInParte(etichetta: '$m', unita: 'min', secondiFatti: m * 60),
        ],
      );
    }
    if (ripetute > 1) {
      return OpzioniInParte(
        domanda: 'Quante ripetute di $ripetute?',
        scelte: [
          for (var k = 1; k < ripetute; k++)
            SceltaInParte(
              etichetta: '$k',
              unita: formatDurataS(k * durata),
              secondiFatti: k * durata,
            ),
        ],
      );
    }
    return OpzioniInParte.nessuna;
  }

  if (distanza == null || distanza <= 0) return OpzioniInParte.nessuna;

  if (ripetute > 1) {
    return OpzioniInParte(
      domanda: 'Quante ripetute di $ripetute?',
      scelte: [
        for (var k = 1; k < ripetute; k++)
          SceltaInParte(
            etichetta: '$k',
            unita: '${formattaMetri(k * distanza)} m',
            metriFatti: k * distanza,
          ),
      ],
    );
  }

  final passo = distanza <= 200
      ? 25
      : distanza <= 800
      ? 50
      : 100;
  return OpzioniInParte(
    domanda: 'Quanti metri di ${formattaMetri(distanza)}?',
    scelte: [
      for (var m = passo; m < distanza; m += passo)
        SceltaInParte(etichetta: formattaMetri(m), unita: 'm', metriFatti: m),
    ],
  );
}

/// «In parte» si può offrire per [s]: ha almeno una scelta.
bool ammetteInParte(DatiSerie s) => !opzioniInParte(s).vuote;

/// Cosa dice una serie fatta in parte: «In parte · 6 di 10» (ripetute),
/// «In parte · 600 di 800 m» (una distanza sola), «In parte · 12' di 30'»
/// (a tempo). Per una serie che non è fatta in parte, una stringa vuota.
String descriviFatto(DatiSerie s) {
  if (s.metriFatti == null && s.secondiFatti == null) return '';
  final ripetute = s.ripetute;
  final distanza = s.distanzaM;
  final durata = s.durataS;

  final metri = s.metriFatti;
  if (metri != null) {
    if (distanza != null && distanza > 0) {
      if (ripetute > 1 && metri % distanza == 0) {
        return 'In parte · ${metri ~/ distanza} di $ripetute';
      }
      return 'In parte · ${formattaMetri(metri)} di '
          '${formattaMetri(ripetute * distanza)} m';
    }
    return 'In parte · ${formattaMetri(metri)} m';
  }

  final secondi = s.secondiFatti!;
  if (durata != null && durata > 0) {
    final totale = ripetute * durata;
    // A tempo ma sotto i due minuti in tutto: si contano le ripetute.
    if (totale < 120 && ripetute > 1 && secondi % durata == 0) {
      return 'In parte · ${secondi ~/ durata} di $ripetute';
    }
    return 'In parte · ${formatDurataS(secondi)} di ${formatDurataS(totale)}';
  }
  return 'In parte · ${formatDurataS(secondi)}';
}

/// Cosa resta segnato su [s] dopo un tocco su «Fatta» ('fatta') o
/// «Saltata» ('saltata'): null (tolto) se era già segnata proprio così,
/// altrimenti l'esito toccato. «Fatta» vale solo per una serie fatta
/// tutta: su una fatta in parte il tocco la fa diventare fatta tutta, non
/// la toglie.
String? esitoDopoTocco(Serie s, String toccato) {
  if (toccato == 'fatta') return s.fattaTutta ? null : 'fatta';
  return s.saltata ? null : toccato;
}

/// Quanto è stato fatto di quanto era scritto: «2.600 di 3.200 m», con il
/// lavoro a tempo accanto («· 25' di 30'») e, con [aTempo], la parola «a
/// tempo» dopo i minuti. Solo i minuti per un lavoro tutto a tempo.
String fattoDiScritto(
  VolumeAllenamento scritto,
  VolumeAllenamento fatto, {
  bool aTempo = false,
}) {
  final metri = scritto.metri > 0
      ? '${formattaMetri(fatto.metri)} di ${formattaMetri(scritto.metri)} m'
      : null;
  final tempo = scritto.secondi > 0
      ? "${formattaTempoLavoro(fatto.secondi)} di "
            "${formattaTempoLavoro(scritto.secondi)}${aTempo ? ' a tempo' : ''}"
      : null;
  return [?metri, ?tempo].join(' · ');
}

/// Quanto è rimasto da fare rispetto allo scritto: «−200» (metri), «−5'»
/// (minuti), entrambi se le due cose sono diverse; null se è stato fatto
/// tutto.
String? scartoScritto(VolumeAllenamento scritto, VolumeAllenamento fatto) {
  final metri = scritto.metri - fatto.metri;
  final secondi = scritto.secondi - fatto.secondi;
  final parti = [
    if (metri > 0) '−${formattaMetri(metri)}',
    if (secondi > 0) "−${formattaTempoLavoro(secondi)}",
  ];
  return parti.isEmpty ? null : parti.join(' · ');
}

/// Com'è andato un gruppo di serie (una piramide, un «2x»), in una riga:
/// «fatta» se sono tutte fatte tutte, «saltata» se sono tutte saltate,
/// altrimenti i pezzi che ci sono: «2 fatte, 1 in parte, 1 saltata». Null
/// se nessuna è segnata.
String? riassuntoEsiti(List<Serie> gruppo) {
  final tutte = gruppo.where((s) => s.fattaTutta).length;
  final inParte = gruppo.where((s) => s.fatta && s.inParte).length;
  final saltate = gruppo.where((s) => s.saltata).length;
  if (gruppo.isEmpty || tutte + inParte + saltate == 0) return null;
  if (tutte == gruppo.length) return 'fatta';
  if (saltate == gruppo.length) return 'saltata';
  return [
    if (tutte > 0) tutte == 1 ? '1 fatta' : '$tutte fatte',
    if (inParte > 0) '$inParte in parte',
    if (saltate > 0) saltate == 1 ? '1 saltata' : '$saltate saltate',
  ].join(', ');
}

/// Le famiglie di zona della Com'è andata: A (A1, A2), B (B1, B2), C (C,
/// C1, C2, C3), D; null per una serie senza zona.
String? famigliaZona(String? zona) => switch (zona) {
  'A1' || 'A2' => 'A',
  'B1' || 'B2' => 'B',
  'C' || 'C1' || 'C2' || 'C3' => 'C',
  'D' => 'D',
  _ => null,
};

/// Quanto è scritto e quanto è stato fatto in una famiglia di zona
/// ([famigliaZona]; null: senza zona).
typedef ScartoFamiglia = ({
  String? famiglia,
  VolumeAllenamento scritto,
  VolumeAllenamento fatto,
});

/// Lo scarto fra scritto e fatto per ogni famiglia di zona che ha del
/// lavoro scritto, nell'ordine A, B, C, D e infine senza zona.
List<ScartoFamiglia> scartoPerFamiglia(Iterable<DatiSerie> serie) {
  final perFamiglia = <String?, List<DatiSerie>>{};
  for (final s in serie) {
    (perFamiglia[famigliaZona(s.zona)] ??= []).add(s);
  }
  return [
    for (final famiglia in const ['A', 'B', 'C', 'D', null])
      if (perFamiglia[famiglia] case final delle?)
        if (volumeDi(delle) case final scritto when !scritto.vuoto)
          (famiglia: famiglia, scritto: scritto, fatto: volumeFattoDi(delle)),
  ];
}

/// Com'è andata un allenamento, per le serie del gruppo.
typedef RiepilogoComEAndata = ({
  VolumeAllenamento scritto,
  VolumeAllenamento fatto,

  /// Quante serie sono segnate fatte tutte, in parte, saltate; e quante
  /// non sono segnate: queste contano come scritte.
  int fatteTutte,
  int inParte,
  int saltate,
  int nonSegnate,
  List<ScartoFamiglia> perFamiglia,
});

/// Com'è andata [serie] (di norma `serieDelGruppo`).
RiepilogoComEAndata riepilogoComEAndata(Iterable<Serie> serie) {
  final elenco = serie.toList();
  return (
    scritto: volumeDi(elenco),
    fatto: volumeFattoDi(elenco),
    fatteTutte: elenco.where((s) => s.fattaTutta).length,
    inParte: elenco.where((s) => s.fatta && s.inParte).length,
    saltate: elenco.where((s) => s.saltata).length,
    nonSegnate: elenco.where((s) => s.esito == null).length,
    perFamiglia: scartoPerFamiglia(elenco),
  );
}
