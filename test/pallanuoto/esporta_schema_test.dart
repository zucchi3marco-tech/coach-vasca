import 'dart:convert';

import 'package:coach_vasca/features/pallanuoto/pdf/schema_tattico_pdf.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/esporta_schema.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/water_polo_tactics_board.dart';
import 'package:flutter_test/flutter_test.dart';

const PassoLavagna _passo = (
  giocatori: [
    GiocatoreLavagna(posizione: Offset(0.3, 0.6), colore: ColoreLavagna.bianco),
    GiocatoreLavagna(
      posizione: Offset(0.32, 0.62),
      colore: ColoreLavagna.giallo,
    ),
  ],
  frecce: [
    FrecciaLavagna(
      inizio: Offset(0.3, 0.6),
      fine: Offset(0.7, 0.6),
      colore: ColoreLavagna.nero,
      tipo: TipoFreccia.passaggio,
      controllo: Offset(0.5, 0.8),
    ),
  ],
  zone: [
    ZonaLavagna(
      da: Offset(0.1, 0.1),
      a: Offset(0.5, 0.4),
      colore: ColoreLavagna.giallo,
      forma: FormaZona.ovale,
    ),
  ],
  testi: [
    TestoLavagna(
      punto: Offset(0.5, 0.2),
      testo: 'Centroboa',
      colore: ColoreLavagna.bianco,
    ),
  ],
);

void main() {
  test('il nome del file viene dal titolo, senza accenti né simboli', () {
    expect(nomeFileSchema('Superiorità 6 vs 5!'), 'superiorita-6-vs-5');
    expect(nomeFileSchema('  ***  '), 'schema');
  });

  test('la legenda elenca solo i tratti usati, nell\'ordine dei tipi', () {
    expect(legendaFrecce([_passo]), ['tratteggiata = passaggio']);
  });

  testWidgets('immagine del passo e PDF di tutto lo schema', (tester) async {
    await tester.runAsync(() async {
      final png = await immaginePasso(_passo, CampoLavagna.meta);
      // Firma di un file PNG.
      expect(png.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);

      final pdf = await generaSchemaPdf(
        titolo: 'Superiorità 6 vs 5',
        categoria: 'Superiorità',
        campo: CampoLavagna.meta.nome,
        immaginiPassi: [png, png],
        legenda: legendaFrecce([_passo]),
      );
      expect(ascii.decode(pdf.sublist(0, 5)), '%PDF-');
    });
  });
}
