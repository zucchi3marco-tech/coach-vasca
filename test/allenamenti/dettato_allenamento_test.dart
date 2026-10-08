import 'package:coach_vasca/features/allenamenti/domain/dettato_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('i numeri in lettere', () {
    expect(numeroDaParola('otto'), 8);
    expect(numeroDaParola('cento'), 100);
    expect(numeroDaParola('venticinque'), 25);
    expect(numeroDaParola('ventotto'), 28);
    expect(numeroDaParola('trentuno'), 31);
    expect(numeroDaParola('duecentocinquanta'), 250);
    expect(numeroDaParola('milleduecento'), 1200);
    expect(numeroDaParola('duemila'), 2000);
    expect(numeroDaParola('centoboa'), isNull);
    expect(numeroDaParola('una'), isNull);
    expect(numeroDaParola('dorso'), isNull);
  });

  test('come scrive il browser, come lo capisce l\'interprete', () {
    expect(
      normalizzaDettato('otto da cento stile libero'),
      '8 da 100 stile libero',
    );
    expect(normalizzaDettato('8% stile libero'), '8x100 stile libero');
    expect(normalizzaDettato('10 percento'), '10x100');
    expect(normalizzaDettato('ripartenza 1 minuto e 30'), "ripartenza 1'30''");
    expect(normalizzaDettato('ripartenza uno e trenta'), "ripartenza 1'30''");
    expect(normalizzaDettato('recupero 20 secondi'), "recupero 20''");
    expect(normalizzaDettato('10 minuti remate'), "10' remate");
    expect(normalizzaDettato('zona b uno'), 'zona B1');
    expect(normalizzaDettato('a 2 c 3'), 'A2 C3');
    // "a 1:30" è un tempo, non la zona A1.
    expect(normalizzaDettato('8 per 100 a 1:30'), '8 per 100 a 1:30');
    expect(normalizzaDettato('quattro per cinquanta pool'), '4 per 50 pull');
    expect(normalizzaDettato('ogni 1,30'), 'ogni 1.30');
  });

  test('una frase detta come capita, letta senza errori', () {
    final s = leggiRigaSerie(
      righeDaDettato('otto per cento stile libero b uno ripartenza 1 e 30'),
      blocco: 'principale',
    )!.single;
    expect(s.ripetute, 8);
    expect(s.distanzaM, 100);
    expect(s.zona, 'B1');
    expect(s.ripartenzaS, 90);
    expect(s.note, isNull);

    final percento = leggiRigaSerie(
      righeDaDettato('8% gambe recupero 15 secondi'),
      blocco: 'principale',
    )!.single;
    expect(percento.ripetute, 8);
    expect(percento.esecuzione, 'gambe');
    expect(percento.recuperoS, 15);
  });

  test('una pausa, una riga; un pezzo staccato si riattacca', () {
    const dettato =
        'riscaldamento 400 misti\n'
        'otto da cento stile libero\n'
        'b uno recupero 20\n'
        'poi 200 dorso sciolto';
    final righe = righeDaDettato(dettato);
    expect(
      righe,
      'riscaldamento 400 misti\n'
      '8 da 100 stile libero B1 recupero 20\n'
      '200 dorso sciolto',
    );
    final scritto = interpretaAllenamento(righe);
    expect(scritto.righeNonCapite, 0);
    expect(scritto.serie[1].zona, 'B1');
    expect(scritto.serie[1].recuperoS, 20);
  });
}
