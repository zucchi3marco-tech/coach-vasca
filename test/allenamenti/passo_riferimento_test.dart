import 'package:coach_vasca/features/allenamenti/application/passo_riferimento_provider.dart';
import 'package:coach_vasca/features/allenamenti/domain/durata_serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/orologio_vasca.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/domain/personal_best.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(String id, {String? gruppo = 'u14', bool attivo = true}) =>
    Atleta(
      id: id,
      clubId: 'c1',
      nome: id,
      cognome: id,
      dataNascita: DateTime(2012),
      sport: 'nuoto',
      gruppoId: gruppo,
      consensoPrivacyFirmato: true,
      attivo: attivo,
    );

PersonalBest _primato(String atleta, int distanza, double tempo) =>
    PersonalBest(
      id: '$atleta-$distanza',
      atletaId: atleta,
      clubId: 'c1',
      stile: 'libero',
      distanzaM: distanza,
      tempoS: tempo,
    );

SerieScritta _una(String riga) =>
    leggiRigaSerie(riga, blocco: 'principale')!.single;

void main() {
  group('passo per zona', () {
    const riferimento = (passo100S: 80.0, differenzialeS: 90.0);

    test('senza il gruppo, il passo medio di sempre', () {
      expect(passoPerZona('B1', null), passoMedioS);
    });

    test('con il gruppo: aerobico più lento, lattacido vicino al primato', () {
      expect(passoPerZona('A1', riferimento), 90 + 3.5 + 12);
      expect(passoPerZona('A2', riferimento), 90 + 3.5 + 5);
      expect(passoPerZona('B1', riferimento), 90 + 3.5);
      expect(passoPerZona('B2', riferimento), 90);
      expect(passoPerZona('C1', riferimento), 81.5);
      expect(passoPerZona('C3', riferimento), 80);
      // Senza zona si conta come A1.
      expect(passoPerZona(null, riferimento), 105.5);
    });

    test('senza primato sui 200 il differenziale si stima dal 100', () {
      expect(
        passoPerZona('B2', (passo100S: 80.0, differenzialeS: null)),
        closeTo(92, 1e-9),
      );
    });

    test('la durata e le partenze stimate seguono il gruppo', () {
      final serie = _una('8x100 sl B2 r10');
      expect(secondiPerRipetuta(serie, riferimento: riferimento), 90 + 10);
      expect(
        intervalloPartenze(
          _una('8x100 sl B2'),
          riferimento: riferimento,
        ).secondi,
        // 90 di nuoto + 60 di recupero tipico in B2.
        150,
      );
      // Una ripartenza scritta vince sempre.
      expect(
        secondiPerRipetuta(_una('8x100 sl B2 @1:30'), riferimento: riferimento),
        90,
      );
    });
  });

  group('passo di riferimento del gruppo', () {
    test('è quello della corsia più lenta del gruppo', () {
      final riferimento = passoRiferimentoDelGruppo(
        atleti: [_atleta('a'), _atleta('b'), _atleta('c'), _atleta('d')],
        primati: [
          _primato('a', 100, 60),
          _primato('b', 100, 62),
          _primato('c', 100, 80),
          _primato('c', 200, 170),
          _primato('d', 100, 84),
        ],
        gruppoId: 'u14',
      );
      // Troppo diversi per una corsia sola: i lenti sono c e d.
      expect(riferimento!.passo100S, 82);
      expect(riferimento.differenzialeS, 90);
    });

    test('contano solo gli attivi del gruppo', () {
      final riferimento = passoRiferimentoDelGruppo(
        atleti: [
          _atleta('a'),
          _atleta('b', gruppo: 'u16'),
          _atleta('c', attivo: false),
        ],
        primati: [
          _primato('a', 100, 70),
          _primato('b', 100, 90),
          _primato('c', 100, 95),
        ],
        gruppoId: 'u14',
      );
      expect(riferimento!.passo100S, 70);
    });

    test('nessun primato sui 100: nessun riferimento', () {
      expect(
        passoRiferimentoDelGruppo(
          atleti: [_atleta('a')],
          primati: [_primato('a', 200, 150)],
          gruppoId: 'u14',
        ),
        isNull,
      );
    });
  });
}
