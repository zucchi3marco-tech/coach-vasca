import 'package:coach_vasca/features/novita/data/novita_viste.dart';
import 'package:coach_vasca/features/novita/domain/novita.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('su un telefono nuovo non c\'è niente di visto', () async {
    expect(await leggiUltimaNovitaVista(), isNull);
  });

  test('segna la novità più recente del registro', () async {
    await segnaNovitaViste();
    expect(await leggiUltimaNovitaVista(), registroNovita.first.id);
  });

  test('con un registro dato segna il suo primo id', () async {
    await segnaNovitaViste([
      Novita(id: 'nuova', data: DateTime(2026, 11), titolo: 'N', testo: 'T'),
      Novita(id: 'vecchia', data: DateTime(2026, 10), titolo: 'V', testo: 'T'),
    ]);
    expect(await leggiUltimaNovitaVista(), 'nuova');
  });

  test('con il registro vuoto non scrive niente', () async {
    SharedPreferences.setMockInitialValues({'novita_ultima_vista': 'prima'});
    await segnaNovitaViste(const []);
    expect(await leggiUltimaNovitaVista(), 'prima');
  });
}
