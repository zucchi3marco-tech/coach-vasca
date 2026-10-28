import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/domain/foglio_atleti.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime(2026, 10, 18);

const _squadre = [
  Gruppo(id: 'g1', clubId: 'c1', nome: 'Esordienti A', ordine: 0),
  Gruppo(id: 'g2', clubId: 'c1', nome: 'Under 14', ordine: 1),
];

const _titoli = ['Cognome', 'Nome', 'Data di nascita'];

Atleta _atleta({
  String id = 'a1',
  String cognome = 'Rossi',
  String nome = 'Mario',
  DateTime? nascita,
  bool attivo = true,
  String? gruppoId,
  String? ruolo,
  String? sesso,
  String? tessera,
  String? email,
  String? telefono,
  DateTime? visita,
  String? note,
  bool consenso = false,
}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: cognome,
  dataNascita: nascita ?? DateTime(2012, 3, 12),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: consenso,
  attivo: attivo,
  gruppoId: gruppoId,
  ruolo: ruolo,
  sesso: sesso,
  numeroTesseraFin: tessera,
  emailGenitore: email,
  telefonoGenitore: telefono,
  visitaMedicaScadenza: visita,
  note: note,
);

FoglioAtleti _analizza(
  List<List<Object?>> tabella, {
  List<Atleta> esistenti = const [],
  List<Gruppo> squadre = _squadre,
}) => analizzaFoglioAtleti(
  tabella,
  squadre: squadre,
  esistenti: esistenti,
  oggi: _oggi,
);

/// Una tabella con la riga dei titoli e le righe date.
List<List<Object?>> _tab(List<String> titoli, List<List<Object?>> righe) => [
  titoli,
  ...righe,
];

/// Legge la data di nascita di una sola riga.
FoglioAtleti _conNascita(Object? nascita) => _analizza(
  _tab(_titoli, [
    ['Rossi', 'Mario', nascita],
  ]),
);

