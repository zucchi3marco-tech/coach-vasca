import 'package:coach_vasca/features/ai_genera/domain/focus_lavoro.dart';
import 'package:coach_vasca/features/ai_genera/domain/modulo_compilato.dart';
import 'package:coach_vasca/features/ai_genera/domain/parametri_generazione.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParametriGenerazione.toMap', () {
    test(
      'porta tutti i campi che la Edge Function usa, focus multiplo incluso',
      () {
        final mappa = const ParametriGenerazione(
          gruppo: 'U14',
          volumeMetri: 3000,
          volumeLavoroCentraleM: 1500,
          focus: ['braccia', 'gambe'],
          dettaglioBraccia: DettaglioFocus(
            metri: 600,
            attrezzatura: ['palette'],
            stile: 'libero',
          ),
          dettaglioGambe: DettaglioFocus(metri: 400),
          attrezzaturaLavoroCentrale: ['pull'],
          minutiMax: 75,
          vascaM: 25,
          regimiAmmessi: ['A1', 'B1'],
        ).toMap();

        expect(mappa['focus'], ['braccia', 'gambe']);
        expect(mappa['volumeLavoroCentraleMetri'], 1500);
        expect(mappa['minutiMax'], 75);
        expect(mappa['vascaM'], 25);
        expect(mappa['attrezzaturaLavoroCentrale'], ['pull']);
        expect(mappa['dettaglioBraccia'], {
          'metri': 600,
          'attrezzatura': ['palette'],
          'stile': 'libero',
        });
        expect((mappa['dettaglioGambe'] as Map)['metri'], 400);
        expect(mappa['dettaglioGambe'], isNot(contains('palette')));
      },
    );

    test('senza dettagli i campi sono null', () {
      final mappa = const ParametriGenerazione(
        gruppo: 'U14',
        volumeMetri: 3000,
        focus: ['completo'],
        regimiAmmessi: ['A1'],
      ).toMap();
      expect(mappa['dettaglioBraccia'], isNull);
      expect(mappa['dettaglioGambe'], isNull);
      expect(mappa['stileTecnica'], isNull);
    });
  });

  group('ModuloCompilato.fromMap', () {
    test('legge solo i campi presenti', () {
      final m = ModuloCompilato.fromMap({
        'vascaM': 25,
        'volumeMetri': 5000,
        'volumeLavoroCentraleMetri': 3000,
        'tipiLavoro': ['A2'],
        'focus': ['gambe', 'braccia'],
        'metriGambe': 400,
        'metriBraccia': 600,
        'attrezziBraccia': ['palette'],
        'vincoli': ' no rana ',
      });
      expect(m.vascaM, 25);
      expect(m.minutiMax, isNull);
      expect(m.volumeMetri, 5000);
      expect(m.tipiLavoro, ['A2']);
      expect(m.focus, ['gambe', 'braccia']);
      expect(m.gambe?.metri, 400);
      expect(m.braccia?.attrezzatura, ['palette']);
      expect(m.vincoli, 'no rana');
      expect(m.vuoto, isFalse);
    });

    test('una mappa vuota è vuota', () {
      expect(ModuloCompilato.fromMap({}).vuoto, isTrue);
      expect(ModuloCompilato.fromMap({'vincoli': '  '}).vuoto, isTrue);
    });

    test('ignora valori del tipo sbagliato senza crashare', () {
      final m = ModuloCompilato.fromMap({
        'vascaM': 'venticinque',
        'tipiLavoro': 'A1',
        'focus': [1, 'gambe'],
      });
      expect(m.vascaM, isNull);
      expect(m.tipiLavoro, isEmpty);
      expect(m.focus, ['gambe']);
    });
  });

  group('dettagliFocusPerSeduta', () {
    const braccia = DettaglioFocus(metri: 600, attrezzatura: ['palette']);
    const gambe = DettaglioFocus(metri: 400, stile: 'delfino');

    test('include solo i dettagli dei focus della seduta', () {
      final r = dettagliFocusPerSeduta(
        focus: ['gambe'],
        volumeSeduta: 3000,
        braccia: braccia,
        gambe: gambe,
      );
      expect(r.braccia, isNull);
      expect(r.gambe?.metri, 400);
      expect(r.gambe?.stile, 'delfino');
    });

    test('riduce in proporzione se braccia e gambe superano la seduta', () {
      final r = dettagliFocusPerSeduta(
        focus: ['braccia', 'gambe'],
        volumeSeduta: 500,
        braccia: braccia,
        gambe: gambe,
      );
      expect(r.braccia!.metri! + r.gambe!.metri!, 500);
      expect(r.braccia!.metri, 300);
      expect(r.braccia!.attrezzatura, ['palette']);
    });

    test('senza metri (Auto) lascia i metri vuoti', () {
      final r = dettagliFocusPerSeduta(
        focus: ['braccia'],
        volumeSeduta: 1000,
        braccia: const DettaglioFocus(attrezzatura: ['pull']),
      );
      expect(r.braccia?.metri, isNull);
    });
  });
}
