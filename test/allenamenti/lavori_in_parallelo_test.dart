import 'package:coach_vasca/features/allenamenti/domain/durata_serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/piano_salvataggio_testo.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/variante_spalla.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/carico/domain/volumi_atleta.dart';
import 'package:coach_vasca/features/export/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(String id, String nome, String cognome, {String? ruolo}) =>
    Atleta(
      id: id,
      clubId: 'c1',
      nome: nome,
      cognome: cognome,
      dataNascita: DateTime(2011, 1, 1),
      sport: 'pallanuoto',
      consensoPrivacyFirmato: true,
      attivo: true,
      ruolo: ruolo,
    );

final _atleti = [
  _atleta('rm', 'Marco', 'Rossi'),
  _atleta('bi', 'Sofia', 'Bianchi'),
  _atleta('ve', 'Pietro', 'Verdi', ruolo: 'portiere'),
  _atleta('ce', 'Luca', 'Neri', ruolo: 'centroboa'),
  _atleta('ma', 'Anna', 'Gialli', ruolo: 'marcatore'),
];

AllenamentoScritto _leggi(String testo) =>
    interpretaAllenamento(testo, atleti: _atleti);

/// Le serie salvate come le rimette il salvataggio del testo: id, ordine,
/// e un vero id per ogni gruppo e momento.
List<Serie> _salvate(List<SerieScritta> scritte) {
  final piano = pianoSalvataggio(
    vecchie: const [],
    nuove: scritte,
    nuovoId: () => 'id${_contatore++}',
  );
  return [
    for (final (i, c) in piano.crea.indexed)
      Serie(
        id: 's$i',
        allenamentoId: 'a1',
        clubId: 'c1',
        ordine: c.ordine,
        blocco: c.nuova.blocco,
        ripetute: c.nuova.ripetute,
        distanzaM: c.nuova.distanzaM,
        durataS: c.nuova.durataS,
        stile: c.nuova.stile,
        esecuzione: c.nuova.esecuzione,
        zona: c.nuova.zona,
        recuperoS: c.nuova.recuperoS,
        ripartenzaS: c.nuova.ripartenzaS,
        note: c.nuova.note,
        piramideId: c.piramideId,
        recuperoDopoS: c.nuova.recuperoDopoS,
        destinatari: c.nuova.destinatari,
        momentoId: c.momentoId,
      ),
  ];
}

var _contatore = 0;

const _seduta =
    'Riscaldamento\n'
    '400 sl A1\n'
    '\n'
    'Principale\n'
    '8x100 A2 @1:45\n'
    '4x50 C1 r30\n'
    'Portieri\n'
    "3x6' tiri \"parate da fuori\"\n"
    'Centroboa\n'
    "10x1' tecnico-tattico \"lotta in posizione\"\n"
    "10' tiri\n"
    'Tutti\n'
    "10' partita\n"
    '\n'
    'Defaticamento\n'
    '200 sl sciolto';

