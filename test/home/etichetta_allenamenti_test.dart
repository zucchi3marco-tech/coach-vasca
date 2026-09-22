import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_vasca/features/home/voci_home.dart';

void main() {
  test(
    '«Allenamenti» resta la parola vera, solo con un trattino invisibile',
    () {
      final etichetta = destinazioneHome(VoceHome.allenamenti, null).etichetta;

      expect(etichetta.replaceAll('­', ''), 'Allenamenti');
      expect(etichetta, isNot('Allenamenti')); // contiene il trattino software
    },
  );

  testWidgets(
    'il trattino software non si vede quando la parola sta su una riga',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Text(destinazioneHome(VoceHome.allenamenti, null).etichetta),
        ),
      );
      final larga = tester.getSize(find.textContaining('Allena'));

      await tester.pumpWidget(const MaterialApp(home: Text('Allenamenti')));
      final senzaTrattino = tester.getSize(find.text('Allenamenti'));

      // Stessa larghezza (nessuna spaziatura in più) e una riga sola.
      expect(larga.width, senzaTrattino.width);
      expect(larga.height, senzaTrattino.height);
    },
  );

  testWidgets('se lo spazio manca, va a capo al trattino invisibile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          // Abbastanza per "Allena-" ma non per l'intera parola.
          width: 70,
          child: Text(
            destinazioneHome(VoceHome.allenamenti, null).etichetta,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );

    expect(find.textContaining('Allena'), findsOneWidget);
    final size = tester.getSize(find.textContaining('Allena'));
    // È andata su due righe (altezza doppia rispetto a una riga sola) e la
    // riga mostra il trattino visibile lasciato dal carattere invisibile.
    expect(size.height, greaterThan(20));
  });
}
