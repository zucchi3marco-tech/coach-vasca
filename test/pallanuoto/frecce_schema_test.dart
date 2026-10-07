import 'package:coach_vasca/features/pallanuoto/data/schemi_tattici_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/schema_tattico.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/water_polo_tactics_board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('salvataggio delle frecce', () {
    test('tipo e curva sopravvivono al salvataggio', () {
      final passo = passoSchemaDaLavagna(
        const [
          GiocatoreLavagna(
            posizione: Offset(0.2, 0.3),
            colore: ColoreLavagna.rosso,
          ),
        ],
        const [
          FrecciaLavagna(
            inizio: Offset(0.1, 0.1),
            fine: Offset(0.5, 0.5),
            colore: ColoreLavagna.nero,
            tipo: TipoFreccia.passaggio,
            controllo: Offset(0.4, 0.1),
          ),
          FrecciaLavagna(
            inizio: Offset(0.6, 0.6),
            fine: Offset(0.7, 0.2),
            colore: ColoreLavagna.bianco,
            tipo: TipoFreccia.tiro,
          ),
        ],
      );

      final riletto = passoLavagnaDaSchema(
        passiSchemaDaMappa(datiSchemaInMappa([passo])).single,
      );

      final curva = riletto.frecce[0];
      expect(curva.tipo, TipoFreccia.passaggio);
      expect(curva.controllo, const Offset(0.4, 0.1));
      expect(curva.colore, ColoreLavagna.nero);
      final dritta = riletto.frecce[1];
      expect(dritta.tipo, TipoFreccia.tiro);
      expect(dritta.controllo, isNull);
      expect(riletto.giocatori.single.colore, ColoreLavagna.rosso);
    });

    test('le frecce salvate prima dei tipi restano nuotate dritte', () {
      final passi = passiSchemaDaMappa({
        'passi': [
          {
            'giocatori': const [],
            'frecce': [
              {
                'inizio': [0.1, 0.2],
                'fine': [0.3, 0.4],
                'colore': 'blu',
              },
            ],
          },
        ],
      });
      final freccia = passoLavagnaDaSchema(passi.single).frecce.single;
      expect(freccia.tipo, TipoFreccia.nuotata);
      expect(freccia.controllo, isNull);
    });

    test('un tipo sconosciuto (versione futura) diventa nuotata', () {
      expect(TipoFreccia.daNome('blocco'), TipoFreccia.nuotata);
    });
  });

  group('animazione lungo le frecce', () {
    const curva = FrecciaLavagna(
      inizio: Offset(0.2, 0.8),
      fine: Offset(0.6, 0.3),
      colore: ColoreLavagna.nero,
      controllo: Offset(0.1, 0.4),
    );

    test('trova la freccia che parte e arriva dove si sposta il pezzo', () {
      expect(
        frecciaPerSpostamento(
          [curva],
          const Offset(0.21, 0.79),
          const Offset(0.6, 0.31),
        ),
        same(curva),
      );
    });

    test('nessuna freccia se lo spostamento non le corrisponde', () {
      expect(
        frecciaPerSpostamento(
          [curva],
          const Offset(0.2, 0.8),
          const Offset(0.9, 0.9),
        ),
        isNull,
      );
    });

    test('il pezzo segue la piega della freccia e arriva esatto', () {
      const da = Offset(0.22, 0.8);
      const a = Offset(0.62, 0.3);
      final controllo = controlloPerSpostamento(curva, da, a)!;
      expect(controllo.dx, closeTo(0.12, 1e-9));
      expect(controllo.dy, closeTo(0.4, 1e-9));
    });

    test('freccia dritta: movimento dritto', () {
      expect(
        controlloPerSpostamento(
          curva.copiaCon(dritta: true),
          const Offset(0.2, 0.8),
          const Offset(0.6, 0.3),
        ),
        isNull,
      );
    });
  });

  test('specchiare scambia destra e sinistra, frecce e curve comprese', () {
    final passo = passoSchemaDaLavagna(
      const [
        GiocatoreLavagna(
          posizione: Offset(0.2, 0.3),
          colore: ColoreLavagna.blu,
        ),
      ],
      const [
        FrecciaLavagna(
          inizio: Offset(0.1, 0.5),
          fine: Offset(0.4, 0.2),
          colore: ColoreLavagna.nero,
          tipo: TipoFreccia.passaggio,
          controllo: Offset(0.3, 0.6),
        ),
      ],
    );
    final specchiato = passoLavagnaDaSchema(passoSpecchiato(passo));
    final g = specchiato.giocatori.single.posizione;
    expect(g.dx, closeTo(0.8, 1e-9));
    expect(g.dy, 0.3);
    final f = specchiato.frecce.single;
    expect(f.inizio.dx, closeTo(0.9, 1e-9));
    expect(f.fine.dx, closeTo(0.6, 1e-9));
    expect(f.controllo!.dx, closeTo(0.7, 1e-9));
    expect(f.controllo!.dy, 0.6);
    expect(f.tipo, TipoFreccia.passaggio);
  });
}
