import 'package:coach_vasca/features/allenamenti/domain/destinatari.dart';
import 'package:coach_vasca/features/allenamenti/domain/modifica_allenamento.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/domain/serie_fatta.dart';
import 'package:coach_vasca/features/secco/domain/varianti_secco.dart';
import 'package:flutter_test/flutter_test.dart';

EsercizioSeduta _riga(
  String id,
  int ordine, {
  String esercizio = 'squat',
  int serie = 3,
  String? varianteDi,
  Destinatari destinatari = Destinatari.tutti,
}) => EsercizioSeduta(
  id: id,
  allenamentoId: 's1',
  clubId: 'c1',
  esercizioId: esercizio,
  ordine: ordine,
  serie: serie,
  ripetizioni: 10,
  recuperoS: 60,
  varianteDi: varianteDi,
  destinatari: destinatari,
);

SerieFatta _fatta(
  String riga,
  int serie, {
  String allenamento = 's1',
  String esercizio = 'squat',
  VotoSerie? voto,
  DateTime? il,
}) => SerieFatta(
  id: '$riga-$serie',
  atletaId: 'rossi',
  clubId: 'c1',
  allenamentoId: allenamento,
  rigaId: riga,
  esercizioId: esercizio,
  serie: serie,
  ripetizioni: 10,
  fattaIl: il ?? DateTime(2026, 10, 20, 18, serie),
  voto: voto,
);

