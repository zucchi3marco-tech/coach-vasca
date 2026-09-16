import 'package:flutter/material.dart';

import '../colori_app.dart';
import '../tokens_dominio.dart';
import 'palette.dart';

/// Token semantici e di dominio del tema chiaro — DESIGN.md sezioni 5 e
/// 7. **Nessuna schermata importa questo file**: legge solo
/// `palette.dart`, e le sue istanze sono esposte come
/// `ColoriApp.chiaro`/`TokenDominio.chiaro`.
const coloriAppChiaro = ColoriApp(
  // Superfici — nel chiaro i livelli si distinguono con ombra e bordo
  // (vedi app_elevation.dart), la superficie resta bianca dal livello 1
  // in su.
  sfondo: Palette.chiaro100,
  superficie: Palette.chiaro0,
  superficieAlt: Palette.chiaro50,
  superficieAlta: Palette.chiaro0,
  superficieMassima: Palette.chiaro0,
  scrim: Color.fromRGBO(12, 27, 36, 0.48), // chiaro900 (testo) a bassa opacità
  // Linee
  linea: Palette.chiaro200,
  lineaForte: Palette.chiaro300,
  // Testo — niente #000000 (DESIGN.md sezione 5).
  testo: Palette.chiaro900,
  testoSecondario: Palette.chiaro600,
  testoTenue: Palette.chiaro500,
  // Azione — acqua600, il blu della piastrella.
  azione: Palette.acqua600,
  azionePremuta: Palette.acqua700,
  azioneInk: Palette.chiaro0,
  azioneTenue: Color(0xFFE3EEF5),
  azioneFuoco: Color.fromRGBO(13, 92, 135, 0.40), // acqua600 a bassa opacità
  // Segnale
  rosso: Palette.rossoChiaro,
  rossoTenue: Color(0xFFFCEAE8),
  ok: Palette.verdeChiaro,
  okTenue: Color(0xFFE6F4EC),
  attenzione: Palette.ambraChiaro,
  attenzioneTenue: Color(0xFFFBF1E2),
);

const tokenDominioChiaro = TokenDominio(
  coloriZona: {
    'A1': Color(0xFF4FA3D1),
    'A2': Color(0xFF2E8B8B),
    'B1': Color(0xFF5A9E3F),
    'B2': Color(0xFFC79A18),
    'C1': Color(0xFFD68A3A),
    'C2': Color(0xFFD9741F),
    // Zona storica (pre-split C1/C2/C3): stessi valori di C2, non più
    // proposta nelle schermate — DESIGN.md sezione 7.
    'C': Color(0xFFD9741F),
    'C3': Color(0xFFC2571A),
    'D': Color(0xFF8E3B8F),
  },
  calottinaBiancaFondo: Palette.chiaro0,
  calottinaBiancaBordo: Palette.chiaro300, // lineaForte
  calottinaBluFondo: Color(0xFF14477D),
  calottinaRossaFondo: Palette.rossoChiaro,
  calottinaNumeroSuBianca: Palette.chiaro900,
  calottinaNumeroSuBlu: Palette.chiaro0,
  calottinaNumeroSuRossa: Palette.chiaro0,
);
