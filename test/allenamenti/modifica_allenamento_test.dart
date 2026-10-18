import 'package:coach_vasca/core/utils/date_italiane.dart';
import 'package:coach_vasca/features/allenamenti/domain/modifica_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/presentation/modifiche_da_controllare_screen.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _rigaSerie(
  String id,
  int ordine, {
  int ripetute = 4,
  int distanzaM = 100,
}) => {
  'id': id,
  'allenamento_id': 'a1',
  'club_id': 'c1',
  'ordine': ordine,
  'blocco': 'principale',
  'ripetute': ripetute,
  'distanza_m': distanzaM,
  'durata_s': null,
  'stile': 'libero',
  'esecuzione': 'nuoto',
  'zona': 'B1',
  'passo_obiettivo_s': 85,
  'recupero_s': 20,
  'created_at': '2026-10-01T10:00:00Z',
};

Map<String, dynamic> _riga({
  List<String> autori = const ['Luca'],
  bool nuovo = false,
  Map<String, dynamic>? prima,
  Object? allenamenti = const {
    'titolo': 'Tecnica',
    'data': '2026-10-20',
    'gruppo_id': 'g1',
  },
}) => {
  'id': 'm1',
  'allenamento_id': 'a1',
  'club_id': 'c1',
  'capo_user_id': 'u-capo',
  'autori': autori,
  'nuovo': nuovo,
  'prima': prima,
  'aperta_at': '2026-10-18T10:00:00Z',
  'ultima_at': '2026-10-18T10:30:00Z',
  'visto_at': null,
  'allenamenti': allenamenti,
};

