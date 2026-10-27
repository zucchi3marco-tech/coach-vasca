import 'package:coach_vasca/features/campionati/application/sito_fin_cambiato.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('una segnalazione al giorno, con il testo e la pagina', () async {
    var adesso = DateTime(2026, 10, 27, 9);
    final mandate = <(String, String, String?)>[];
    final segnalatore = SegnalatoreSitoFin(({
      required clubId,
      required testo,
      required contesto,
    }) async {
      mandate.add((clubId, testo, contesto.pagina));
    }, adesso: () => adesso);

    await segnalatore.segnala(clubId: 'c1', cosa: 'girone U14, CMPid 259');
    await segnalatore.segnala(clubId: 'c1', cosa: 'girone U16, CMPid 260');
    expect(mandate, hasLength(1));
    expect(mandate.single.$1, 'c1');
    expect(
      mandate.single.$2,
      contains('il sito della FIN Lombardia è cambiato'),
    );
    expect(mandate.single.$2, contains('girone U14, CMPid 259'));
    expect(mandate.single.$3, 'Campionati FIN, girone U14, CMPid 259');

    adesso = DateTime(2026, 10, 28, 8);
    await segnalatore.segnala(clubId: 'c1', cosa: 'girone U16, CMPid 260');
    expect(mandate, hasLength(2));
  });

  test('se non parte non dà errori e si riprova la volta dopo', () async {
    var tentativi = 0;
    final segnalatore = SegnalatoreSitoFin(({
      required clubId,
      required testo,
      required contesto,
    }) async {
      tentativi++;
      if (tentativi == 1) throw Exception('senza rete');
    }, adesso: () => DateTime(2026, 10, 27));

    await segnalatore.segnala(clubId: 'c1', cosa: 'elenco');
    await segnalatore.segnala(clubId: 'c1', cosa: 'elenco');
    await segnalatore.segnala(clubId: 'c1', cosa: 'elenco');
    expect(tentativi, 2);
  });
}
