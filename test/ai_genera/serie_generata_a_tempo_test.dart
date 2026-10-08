import 'package:coach_vasca/features/ai_genera/application/tempo_stimato_service.dart';
import 'package:coach_vasca/features/ai_genera/domain/scheda_generata.dart';
import 'package:coach_vasca/features/allenamenti/presentation/serie_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scheda = SchedaGenerata.fromMap({
    'titolo': 'Superiorità',
    'serie': [
      {
        'ordine': 1,
        'blocco': 'principale',
        'ripetute': 8,
        'distanzaM': 50,
        'durataS': null,
        'stile': 'libero',
        'esecuzione': 'nuoto',
        'zona': 'B1',
        'recuperoS': 20,
      },
      {
        'ordine': 2,
        'blocco': 'principale',
        'ripetute': 3,
        'distanzaM': null,
        'durataS': 300,
        'stile': 'libero',
        'esecuzione': 'uomo in più',
        'zona': 'C1',
        'recuperoS': 60,
      },
    ],
  });

  test('una serie a tempo della scheda generata: niente metri', () {
    final aTempo = scheda.serie[1];
    expect(aTempo.distanzaM, isNull);
    expect(aTempo.durataS, 300);
    expect(aTempo.distanzaTotaleM, 0);
    expect(scheda.volumeTotaleM, 400);
    expect(titoloSerieProposta(aTempo), "3×5' Uomo in più");
    expect(titoloSerieProposta(scheda.serie[0]), '8×50m Libero Nuoto');
    // E torna uguale salvata nello storico.
    final riletta = SchedaGenerata.fromMap(scheda.toMap()).serie[1];
    expect(riletta.durataS, 300);
    expect(riletta.distanzaM, isNull);
  });

  test('i minuti di una serie a tempo: durata più recupero', () {
    // 3 × (300 + 60) = 18 minuti.
    expect(stimaMinutiSessione([scheda.serie[1]]), 18);
  });

  test('le schede vecchie dello storico (solo distanza) si leggono', () {
    final vecchia = SerieGenerata.fromMap({
      'ordine': 1,
      'blocco': 'riscaldamento',
      'ripetute': 1,
      'distanzaM': 400,
      'stile': 'misti',
      'esecuzione': 'nuoto',
    });
    expect(vecchia.distanzaM, 400);
    expect(vecchia.durataS, isNull);
  });
}