void main() {
  group('ModificaAllenamento.fromMap', () {
    test('legge la riga con l\'allenamento incorporato', () {
      final m = ModificaAllenamento.fromMap(_riga(autori: ['Luca', 'Anna']));
      expect(m.id, 'm1');
      expect(m.allenamentoId, 'a1');
      expect(m.clubId, 'c1');
      expect(m.capoUserId, 'u-capo');
      expect(m.autori, ['Luca', 'Anna']);
      expect(m.nuovo, isFalse);
      expect(m.prima, isNull);
      expect(m.aperta, isTrue);
      expect(m.titolo, 'Tecnica');
      expect(m.data, DateTime(2026, 10, 20));
      expect(m.gruppoId, 'g1');
      expect(m.ultimaAt.isAfter(m.apertaAt), isTrue);
    });

    test('senza l\'allenamento incorporato i suoi campi sono null', () {
      final m = ModificaAllenamento.fromMap(_riga(allenamenti: null));
      expect(m.titolo, isNull);
      expect(m.data, isNull);
      expect(m.gruppoId, isNull);
      expect(m.titoloMostrato, 'Allenamento');
    });

    test('un titolo vuoto si mostra come «Allenamento»', () {
      final m = ModificaAllenamento.fromMap(
        _riga(allenamenti: {'titolo': '  ', 'data': '2026-10-20'}),
      );
      expect(m.titoloMostrato, 'Allenamento');
    });

    test('la frase dice modificato o aggiunto', () {
      expect(
        ModificaAllenamento.fromMap(_riga(autori: ['Luca', 'Anna'])).frase,
        'Luca e Anna hanno modificato «Tecnica»',
      );
      expect(
        ModificaAllenamento.fromMap(_riga(nuovo: true)).frase,
        'Luca ha aggiunto «Tecnica»',
      );
    });
  });

  group('serieDiPrima ed eserciziDiPrima', () {
    test('rileggono le serie dal jsonb, nell\'ordine', () {
      final m = ModificaAllenamento.fromMap(
        _riga(
          prima: {
            'allenamento': {'titolo': 'Vecchio'},
            'serie': [
              _rigaSerie('s1', 1),
              _rigaSerie('s2', 2, ripetute: 8, distanzaM: 50),
            ],
            'esercizi': [],
          },
        ),
      );
      final serie = m.serieDiPrima();
      expect(serie.map((s) => s.id), ['s1', 's2']);
      expect(serie[0].ripetute, 4);
      expect(serie[0].distanzaM, 100);
      expect(serie[0].zona, 'B1');
      expect(serie[0].passoObiettivoS, 85.0);
      expect(serie[1].ripetute, 8);
      expect(serie[1].distanzaM, 50);
      expect(m.allenamentoDiPrima['titolo'], 'Vecchio');
    });

    test('senza «prima» (allenamento nuovo) non ci sono serie', () {
      final m = ModificaAllenamento.fromMap(_riga(nuovo: true));
      expect(m.serieDiPrima(), isEmpty);
      expect(m.eserciziDiPrima(), isEmpty);
      expect(m.allenamentoDiPrima, isEmpty);
    });

    test('gli esercizi del secco tornano in ordine', () {
      final m = ModificaAllenamento.fromMap(
        _riga(
          prima: {
            'allenamento': {},
            'serie': [],
            'esercizi': [
              {
                'id': 'r2',
                'allenamento_id': 'a1',
                'club_id': 'c1',
                'esercizio_id': 'e2',
                'ordine': 2,
                'serie': 3,
                'ripetizioni': null,
                'durata_s': 30,
                'carico': null,
              },
              {
                'id': 'r1',
                'allenamento_id': 'a1',
                'club_id': 'c1',
                'esercizio_id': 'e1',
                'ordine': 1,
                'serie': 4,
                'ripetizioni': 10,
                'durata_s': null,
                'carico': '60 kg',
              },
            ],
          },
        ),
      );
      final esercizi = m.eserciziDiPrima();
      expect(esercizi.map((e) => e.id), ['r1', 'r2']);
      expect(esercizi[0].carico, '60 kg');
      expect(esercizi[1].durataS, 30);
    });
  });

  group('elencoNomi', () {
    test('uno, due, tre nomi', () {
      expect(elencoNomi(['Luca']), 'Luca');
      expect(elencoNomi(['Luca', 'Anna']), 'Luca e Anna');
      expect(elencoNomi(['Luca', 'Anna', 'Gino']), 'Luca, Anna e Gino');
    });

    test('nessun nome: «Un allenatore»', () {
      expect(elencoNomi([]), 'Un allenatore');
    });
  });

  group('confrontaRighe', () {
    List<String> segni(List<RigaConfronto> righe) => [
      for (final r in righe)
        switch (r.stato) {
          StatoRiga.uguale => '= ${r.testo}',
          StatoRiga.tolta => '- ${r.testo}',
          StatoRiga.aggiunta => '+ ${r.testo}',
        },
    ];

    test('righe uguali: tutte uguali', () {
      expect(segni(confrontaRighe(['a', 'b'], ['a', 'b'])), ['= a', '= b']);
    });

    test('una riga tolta', () {
      expect(segni(confrontaRighe(['a', 'b', 'c'], ['a', 'c'])), [
        '= a',
        '- b',
        '= c',
      ]);
    });

    test('una riga aggiunta', () {
      expect(segni(confrontaRighe(['a', 'c'], ['a', 'b', 'c'])), [
        '= a',
        '+ b',
        '= c',
      ]);
    });

    test('una riga cambiata: la tolta prima dell\'aggiunta', () {
      expect(segni(confrontaRighe(['a', 'b', 'c'], ['a', 'x', 'c'])), [
        '= a',
        '- b',
        '+ x',
        '= c',
      ]);
    });

    test('tutto nuovo e tutto tolto', () {
      expect(segni(confrontaRighe([], ['a', 'b'])), ['+ a', '+ b']);
      expect(segni(confrontaRighe(['a', 'b'], [])), ['- a', '- b']);
      expect(confrontaRighe([], []), isEmpty);
    });

    test('righe spostate: tiene la sottosequenza comune più lunga', () {
      final r = confrontaRighe(['a', 'b', 'c', 'd'], ['b', 'c', 'd', 'a']);
      expect(segni(r), ['- a', '= b', '= c', '= d', '+ a']);
    });

    test('"Prima" e "Ora" si ricostruiscono dal confronto', () {
      final prima = ['400 sl', '4x50 gambe', '', '8x100 sl B1', '200 do'];
      final ora = ['400 sl', '4x50 gambe pinne', '', '8x100 sl B2', '200 do'];
      final r = confrontaRighe(prima, ora);
      expect([
        for (final x in r)
          if (x.stato != StatoRiga.aggiunta) x.testo,
      ], prima);
      expect([
        for (final x in r)
          if (x.stato != StatoRiga.tolta) x.testo,
      ], ora);
    });
  });

  group('righeSecco', () {
    test('nome, serie×ripetizioni o durata, carico', () {
      final righe = righeSecco(
        const [
          EsercizioSeduta(
            id: 'r2',
            allenamentoId: 'a1',
            clubId: 'c1',
            esercizioId: 'e2',
            ordine: 2,
            serie: 3,
            durataS: 30,
          ),
          EsercizioSeduta(
            id: 'r1',
            allenamentoId: 'a1',
            clubId: 'c1',
            esercizioId: 'e1',
            ordine: 1,
            serie: 4,
            ripetizioni: 10,
            carico: '60 kg',
          ),
          EsercizioSeduta(
            id: 'r3',
            allenamentoId: 'a1',
            clubId: 'c1',
            esercizioId: 'ignoto',
            ordine: 3,
            serie: 2,
            ripetizioni: 8,
            carico: ' ',
          ),
        ],
        {'e1': 'Squat', 'e2': 'Plank'},
      );
      expect(righe, ["Squat 4×10 60 kg", "Plank 3×30''", 'Esercizio 2×8']);
    });
  });

  group('quandoFa', () {
    final adesso = DateTime(2026, 10, 18, 19, 0);

    test('adesso, minuti fa', () {
      expect(
        quandoFa(DateTime(2026, 10, 18, 18, 59, 30), adesso: adesso),
        'adesso',
      );
      expect(
        quandoFa(DateTime(2026, 10, 18, 18, 59), adesso: adesso),
        '1 minuto fa',
      );
      expect(
        quandoFa(DateTime(2026, 10, 18, 18, 35), adesso: adesso),
        '25 minuti fa',
      );
    });

    test('oggi, ieri, un altro giorno', () {
      expect(
        quandoFa(DateTime(2026, 10, 18, 9, 5), adesso: adesso),
        'oggi alle 09:05',
      );
      expect(
        quandoFa(DateTime(2026, 10, 17, 18, 30), adesso: adesso),
        'ieri alle 18:30',
      );
      expect(
        quandoFa(DateTime(2026, 10, 12, 18, 30), adesso: adesso),
        '12 ott alle 18:30',
      );
    });

    test(
      'un\'ora esatta è già «oggi alle»; un orologio indietro è «adesso»',
      () {
        expect(
          quandoFa(DateTime(2026, 10, 18, 18, 0), adesso: adesso),
          'oggi alle 18:00',
        );
        expect(
          quandoFa(DateTime(2026, 10, 18, 19, 5), adesso: adesso),
          'adesso',
        );
      },
    );

    test('a cavallo della mezzanotte: ieri', () {
      expect(
        quandoFa(
          DateTime(2026, 10, 17, 23, 30),
          adesso: DateTime(2026, 10, 18, 0, 20),
        ),
        '50 minuti fa',
      );
      expect(
        quandoFa(
          DateTime(2026, 10, 17, 22, 30),
          adesso: DateTime(2026, 10, 18, 0, 20),
        ),
        'ieri alle 22:30',
      );
    });
  });

  group('sottotitoloModifica', () {
    test('squadra, data e quando', () {
      final m = ModificaAllenamento.fromMap(_riga());
      final adesso = m.ultimaAt.add(const Duration(minutes: 25));
      expect(
        sottotitoloModifica(m, squadra: 'U14', adesso: adesso),
        'U14 · mar 20 ott · 25 minuti fa',
      );
      expect(
        sottotitoloModifica(m, adesso: adesso),
        'mar 20 ott · 25 minuti fa',
      );
    });
  });
}
