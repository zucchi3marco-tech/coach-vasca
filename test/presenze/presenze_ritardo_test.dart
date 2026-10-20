import 'dart:io';

import 'package:coach_vasca/core/utils/date_italiane.dart';
import 'package:coach_vasca/core/utils/percentuale_presenze.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/presenze/domain/presenze_stagione.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le righe di [sorgente] che confrontano uno stato con la parola
/// 'presente' (== / != / case / braccio di uno switch). Le righe di
/// commento non contano.
List<int> righeCheGuardanoSoloPresente(String sorgente) {
  final confronto = RegExp(
    r'''(==|!=)\s*['"]presente['"]'''
    r'''|['"]presente['"]\s*(==|!=|=>)'''
    r'''|\bcase\s+['"]presente['"]''',
  );
  final righe = sorgente.split('\n');
  return [
    for (var i = 0; i < righe.length; i++)
      if (!righe[i].trimLeft().startsWith('//') && confronto.hasMatch(righe[i]))
        i + 1,
  ];
}

/// I soli file che possono nominare 'presente' in un confronto: quello che
/// definisce la regola. Tutto il resto passa da `contaComePresente`; per
/// sapere *quale* tasto è selezionato o per le etichette si usano le
/// costanti (`statoPresente`...), che il confronto con la parola nuda non
/// vede. Il seme della demo scrive 'presente' ma non lo confronta.
const _consentiti = {'lib/features/presenze/domain/presenza.dart'};

final _oggi = DateTime(2026, 10, 20);

Allenamento _allenamento(String id, DateTime data, {String? gruppo = 'u14'}) =>
    Allenamento(id: id, clubId: 'c1', data: data, gruppoId: gruppo);

Presenza _presenza(String allenamento, String stato, {String atleta = 'r'}) =>
    Presenza(
      id: '$atleta-$allenamento',
      allenamentoId: allenamento,
      atletaId: atleta,
      clubId: 'c1',
      stato: stato,
    );

Atleta _atleta(String id) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Mario',
  cognome: 'Rossi',
  dataNascita: DateTime(2012),
  sport: 'nuoto',
  gruppoId: 'u14',
  consensoPrivacyFirmato: true,
  attivo: true,
);

