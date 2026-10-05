import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:flutter_test/flutter_test.dart';

SchedaBenessere _scheda({
  DateTime? data,
  int voci = 5,
  double sonno = 9,
  bool dolori = false,
  List<String> zone = const [],
  int? intensita,
  List<String> sintomi = const [],
}) => SchedaBenessere(
  id: 'x',
  atletaId: 'a',
  clubId: 'c',
  data: data ?? DateTime(2026, 10, 5),
  dolori: dolori,
  zoneDolore: zone,
  intensitaDolore: intensita,
  oreSonno: sonno,
  compilataIl: DateTime(2026, 10, 5),
  qualitaSonno: voci,
  energia: voci,
  muscoli: voci,
  stress: voci,
  umore: voci,
  sintomi: sintomi,
);

final _quindicenne = DateTime(2011, 1, 1);

void main() {
  test('tutte le voci al massimo e sonno pieno: 100, pronto', () {
    final p = calcolaPunteggio(_scheda(), dataNascita: _quindicenne);
    expect(p.valore, 100);
    expect(p.livello, 0);
    expect(p.motivi, isEmpty);
  });

  test('voci tutte "normale" (3): base 60, gia\' verde', () {
    final p = calcolaPunteggio(_scheda(voci: 3), dataNascita: _quindicenne);
    expect(p.base, 60);
    expect(p.livello, 0);
  });

  test('voci a 2: base 40, giallo', () {
    final p = calcolaPunteggio(_scheda(voci: 2), dataNascita: _quindicenne);
    expect(p.base, 40);
    expect(p.livello, 1);
  });

  test('sonno sotto le 8 ore per un minorenne toglie 5 punti a mezz\'ora', () {
    final p = calcolaPunteggio(_scheda(sonno: 7), dataNascita: _quindicenne);
    expect(p.valore, 90);
  });

  test('per un adulto l\'obiettivo di sonno e\' 7 ore', () {
    final p = calcolaPunteggio(
      _scheda(sonno: 7),
      dataNascita: DateTime(1990, 1, 1),
    );
    expect(p.valore, 100);
  });

  test('meno di 5 ore di sonno: sempre rosso', () {
    final p = calcolaPunteggio(_scheda(sonno: 4.5), dataNascita: _quindicenne);
    expect(p.livello, 2);
  });

  test('dolore alla spalla pesa di piu\' e da 7/10 e\' rosso', () {
    final ginocchio = calcolaPunteggio(
      _scheda(dolori: true, zone: ['ginocchio'], intensita: 5),
    );
    final spalla = calcolaPunteggio(
      _scheda(dolori: true, zone: ['spalla'], intensita: 5),
    );
    expect(spalla.valore, lessThan(ginocchio.valore));
    final forte = calcolaPunteggio(
      _scheda(dolori: true, zone: ['spalla'], intensita: 7),
    );
    expect(forte.livello, 2);
  });

  test('febbre: -30 e rosso', () {
    final p = calcolaPunteggio(_scheda(sintomi: ['febbre']));
    expect(p.valore, 70);
    expect(p.livello, 2);
  });

  test('molto sotto il suo solito: il semaforo sale di un livello', () {
    final storico = [
      for (var g = 1; g <= 10; g++)
        _scheda(data: DateTime(2026, 10, 5 - g), voci: 5),
    ];
    // 80 sarebbe verde, ma per questo atleta e' 20 punti sotto il solito.
    final oggi = _scheda(voci: 4);
    final p = calcolaPunteggio(oggi, storico: storico);
    expect(p.valore, 80);
    expect(p.mediaPersonale, 100);
    expect(p.livello, 1);
  });
}
