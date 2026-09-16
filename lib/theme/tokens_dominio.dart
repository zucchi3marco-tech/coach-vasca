import 'package:flutter/material.dart';

import 'colori_app.dart';
import 'tokens/tokens_chiaro.dart';
import 'tokens/tokens_scuro.dart';

/// Colori di dominio — DESIGN.md sezione 7, livello 3 dell'architettura
/// dei token (sezione 3): zone di intensità, calottine, colore "in
/// corso". Sono dati, non interfaccia: hanno un valore fisso per tema,
/// scelti a occhio (non derivabili l'uno dall'altro con una formula).
///
/// Si legge con `Theme.of(context).extension<TokenDominio>()`.
@immutable
class TokenDominio extends ThemeExtension<TokenDominio> {
  const TokenDominio({
    required this.coloriZona,
    required this.calottinaBiancaFondo,
    required this.calottinaBiancaBordo,
    required this.calottinaBluFondo,
    required this.calottinaRossaFondo,
    required this.calottinaNumeroSuBianca,
    required this.calottinaNumeroSuBlu,
    required this.calottinaNumeroSuRossa,
  });

  /// Colore per sigla di zona (A1, A2, B1, B2, C1, C2, C3, D). `C` senza
  /// numero (zona storica, sostituita da C1/C2/C3 — DESIGN.md sezione 7)
  /// resta con gli stessi valori di C2, mai rimossa: serve alle serie
  /// salvate prima dello split.
  final Map<String, Color> coloriZona;

  final Color calottinaBiancaFondo;
  final Color calottinaBiancaBordo;
  final Color calottinaBluFondo;
  final Color calottinaRossaFondo;

  /// Il colore del numero dentro la calottina non cambia fra i due temi
  /// (DESIGN.md sezione 7): il fondo della calottina bianca resta chiaro
  /// in entrambi, quello di blu/rossa resta scuro in entrambi, quindi lo
  /// stesso numero regge il contrasto sempre.
  final Color calottinaNumeroSuBianca;
  final Color calottinaNumeroSuBlu;
  final Color calottinaNumeroSuRossa;

  /// Colore della zona, o un neutro tenue se la sigla non è
  /// riconosciuta — non deve mai capitare, ma non deve nemmeno far
  /// crashare una schermata.
  Color colorePerZona(String? sigla, {required Color rispetto}) =>
      coloriZona[sigla] ?? rispetto;

  /// Curve del grafico Banister — DESIGN.md sezione 7: sono già in
  /// [ColoriApp] (fitness = azione, fatica = attenzione, forma = ok),
  /// qui solo un getter di comodo che le richiama invece di duplicarle.
  Color curvaFitness(ColoriApp colori) => colori.azione;
  Color curvaFatica(ColoriApp colori) => colori.attenzione;
  Color curvaForma(ColoriApp colori) => colori.ok;

  static const chiaro = tokenDominioChiaro;
  static const scuro = tokenDominioScuro;

  @override
  TokenDominio copyWith({
    Map<String, Color>? coloriZona,
    Color? calottinaBiancaFondo,
    Color? calottinaBiancaBordo,
    Color? calottinaBluFondo,
    Color? calottinaRossaFondo,
    Color? calottinaNumeroSuBianca,
    Color? calottinaNumeroSuBlu,
    Color? calottinaNumeroSuRossa,
  }) {
    return TokenDominio(
      coloriZona: coloriZona ?? this.coloriZona,
      calottinaBiancaFondo: calottinaBiancaFondo ?? this.calottinaBiancaFondo,
      calottinaBiancaBordo: calottinaBiancaBordo ?? this.calottinaBiancaBordo,
      calottinaBluFondo: calottinaBluFondo ?? this.calottinaBluFondo,
      calottinaRossaFondo: calottinaRossaFondo ?? this.calottinaRossaFondo,
      calottinaNumeroSuBianca:
          calottinaNumeroSuBianca ?? this.calottinaNumeroSuBianca,
      calottinaNumeroSuBlu: calottinaNumeroSuBlu ?? this.calottinaNumeroSuBlu,
      calottinaNumeroSuRossa:
          calottinaNumeroSuRossa ?? this.calottinaNumeroSuRossa,
    );
  }

  @override
  TokenDominio lerp(ThemeExtension<TokenDominio>? other, double t) {
    // Token discreti (colori di dominio, non un gradiente): niente
    // interpolazione reale, il cambio tema è istantaneo (DESIGN.md
    // sezione 15).
    if (other is! TokenDominio) return this;
    return t < 0.5 ? this : other;
  }
}

/// Scorciatoia analoga a `context.colori` (vedi `colori_app.dart`):
/// `context.dominio.coloriZona['A1']` invece di
/// `Theme.of(context).extension<TokenDominio>()!.coloriZona['A1']`.
extension TokenDominioContext on BuildContext {
  TokenDominio get dominio =>
      Theme.of(this).extension<TokenDominio>() ?? TokenDominio.chiaro;
}
