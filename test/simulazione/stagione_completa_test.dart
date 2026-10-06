// Simulazione di un anno di campionato (settembre 2026 - giugno 2027):
// 12 atleti, 4 allenamenti a settimana, una partita ogni sabato, una
// scheda benessere al giorno per atleta, con preparazione, pausa di
// Natale, un'influenza, un sovraccarico alla spalla, un atleta che compie
// 18 anni a meta' stagione e due cambi dell'ora. Controlla che date,
// calendario, carico, presenze e Prontezza restino corretti per tutto
// l'anno e che i calcoli restino veloci con un anno di dati.
//
// I test di calendario presuppongono il fuso dell'Italia (Europe/Rome),
// quello in cui gira l'app: e' li' che esistono i giorni da 23 e 25 ore.

import 'package:coach_vasca/core/utils/giorni.dart';
import 'package:coach_vasca/core/utils/percentuale_presenze.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/prossimo_allenamento.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/carico/domain/banister.dart';
import 'package:coach_vasca/features/home/atleta/home_atleta_widgets.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:flutter_test/flutter_test.dart';

final inizioStagione = DateTime(2026, 9, 1);
final fineStagione = DateTime(2027, 6, 30);

/// Pausa natalizia: niente allenamenti ne' partite.
bool inPausa(DateTime g) =>
    !g.isBefore(DateTime(2026, 12, 23)) && g.isBefore(DateTime(2027, 1, 7));

/// I giorni della stagione, uno per data di calendario.
List<DateTime> giorniStagione() => [
  for (
    var g = inizioStagione;
    !g.isAfter(fineStagione);
    g = aggiungiGiorni(g, 1)
  )
    g,
];

List<Allenamento> calendarioAllenamenti() => [
  for (final g in giorniStagione())
    if (!inPausa(g) &&
        const {
          DateTime.monday,
          DateTime.tuesday,
          DateTime.thursday,
          DateTime.friday,
        }.contains(g.weekday))
      Allenamento(
        id: 'all-${g.toIso8601String()}',
        clubId: 'club',
        data: DateTime(g.year, g.month, g.day, 18, 30),
        gruppoId: 'u14',
      ),
];

/// Data di nascita degli atleti: l'atleta 6 compie 18 anni il 14/2/2027.
DateTime nascita(int atleta) =>
    atleta == 6 ? DateTime(2009, 2, 14) : DateTime(2011, 1 + atleta, 3);

/// La scheda di un atleta in un giorno, con gli episodi della stagione.
SchedaBenessere schedaDelGiorno(int a, DateTime g) {
  final giornoAnno = giorniTra(inizioStagione, g);
  var energia = 3 + (a + giornoAnno) % 2; // 3-4
  var muscoli = 3 + (a * 3 + giornoAnno) % 2;
  var stress = 4;
  var umore = 4;
  var qualita = 4;
  var sonno = 8.0 + ((a + giornoAnno) % 3) * 0.5;
  var dolori = false;
  var zone = <String>[];
  int? intensita;
  var sintomi = <String>[];

  // Settembre: preparazione, carichi alti, muscoli doloranti.
  if (g.month == 9) {
    muscoli = 2;
    energia = 3;
  }
  // Natale: riposo, tutti freschi.
  if (inPausa(g)) {
    energia = 5;
    muscoli = 5;
    stress = 5;
  }
  // Atleta 2: influenza dal 12 al 15 gennaio.
  if (a == 2 &&
      !g.isBefore(DateTime(2027, 1, 12)) &&
      !g.isAfter(DateTime(2027, 1, 15))) {
    sintomi = ['febbre'];
    energia = 1;
  }
  // Atleta 3: sovraccarico alla spalla in febbraio, prima cresce poi
  // passa.
  if (a == 3 && g.month == 2) {
    dolori = true;
    zone = ['spalla'];
    intensita = g.day <= 7
        ? 4
        : g.day <= 14
        ? 7
        : 3;
  }
  // Giugno: esami di scuola, piu' stress e meno sonno.
  if (g.month == 6) {
    stress = 2;
    sonno = 6.5;
  }
  // L'atleta 6 dorme sempre 7,5 h: da minorenne e' poco, da adulto basta.
  if (a == 6) sonno = 7.5;

  return SchedaBenessere(
    id: 's-$a-${g.toIso8601String()}',
    atletaId: 'atleta-$a',
    clubId: 'club',
    data: g,
    dolori: dolori,
    zoneDolore: zone,
    intensitaDolore: intensita,
    oreSonno: sonno,
    compilataIl: DateTime(g.year, g.month, g.day, 7, 30),
    qualitaSonno: qualita,
    energia: energia,
    muscoli: muscoli,
    stress: stress,
    umore: umore,
    sintomi: sintomi,
  );
}

