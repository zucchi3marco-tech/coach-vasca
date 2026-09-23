// `flutter test` gira sulla VM (mai su web), quindi importa sempre lo
// stub — vedi dettatura_vocale.dart. La versione web (interop con la Web
// Speech API) è verificata da `flutter build web` (compila anche per
// WASM), non da un test automatico: nessun harness qui ha un microfono
// vero da usare.
import 'package:coach_vasca/core/dettatura/dettatura_vocale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fuori dal web la dettatura non è mai disponibile', () {
    expect(DettatoreVocale.disponibile, isFalse);
  });

  test('avvia/ferma/dispose non fanno nulla e non lanciano eccezioni', () {
    var chiamato = false;
    final dettatore = DettatoreVocale(
      onTrascrizione: (_) => chiamato = true,
      onErrore: (_) => chiamato = true,
      onFine: () => chiamato = true,
    );

    expect(dettatore.inAscolto, isFalse);
    expect(() => dettatore.avvia(), returnsNormally);
    expect(() => dettatore.ferma(), returnsNormally);
    expect(() => dettatore.dispose(), returnsNormally);
    expect(chiamato, isFalse);
  });
}