void main() {
  group('una sola regola per «c\'era»', () {
    test('nessun file guarda solo \'presente\'', () {
      final trovati = <String>[];
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final percorso = file.path.replaceAll(r'\', '/');
        if (_consentiti.contains(percorso)) continue;
        for (final riga in righeCheGuardanoSoloPresente(
          file.readAsStringSync(),
        )) {
          trovati.add(
            '$percorso:$riga: Qui si guarda solo \'presente\': usa '
            'contaComePresente, se no chi è in ritardo non conta.',
          );
        }
      }
      expect(trovati, isEmpty, reason: trovati.join('\n'));
    });

    test('la guardia vede i confronti che deve vedere', () {
      for (final riga in [
        "if (p.stato == 'presente') x();",
        "if (p.stato != 'presente') x();",
        'if (p.stato == "presente") x();',
        "if (p.stato=='presente') x();",
        "  'presente' => 1,",
        "case 'presente':",
        "if ('presente' == stato) x();",
      ]) {
        expect(righeCheGuardanoSoloPresente(riga), [1], reason: riga);
      }
    });

    test('e lascia stare il resto', () {
      for (final riga in [
        "stato: 'presente',",
        "'presente': conti[a.id]?.presente ?? 0,",
        "// se p.stato == 'presente' non basta",
        'if (contaComePresente(p.stato)) x();',
        'if (stato == statoPresente) x();',
      ]) {
        expect(righeCheGuardanoSoloPresente(riga), isEmpty, reason: riga);
      }
    });

    test('presente e in ritardo c\'erano, gli altri no', () {
      expect(contaComePresente('presente'), isTrue);
      expect(contaComePresente('ritardo'), isTrue);
      expect(contaComePresente('assente'), isFalse);
      expect(contaComePresente('giustificato'), isFalse);
      expect(contaComePresente(null), isFalse);
    });

    test('le etichette in italiano', () {
      expect(etichettaStatoPresenza('presente'), 'Presente');
      expect(etichettaStatoPresenza('ritardo'), 'In ritardo');
      expect(etichettaStatoPresenza('assente'), 'Assente');
      expect(etichettaStatoPresenza('giustificato'), 'Giustificato');
    });
  });

  group('percentuali e conteggi', () {
    // Lunedì 12 ottobre 2026: la settimana va dal 12 al 18.
    final allenamenti = [
      _allenamento('set-30', DateTime(2026, 9, 30, 18)),
      _allenamento('ott-05', DateTime(2026, 10, 5, 18)),
      _allenamento('ott-12', DateTime(2026, 10, 12, 18)),
      _allenamento('ott-14', DateTime(2026, 10, 14, 18)),
      _allenamento('ott-18', DateTime(2026, 10, 18, 20)),
      _allenamento('ott-19', DateTime(2026, 10, 19, 18)),
      // Non ancora fatto: non è un'assenza.
      _allenamento('ott-25', DateTime(2026, 10, 25, 18)),
    ];
    final presenze = [
      _presenza('set-30', 'presente'),
      _presenza('ott-05', 'presente'),
      _presenza('ott-12', 'presente'),
      _presenza('ott-14', 'ritardo'),
      _presenza('ott-18', 'assente'),
      _presenza('ott-19', 'presente'),
    ];

    test('la percentuale conta il ritardo come presente', () {
      final percentuale = percentualePresenze(
        allenamenti: allenamenti,
        presenze: presenze,
        atletaId: 'r',
        gruppoAtleta: 'u14',
        adesso: _oggi,
      );
      // 5 su 6 fatti (il 25 non c'è ancora).
      expect(percentuale, closeTo(5 / 6 * 100, 0.001));
    });

    test('solo in ritardo fa il 100%, non lo 0', () {
      expect(
        percentualePresenze(
          allenamenti: [allenamenti[3]],
          presenze: [_presenza('ott-14', 'ritardo')],
          atletaId: 'r',
          gruppoAtleta: 'u14',
          adesso: _oggi,
        ),
        100,
      );
    });

    test('settimana (lunedì-domenica) e mese di calendario', () {
      final c = presenzeSettimanaEMese(
        allenamenti: allenamenti,
        presenze: presenze,
        atletaId: 'r',
        gruppoAtleta: 'u14',
        giorno: DateTime(2026, 10, 14, 18),
        adesso: _oggi,
      );
      // 12, 14 e la domenica 18: presente, in ritardo, assente.
      expect(c.settimana, (presenti: 2, su: 3));
      // Dal 5 al 19 ottobre: il 30 settembre e il 25 non contano.
      expect(c.mese, (presenti: 4, su: 5));
    });

    test('la domenica è l\'ultimo giorno, il lunedì apre la successiva', () {
      expect(
        lunediDellaSettimana(DateTime(2026, 10, 18, 23)),
        DateTime(2026, 10, 12),
      );
      expect(
        lunediDellaSettimana(DateTime(2026, 10, 19)),
        DateTime(2026, 10, 19),
      );
      final lunedi = presenzeSettimanaEMese(
        allenamenti: allenamenti,
        presenze: presenze,
        atletaId: 'r',
        gruppoAtleta: 'u14',
        giorno: DateTime(2026, 10, 19, 18),
        adesso: _oggi,
      );
      expect(lunedi.settimana, (presenti: 1, su: 1));
    });

    test('l\'appello in corso conta anche se comincia più tardi', () {
      final dopo = _allenamento('stasera', DateTime(2026, 10, 20, 21));
      final senza = presenzeSettimanaEMese(
        allenamenti: [dopo],
        presenze: const [],
        atletaId: 'r',
        gruppoAtleta: 'u14',
        giorno: dopo.data,
        adesso: DateTime(2026, 10, 20, 17),
      );
      expect(senza.settimana.su, 0);
      final con = presenzeSettimanaEMese(
        allenamenti: [dopo],
        presenze: [_presenza('stasera', 'ritardo')],
        atletaId: 'r',
        gruppoAtleta: 'u14',
        giorno: dopo.data,
        adesso: DateTime(2026, 10, 20, 17),
        sempre: {'stasera'},
      );
      expect(con.settimana, (presenti: 1, su: 1));
      expect(con.mese, (presenti: 1, su: 1));
    });

    test('gli allenamenti di un altro gruppo non lo riguardano', () {
      final c = presenzeSettimanaEMese(
        allenamenti: [
          allenamenti[2],
          _allenamento('altro', DateTime(2026, 10, 13, 18), gruppo: 'u16'),
        ],
        presenze: [_presenza('ott-12', 'ritardo')],
        atletaId: 'r',
        gruppoAtleta: 'u14',
        giorno: DateTime(2026, 10, 14),
        adesso: _oggi,
      );
      expect(c.settimana, (presenti: 1, su: 1));
    });

    test('il mese con la preposizione giusta', () {
      expect(inMese(DateTime(2026, 10, 5)), 'a ottobre');
      expect(inMese(DateTime(2026, 4, 5)), 'ad aprile');
      expect(inMese(DateTime(2026, 8, 5)), 'ad agosto');
      expect(inMese(DateTime(2026, 12, 5)), 'a dicembre');
    });
  });

  test('il carico conta la seduta di chi è arrivato in ritardo', () {
    final giorno = DateTime(2026, 10, 1);
    final sedute = seduteDiAtleta(
      dataAllenamenti: {'in_ritardo': giorno, 'assente': giorno},
      seriePerAllenamento: const {},
      statoPresenze: const {'in_ritardo': 'ritardo', 'assente': 'assente'},
      dataPartite: const {},
      partiteConvocato: const {},
      rpe: const {},
      oggi: DateTime(2026, 10, 10),
    );
    expect(sedute.map((s) => s.eventoId), ['in_ritardo']);
  });

  group('la griglia della stagione', () {
    final allenamenti = [
      _allenamento('a1', DateTime(2026, 10, 12, 18)),
      _allenamento('a2', DateTime(2026, 10, 14, 18)),
      _allenamento('a3', DateTime(2026, 10, 16, 18)),
    ];

    test('in ritardo ha il suo segno ma conta come presente', () {
      final stagione = presenzeStagione(
        allenamenti: allenamenti,
        presenze: [
          _presenza('a1', 'presente'),
          _presenza('a2', 'ritardo'),
          _presenza('a3', 'ritardo'),
        ],
        atleti: [_atleta('r')],
        gruppoId: 'u14',
        dal: DateTime(2026, 10, 1),
        adesso: _oggi,
      );
      final riga = stagione.righe.single;
      expect(riga.stati, [
        StatoPresenza.presente,
        StatoPresenza.inRitardo,
        StatoPresenza.inRitardo,
      ]);
      expect(riga.presenti, 3);
      expect(riga.inRitardo, 2);
      expect(riga.percentuale, 100);
      // Le presenze di fila non si interrompono per un ritardo.
      expect(riga.diFila, 3);
      expect(stagione.presentiMedi, 1);
    });

    test('un ritardo in mezzo non spezza la serie', () {
      final stagione = presenzeStagione(
        allenamenti: allenamenti,
        presenze: [
          _presenza('a1', 'assente'),
          _presenza('a2', 'ritardo'),
          _presenza('a3', 'presente'),
        ],
        atleti: [_atleta('r')],
        gruppoId: 'u14',
        dal: DateTime(2026, 10, 1),
        adesso: _oggi,
      );
      expect(stagione.righe.single.diFila, 2);
    });
  });
}