void main() {
  // Lancio della palla medica per tutti; Rossi (spalla) fa l'extrarotazione;
  // Bianchi non fa il plank.
  final lancio = _riga('lancio', 1, esercizio: 'palla-medica');
  final plank = _riga(
    'plank',
    2,
    esercizio: 'plank',
    destinatari: const Destinatari(tranneAtleti: ['bianchi']),
  );
  final variante = _riga(
    'extra',
    1,
    esercizio: 'extrarotazione',
    serie: 2,
    varianteDi: 'lancio',
    destinatari: const Destinatari.solo(['rossi']),
  );
  final seduta = [variante, plank, lancio];

  group('chi fa che cosa', () {
    test('ognuno i suoi esercizi, in ordine', () {
      expect(eserciziDellAtleta(seduta, 'rossi').map((r) => r.id), [
        'extra',
        'plank',
      ]);
      expect(eserciziDellAtleta(seduta, 'bianchi').map((r) => r.id), [
        'lancio',
      ]);
      expect(eserciziDellAtleta(seduta, 'verdi').map((r) => r.id), [
        'lancio',
        'plank',
      ]);
    });

    test('gli esercizi di tutti senza le varianti', () {
      expect(righePrincipali(seduta).map((r) => r.id), ['lancio', 'plank']);
      expect(variantiDi(lancio, seduta).map((r) => r.id), ['extra']);
      expect(atletiFuoriDa(lancio, seduta), {'rossi'});
      expect(atletiConVarianti(seduta), {'rossi', 'bianchi'});
    });

    test('una variante di un esercizio tolto non conta', () {
      expect(eserciziDellAtleta([variante, plank], 'rossi').map((r) => r.id), [
        'plank',
      ]);
    });

    test('la variante non allunga la seduta', () {
      expect(minutiStimati(seduta), minutiStimati([lancio, plank]));
    });

    test('nuova variante: al posto dell\'esercizio, solo per lui', () {
      final v = nuovaVariante(
        riga: plank,
        atletaId: 'bianchi',
        esercizioId: 'plank',
        serie: 2,
        ripetizioni: null,
        durataS: 20,
        carico: null,
        recuperoS: 30,
      );
      expect(v.varianteDi, 'plank');
      expect(v.ordine, plank.ordine);
      expect(v.destinatari.soloAtleti, ['bianchi']);
      expect(v.ripetizioni, isNull);
      expect(v.toPayload()['solo_atleti'], ['bianchi']);
      expect(v.toPayload()['tranne_atleti'], isNull);
    });

    test('escluso e di nuovo come tutti', () {
      final senza = conEscluso(lancio, 'verdi');
      expect(senza.destinatari.tranneAtleti, ['verdi']);
      expect(conEscluso(senza, 'verdi'), same(senza));
      expect(senzaEscluso(senza, 'verdi').destinatari.perTutti, isTrue);
      expect(senza.toPayload()['tranne_atleti'], ['verdi']);
      expect(lancio.toPayload()['tranne_atleti'], isNull);
    });

    test('il foglio dell\'esercizio non toglie la variante', () {
      final cambiata = variante.conPrescrizione(
        serie: 3,
        ripetizioni: 8,
        durataS: null,
        carico: 'elastico verde',
        recuperoS: 45,
        note: null,
      );
      expect(cambiata.varianteDi, 'lancio');
      expect(cambiata.destinatari.soloAtleti, ['rossi']);
      expect(cambiata.serie, 3);
    });

    test('dalla riga del database', () {
      final r = EsercizioSeduta.fromMap({
        'id': 'extra',
        'allenamento_id': 's1',
        'club_id': 'c1',
        'esercizio_id': 'extrarotazione',
        'ordine': 1,
        'serie': 2,
        'ripetizioni': 10,
        'variante_di': 'lancio',
        'solo_atleti': ['rossi'],
        'tranne_atleti': null,
      });
      expect(r.variante, isTrue);
      expect(r.destinatari.soloAtleti, ['rossi']);
    });
  });

  group('il confronto di una modifica', () {
    test('la variante dopo il suo esercizio, con per chi', () {
      final nomi = {
        'palla-medica': 'Lancio palla medica',
        'plank': 'Plank',
        'extrarotazione': 'Extrarotazione',
      };
      final righe = righeSecco(
        seduta,
        nomi,
        nomeAtleta: (id) => {'rossi': 'Rossi', 'bianchi': 'Bianchi'}[id],
      );
      expect(righe, [
        'Lancio palla medica 3×10',
        'Rossi: Extrarotazione 2×10',
        'Plank 3×10 (tutti tranne Bianchi)',
      ]);
    });
  });

  group('il voto delle serie', () {
    test('com\'è andato un esercizio', () {
      expect(descriviVoti([_fatta('lancio', 1)]), isNull);
      expect(
        descriviVoti([_fatta('lancio', 1, voto: VotoSerie.giusta)]),
        'giusta',
      );
      expect(
        descriviVoti([
          _fatta('lancio', 1, voto: VotoSerie.giusta),
          _fatta('lancio', 2, voto: VotoSerie.giusta),
        ]),
        'tutte giuste',
      );
      expect(
        descriviVoti([
          _fatta('lancio', 1, voto: VotoSerie.dura),
          _fatta('lancio', 2, voto: VotoSerie.giusta),
          _fatta('lancio', 3, voto: VotoSerie.giusta),
          _fatta('lancio', 4),
        ]),
        '2 giuste · 1 dura',
      );
      expect(
        descriviVoti([
          _fatta('lancio', 1, voto: VotoSerie.facile),
          _fatta('lancio', 2, voto: VotoSerie.dura),
        ]),
        '1 facile · 1 dura',
      );
    });

    test('il voto va e torna dal database', () {
      final f = _fatta('lancio', 1, voto: VotoSerie.facile);
      expect(f.toPayload()['voto'], 'facile');
      expect(
        SerieFatta.fromMap({
          ...f.toPayload(),
          'fatta_il': '2026-10-20T16:00:00Z',
        }).voto,
        VotoSerie.facile,
      );
      expect(f.conVoto(null).toPayload()['voto'], isNull);
      expect(VotoSerie.daNome('boh'), isNull);
    });

    test('l\'ultima volta: le serie della seduta più recente', () {
      final precedenti = [
        _fatta('vecchia', 1, allenamento: 'a1', il: DateTime(2026, 10, 1)),
        _fatta(
          'recente',
          1,
          allenamento: 'a2',
          voto: VotoSerie.facile,
          il: DateTime(2026, 10, 15, 18),
        ),
        _fatta(
          'recente',
          2,
          allenamento: 'a2',
          voto: VotoSerie.facile,
          il: DateTime(2026, 10, 15, 18, 2),
        ),
        // Questa seduta non conta.
        _fatta('lancio', 1, il: DateTime(2026, 10, 20, 18)),
        // Un altro esercizio nemmeno.
        _fatta(
          'altro',
          1,
          allenamento: 'a3',
          esercizio: 'plank',
          il: DateTime(2026, 10, 18),
        ),
      ];
      final ultima = ultimaVoltaDi(_riga('lancio', 1), precedenti);
      expect(ultima.map((f) => f.id), ['recente-1', 'recente-2']);
      expect(descriviVoti(ultima), 'tutte facili');
      expect(
        ultimaVoltaDi(_riga('lancio', 1, esercizio: 'nuovo'), precedenti),
        isEmpty,
      );
    });
  });
}
