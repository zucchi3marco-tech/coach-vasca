import 'package:coach_vasca/features/allenamenti/domain/durata_serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/piano_salvataggio_testo.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/variante_spalla.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:coach_vasca/features/atleti/domain/abbina_atleta.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/carico/domain/volumi_atleta.dart';
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
  _atleta('rl', 'Luca', 'Rossi'),
  _atleta('bi', 'Sofia', 'Bianchi'),
  _atleta('ve', 'Pietro', 'Verdi', ruolo: 'portiere'),
];

AllenamentoScritto _leggi(String testo) =>
    interpretaAllenamento(testo, atleti: _atleti);

/// Le serie salvate come le rimette il salvataggio del testo: con un id
/// e l'ordine, e un vero `piramideId` per ogni gruppo.
List<Serie> _salvate(List<SerieScritta> scritte) => [
  for (final (i, s) in scritte.indexed)
    Serie(
      id: 's$i',
      allenamentoId: 'a1',
      clubId: 'c1',
      ordine: i + 1,
      blocco: s.blocco,
      ripetute: s.ripetute,
      distanzaM: s.distanzaM,
      durataS: s.durataS,
      stile: s.stile,
      esecuzione: s.esecuzione,
      zona: s.zona,
      recuperoS: s.recuperoS,
      note: s.note,
      piramideId: s.piramideId,
      recuperoDopoS: s.recuperoDopoS,
      destinatari: s.destinatari,
    ),
];

