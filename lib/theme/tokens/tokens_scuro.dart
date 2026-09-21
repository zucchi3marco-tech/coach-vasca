import 'package:flutter/material.dart';

import '../colori_app.dart';
import '../tokens_dominio.dart';
import 'palette.dart';

/// Token semantici e di dominio del tema scuro — DESIGN.md sezioni 5 e
/// 7. **Nessuna schermata importa questo file**: legge solo
/// `palette.dart`, e le sue istanze sono esposte come
/// `ColoriApp.scuro`/`TokenDominio.scuro`.
///
/// Non è il chiaro invertito (DESIGN.md sezione 15): la profondità si fa
/// con la luminosità della superficie, non con l'ombra; gli accenti
/// salgono di luminosità e scendono di saturazione; l'inchiostro sopra
/// gli accenti si inverte.
const coloriAppScuro = ColoriApp(
  sfondo: Palette.scuro900,
  superficie: Palette.scuro800,
  superficieAlt: Palette.scuro700,
  superficieAlta: Palette.scuro600,
  superficieMassima: Palette.scuro500,
  scrim: Color.fromRGBO(3, 8, 12, 0.72),
  linea: Palette.scuro400,
  lineaForte: Palette.scuro300,
  testo: Palette.scuro50,
  testoSecondario: Palette.scuro100,
  testoTenue: Palette.scuro200,
  azione: Palette.acqua400,
  azionePremuta: Palette.acqua300,
  // Inchiostro scuro sopra l'azzurro chiaro d'azione, non bianco — vedi
  // ColoriApp.azioneInk.
  azioneInk: Color(0xFF072A38),
  azioneTenue: Color.fromRGBO(79, 195, 232, 0.14), // acqua400 a bassa opacità
  azioneFuoco: Color.fromRGBO(79, 195, 232, 0.45),
  rosso: Palette.rossoScuro,
  rossoTenue: Color.fromRGBO(255, 107, 90, 0.14), // rossoScuro a bassa opacità
  ok: Palette.verdeScuro,
  okTenue: Color.fromRGBO(69, 211, 145, 0.14), // verdeScuro a bassa opacità
  attenzione: Palette.ambraScuro,
  attenzioneTenue: Color.fromRGBO(240, 169, 60, 0.14), // ambraScuro
);

const tokenDominioScuro = TokenDominio(
  coloriZona: {
    'A1': Color(0xFF6FBDE6),
    'A2': Color(0xFF4FB3B3),
    'B1': Color(0xFF7CC45E),
    'B2': Color(0xFFE3BA45),
    'C1': Color(0xFFEDA75C),
    'C2': Color(0xFFF09146),
    // Zona storica: stessi valori di C2 — vedi tokens_chiaro.dart.
    'C': Color(0xFFF09146),
    'C3': Color(0xFFE37440),
    'D': Color(0xFFB769B8),
  },
  calottinaBiancaFondo: Palette.scuro50,
  calottinaBiancaBordo: Palette.scuro200,
  calottinaBluFondo: Color(0xFF2A6DB0),
  calottinaRossaFondo: Color(0xFFE8503F),
  // Il colore del numero non cambia fra i temi (DESIGN.md sezione 7): il
  // fondo di ogni calottina resta nello stesso registro di luminosità in
  // entrambi (bianca sempre chiara, blu/rossa sempre scure).
  calottinaNumeroSuBianca: Palette.chiaro900,
  calottinaNumeroSuBlu: Palette.chiaro0,
  calottinaNumeroSuRossa: Palette.chiaro0,
  // Tavolozza "evidenza" (dashboard atleta + grafico Banister) — vedi
  // TokenDominio.evidenzaCiano e DESIGN.md "Dove spendere l'audacia".
  evidenzaCiano: Color(0xFF2FE3FF),
  evidenzaVerde: Color(0xFF5EE88A),
  evidenzaAmbra: Color(0xFFFFC24B),
  evidenzaViola: Color(0xFFB794FF),
);
