import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/presenze/domain/presenze_stagione.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(String id, {String? gruppo = 'u14'}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: id,
  cognome: id,
  dataNascita: DateTime(2012),
  sport: 'nuoto',
  gruppoId: gruppo,
  consensoPrivacyFirmato: true,
  attivo: true,
);

Allenamento _allenamento(String id, int giorno, {String? gruppo = 'u14'}) =>
    Allenamento(
      id: id,
      clubId: 'c1',
      data: DateTime(2026, 9, giorno),
      gruppoId: gruppo,
    );

Presenza _presenza(String atleta, String allenamento, String stato) => Presenza(
  id: '$atleta-$allenamento',
  allenamentoId: allenamento,
  atletaId: atleta,
  clubId: 'c1',
  stato: stato,
);

final _adesso = DateTime(2026, 9, 30, 12);

void main() {
  test('griglia, percentuali e presenze di fila', () {
    final risultato = presenzeStagione(
      allenamenti: [
        _allenamento('a1', 1),
        _allenamento('a2', 3),
        _allenamento('a3', 5),
        _allenamento('a4', 8),
        // Programmato: non ancora fatto, non conta.
        _allenamento('futuro', 30 + 5),
      ],
      presenze: [
        _presenza('rossi', 'a1', 'assente'),
        _presenza('rossi', 'a2', 'presente'),
        _presenza('rossi', 'a3', 'giustificato'),
        _presenza('rossi', 'a4', 'presente'),
        _presenza('bianchi', 'a1', 'presente'),
        _presenza('bianchi', 'a2', 'presente'),
        _presenza('bianchi', 'a3', 'presente'),
        _presenza('bianchi', 'a4', 'presente'),
      ],
      atleti: [_atleta('rossi'), _atleta('bianchi')],
      gruppoId: 'u14',
      dal: DateTime(2026, 9, 1),
      adesso: _adesso,
    );

    expect(risultato.allenamenti.map((a) => a.id), ['a1', 'a2', 'a3', 'a4']);
    // Dalla percentuale più alta.
    expect(risultato.righe.map((r) => r.atleta.id), ['bianchi', 'rossi']);
    final rossi = risultato.righe.last;
    expect(rossi.stati, [
      StatoPresenza.assente,
      StatoPresenza.presente,
      StatoPresenza.giustificato,
      StatoPresenza.presente,
    ]);
    expect(rossi.percentuale, 50);
    // Il giustificato non interrompe: presente, giustificato, presente.
    expect(rossi.diFila, 2);
    expect(risultato.righe.first.diFila, 4);
    expect(risultato.media, 75);
    // 6 presenti in 4 allenamenti con le presenze segnate.
    expect(risultato.presentiMedi, 1.5);
  });

  test('allenamenti di altri gruppi e presenze mai segnate', () {
    final risultato = presenzeStagione(
      allenamenti: [
        _allenamento('a1', 1),
        _allenamento('u16', 2, gruppo: 'u16'),
        _allenamento('club', 3, gruppo: null),
        // Nessuno ha segnato le presenze: per le percentuali è
        // un'assenza, ma non interrompe le presenze di fila.
        _allenamento('dimenticato', 4),
      ],
      presenze: [
        _presenza('verdi', 'a1', 'presente'),
        _presenza('verdi', 'club', 'presente'),
        _presenza('neri', 'u16', 'presente'),
      ],
      atleti: [
        _atleta('verdi'),
        _atleta('neri', gruppo: 'u16'),
      ],
      gruppoId: null,
      dal: DateTime(2026, 9, 1),
      adesso: _adesso,
    );

    final verdi = risultato.righe.firstWhere((r) => r.atleta.id == 'verdi');
    expect(verdi.stati, [
      StatoPresenza.presente,
      StatoPresenza.nonSuo,
      StatoPresenza.presente,
      StatoPresenza.nonSegnato,
    ]);
    expect(verdi.suoi, 3);
    expect(verdi.percentuale, closeTo(66.7, 0.1));
    expect(verdi.diFila, 2);

    final neri = risultato.righe.firstWhere((r) => r.atleta.id == 'neri');
    // Allenamento del club non segnato: lo riguarda, ed è un'assenza.
    expect(neri.stati[2], StatoPresenza.nonSegnato);
    expect(neri.diFila, 0);
  });

  test('il periodo parte dal giorno scelto; senza allenamenti nessuna %', () {
    final risultato = presenzeStagione(
      allenamenti: [_allenamento('a1', 1)],
      presenze: const [],
      atleti: [_atleta('rossi')],
      gruppoId: 'u14',
      dal: DateTime(2026, 9, 10),
      adesso: _adesso,
    );
    expect(risultato.allenamenti, isEmpty);
    expect(risultato.righe.single.percentuale, isNull);
    expect(risultato.media, isNull);
    expect(risultato.presentiMedi, isNull);
  });
}
