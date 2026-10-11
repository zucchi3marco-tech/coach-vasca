import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/test/domain/tempi_da_foto.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(String id, String nome, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: cognome,
  dataNascita: DateTime(2011, 1, 1),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

void main() {
  final atleti = [
    _atleta('1', 'Marco', 'Rossi'),
    _atleta('2', 'Luca', 'Rossi'),
    _atleta('3', 'Sofia', 'Bianchi'),
    _atleta('4', 'Niccolò', 'De Santis'),
  ];

  test('i nomi scritti sul foglio si abbinano agli atleti', () {
    expect(abbinaAtleta('Bianchi', atleti)?.id, '3');
    expect(abbinaAtleta('BIANCHI SOFIA', atleti)?.id, '3');
    expect(abbinaAtleta('Sofia', atleti)?.id, '3');
    // Due Rossi: serve il nome o l'iniziale.
    expect(abbinaAtleta('Rossi', atleti), isNull);
    expect(abbinaAtleta('Rossi M.', atleti)?.id, '1');
    expect(abbinaAtleta('Luca Rossi', atleti)?.id, '2');
    // Accenti e cognomi di due parole.
    expect(abbinaAtleta('niccolo de santis', atleti)?.id, '4');
    expect(abbinaAtleta('De Santis', atleti)?.id, '4');
    // Un nome che non c'è resta da scegliere.
    expect(abbinaAtleta('Verdi', atleti), isNull);
    expect(abbinaAtleta('Rossi Giorgio', atleti), isNull);
  });

  test('i tempi si leggono come li scrive un allenatore', () {
    expect(leggiTempo('1\'05"20'), closeTo(65.2, 0.001));
    expect(leggiTempo('1\'05.2'), closeTo(65.2, 0.001));
    expect(leggiTempo('1:05.2'), closeTo(65.2, 0.001));
    expect(leggiTempo('32"5'), closeTo(32.5, 0.001));
    expect(leggiTempo('65,2'), closeTo(65.2, 0.001));
    expect(leggiTempo('28"'), 28);
    expect(leggiTempo(''), isNull);
    expect(leggiTempo('abc'), isNull);
  });

  test('una riga letta tiene tutti i tempi e sa qual è il migliore', () {
    final riga = RigaTempiLetta.fromMap({
      'nome': 'Rossi M.',
      'tempiS': [66.1, 65.2, 67],
      'distanzaM': null,
    });
    expect(riga.tempiS, [66.1, 65.2, 67.0]);
    expect(riga.migliore, 65.2);
    expect(riga.distanzaM, isNull);
  });
}
