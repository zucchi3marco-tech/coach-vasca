import 'package:coach_vasca/features/allenamenti/domain/orologio_vasca.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:flutter_test/flutter_test.dart';

SerieScritta _una(String riga) =>
    leggiRigaSerie(riga, blocco: 'principale')!.single;

void main() {
  group('ogni quanto si parte', () {
    test('con la ripartenza, quella', () {
      final i = intervalloPartenze(_una('8x100 sl @1:30 r10'));
      expect(i.secondi, 90);
      expect(i.stimato, isFalse);
    });

    test('nelle serie a tempo, lavoro più recupero', () {
      final i = intervalloPartenze(_una("4x5' r60"));
      expect(i.secondi, 360);
      expect(i.stimato, isFalse);
    });

    test('senza, la stima arrotondata ai 5 secondi', () {
      // 110 s di nuoto + 15 di recupero tipico sui 100 = 125.
      final i = intervalloPartenze(_una('8x100 sl'));
      expect(i.secondi, 125);
      expect(i.stimato, isTrue);
      // 50 m: 55 + 12 = 67 -> 65.
      expect(intervalloPartenze(_una('8x50 sl')).secondi, 65);
    });
  });

  group('l\'orologio', () {
    const piano = PianoPartenze(ripetute: 3, intervalloS: 60);

    test('alla partenza: prima ripetuta, si legge "Via"', () {
      final s = piano.a(0);
      expect(s.ripetuta, 1);
      expect(s.dallaPartenzaS, 0);
      expect(s.allaProssimaS, 60);
      expect(s.appenaPartita, isTrue);
      expect(s.finita, isFalse);
    });

    test(
      'a metà della seconda: tempo dalla partenza e conto alla rovescia',
      () {
        final s = piano.a(75);
        expect(s.ripetuta, 2);
        expect(s.dallaPartenzaS, 15);
        expect(s.allaProssimaS, 45);
        expect(s.appenaPartita, isFalse);
      },
    );

    test('all\'ultima non c\'è una prossima partenza; poi è finita', () {
      expect(piano.a(150).ripetuta, 3);
      expect(piano.a(150).allaProssimaS, isNull);
      expect(piano.a(179).finita, isFalse);
      final fine = piano.a(180);
      expect(fine.finita, isTrue);
      expect(fine.ripetuta, 3);
    });

    test('partenze sfalsate: ogni gruppo ha la sua prossima partenza', () {
      const sfalsate = PianoPartenze(
        ripetute: 2,
        intervalloS: 60,
        gruppi: 3,
        distaccoS: 10,
      );
      expect(sfalsate.durataS, 140);
      final s = sfalsate.a(5);
      // Il secondo gruppo parte a 10, il terzo a 20.
      expect(s.prossimiGruppi, [5, 15]);
      expect(sfalsate.a(11).appenaPartita, isTrue);
      expect(sfalsate.a(13).appenaPartita, isFalse);
      // Il primo gruppo ha finito le partenze, il terzo parte a 80.
      final tardi = sfalsate.a(75);
      expect(tardi.allaProssimaS, isNull);
      expect(tardi.prossimiGruppi, [null, 5]);
      expect(sfalsate.a(139).finita, isFalse);
      expect(sfalsate.a(140).finita, isTrue);
    });

    test('serie a tempo: lavoro, poi recupero fino alla prossima', () {
      const aTempo = PianoPartenze(ripetute: 2, intervalloS: 360, lavoroS: 300);
      final lavoro = aTempo.a(100);
      expect(lavoro.inRecupero, isFalse);
      expect(lavoro.allaFineFaseS, 200);
      final recupero = aTempo.a(320);
      expect(recupero.inRecupero, isTrue);
      expect(recupero.allaFineFaseS, 40);
    });
  });
}