void main() {
  group('nel testo', () {
    test('portieri e centroboa vanno insieme alle righe di tutti sopra', () {
      final scritto = _leggi(_seduta);
      expect(scritto.righeNonCapite, 0);
      final s = scritto.serie;
      expect(s, hasLength(8));
      // Il riscaldamento, la partita e il defaticamento non sono momenti.
      expect(s[0].momentoId, isNull);
      expect(s[6].momentoId, isNull);
      expect(s[7].momentoId, isNull);
      // Le due serie di tutti, i portieri e i centroboa: un momento solo.
      expect({for (final x in s.sublist(1, 6)) x.momentoId}, hasLength(1));
      expect(s[1].momentoId, isNotNull);
      expect(s[3].destinatari, Destinatari.portieri);
      expect(s[4].destinatari, const Destinatari(ruolo: 'centroboa'));
    });

    test('un titolo o "Tutti" aprono un momento nuovo', () {
      final s = _leggi(
        'Principale\n'
        '400 sl\n'
        "Portieri: 5' gambe\n"
        'Tutti\n'
        '8x50 sl\n'
        'Portieri\n'
        "6' tiri\n"
        'Altro\n'
        "Portieri: 10' tiri",
      ).serie;
      expect(s[0].momentoId, s[1].momentoId);
      expect(s[2].momentoId, s[3].momentoId);
      expect(s[2].momentoId, isNot(s[0].momentoId));
      // Da sola in un blocco: una serie normale, solo per i portieri.
      expect(s[4].momentoId, isNull);
    });

    test('i ruoli nuovi e "Tutti tranne" aprono o chiudono come prima', () {
      final s = _leggi(
        'Marcatori\n'
        "5' gambe\n"
        'Esterni\n'
        "5' tiri\n"
        'Tutti tranne Bianchi\n'
        '200 sl\n'
        'Bianchi\n'
        '200 gambe',
      ).serie;
      expect(s[0].destinatari, const Destinatari(ruolo: 'marcatore'));
      expect(s[1].destinatari, const Destinatari(ruolo: 'esterno'));
      // Marcatori ed esterni insieme, senza una colonna di tutti.
      expect(s[0].momentoId, s[1].momentoId);
      // Bianchi fa le gambe mentre gli altri nuotano.
      expect(s[2].momentoId, s[3].momentoId);
      expect(s[2].momentoId, isNot(s[0].momentoId));
    });

    test('rilette, le serie scritte sono le stesse, momenti compresi', () {
      for (final testo in [
        _seduta,
        // Le serie di tutti dopo quelle dei portieri, nello stesso momento.
        'Principale\n400 sl\nPortieri: 5\' gambe\n200 sl\nTutti\n100 sl',
        // Due momenti di fila.
        'Principale\n400 sl\nPortieri\n6\' tiri\nTutti\n8x50 sl\nCentroboa\n'
            "5' tecnico-tattico",
        // Un momento senza la colonna di tutti, dopo una serie normale.
        'Principale\n400 sl\nTutti\nMovimento\n4x50 sl\nPortieri\n4x50 gambe',
      ]) {
        final prima = _leggi(testo);
        final salvate = _salvate(prima.serie);
        final riscritto = testoDaSerie(salvate, atleti: _atleti);
        final dopo = _leggi(riscritto);
        expect(dopo.righeNonCapite, 0, reason: riscritto);
        expect(dopo.serie.length, prima.serie.length, reason: riscritto);
        for (var i = 0; i < prima.serie.length; i++) {
          expect(
            stessaSerie(dopo.serie[i], prima.serie[i]),
            isTrue,
            reason: 'serie $i in\n$riscritto',
          );
          // Nello stesso momento le stesse serie.
          for (var j = 0; j < i; j++) {
            expect(
              dopo.serie[i].momentoId != null &&
                  dopo.serie[i].momentoId == dopo.serie[j].momentoId,
              salvate[i].momentoId != null &&
                  salvate[i].momentoId == salvate[j].momentoId,
              reason: 'serie $j e $i in\n$riscritto',
            );
          }
        }
      }
    });

    test('nel riscritto le serie di tutti dopo i portieri hanno "Tutti:"', () {
      final riscritto = testoDaSerie(
        _salvate(
          _leggi(
            'Principale\n400 sl\nPortieri: 5\' gambe\n200 sl\nTutti\n100 sl',
          ).serie,
        ),
        atleti: _atleti,
      );
      expect(
        riscritto,
        "Principale\n400 sl\n\nPortieri\n5' sl gambe\nTutti: 200 sl\n\nTutti\n"
        '100 sl',
      );
    });

    test('il salvataggio riusa il momento delle serie che c\'erano', () {
      final vecchie = _salvate(_leggi(_seduta).serie);
      final piano = pianoSalvataggio(
        vecchie: vecchie,
        nuove: _leggi(_seduta.replaceFirst('8x100', '10x100')).serie,
        nuovoId: () => 'nuovo',
      );
      expect(piano.aggiorna.map((a) => a.vecchia.id), ['s1']);
      expect(piano.aggiorna.single.momentoId, vecchie[1].momentoId);
    });
  });

  group('chi fa cosa', () {
    final serie = _salvate(_leggi(_seduta).serie);
    List<int> ordini(List<Serie> s) => [for (final x in s) x.ordine];

    test('ognuno fa la sua colonna, poi si riparte insieme', () {
      // Un giocatore di movimento: le serie di tutti.
      expect(ordini(serieDellAtleta(serie, 'rm', null)), [1, 2, 3, 7, 8]);
      // Un portiere: le parate al posto del nuoto.
      expect(ordini(serieDellAtleta(serie, 've', 'portiere')), [1, 4, 7, 8]);
      // Un centroboa: la lotta e i tiri, poi la partita con tutti.
      expect(ordini(serieDellAtleta(serie, 'ce', 'centroboa')), [
        1,
        5,
        6,
        7,
        8,
      ]);
      // Un marcatore fa quello di tutti: non c'è una colonna per lui.
      expect(ordini(serieDellAtleta(serie, 'ma', 'marcatore')), [
        1,
        2,
        3,
        7,
        8,
      ]);
    });

    test('"Movimento" vale anche per centroboa e marcatori', () {
      expect(ruoloComprende('movimento', 'centroboa'), isTrue);
      expect(ruoloComprende('movimento', null), isTrue);
      expect(ruoloComprende('movimento', 'portiere'), isFalse);
      expect(ruoloComprende('centroboa', null), isFalse);
      final s = _salvate(
        _leggi(
          'Movimento\n4x50 sl\nPortieri\n4x50 gambe\nCentroboa\n'
          "5' tecnico-tattico",
        ).serie,
      );
      // La colonna più precisa: il centroboa fa la sua, non "movimento".
      expect(ordini(serieDellAtleta(s, 'ce', 'centroboa')), [3]);
      expect(ordini(serieDellAtleta(s, 'ma', 'marcatore')), [1]);
      expect(ordini(serieDellAtleta(s, 've', 'portiere')), [2]);
    });

    test('alcuni atleti per nome vincono sul ruolo', () {
      final s = _salvate(
        _leggi(
          '8x100 sl\nCentroboa\n10\' tecnico-tattico\nNeri\n'
          '10\' gambe',
        ).serie,
      );
      expect(ordini(serieDellAtleta(s, 'ce', 'centroboa')), [3]);
    });

    test('i metri e la durata del gruppo', () {
      final scritto = _leggi(_seduta);
      // Riscaldamento, 8x100, 4x50 e defaticamento: senza i portieri.
      expect(scritto.metri, 400 + 800 + 200 + 200);
      // Il volume dei portieri: il riscaldamento e il defaticamento.
      expect(volumeDi(serieDeiPortieri(scritto.serie)).metri, 600);
      // Il momento dura quanto la colonna più lunga: i centroboa, 10' + 10'.
      final senzaMomento = minutiSeduta([
        for (final s in scritto.serie)
          if (s.momentoId == null) s,
      ]);
      expect(minutiSeduta(scritto.serie), senzaMomento + 20);
    });

    test('nel volume dell\'atleta solo la sua colonna', () {
      final righe = [
        for (final s in serie)
          {
            'allenamento_id': 'a1',
            'ripetute': s.ripetute,
            'distanza_m': s.distanzaM,
            'durata_s': s.durataS,
            'zona': s.zona,
            'esecuzione': s.esecuzione,
            ...s.destinatari.campi,
            'momento_id': s.momentoId,
          },
      ];
      final portiere = VolumiAtleta.daSerie(
        righe,
        {'a1'},
        atletaId: 've',
        ruolo: 'portiere',
      );
      expect(portiere.volumeTotaleM, 600);
      expect(portiere.tempoPerEsecuzione['tiri'], 3 * 360);
      final movimento = VolumiAtleta.daSerie(righe, {'a1'}, atletaId: 'rm');
      expect(movimento.volumeTotaleM, 1600);
    });

    test('il CSV dice quali serie vanno insieme', () {
      final numeri = numeriMomenti(serie);
      expect(numeri.values, [1]);
      expect(numeri[serie[1].momentoId], 1);
    });
  });

  group('variante per la spalla in un momento', () {
    test('riceve una colonna sua: il resto uguale, i tiri con le gambe', () {
      final serie = _salvate(
        _leggi(
          'Principale\n'
          "4x5' tiri\n"
          '4x50 sl\n'
          'Portieri\n'
          "20' tiri",
        ).serie,
      );
      final piano = pianoVarianteSpalla(serie, atletaId: 'bi', ruolo: null);
      expect(piano.esclusioni.map((e) => e.serie.id), ['s0']);
      // Dopo l'ultimo gruppo del momento, nel momento.
      expect(piano.nuove.keys, [2]);
      final colonna = piano.nuove[2]!;
      expect(colonna.map((c) => c.esecuzione), ['gambe', 'nuoto']);
      expect(colonna.map((c) => c.momentoId).toSet(), {serie.first.momentoId});
      expect(
        colonna.every(
          (c) => c.destinatari == const Destinatari(soloAtleti: ['bi']),
        ),
        isTrue,
      );
    });

    test('un portiere esce solo dalle sue parate', () {
      final serie = _salvate(
        _leggi("Principale\n4x50 sl\nPortieri\n20' tiri").serie,
      );
      final piano = pianoVarianteSpalla(
        serie,
        atletaId: 've',
        ruolo: 'portiere',
      );
      // Il nuoto di tutti non lo fa: resta solo la sua colonna.
      expect(piano.esclusioni.map((e) => e.serie.id), ['s1']);
      expect(piano.nuove.values.single.map((c) => c.esecuzione), ['gambe']);
    });
  });
}
