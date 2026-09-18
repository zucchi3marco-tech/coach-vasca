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
    required this.evidenzaCiano,
    required this.evidenzaVerde,
    required this.evidenzaAmbra,
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

  /// Tavolozza "evidenza" — DESIGN.md sezione "Dove spendere l'audacia":
  /// riservata alla dashboard atleta (icone delle sue schede) e al
  /// grafico Banister ovunque appaia (vedi [curvaFitness]/[curvaForma]).
  /// Non va riusata altrove senza deciderlo esplicitamente — resta
  /// un'eccezione delimitata, non il nuovo colore d'azione dell'app.
  final Color evidenzaCiano;
  final Color evidenzaVerde;
  final Color evidenzaAmbra;

  /// Colore della zona, o un neutro tenue se la sigla non è
  /// riconosciuta — non deve mai capitare, ma non deve nemmeno far
  /// crashare una schermata.
  Color colorePerZona(String? sigla, {required Color rispetto}) =>
      coloriZona[sigla] ?? rispetto;

  /// Curve del grafico Banister — DESIGN.md sezione 7. Fitness e forma
  /// usano la tavolozza "evidenza" (più vivaci, vedi sopra); fatica resta
  /// `colori.attenzione` (il significato "in corso/da tenere d'occhio" le
  /// si addice già). Il parametro `colori` resta per compatibilità con i
  /// chiamanti esistenti, anche se le prime due non lo usano più.
  Color curvaFitness(ColoriApp colori) => evidenzaCiano;
  Color curvaFatica(ColoriApp colori) => colori.attenzione;
  Color curvaForma(ColoriApp colori) => evidenzaVerde;

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
    Color? evidenzaCiano,
    Color? evidenzaVerde,
    Color? evidenzaAmbra,
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
      evidenzaCiano: evidenzaCiano ?? this.evidenzaCiano,
      evidenzaVerde: evidenzaVerde ?? this.evidenzaVerde,
      evidenzaAmbra: evidenzaAmbra ?? this.evidenzaAmbra,
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
