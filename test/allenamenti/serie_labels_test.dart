import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/presentation/serie_labels.dart';
import 'package:flutter_test/flutter_test.dart';

String _titolo(String riga) =>
    titoloSerie(leggiRigaSerie(riga, blocco: 'principale')!.single);

void main() {
  test('nel lavoro di pallanuoto e a secco il titolo non dice "Libero"', () {
    expect(_titolo('8x100 sl'), '8×100m Libero');
    expect(_titolo('4x50 do gambe'), '4×50m Dorso Gambe');
    expect(_titolo("4x5' uomo in +"), isNot(contains('Libero')));
    expect(_titolo("4x5' uomo in +"), endsWith('Uomo in più'));
    expect(_titolo("20' gioco da schierati"), endsWith('Gioco da schierati'));
    expect(_titolo('4x25 palleggio'), '4×25m Palleggio');
    // Uno stile scritto apposta resta.
    expect(_titolo('4x25 ra palleggio'), '4×25m Rana Palleggio');
  });
}