void main() {
  group('Calendario lungo tutta la stagione', () {
    test('un giorno per data, sempre a mezzanotte, anche ai cambi d\'ora', () {
      final giorni = giorniStagione();
      expect(giorni.length, 303); // 1/9/2026 - 30/6/2027
      for (var i = 0; i < giorni.length; i++) {
        final g = giorni[i];
        expect((g.hour, g.minute), (0, 0), reason: '$g non e\' mezzanotte');
        if (i > 0) expect(giorniTra(giorni[i - 1], g), 1);
      }
      expect(giorni.toSet().length, giorni.length);
    });

    test('ogni settimana del calendario parte di lunedi', () {
      var lunedi = DateTime(2026, 8, 31);
      while (lunedi.isBefore(fineStagione)) {
        expect(lunedi.weekday, DateTime.monday, reason: '$lunedi');
        expect(lunedi.hour, 0, reason: '$lunedi');
        lunedi = aggiungiGiorni(lunedi, 7);
      }
    });

    test('"Tra N giorni" e\' giusto ai cambi d\'ora e a Capodanno', () {
      // Ora legale: domenica 28 marzo 2027 dura 23 ore.
      final sabatoMarzo = DateTime(2027, 3, 27, 22);
      expect(traQuanto(DateTime(2027, 3, 28), oggi: sabatoMarzo), 'Domani');
      expect(
        traQuanto(DateTime(2027, 3, 29, 18, 30), oggi: sabatoMarzo),
        'Tra 2 giorni',
      );
      // Ora solare: domenica 25 ottobre 2026 dura 25 ore.
      final sabatoOttobre = DateTime(2026, 10, 24, 23, 30);
      expect(traQuanto(DateTime(2026, 10, 25), oggi: sabatoOttobre), 'Domani');
      expect(
        traQuanto(DateTime(2026, 10, 26), oggi: sabatoOttobre),
        'Tra 2 giorni',
      );
      expect(
        traQuanto(DateTime(2027, 1, 1), oggi: DateTime(2026, 12, 31, 23)),
        'Domani',
      );
    });

    test('duplicare la settimana del cambio d\'ora tiene giorno e orario', () {
      final sorgente = DateTime(2026, 10, 19, 18, 30); // lunedi
      final inizioSorgente = DateTime(2026, 10, 19);
      final nuovoInizio = DateTime(2026, 10, 26);
      final copia = aggiungiGiorni(
        sorgente,
        giorniTra(inizioSorgente, nuovoInizio),
      );
      expect(copia, DateTime(2026, 10, 26, 18, 30));
      final marzo = aggiungiGiorni(
        DateTime(2027, 3, 26, 18, 30),
        giorniTra(DateTime(2027, 3, 22), DateTime(2027, 3, 29)),
      );
      expect(marzo, DateTime(2027, 4, 2, 18, 30));
    });
  });

  group('Allenamenti e presenze', () {
    final allenamenti = calendarioAllenamenti();

    test('circa 4 allenamenti a settimana, nessuno nella pausa', () {
      expect(allenamenti.length, inInclusiveRange(160, 175));
      expect(allenamenti.where((a) => inPausa(a.data)), isEmpty);
    });

    test('il prossimo allenamento e\' sempre quello giusto, ogni giorno', () {
      for (final g in giorniStagione()) {
        final p = prossimoAllenamento(allenamenti, 'u14', oggi: g);
        if (p == null) {
          expect(g.isAfter(allenamenti.last.data), isTrue);
          continue;
        }
        expect(p.data.isBefore(g), isFalse, reason: '$g -> ${p.data}');
        expect(
          allenamenti.where(
            (a) => !a.data.isBefore(g) && a.data.isBefore(p.data),
          ),
          isEmpty,
          reason: 'ne salta uno il $g',
        );
      }
      // Nella pausa di Natale si salta al 7 gennaio.
      final dopoNatale = prossimoAllenamento(
        allenamenti,
        'u14',
        oggi: DateTime(2026, 12, 24),
      )!;
      expect(soloData(dopoNatale.data), DateTime(2027, 1, 7));
    });

    test(
      'gli allenamenti futuri gia\' programmati non contano come assenze',
      () {
        final adesso = DateTime(2026, 11, 15, 12);
        final passati = allenamenti.where((a) => a.data.isBefore(adesso));
        final presenze = [
          for (final a in passati)
            Presenza(
              id: 'p-${a.id}',
              allenamentoId: a.id,
              atletaId: 'atleta-0',
              clubId: 'club',
              stato: 'presente',
            ),
        ];
        final percentuale = percentualePresenze(
          allenamenti: allenamenti,
          presenze: presenze,
          atletaId: 'atleta-0',
          gruppoAtleta: 'u14',
          adesso: adesso,
        );
        expect(percentuale, 100);
      },
    );
  });

  group('Carico e grafico della forma su tutta la stagione', () {
    final carico = <DateTime, double>{
      for (final a in calendarioAllenamenti()) soloData(a.data): 450,
      for (final g in giorniStagione())
        if (g.weekday == DateTime.saturday && !inPausa(g)) g: 600,
    };
    final punti = calcolaBanister(carico);
    final perGiorno = {for (final p in punti) p.data: p};

    test('un punto per giorno e nessun carico perso ai cambi d\'ora', () {
      for (final p in punti) {
        expect(p.data.hour, 0, reason: '${p.data}');
      }
      final totaleIn = carico.values.reduce((a, b) => a + b);
      final totaleOut = punti.map((p) => p.carico).reduce((a, b) => a + b);
      expect(totaleOut, totaleIn);
      // Il lunedi dopo il cambio dell'ora il carico c'e'.
      expect(perGiorno[DateTime(2026, 10, 26)]!.carico, 450);
      expect(perGiorno[DateTime(2027, 3, 29)]!.carico, 450);
    });

    test('la forma risale nella pausa di Natale', () {
      final prima = perGiorno[DateTime(2026, 12, 22)]!;
      final dopo = perGiorno[DateTime(2027, 1, 6)]!;
      expect(dopo.fatica, lessThan(prima.fatica));
      expect(dopo.forma, greaterThan(prima.forma));
    });
  });

  group('Prontezza, un anno di schede', () {
    final giorni = giorniStagione();
    final schede = {
      for (var a = 0; a < 12; a++)
        a: [for (final g in giorni) schedaDelGiorno(a, g)],
    };

    PunteggioBenessere punteggio(int a, DateTime g) {
      final tutte = schede[a]!;
      final s = tutte.firstWhere((x) => x.data == g);
      return calcolaPunteggio(s, dataNascita: nascita(a), storico: tutte);
    }

    test(
      'ogni giorno, ogni atleta: punteggio fra 0 e 100 e semaforo coerente',
      () {
        for (var a = 0; a < 12; a++) {
          for (final g in giorni) {
            final p = punteggio(a, g);
            expect(p.valore, inInclusiveRange(0, 100));
            if (p.motivi.any((m) => m.critico)) {
              expect(p.livello, 2, reason: 'atleta $a il $g');
            }
          }
        }
      },
    );

    test('il confronto col suo solito parte solo dopo 5 schede', () {
      expect(punteggio(0, giorni[3]).mediaPersonale, isNull);
      expect(punteggio(0, giorni[10]).mediaPersonale, isNotNull);
    });

    test('l\'influenza di gennaio e la spalla di febbraio sono in rosso', () {
      expect(punteggio(2, DateTime(2027, 1, 13)).livello, 2);
      expect(punteggio(2, DateTime(2027, 1, 20)).livello, isNot(2));
      // Il primo fastidio alla spalla (4/10) gia' fa scattare l'attenzione:
      // e' molto sotto il suo solito.
      expect(punteggio(3, DateTime(2027, 2, 1)).livello, greaterThan(0));
      expect(punteggio(3, DateTime(2027, 2, 10)).livello, 2);
      // A fine mese il dolore e' 3/10 e non e' piu' rosso.
      expect(punteggio(3, DateTime(2027, 2, 25)).livello, isNot(2));
    });

    test('a 18 anni l\'obiettivo di sonno passa da 8 a 7 ore', () {
      final prima = punteggio(6, DateTime(2027, 2, 13));
      final dopo = punteggio(6, DateTime(2027, 2, 14));
      expect(prima.motivi.any((m) => m.testo.startsWith('Sonno')), isTrue);
      expect(dopo.motivi.any((m) => m.testo.startsWith('Sonno')), isFalse);
    });

    test('le settimane di esami di giugno abbassano la squadra', () {
      double mediaSquadra(DateTime g) =>
          [for (var a = 0; a < 12; a++) punteggio(a, g).valore]
              .reduce((x, y) => x + y) /
          12;
      expect(
        mediaSquadra(DateTime(2027, 6, 15)),
        lessThan(mediaSquadra(DateTime(2027, 5, 15))),
      );
    });

    test('un anno di Prontezza per 12 atleti si calcola in fretta', () {
      final cronometro = Stopwatch()..start();
      for (var a = 0; a < 12; a++) {
        for (final g in giorni) {
          punteggio(a, g);
        }
      }
      cronometro.stop();
      // 12 atleti x 303 giorni, ognuno con il confronto sulle 4 settimane.
      expect(cronometro.elapsedMilliseconds, lessThan(5000));
      // ignore: avoid_print
      print('Prontezza di una stagione: ${cronometro.elapsedMilliseconds} ms');
    });
  });
}
