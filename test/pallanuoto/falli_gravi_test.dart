import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/fascia_calottine_partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/selettore_giocatore_partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/squalifiche_partita.dart';
import 'package:flutter_test/flutter_test.dart';

var _n = 0;

EventoPartita _espulsione({
  String? atleta,
  int? avversario,
  bool rigore = false,
}) => EventoPartita(
  id: 'e${_n++}',
  partitaId: 'p1',
  clubId: 'c1',
  tipo: 'espulsione',
  squadra: atleta != null ? 'nostra' : 'avversaria',
  atletaId: atleta,
  numeroCalottinaAvversario: avversario,
  espulsioneDaRigore: rigore,
  creatoIl: DateTime(2026, 10, 24, 15, _n),
);

void main() {
  group('falli gravi', () {
    test('espulsioni e rigori contano insieme, nostri e avversari', () {
      final eventi = [
        _espulsione(atleta: 'rossi'),
        _espulsione(atleta: 'rossi', rigore: true),
        _espulsione(avversario: 7),
        EventoPartita(
          id: 'tiro',
          partitaId: 'p1',
          clubId: 'c1',
          tipo: 'tiro',
          squadra: 'nostra',
          atletaId: 'rossi',
          esito: 'gol',
          creatoIl: DateTime(2026, 10, 24),
        ),
      ];
      expect(contaFalliGravi(eventi), {
        const NostroGiocatoreId('rossi'): 2,
        const AvversarioGiocatoreId(7): 1,
      });
      expect(calcolaSqualificati(eventi), isEmpty);
    });

    test('al terzo fallo grave il giocatore è fuori', () {
      final eventi = [
        _espulsione(atleta: 'rossi'),
        _espulsione(atleta: 'rossi'),
        _espulsione(atleta: 'rossi', rigore: true),
        _espulsione(avversario: 4),
        _espulsione(avversario: 4),
        _espulsione(avversario: 4),
        _espulsione(atleta: 'bianchi'),
      ];
      expect(calcolaSqualificati(eventi), {
        const NostroGiocatoreId('rossi'),
        const AvversarioGiocatoreId(4),
      });
    });
  });

  group('calottine tutte nello schermo', () {
    double altezzaUsata(int quante, ({int colonne, double lato}) m) {
      final righe = (quante / m.colonne).ceil();
      return righe * m.lato + (righe - 1) * 8;
    }

    test('telefono in orizzontale: 15 calottine senza scorrere', () {
      for (final altezza in [260.0, 300.0, 340.0]) {
        final m = misuraFascia(15, altezza);
        expect(altezzaUsata(15, m), lessThanOrEqualTo(altezza));
        expect(m.lato, greaterThanOrEqualTo(48));
      }
    });

    test('con spazio resta la misura piena su due colonne', () {
      expect(misuraFascia(15, 1000), (colonne: 2, lato: 64.0));
    });

    test('più colonne solo se le calottine vengono più grandi', () {
      final m = misuraFascia(13, 420);
      expect(altezzaUsata(13, m), lessThanOrEqualTo(420));
      expect(m.colonne, greaterThan(2));
    });
  });
}