void main() {
  group('colonne', () {
    test('titoli nella prima riga', () {
      final f = _analizza(
        _tab(
          [..._titoli, 'Squadra'],
          [
            ['Rossi', 'Mario', '12/03/2012', 'Esordienti A'],
          ],
        ),
      );
      expect(f.ok, isTrue);
      expect(f.nuovi, hasLength(1));
      expect(f.nuovi.single.riga, 2);
      expect(f.nuovi.single.cognome, 'Rossi');
      expect(f.nuovi.single.squadraId, 'g1');
      expect(
        f.colonneRiconosciute,
        containsAll(['Cognome', 'Nome', 'Data di nascita', 'Squadra']),
      );
      expect(f.colonneNonUsate, isEmpty);
      expect(f.avvisi, isEmpty);
    });

    test('titoli nella terza riga: il numero di riga e quello di Excel', () {
      final f = _analizza([
        ['Elenco atleti 2026', null, null],
        [null, null, null],
        _titoli,
        ['Rossi', 'Mario', '12/03/2012'],
        ['Verdi', 'Luca', '01/05/2011'],
      ]);
      expect(f.ok, isTrue);
      expect(f.nuovi.map((r) => r.riga), [4, 5]);
    });

    test('titoli oltre la decima riga: non li trova', () {
      final f = _analizza([
        for (var i = 0; i < 10; i++) ['x', null, null],
        _titoli,
        ['Rossi', 'Mario', '12/03/2012'],
      ]);
      expect(f.ok, isFalse);
    });

    test('sinonimi dei titoli', () {
      final f = _analizza(
        _tab(
          [
            'COGNOME',
            'Nome ',
            'Nato il',
            'Categoria',
            'Ruolo',
            'M/F',
            'N. Matricola',
            'E-mail genitore',
            'Cellulare',
            'Certificato medico',
            'Consenso',
            'Annotazioni',
          ],
          [
            [
              'Rossi',
              'Mario',
              '12/03/2012',
              'Under 14',
              'portiere',
              'm',
              '4455',
              'Papa@Mail.it',
              '3331234567',
              '30/09/2027',
              'sì',
              'mancino',
            ],
          ],
        ),
      );
      final r = f.nuovi.single;
      expect(r.squadraId, 'g2');
      expect(r.ruolo, 'portiere');
      expect(r.sesso, 'M');
      expect(r.tessera, '4455');
      expect(r.email, 'papa@mail.it');
      expect(r.telefono, '3331234567');
      expect(r.visitaMedica, DateTime(2027, 9, 30));
      expect(r.consenso, isTrue);
      expect(r.note, 'mancino');
      expect(f.colonneNonUsate, isEmpty);
    });

    test('"DN", "Data N" e "Tel"', () {
      for (final titolo in ['DN', 'Data N', 'Data di nascita', 'Nata il']) {
        final f = _analizza(
          _tab(
            ['Cognome', 'Nome', titolo, 'Tel'],
            [
              ['Rossi', 'Mario', '12/03/2012', '0123 456'],
            ],
          ),
        );
        expect(f.nuovi, hasLength(1), reason: titolo);
        expect(f.nuovi.single.telefono, '0123 456');
      }
    });

    test('colonne non usate', () {
      final f = _analizza(
        _tab(
          [..._titoli, 'Taglia maglietta', ''],
          [
            ['Rossi', 'Mario', '12/03/2012', 'M', 'x'],
          ],
        ),
      );
      expect(f.colonneNonUsate, ['Taglia maglietta']);
    });

    test('nessuna colonna dei nomi', () {
      final f = _analizza([
        ['Squadra', 'Data di nascita'],
        ['Esordienti A', '12/03/2012'],
      ]);
      expect(f.ok, isFalse);
      expect(
        f.errore,
        'Non trovo le colonne Cognome e Nome: la prima riga del foglio deve '
        'avere i titoli. Puoi partire dal modello.',
      );
      expect(f.nuovi, isEmpty);
    });

    test('solo il cognome, senza nome: non basta', () {
      final f = _analizza([
        ['Cognome', 'Data di nascita'],
        ['Rossi', '12/03/2012'],
      ]);
      expect(f.ok, isFalse);
    });

    test('manca la colonna della data di nascita', () {
      final f = _analizza([
        ['Cognome', 'Nome', 'Squadra'],
        ['Rossi', 'Mario', 'Esordienti A'],
      ]);
      expect(f.ok, isFalse);
      expect(f.errore, contains('Data di nascita'));
      expect(f.nuovi, isEmpty);
    });

    test('piu di 500 righe: non si importa niente', () {
      final f = _analizza(
        _tab(_titoli, [
          for (var i = 0; i < 501; i++) ['Cognome$i', 'Nome', '12/03/2012'],
        ]),
      );
      expect(f.ok, isFalse);
      expect(f.errore, contains('500'));
      expect(f.nuovi, isEmpty);
    });

    test('500 righe vanno bene, e le righe vuote non contano', () {
      final f = _analizza(
        _tab(_titoli, [
          for (var i = 0; i < 500; i++) ['Cognome$i', 'Nome', '12/03/2012'],
          [null, null, null],
          ['', ' ', null],
        ]),
      );
      expect(f.ok, isTrue);
      expect(f.nuovi, hasLength(500));
      expect(f.escluse, isEmpty);
    });
  });

  group('nome e cognome in una colonna', () {
    FoglioAtleti analizza(List<String> nomi) => _analizza(
      _tab(
        ['Cognome e nome', 'Data di nascita'],
        [
          for (var i = 0; i < nomi.length; i++) [nomi[i], '12/03/201${i % 10}'],
        ],
      ),
    );

    test('prime parole come cognome quando e una particella', () {
      final f = analizza([
        'De Luca Marco',
        'Rossi Maria Chiara',
        'Dalla Valle Anna',
        "D'Amico Luca",
        'Di Lo Presti Sara',
      ]);
      final nomi = [for (final r in f.nuovi) (r.cognome, r.nome)];
      expect(nomi, [
        ('De Luca', 'Marco'),
        ('Rossi', 'Maria Chiara'),
        ('Dalla Valle', 'Anna'),
        ("D'Amico", 'Luca'),
        ('Di Lo Presti', 'Sara'),
      ]);
    });

    test('con la virgola il cognome e prima della virgola', () {
      final f = analizza(['Rossi, Mario', 'De Luca Bianchi, Anna Maria']);
      expect(
        [for (final r in f.nuovi) (r.cognome, r.nome)],
        [('Rossi', 'Mario'), ('De Luca Bianchi', 'Anna Maria')],
      );
    });

    test('maiuscole e avviso', () {
      final f = analizza(['BIANCHI LUCA']);
      expect(f.nuovi.single.cognome, 'Bianchi');
      expect(f.nuovi.single.nome, 'Luca');
      expect(f.avvisi, hasLength(1));
      expect(f.avvisi.single, contains('colonna sola'));
    });

    test('una parola sola: manca il nome', () {
      final f = analizza(['Rossi']);
      expect(f.nuovi, isEmpty);
      expect(f.escluse.single.motivo, 'manca il nome');
    });

    test('con cognome e nome separati la colonna unica non serve', () {
      final f = _analizza(
        _tab(
          ['Cognome', 'Nome', 'Atleta', 'Data di nascita'],
          [
            ['Rossi', 'Mario', 'Altro Nome', '12/03/2012'],
          ],
        ),
      );
      expect(f.nuovi.single.cognome, 'Rossi');
      expect(f.nuovi.single.nome, 'Mario');
      expect(f.avvisi, isEmpty);
      expect(f.colonneNonUsate, ['Atleta']);
    });
  });

  group('date di nascita', () {
    DateTime? nascitaDi(Object? v) {
      final f = _conNascita(v);
      return f.nuovi.isEmpty ? null : f.nuovi.single.dataNascita;
    }

    test('i formati di testo', () {
      final atteso = DateTime(2012, 3, 12);
      expect(nascitaDi('12/03/2012'), atteso);
      expect(nascitaDi('12-03-2012'), atteso);
      expect(nascitaDi('12.03.2012'), atteso);
      expect(nascitaDi('2012-03-12'), atteso);
      expect(nascitaDi('2012-03-12T00:00:00'), atteso);
      expect(nascitaDi(' 12 / 03 / 2012 '), atteso);
      expect(nascitaDi('12/3/2012'), atteso);
      expect(nascitaDi('1/2/2012'), DateTime(2012, 2, 1));
    });

    test('anno a due cifre: fino a quello di oggi 20yy, dopo 19yy', () {
      expect(nascitaDi('12/03/12'), DateTime(2012, 3, 12));
      expect(nascitaDi('12/03/26'), DateTime(2026, 3, 12));
      expect(nascitaDi('12/03/45'), DateTime(1945, 3, 12));
      expect(nascitaDi('12/03/99'), DateTime(1999, 3, 12));
    });

    test('nomi dei mesi', () {
      expect(nascitaDi('12 marzo 2012'), DateTime(2012, 3, 12));
      expect(nascitaDi('12 mar 2012'), DateTime(2012, 3, 12));
      expect(nascitaDi('5 Settembre 2011'), DateTime(2011, 9, 5));
      expect(nascitaDi('5 sett. 2011'), DateTime(2011, 9, 5));
      expect(nascitaDi('1 dicembre 12'), DateTime(2012, 12, 1));
    });

    test('data gia come data e come numero di Excel', () {
      expect(nascitaDi(DateTime(2012, 3, 12, 14, 30)), DateTime(2012, 3, 12));
      expect(nascitaDi(36526), DateTime(2000, 1, 1));
      expect(nascitaDi(36526.0), DateTime(2000, 1, 1));
      expect(nascitaDi(40980.5), DateTime(2012, 3, 12));
    });

    test('data impossibile: la riga resta fuori', () {
      final f = _conNascita('31/02/2012');
      expect(f.nuovi, isEmpty);
      expect(f.escluse.single.riga, 2);
      expect(f.escluse.single.motivo, contains('non leggibile'));
      expect(_conNascita('32/01/2012').nuovi, isEmpty);
      expect(_conNascita('12/13/2012').nuovi, isEmpty);
    });

    test('testo che non e una data', () {
      final f = _conNascita('boh');
      expect(f.escluse.single.motivo, 'data di nascita non leggibile: «boh»');
    });

    test('data mancante', () {
      for (final v in [null, '', '  ']) {
        final f = _conNascita(v);
        expect(f.nuovi, isEmpty);
        expect(f.escluse.single.motivo, 'manca la data di nascita');
      }
    });

    test('data strana: nel futuro o prima del 1940', () {
      final futura = _conNascita('01/01/2030');
      expect(futura.nuovi, isEmpty);
      expect(
        futura.escluse.single.motivo,
        'data di nascita strana: 01/01/2030',
      );
      expect(_conNascita('31/12/1939').nuovi, isEmpty);
      expect(_conNascita('01/01/1940').nuovi, hasLength(1));
      // Oggi va bene, domani no.
      expect(_conNascita('18/10/2026').nuovi, hasLength(1));
      expect(_conNascita('19/10/2026').nuovi, isEmpty);
      // Il numero 2012 (solo l'anno) e il 1905 per Excel: strano.
      expect(_conNascita(2012).escluse.single.motivo, contains('strana'));
    });
  });

  group('nomi', () {
    ({String cognome, String nome}) leggi(String cognome, String nome) {
      final f = _analizza(
        _tab(_titoli, [
          [cognome, nome, '12/03/2012'],
        ]),
      );
      return (cognome: f.nuovi.single.cognome, nome: f.nuovi.single.nome);
    }

    test('maiuscolo o minuscolo diventa Maiuscola Iniziale', () {
      expect(leggi('ROSSI', 'mario'), (cognome: 'Rossi', nome: 'Mario'));
      expect(leggi('DE LUCA', 'MARIA CHIARA'), (
        cognome: 'De Luca',
        nome: 'Maria Chiara',
      ));
      expect(leggi("d'amico", 'luca'), (cognome: "D'Amico", nome: 'Luca'));
      expect(leggi('ROSSI-VERDI', 'anna-maria'), (
        cognome: 'Rossi-Verdi',
        nome: 'Anna-Maria',
      ));
    });

    test('scritto misto resta com e', () {
      expect(leggi('McDonald', 'Mario'), (cognome: 'McDonald', nome: 'Mario'));
      expect(leggi('De Luca', 'Maria Chiara'), (
        cognome: 'De Luca',
        nome: 'Maria Chiara',
      ));
      expect(leggi('ROSSI', 'Mario'), (cognome: 'Rossi', nome: 'Mario'));
    });

    test('spazi in piu', () {
      expect(leggi('  De   Luca ', ' Maria   Chiara'), (
        cognome: 'De Luca',
        nome: 'Maria Chiara',
      ));
    });

    test('righe vuote: saltate senza dirlo', () {
      final f = _analizza(
        _tab(_titoli, [
          [null, null, null],
          ['', '  ', ''],
          ['Rossi', 'Mario', '12/03/2012'],
        ]),
      );
      expect(f.nuovi, hasLength(1));
      expect(f.escluse, isEmpty);
    });

    test('manca il cognome o il nome', () {
      final f = _analizza(
        _tab(_titoli, [
          [null, 'Mario', '12/03/2012'],
          ['Rossi', '', '12/03/2012'],
          [null, null, '12/03/2012'],
        ]),
      );
      expect(f.nuovi, isEmpty);
      expect(
        [for (final e in f.escluse) (e.riga, e.motivo)],
        [
          (2, 'manca il cognome'),
          (3, 'manca il nome'),
          (4, 'mancano cognome e nome'),
        ],
      );
    });
  });

  group('altri campi', () {
    FoglioAtleti conCampi(String titolo, Object? valore) => _analizza(
      _tab(
        [..._titoli, titolo],
        [
          ['Rossi', 'Mario', '12/03/2012', valore],
        ],
      ),
    );

    test('ruolo: tutte le parole', () {
      const attesi = {
        'portiere': 'portiere',
        'P': 'portiere',
        'por': 'portiere',
        'GK': 'portiere',
        'Centroboa': 'centroboa',
        'cb': 'centroboa',
        'boa': 'centroboa',
        'Marcatore': 'marcatore',
        'difensore': 'marcatore',
        'dif': 'marcatore',
        'Esterno': 'esterno',
        'ala': 'esterno',
        'Movimento': 'movimento',
        'giocatore': 'movimento',
        'mov': 'movimento',
        'M': 'movimento',
      };
      for (final e in attesi.entries) {
        final r = conCampi('Ruolo', e.key).nuovi.single;
        expect(r.ruolo, e.value, reason: e.key);
        expect(r.avvisi, isEmpty, reason: e.key);
      }
    });

    test('ruolo sconosciuto: avviso e campo vuoto', () {
      final r = conCampi('Ruolo', 'tuttofare').nuovi.single;
      expect(r.ruolo, isNull);
      expect(r.avvisi.single, contains('tuttofare'));
    });

    test('sesso', () {
      for (final v in [
        'm',
        'M',
        'Maschio',
        'maschile',
        'uomo',
        'ragazzo',
        'u',
      ]) {
        expect(conCampi('Sesso', v).nuovi.single.sesso, 'M', reason: v);
      }
      for (final v in [
        'f',
        'F',
        'Femmina',
        'femminile',
        'donna',
        'ragazza',
        'd',
      ]) {
        expect(conCampi('Sesso', v).nuovi.single.sesso, 'F', reason: v);
      }
      final r = conCampi('Sesso', 'boh').nuovi.single;
      expect(r.sesso, isNull);
      expect(r.avvisi.single, contains('boh'));
      expect(conCampi('Sesso', null).nuovi.single.avvisi, isEmpty);
    });

    test('tessera e telefono scritti come numeri', () {
      expect(conCampi('Tessera FIN', 123456).nuovi.single.tessera, '123456');
      expect(conCampi('Tessera FIN', 123456.0).nuovi.single.tessera, '123456');
      expect(conCampi('Tessera FIN', ' AB-12 ').nuovi.single.tessera, 'AB-12');
      expect(
        conCampi('Telefono', 3331234567).nuovi.single.telefono,
        '3331234567',
      );
      expect(
        conCampi('Telefono', 3331234567.0).nuovi.single.telefono,
        '3331234567',
      );
      expect(
        conCampi('Telefono', '333 123 4567').nuovi.single.telefono,
        '333 123 4567',
      );
      expect(conCampi('Tessera FIN', null).nuovi.single.tessera, isNull);
    });

    test('email: minuscolo, e un avviso se non sembra una email', () {
      expect(
        conCampi('Email genitore', ' Papa@Mail.IT ').nuovi.single.email,
        'papa@mail.it',
      );
      final r = conCampi('Email genitore', 'papa.mail.it').nuovi.single;
      expect(r.email, isNull);
      expect(r.avvisi.single, contains('papa.mail.it'));
      // La riga resta tra quelle da aggiungere.
    });

    test('consenso', () {
      for (final v in [
        'sì',
        'Si',
        'x',
        'X',
        'yes',
        'true',
        '1',
        'Firmato',
        true,
        1,
      ]) {
        expect(
          conCampi('Consenso privacy', v).nuovi.single.consenso,
          isTrue,
          reason: '$v',
        );
      }
      for (final v in ['no', '', null, 'forse', false, 0]) {
        expect(
          conCampi('Consenso privacy', v).nuovi.single.consenso,
          isFalse,
          reason: '$v',
        );
      }
    });

    test('visita medica: data valida o avviso', () {
      expect(
        conCampi('Visita medica', '30/09/2027').nuovi.single.visitaMedica,
        DateTime(2027, 9, 30),
      );
      expect(
        conCampi(
          'Visita medica',
          DateTime(2027, 9, 30),
        ).nuovi.single.visitaMedica,
        DateTime(2027, 9, 30),
      );
      final r = conCampi('Visita medica', 'a settembre').nuovi.single;
      expect(r.visitaMedica, isNull);
      expect(r.avvisi.single, contains('a settembre'));
    });

    test('note', () {
      expect(conCampi('Note', '  mancino ').nuovi.single.note, 'mancino');
      expect(conCampi('Note', '').nuovi.single.note, isNull);
    });
  });

  group('doppioni nel file', () {
    test('la seconda riga uguale resta fuori', () {
      final f = _analizza(
        _tab(_titoli, [
          ['Rossi', 'Mario', '12/03/2012'],
          ['Verdi', 'Luca', '01/05/2011'],
          ['ROSSI', 'mario', '12/03/2012'],
          ["Rossi", 'Mario', '13/03/2012'],
        ]),
      );
      expect(f.nuovi.map((r) => r.riga), [2, 3, 5]);
      expect(f.escluse.single.riga, 4);
      expect(f.escluse.single.motivo, 'uguale alla riga 2');
    });

    test('accenti e apostrofi non contano', () {
      final f = _analizza(
        _tab(_titoli, [
          ["D'Amico", 'José', '12/03/2012'],
          ['Damico', 'Jose', '12/03/2012'],
        ]),
      );
      expect(f.nuovi, hasLength(1));
      expect(f.escluse.single.motivo, 'uguale alla riga 2');
    });
  });

  group('atleti gia nell\'app', () {
    final titoliTutti = [
      ..._titoli,
      'Squadra',
      'Ruolo',
      'Sesso',
      'Tessera',
      'Email',
      'Telefono',
      'Visita',
      'Consenso',
      'Note',
    ];
    final righeTutte = <Object?>[
      'Rossi',
      'Mario',
      '12/03/2012',
      'Esordienti A',
      'centroboa',
      'M',
      '999',
      'papa@mail.it',
      '3331234567',
      '30/09/2027',
      'sì',
      'dal foglio',
    ];

    test('riconosce con maiuscole e accenti diversi', () {
      final f = _analizza(
        _tab(_titoli, [
          ['ROSSI', 'MÀRIO', '12/03/2012'],
        ]),
        esistenti: [_atleta(nome: 'Màrio')],
      );
      expect(f.nuovi, isEmpty);
      expect(f.giaPresenti, hasLength(1));
      expect(f.giaPresenti.single.campi({}), isEmpty);
      expect(f.giaPresenti.single.completamento({}), isNull);
    });

    test('riempie solo i campi vuoti e non sovrascrive mai', () {
      final esistente = _atleta(
        ruolo: 'portiere',
        tessera: '123',
        note: 'scritta nell\'app',
      );
      final f = _analizza(
        _tab(titoliTutti, [righeTutte]),
        esistenti: [esistente],
      );
      final r = f.giaPresenti.single;
      expect(r.campi({}), [
        CampoAtleta.squadra,
        CampoAtleta.sesso,
        CampoAtleta.email,
        CampoAtleta.telefono,
        CampoAtleta.visitaMedica,
        CampoAtleta.consenso,
      ]);
      final c = r.completamento({})!;
      expect(c.gruppoId, 'g1');
      expect(c.sesso, 'M');
      expect(c.email, 'papa@mail.it');
      expect(c.telefono, '3331234567');
      expect(c.visitaMedica, DateTime(2027, 9, 30));
      expect(c.consenso, isTrue);
      // Quello che c'era resta.
      expect(c.ruolo, 'portiere');
      expect(c.tessera, '123');
      expect(c.note, 'scritta nell\'app');
      expect(f.quantiDaCompletare({}), 1);
    });

    test('un atleta gia completo non cambia', () {
      final completo = _atleta(
        gruppoId: 'g2',
        ruolo: 'portiere',
        sesso: 'F',
        tessera: '1',
        email: 'a@b.it',
        telefono: '1',
        visita: DateTime(2026, 1, 1),
        note: 'n',
        consenso: true,
      );
      final f = _analizza(
        _tab(titoliTutti, [righeTutte]),
        esistenti: [completo],
      );
      expect(f.giaPresenti.single.campi({}), isEmpty);
      expect(f.quantiDaCompletare({}), 0);
    });

    test('il consenso del foglio non toglie quello dell\'app', () {
      final f = _analizza(
        _tab(
          [..._titoli, 'Consenso'],
          [
            ['Rossi', 'Mario', '12/03/2012', 'no'],
          ],
        ),
        esistenti: [_atleta(consenso: true)],
      );
      expect(f.giaPresenti.single.campi({}), isEmpty);
    });

    test('anche non attivo: si riconosce, non si riattiva', () {
      final f = _analizza(
        _tab(_titoli, [
          ['Rossi', 'Mario', '12/03/2012'],
        ]),
        esistenti: [_atleta(attivo: false)],
      );
      expect(f.nuovi, isEmpty);
      expect(f.giaPresenti.single.atleta.attivo, isFalse);
    });

    test('stesso nome ma altra data di nascita: nuovo, con avviso', () {
      final f = _analizza(
        _tab(_titoli, [
          ['Rossi', 'Mario', '12/03/2013'],
        ]),
        esistenti: [_atleta(nascita: DateTime(2011, 3, 12))],
      );
      expect(f.giaPresenti, isEmpty);
      final r = f.nuovi.single;
      expect(
        r.avvisi.single,
        "C'è già Rossi Mario nato il 12/03/2011: controlla la data.",
      );
    });

    test('un doppione di chi c\'e gia resta fuori la seconda volta', () {
      final f = _analizza(
        _tab(_titoli, [
          ['Rossi', 'Mario', '12/03/2012'],
          ['Rossi', 'Mario', '12/03/2012'],
        ]),
        esistenti: [_atleta()],
      );
      expect(f.giaPresenti, hasLength(1));
      expect(f.escluse.single.motivo, 'uguale alla riga 2');
    });
  });

  group('squadre', () {
    FoglioAtleti analizza(
      List<String?> nomi, {
      List<Atleta> esistenti = const [],
    }) => _analizza(
      _tab(
        [..._titoli, 'Squadra'],
        [
          for (var i = 0; i < nomi.length; i++)
            ['Cognome$i', 'Nome', '12/03/2012', nomi[i]],
        ],
      ),
      esistenti: esistenti,
    );

    test('si riconosce senza badare a maiuscole e spazi', () {
      final f = analizza(['esordienti  a', 'UNDER 14', null, '']);
      expect(f.nuovi.map((r) => r.squadraId), ['g1', 'g2', null, null]);
      expect(f.nuovi.map((r) => r.squadra), [
        'esordienti a',
        'UNDER 14',
        null,
        null,
      ]);
      expect(f.squadreSconosciute, isEmpty);
    });

    test('nomi sconosciuti: una volta sola, e il coach li abbina', () {
      final f = analizza(['Under 12', 'under  12', 'Master']);
      expect(f.squadreSconosciute, ['Under 12', 'Master']);
      expect(f.nuovi.every((r) => r.squadraSconosciuta), isTrue);

      final mappa = <String, String?>{
        chiaveSquadra('Under 12'): 'g2',
        chiaveSquadra('Master'): null,
      };
      expect(f.nuovi.map((r) => r.gruppoFinale(mappa)), ['g2', 'g2', null]);
      // Senza scelta: senza squadra.
      expect(f.nuovi.map((r) => r.gruppoFinale({})), [null, null, null]);
    });

    test('per chi c\'e gia, la squadra si aggiunge solo se non ne ha', () {
      final f = analizza(
        ['Master'],
        esistenti: [_atleta(cognome: 'Cognome0', nome: 'Nome')],
      );
      final r = f.giaPresenti.single;
      expect(r.campi({}), isEmpty);
      expect(r.campi({chiaveSquadra('Master'): 'g1'}), [CampoAtleta.squadra]);
      expect(r.completamento({chiaveSquadra('Master'): 'g1'})!.gruppoId, 'g1');

      final conSquadra = analizza(
        ['Master'],
        esistenti: [_atleta(cognome: 'Cognome0', nome: 'Nome', gruppoId: 'g2')],
      ).giaPresenti.single;
      expect(conSquadra.campi({chiaveSquadra('Master'): 'g1'}), isEmpty);
    });

    test('le righe escluse non portano squadre da abbinare', () {
      final f = _analizza(
        _tab(
          [..._titoli, 'Squadra'],
          [
            ['Rossi', 'Mario', '31/02/2012', 'Master'],
          ],
        ),
      );
      expect(f.squadreSconosciute, isEmpty);
    });
  });
}