void main() {
  group('Destinatari', () {
    test('per chi è una serie', () {
      const portieri = Destinatari.portieri;
      expect(portieri.perAtleta('ve', 'portiere'), isTrue);
      expect(portieri.perAtleta('rm', null), isFalse);
      // Senza ruolo indicato si conta come movimento.
      expect(Destinatari.movimento.perAtleta('rm', null), isTrue);
      const tranne = Destinatari(tranneAtleti: ['bi']);
      expect(tranne.perAtleta('bi', null), isFalse);
      expect(tranne.perAtleta('ve', 'portiere'), isTrue);
      const solo = Destinatari(soloAtleti: ['bi']);
      expect(solo.perAtleta('bi', null), isTrue);
      expect(solo.perAtleta('rm', null), isFalse);
      expect(Destinatari.tutti.perAtleta('ve', 'portiere'), isTrue);
    });

    test('nel volume del gruppo e in quello dei portieri', () {
      expect(Destinatari.tutti.delGruppo, isTrue);
      expect(Destinatari.movimento.delGruppo, isTrue);
      expect(Destinatari.portieri.delGruppo, isFalse);
      expect(const Destinatari(tranneAtleti: ['bi']).delGruppo, isTrue);
      expect(const Destinatari(soloAtleti: ['bi']).delGruppo, isFalse);
      expect(Destinatari.portieri.deiPortieri, isTrue);
      expect(Destinatari.movimento.deiPortieri, isFalse);
    });

    test('i campi per il database e la copia locale', () {
      expect(Destinatari.tutti.campi, {
        'per_ruolo': null,
        'solo_atleti': null,
        'tranne_atleti': null,
      });
      expect(
        Destinatari.fromMap(const {
          'per_ruolo': 'movimento',
          'solo_atleti': null,
          'tranne_atleti': ['bi'],
        }),
        const Destinatari(ruolo: 'movimento', tranneAtleti: ['bi']),
      );
      const solo = Destinatari(soloAtleti: ['bi', 'rm']);
      expect(Destinatari.daCampi(soloAtleti: solo.soloAtletiJson), solo);
      // L'ordine degli id non conta.
      expect(solo, const Destinatari(soloAtleti: ['rm', 'bi']));
    });

    test('senza un atleta', () {
      expect(
        Destinatari.movimento.senza('bi'),
        const Destinatari(ruolo: 'movimento', tranneAtleti: ['bi']),
      );
      expect(
        const Destinatari(soloAtleti: ['bi', 'rm']).senza('bi'),
        const Destinatari(soloAtleti: ['rm']),
      );
      expect(const Destinatari(soloAtleti: ['bi']).senza('bi'), isNull);
    });
  });

  group('nel testo', () {
    test('una riga da sola vale per le righe sotto, fino al titolo', () {
      final scritto = _leggi(
        'Principale\n'
        'Portieri\n'
        "10' tiri\n"
        '4x25 gambe\n'
        'Movimento\n'
        '4x50 sl C1\n'
        'Tutti\n'
        '8x25 sl\n'
        'Defaticamento\n'
        '200 sl',
      );
      expect(scritto.righeNonCapite, 0);
      expect(scritto.righe[1].tipo, TipoRiga.destinatari);
      expect(
        [for (final s in scritto.serie) s.destinatari],
        [
          Destinatari.portieri,
          Destinatari.portieri,
          Destinatari.movimento,
          Destinatari.tutti,
          Destinatari.tutti,
        ],
      );
    });

    test('davanti a una serie vale solo per quella', () {
      final scritto = _leggi(
        "Portieri: 10' tiri\n"
        "Portieri 5' parate\n"
        '4x50 sl',
      );
      expect(scritto.righeNonCapite, 0);
      expect(scritto.serie[0].destinatari, Destinatari.portieri);
      expect(scritto.serie[0].durataS, 600);
      expect(scritto.serie[0].esecuzione, 'tiri');
      expect(scritto.serie[1].destinatari, Destinatari.portieri);
      expect(scritto.serie[2].destinatari, Destinatari.tutti);
    });

    test('i nomi degli atleti del gruppo', () {
      final scritto = _leggi(
        'Rossi M., Bianchi\n'
        '4x50 gambe\n'
        'Tutti tranne Bianchi\n'
        '4x50 tiri\n'
        'Solo i portieri\n'
        '100 sl\n'
        'Movimento\n'
        'Tranne Luca Rossi\n'
        '200 sl\n'
        'Bianchi: 100 gambe',
      );
      expect(scritto.righeNonCapite, 0);
      expect(
        [for (final s in scritto.serie) s.destinatari],
        [
          const Destinatari(soloAtleti: ['rm', 'bi']),
          const Destinatari(tranneAtleti: ['bi']),
          Destinatari.portieri,
          const Destinatari(ruolo: 'movimento', tranneAtleti: ['rl']),
          const Destinatari(soloAtleti: ['bi']),
        ],
      );
    });

    test('un nome che non è nel gruppo si dice', () {
      final scritto = _leggi(
        'Solo Neri\n'
        'Bianchi, Neri\n'
        'Neri: 100 sl\n'
        'sciolto',
      );
      expect(
        scritto.righe[0].problema,
        'Non trovo «Neri» fra gli atleti del gruppo',
      );
      expect(scritto.righe[1].problema, contains('«Neri»'));
      expect(scritto.righe[2].tipo, TipoRiga.errore);
      // Una parola da sola che non è un atleta resta una serie non capita.
      expect(scritto.righe[3].problema, contains('Manca la distanza'));
      // Due Rossi: il cognome da solo non basta.
      expect(_leggi('Rossi: 100 sl').righe.single.tipo, TipoRiga.errore);
      // Le serie con dei numeri non sono mai nomi.
      expect(_leggi('400 sl e 200 do').righe.single.tipo, TipoRiga.serie);
    });

    test('dentro un "2x" la riga per chi non chiude il gruppo', () {
      final scritto = _leggi(
        '2x\n'
        '4x50 tiri\n'
        'Bianchi: 4x50 gambe\n',
      );
      expect(scritto.righeNonCapite, 0);
      expect(scritto.serie, hasLength(4));
      expect(scritto.serie.map((s) => s.piramideId).toSet(), hasLength(1));
      expect(scritto.serie[1].destinatari.soloAtleti, ['bi']);
      expect(scritto.serie[3].destinatari.soloAtleti, ['bi']);
    });

    test('i metri sono quelli del gruppo', () {
      final scritto = _leggi(
        '400 sl\n'
        'Portieri: 800 gambe\n'
        'Bianchi: 300 gambe\n'
        'Tutti tranne Bianchi: 300 sl',
      );
      expect(scritto.metri, 700);
      final volumi = volumiPerBlocco(
        _leggi(
          'Principale\n'
          '400 sl\n'
          'Portieri: 800 gambe',
        ),
      );
      expect(volumi[0]!.blocco.metri, 400);
    });

    test('rilette, le serie scritte sono le stesse', () {
      const testo =
          'Riscaldamento\n'
          '400 sl A1\n'
          '\n'
          'Principale\n'
          'Portieri\n'
          "10' tiri\n"
          '\n'
          'Movimento\n'
          '4x50 sl C1\n'
          '\n'
          'Tutti tranne Bianchi\n'
          '2x\n'
          '4x50 tiri\n'
          'Bianchi: 4x50 gambe\n'
          '\n'
          'Rossi M., Bianchi\n'
          '200 gambe\n'
          '\n'
          'Defaticamento\n'
          '200 sl';
      final prima = _leggi(testo);
      expect(prima.righeNonCapite, 0);
      final riscritto = testoDaSerie(_salvate(prima.serie), atleti: _atleti);
      final dopo = _leggi(riscritto);
      expect(dopo.righeNonCapite, 0, reason: riscritto);
      expect(dopo.serie.length, prima.serie.length, reason: riscritto);
      for (var i = 0; i < prima.serie.length; i++) {
        expect(
          stessaSerie(dopo.serie[i], prima.serie[i]),
          isTrue,
          reason: 'serie $i in\n$riscritto',
        );
      }
      // I titoli resettano: il defaticamento è di nuovo per tutti.
      expect(riscritto, contains('Defaticamento\n200 sl'));
      expect(riscritto, contains('Rossi M., Bianchi\n200 sl gambe'));
      // Nel "2x" con serie per persone diverse, il "per chi" va davanti.
      expect(riscritto, contains('2x\nTutti tranne Bianchi: 4x50 tiri\n'));
    });

    test('una serie di atleti che non ci sono più non si scrive', () {
      final serie = _salvate(_leggi('400 sl\nBianchi: 200 gambe').serie);
      expect(testoDaSerie(serie), 'Principale\n400 sl');
    });

    test('il nome più corto che si ritrova', () {
      expect(nomeBreve(_atleti[2], _atleti), 'Bianchi');
      expect(nomeBreve(_atleti[0], _atleti), 'Rossi M.');
    });

    test('una riga sola del pannello "Aggiungi serie"', () {
      final serie = leggiRigaSerie(
        "Portieri: 10' tiri",
        blocco: 'principale',
        atleti: _atleti,
      )!;
      expect(serie.single.destinatari, Destinatari.portieri);
      expect(
        leggiRigaSerie('Portieri', blocco: 'principale', atleti: _atleti),
        isNull,
      );
    });

    test('dettato: "portieri" e i nomi restano su una riga loro', () {
      expect(
        righeDaDettato(
          '400 stile libero, portieri, 10 minuti tiri',
          atleti: _atleti,
        ),
        "400 stile libero\nportieri\n10' tiri",
      );
      expect(
        righeDaDettato('400 stile libero, Bianchi, 200 gambe', atleti: _atleti),
        '400 stile libero\nBianchi\n200 gambe',
      );
      // Senza gli atleti, un nome si attacca alla serie prima (come prima).
      expect(
        righeDaDettato('400 stile libero, Bianchi'),
        '400 stile libero Bianchi',
      );
    });

    test('il salvataggio aggiorna una serie che cambia destinatari', () {
      final vecchie = _salvate(_leggi('400 sl\n200 gambe').serie);
      final piano = pianoSalvataggio(
        vecchie: vecchie,
        nuove: _leggi('400 sl\nPortieri: 200 gambe').serie,
        nuovoId: () => 'nuovo',
      );
      expect(piano.aggiorna.single.vecchia.id, 's1');
      expect(piano.aggiorna.single.nuova.destinatari, Destinatari.portieri);
      expect(piano.crea, isEmpty);
    });
  });

  group('variante per la spalla', () {
    SchedaBenessere scheda(
      String atleta,
      DateTime data, {
      bool spalla = true,
    }) => SchedaBenessere(
      id: '$atleta-$data',
      atletaId: atleta,
      clubId: 'c1',
      data: data,
      dolori: spalla,
      zoneDolore: spalla ? const ['spalla'] : const [],
      oreSonno: 8,
      compilataIl: data,
    );

    test("chi ha male alla spalla nell'ultima scheda recente", () {
      final oggi = DateTime(2026, 10, 12, 18);
      final doloranti = conDoloreSpalla(
        [
          scheda('bi', DateTime(2026, 10, 11)),
          // Più vecchia di tre giorni: non conta.
          scheda('rm', DateTime(2026, 10, 9)),
          // L'ultima scheda dice che è passato.
          scheda('rl', DateTime(2026, 10, 10)),
          scheda('rl', DateTime(2026, 10, 12), spalla: false),
          // Non è del gruppo.
          scheda('xx', DateTime(2026, 10, 12)),
        ],
        {'bi', 'rm', 'rl'},
        oggi: oggi,
      );
      expect(doloranti, {'bi': DateTime(2026, 10, 11)});
    });

    test('il lavoro con la palla e le braccia diventa gambe', () {
      final serie = _salvate(
        _leggi(
          '400 sl\n'
          "4x5' tiri\n"
          '2x\n'
          '4x50 sl\n'
          '4x50 braccia do\n'
          '\n'
          "Portieri: 10' tiri",
        ).serie,
      );
      final piano = pianoVarianteSpalla(serie, atletaId: 'bi', ruolo: null);
      expect(piano.esclusioni.map((e) => e.serie.id), ['s1', 's3', 's5']);
      expect(
        piano.esclusioni.first.destinatari,
        const Destinatari(tranneAtleti: ['bi']),
      );
      expect(piano.inGambe, isEmpty);
      // Dopo i tiri (gruppo 1) e dopo il "2x" (gruppo 2), solo per lei.
      expect(piano.nuove.keys, [1, 2]);
      final tiri = piano.nuove[1]!.single;
      expect(tiri.esecuzione, 'gambe');
      expect(tiri.durataS, 300);
      expect(tiri.ripetute, 4);
      expect(tiri.destinatari, const Destinatari(soloAtleti: ['bi']));
      final braccia = piano.nuove[2]!;
      expect(braccia, hasLength(2));
      expect(braccia.first.stile, 'dorso');
      expect(braccia.map((s) => s.piramideId).toSet().single, isNotNull);
      expect(piano.serieToccate, 3);

      // Un portiere ha anche i tiri dei portieri.
      expect(
        pianoVarianteSpalla(
          serie,
          atletaId: 've',
          ruolo: 'portiere',
        ).serieToccate,
        4,
      );
      // Preparata la variante, non resta più niente da cambiare.
      final dopo = [
        for (final s in serie)
          if (piano.esclusioni.where((e) => e.serie.id == s.id).firstOrNull
              case final e?)
            Serie(
              id: s.id,
              allenamentoId: s.allenamentoId,
              clubId: s.clubId,
              ordine: s.ordine,
              blocco: s.blocco,
              ripetute: s.ripetute,
              distanzaM: s.distanzaM,
              durataS: s.durataS,
              stile: s.stile,
              esecuzione: s.esecuzione,
              destinatari: e.destinatari,
            )
          else
            s,
      ];
      expect(
        pianoVarianteSpalla(dopo, atletaId: 'bi', ruolo: null).vuoto,
        isTrue,
      );
    });

    test('una serie solo sua diventa gambe dove sta', () {
      final serie = _salvate(_leggi("Bianchi: 10' palleggio").serie);
      final piano = pianoVarianteSpalla(serie, atletaId: 'bi', ruolo: null);
      expect(piano.inGambe.single.id, 's0');
      expect(piano.nuove, isEmpty);
    });
  });

  group('volume e durata', () {
    test('la seduta dura quanto il più lungo fra portieri e movimento', () {
      final serie = _salvate(
        _leggi(
          "10' sl\n"
          "Portieri: 30' tiri\n"
          "Movimento: 20' tiri\n"
          "Bianchi: 60' gambe",
        ).serie,
      );
      expect(minutiSeduta(serie), 40);
      expect(volumiPerAllenamento(serie)['a1']!.secondi, 30 * 60);
      expect(volumeDi(serieDeiPortieri(serie)).secondi, 40 * 60);
    });

    test('il carico di ognuno conta solo le sue serie', () {
      final serie = _salvate(
        _leggi(
          "30' sl\n"
          "Portieri: 30' tiri\n"
          "Bianchi: 60' gambe",
        ).serie,
      );
      final perAllenamento = {
        'a1': <DatiSerie>[...serie],
      };
      List<CaricoSeduta> sedute(String atletaId, String? ruolo) =>
          seduteDiAtleta(
            dataAllenamenti: {'a1': DateTime(2026, 10, 1)},
            seriePerAllenamento: perAllenamento,
            statoPresenze: {'a1': 'presente'},
            dataPartite: const {},
            partiteConvocato: const {},
            rpe: {('allenamento', 'a1'): 5},
            atletaId: atletaId,
            ruolo: ruolo,
            oggi: DateTime(2026, 10, 2),
          );
      expect(sedute('rm', null).single.minuti, 30);
      expect(sedute('ve', 'portiere').single.minuti, 60);
      expect(sedute('bi', null).single.minuti, 90);
    });

    test('i volumi dell\'atleta contano solo le sue serie', () {
      final righe = [
        {
          'allenamento_id': 'a1',
          'ripetute': 1,
          'distanza_m': 400,
          'esecuzione': 'nuoto',
        },
        {
          'allenamento_id': 'a1',
          'ripetute': 1,
          'distanza_m': 800,
          'esecuzione': 'gambe',
          'per_ruolo': 'portiere',
        },
        {
          'allenamento_id': 'a1',
          'ripetute': 1,
          'distanza_m': 300,
          'esecuzione': 'gambe',
          'solo_atleti': ['bi'],
        },
      ];
      expect(
        VolumiAtleta.daSerie(righe, {'a1'}, atletaId: 'rm').volumeTotaleM,
        400,
      );
      expect(
        VolumiAtleta.daSerie(
          righe,
          {'a1'},
          atletaId: 've',
          ruolo: 'portiere',
        ).volumeTotaleM,
        1200,
      );
      expect(
        VolumiAtleta.daSerie(righe, {'a1'}, atletaId: 'bi').volumeTotaleM,
        700,
      );
    });
  });
}
