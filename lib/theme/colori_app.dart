import 'package:flutter/material.dart';

import 'tokens/tokens_chiaro.dart';
import 'tokens/tokens_scuro.dart';

/// Token semantici — DESIGN.md sezione 5, livello 2 dell'architettura dei
/// token (sezione 3): superfici, linee, testo, azione, segnale. Ha due
/// valori, uno per tema. Le schermate e i componenti leggono solo questo
/// livello (e [TokenDominio] per i dati di dominio), mai [Palette]
/// direttamente.
///
/// Si legge con `Theme.of(context).extension<ColoriApp>()`, o con la
/// scorciatoia `context.colori` (DESIGN.md sezione 20).
@immutable
class ColoriApp extends ThemeExtension<ColoriApp> {
  const ColoriApp({
    // Superfici
    required this.sfondo,
    required this.superficie,
    required this.superficieAlt,
    required this.superficieAlta,
    required this.superficieMassima,
    required this.scrim,
    // Linee
    required this.linea,
    required this.lineaForte,
    // Testo
    required this.testo,
    required this.testoSecondario,
    required this.testoTenue,
    // Azione
    required this.azione,
    required this.azionePremuta,
    required this.azioneInk,
    required this.azioneTenue,
    required this.azioneFuoco,
    // Segnale
    required this.rosso,
    required this.rossoTenue,
    required this.ok,
    required this.okTenue,
    required this.attenzione,
    required this.attenzioneTenue,
  });

  final Color sfondo;
  final Color superficie;
  final Color superficieAlt;
  final Color superficieAlta;
  final Color superficieMassima;
  final Color scrim;

  final Color linea;
  final Color lineaForte;

  final Color testo;
  final Color testoSecondario;
  final Color testoTenue;

  final Color azione;
  final Color azionePremuta;

  /// Testo/icone **sopra** [azione]. Nello scuro è inchiostro scuro, non
  /// bianco: bianco sopra l'azzurro chiaro d'azione darebbe 2,9:1 — vedi
  /// DESIGN.md sezione 5.
  final Color azioneInk;
  final Color azioneTenue;
  final Color azioneFuoco;

  final Color rosso;
  final Color rossoTenue;
  final Color ok;
  final Color okTenue;
  final Color attenzione;
  final Color attenzioneTenue;

  static const chiaro = coloriAppChiaro;
  static const scuro = coloriAppScuro;

  @override
  ColoriApp copyWith({
    Color? sfondo,
    Color? superficie,
    Color? superficieAlt,
    Color? superficieAlta,
    Color? superficieMassima,
    Color? scrim,
    Color? linea,
    Color? lineaForte,
    Color? testo,
    Color? testoSecondario,
    Color? testoTenue,
    Color? azione,
    Color? azionePremuta,
    Color? azioneInk,
    Color? azioneTenue,
    Color? azioneFuoco,
    Color? rosso,
    Color? rossoTenue,
    Color? ok,
    Color? okTenue,
    Color? attenzione,
    Color? attenzioneTenue,
  }) {
    return ColoriApp(
      sfondo: sfondo ?? this.sfondo,
      superficie: superficie ?? this.superficie,
      superficieAlt: superficieAlt ?? this.superficieAlt,
      superficieAlta: superficieAlta ?? this.superficieAlta,
      superficieMassima: superficieMassima ?? this.superficieMassima,
      scrim: scrim ?? this.scrim,
      linea: linea ?? this.linea,
      lineaForte: lineaForte ?? this.lineaForte,
      testo: testo ?? this.testo,
      testoSecondario: testoSecondario ?? this.testoSecondario,
      testoTenue: testoTenue ?? this.testoTenue,
      azione: azione ?? this.azione,
      azionePremuta: azionePremuta ?? this.azionePremuta,
      azioneInk: azioneInk ?? this.azioneInk,
      azioneTenue: azioneTenue ?? this.azioneTenue,
      azioneFuoco: azioneFuoco ?? this.azioneFuoco,
      rosso: rosso ?? this.rosso,
      rossoTenue: rossoTenue ?? this.rossoTenue,
      ok: ok ?? this.ok,
      okTenue: okTenue ?? this.okTenue,
      attenzione: attenzione ?? this.attenzione,
      attenzioneTenue: attenzioneTenue ?? this.attenzioneTenue,
    );
  }

  @override
  ColoriApp lerp(ThemeExtension<ColoriApp>? other, double t) {
    // Il cambio di tema è istantaneo, senza dissolvenza (DESIGN.md
    // sezione 15): nessuna interpolazione reale, si passa da un set di
    // token all'altro a metà strada.
    if (other is! ColoriApp) return this;
    return t < 0.5 ? this : other;
  }
}

/// Scorciatoia suggerita da DESIGN.md sezione 20: `context.colori.testo`
/// invece di `Theme.of(context).extension<ColoriApp>()!.testo`. Torna
/// sempre [ColoriApp.chiaro] se, per qualche motivo, il ThemeData attivo
/// non porta l'estensione (non deve succedere una volta che
/// `AppTheme.chiaro`/`.scuro` sono collegati a `MaterialApp`, ma non deve
/// far crashare una schermata se succede).
extension ColoriAppContext on BuildContext {
  ColoriApp get colori =>
      Theme.of(this).extension<ColoriApp>() ?? ColoriApp.chiaro;
}
