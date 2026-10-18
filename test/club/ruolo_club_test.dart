import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RuoloClub', () {
    test('fromDb e db si corrispondono', () {
      expect(RuoloClub.fromDb('owner'), RuoloClub.responsabile);
      expect(RuoloClub.fromDb('coach'), RuoloClub.allenatore);
      expect(RuoloClub.fromDb('assistente'), RuoloClub.assistente);
      for (final ruolo in RuoloClub.values) {
        expect(RuoloClub.fromDb(ruolo.db), ruolo);
      }
      expect(RuoloClub.responsabile.db, 'owner');
      expect(RuoloClub.allenatore.db, 'coach');
      expect(RuoloClub.assistente.db, 'assistente');
    });

    test('un ruolo ignoto è un errore', () {
      expect(() => RuoloClub.fromDb('atleta'), throwsArgumentError);
    });

    test('le etichette sono in italiano', () {
      expect(RuoloClub.responsabile.etichetta, 'Responsabile');
      expect(RuoloClub.allenatore.etichetta, 'Allenatore');
      expect(RuoloClub.assistente.etichetta, 'Assistente');
    });

    test('ogni ruolo ha una descrizione', () {
      expect(
        RuoloClub.responsabile.descrizione,
        'Invita e toglie allenatori e assistenti, e fa tutto il resto.',
      );
      expect(
        RuoloClub.allenatore.descrizione,
        'Fa tutto: allenamenti, atleti, squadre, partite.',
      );
      expect(
        RuoloClub.assistente.descrizione,
        'Allenamenti, presenze, partite e test; non aggiunge o toglie atleti '
        'e squadre.',
      );
    });

    test('chi gestisce atleti e squadre: tutti tranne l\'assistente', () {
      expect(RuoloClub.responsabile.puoGestireAtletiESquadre, isTrue);
      expect(RuoloClub.allenatore.puoGestireAtletiESquadre, isTrue);
      expect(RuoloClub.assistente.puoGestireAtletiESquadre, isFalse);
    });

    test('chi gestisce lo staff: solo il responsabile', () {
      expect(RuoloClub.responsabile.puoGestireStaff, isTrue);
      expect(RuoloClub.allenatore.puoGestireStaff, isFalse);
      expect(RuoloClub.assistente.puoGestireStaff, isFalse);
    });
  });

  group('MembroClub.fromMap', () {
    test('legge una riga di membri_del_club', () {
      final membro = MembroClub.fromMap({
        'user_id': 'u1',
        'nome': ' Luca Bianchi ',
        'ruolo': 'coach',
        'email': 'luca@example.com',
        'sono_io': false,
      });
      expect(membro.userId, 'u1');
      expect(membro.nome, 'Luca Bianchi');
      expect(membro.ruolo, RuoloClub.allenatore);
      expect(membro.email, 'luca@example.com');
      expect(membro.sonoIo, isFalse);
    });

    test('un nome vuoto o assente è null', () {
      expect(
        MembroClub.fromMap({
          'user_id': 'u1',
          'nome': '  ',
          'ruolo': 'assistente',
          'email': null,
          'sono_io': true,
        }).nome,
        isNull,
      );
      expect(
        MembroClub.fromMap({
          'user_id': 'u1',
          'nome': null,
          'ruolo': 'owner',
          'sono_io': true,
        }).nome,
        isNull,
      );
    });
  });
}
