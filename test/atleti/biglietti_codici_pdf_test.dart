import 'package:coach_vasca/features/atleti/application/biglietti_codici_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

BigliettoCodice _b(
  String cognome,
  String nome, {
  String? squadra,
  String codice = 'A1B2C3D4E5',
}) => BigliettoCodice(
  cognome: cognome,
  nome: nome,
  squadra: squadra,
  codice: codice,
  scade: DateTime(2026, 11, 17),
);

List<BigliettoCodice> _tanti(int n) => [
  for (var i = 0; i < n; i++) _b('Cognome$i', 'Nome', squadra: 'Under 14'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formattaCodice', () {
    test('due gruppi da 5', () {
      expect(formattaCodice('A1B2C3D4E5'), 'A1B2C 3D4E5');
    });

    test('mette in maiuscolo e ignora gli spazi ai lati', () {
      expect(formattaCodice(' a1b2c3d4e5 '), 'A1B2C 3D4E5');
    });

    test('un codice di altra lunghezza resta com\'è', () {
      expect(formattaCodice('ABC'), 'ABC');
    });
  });

  group('ordinaBiglietti', () {
    test('per squadra, poi cognome e nome; senza squadra in fondo', () {
      final ordinati = ordinaBiglietti([
        _b('Zanni', 'Anna'),
        _b('Verdi', 'Luca', squadra: 'Under 14'),
        _b('Rossi', 'Mario', squadra: 'Prima squadra'),
        _b('bianchi', 'Zeno', squadra: 'Under 14'),
        _b('Bianchi', 'Aldo', squadra: 'Under 14'),
      ]);
      expect(
        [for (final b in ordinati) b.cognomeNome],
        [
          'Rossi Mario',
          'Bianchi Aldo',
          'bianchi Zeno',
          'Verdi Luca',
          'Zanni Anna',
        ],
      );
    });

    test('non cambia la lista data', () {
      final originale = [_b('Zanni', 'Anna'), _b('Alfa', 'Bea')];
      ordinaBiglietti(originale);
      expect(originale.first.cognome, 'Zanni');
    });
  });

  group('il PDF', () {
    Future<int> pagine(int n, {String? app}) async {
      final doc = await documentoBigliettiCodici(
        nomeClub: 'Club Prova',
        biglietti: _tanti(n),
        indirizzoApp: app,
      );
      return doc.document.pdfPageList.pages.length;
    }

    test('8 biglietti stanno in una pagina, 9 ne fanno due', () async {
      expect(await pagine(1), 1);
      expect(await pagine(8), 1);
      expect(await pagine(9), 2);
      expect(await pagine(16), 2);
      expect(await pagine(17), 3);
    });

    test('senza biglietti c\'è comunque una pagina', () async {
      expect(await pagine(0), 1);
    });

    test('funziona senza e con l\'indirizzo dell\'app', () async {
      final senza = await generaBigliettiCodici(
        nomeClub: 'Club Prova',
        biglietti: _tanti(8),
      );
      final con = await generaBigliettiCodici(
        nomeClub: 'Club Prova',
        biglietti: _tanti(8),
        indirizzoApp: 'https://watertactics.example.app',
      );
      expect(String.fromCharCodes(senza.take(5)), '%PDF-');
      expect(String.fromCharCodes(con.take(5)), '%PDF-');
      // Il QR aggiunge disegni: il file con l'indirizzo pesa di più.
      expect(con.length, greaterThan(senza.length));
    });

    test('nomi con accenti e molto lunghi', () async {
      final bytes = await generaBigliettiCodici(
        nomeClub: 'Società Nuoto Più Veloce',
        biglietti: [
          _b('D\'Àngelo', 'Niccolò', squadra: 'Esordienti A'),
          _b(
            'De Santis Di Monteforte Lunghissimo',
            'Maria Giuseppina Concetta',
            squadra: 'Squadra con un nome davvero molto molto lungo',
          ),
          _b('Rossi', 'Mario'),
        ],
        indirizzoApp: 'https://watertactics.example.app',
      );
      expect(bytes, isNotEmpty);
    });
  });
}
