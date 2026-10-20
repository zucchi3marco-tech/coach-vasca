import 'dart:convert';
import 'dart:typed_data';

// archive arriva con excel: qui serve solo a guardare dentro il file.
// ignore: depend_on_referenced_packages
import 'package:archive/archive.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/domain/personal_best.dart';
import 'package:coach_vasca/features/atleti/domain/tempo_gara.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/carico/domain/rpe_seduta.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/export/application/excel_dati_club.dart';
import 'package:coach_vasca/features/export/domain/dati_club.dart';
import 'package:coach_vasca/features/export/domain/periodo_dati.dart';
import 'package:coach_vasca/features/gare/domain/gara.dart';
import 'package:coach_vasca/features/gare/domain/gara_iscritto.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/referti/domain/referto_letto.dart';
import 'package:coach_vasca/features/referti/domain/referto_partita.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/domain/serie_fatta.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/features/tabelle_passi/domain/tabella_passo.dart';
import 'package:coach_vasca/features/test/domain/test_club.dart';
import 'package:coach_vasca/features/test/domain/test_ingresso.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

const _club = 'club-1';

Atleta _atleta(
  String id,
  String cognome,
  String nome, {
  String? gruppoId,
  bool attivo = true,
  String? userId,
  String? note,
  String? ruolo,
  String? altroGruppoId,
  List<int> giorni = const [],
  bool consenso = true,
}) => Atleta(
  id: id,
  clubId: _club,
  nome: nome,
  cognome: cognome,
  dataNascita: DateTime(2012, 3, 12),
  sesso: 'M',
  sport: 'pallanuoto',
  gruppoId: gruppoId,
  emailGenitore: 'genitore@example.com',
  telefonoGenitore: '333 1234567',
  consensoPrivacyFirmato: consenso,
  consensoPrivacyData: consenso ? DateTime(2026, 9, 5) : null,
  note: note,
  attivo: attivo,
  numeroTesseraFin: '12345',
  userId: userId,
  visitaMedicaScadenza: DateTime(2027, 1, 31),
  ruolo: ruolo,
  altroGruppoId: altroGruppoId,
  giorniAltroGruppo: giorni,
);

EventoPartita _tiro(
  String id,
  String squadra,
  String? atletaId,
  String esito, {
  String contesto = 'azione',
}) => EventoPartita(
  id: id,
  partitaId: 'partita-1',
  clubId: _club,
  tipo: 'tiro',
  squadra: squadra,
  atletaId: atletaId,
  esito: esito,
  contestoTiro: contesto,
  creatoIl: DateTime(2026, 10, 17, 16),
);

/// Un piccolo club: due squadre, tre atleti (uno non più attivo), due
/// stagioni sportive di allenamenti, una partita, una gara dell'anno prima.
DatiClub _dati({bool conSchede = true}) {
  const serieAcqua = [
    Serie(
      id: 'serie-1',
      allenamentoId: 'allenamento-1',
      clubId: _club,
      ordine: 1,
      blocco: 'riscaldamento',
      ripetute: 4,
      distanzaM: 100,
      stile: 'libero',
      esecuzione: 'nuoto',
      zona: 'A1',
      passoObiettivoS: 92.5,
      recuperoS: 20,
    ),
    Serie(
      id: 'serie-2',
      allenamentoId: 'allenamento-1',
      clubId: _club,
      ordine: 2,
      blocco: 'principale',
      ripetute: 8,
      distanzaM: 50,
      stile: 'libero',
      esecuzione: 'tiri',
      destinatari: Destinatari.portieri,
      esito: 'fatta',
      note: 'solo portieri',
    ),
    // Della stagione prima.
    Serie(
      id: 'serie-3',
      allenamentoId: 'allenamento-vecchio',
      clubId: _club,
      ordine: 1,
      blocco: 'principale',
      ripetute: 10,
      distanzaM: 200,
      stile: 'dorso',
      esecuzione: 'nuoto',
    ),
  ];
  return DatiClub(
    squadre: const [
      Gruppo(
        id: 'gruppo-u14',
        clubId: _club,
        nome: 'Under 14',
        ordine: 1,
        sport: 'pallanuoto',
      ),
      Gruppo(
        id: 'gruppo-ass',
        clubId: _club,
        nome: 'Assoluti',
        ordine: 2,
        sport: 'nuoto',
      ),
    ],
    squadreConCapo: const [
      SquadraConCapo(
        id: 'gruppo-u14',
        nome: 'Under 14',
        capoUserId: 'utente-2',
      ),
      SquadraConCapo(id: 'gruppo-ass', nome: 'Assoluti'),
    ],
    membri: const [
      MembroClub(
        userId: 'utente-2',
        ruolo: RuoloClub.allenatore,
        sonoIo: false,
        nome: 'Luca Bianchi',
        email: 'luca@example.com',
      ),
      MembroClub(
        userId: 'utente-1',
        ruolo: RuoloClub.responsabile,
        sonoIo: true,
        nome: 'Marco Rossi',
        email: 'marco@example.com',
      ),
    ],
    atleti: [
      _atleta(
        'atleta-rossi',
        'Rossi',
        'Mario',
        gruppoId: 'gruppo-u14',
        ruolo: 'portiere',
        altroGruppoId: 'gruppo-ass',
        giorni: const [2, 4],
      ),
      _atleta(
        'atleta-bianchi',
        'Bianchi',
        'Anna',
        gruppoId: 'gruppo-ass',
        userId: 'utente-anna',
        note: '=SOMMA(1)',
      ),
      _atleta(
        'atleta-verdi',
        'Verdi',
        'Carlo',
        gruppoId: 'gruppo-u14',
        attivo: false,
        consenso: false,
      ),
    ],
    stagioni: [
      Stagione(
        id: 'stagione-1',
        clubId: _club,
        nome: 'Campionato U14',
        dataInizio: DateTime(2026, 9, 1),
        dataFine: DateTime(2027, 6, 30),
        obiettivo: 'Salvezza',
        gruppoId: 'gruppo-u14',
        campionato: 'Serie C',
        fasi: [
          FaseStagione(
            nome: 'Preparazione',
            dataInizio: DateTime(2026, 9, 1),
            dataFine: DateTime(2026, 10, 31),
            obiettivoMetri: 12000,
          ),
        ],
      ),
    ],
    allenamenti: [
      Allenamento(
        id: 'allenamento-1',
        clubId: _club,
        data: DateTime(2026, 10, 10),
        titolo: 'Resistenza',
        gruppoId: 'gruppo-u14',
        note: 'Bella seduta',
      ),
      Allenamento(
        id: 'allenamento-vecchio',
        clubId: _club,
        data: DateTime(2025, 11, 5),
        titolo: 'Vecchio',
        gruppoId: 'gruppo-u14',
      ),
      Allenamento(
        id: 'allenamento-secco',
        clubId: _club,
        data: DateTime(2026, 10, 12),
        gruppoId: 'gruppo-ass',
        tipo: 'secco',
        durataMin: 40,
      ),
    ],
    serie: serieAcqua,
    presenze: const [
      Presenza(
        id: 'presenza-1',
        allenamentoId: 'allenamento-1',
        atletaId: 'atleta-rossi',
        clubId: _club,
        stato: 'presente',
      ),
      Presenza(
        id: 'presenza-2',
        allenamentoId: 'allenamento-1',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        stato: 'assente',
        note: 'influenza',
      ),
      Presenza(
        id: 'presenza-3',
        allenamentoId: 'allenamento-vecchio',
        atletaId: 'atleta-rossi',
        clubId: _club,
        stato: 'presente',
      ),
    ],
    eserciziSecco: const [
      EsercizioSecco(
        id: 'esercizio-1',
        clubId: _club,
        nome: 'Rotazioni esterne',
        categoria: CategoriaEsercizio.spalla,
        attrezzo: 'Elastico',
        videoYoutube: 'abc123',
        videoDaS: 12,
      ),
      EsercizioSecco(
        id: 'esercizio-2',
        clubId: _club,
        nome: 'Plank',
        categoria: CategoriaEsercizio.core,
        misura: MisuraEsercizio.tempo,
        archiviato: true,
      ),
    ],
    eserciziSeduta: const [
      EsercizioSeduta(
        id: 'riga-1',
        allenamentoId: 'allenamento-secco',
        clubId: _club,
        esercizioId: 'esercizio-1',
        ordine: 1,
        ripetizioni: 12,
        carico: 'elastico rosso',
      ),
      EsercizioSeduta(
        id: 'riga-2',
        allenamentoId: 'allenamento-secco',
        clubId: _club,
        esercizioId: 'esercizio-2',
        ordine: 2,
        serie: 2,
        durataS: 30,
      ),
    ],
    serieSeccoFatte: [
      SerieFatta(
        id: 'fatta-1',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        allenamentoId: 'allenamento-secco',
        rigaId: 'riga-1',
        esercizioId: 'esercizio-1',
        serie: 1,
        fattaIl: DateTime(2026, 10, 12, 18, 5),
        ripetizioni: 12,
        carico: 'elastico rosso',
        caricoPrevisto: 'elastico rosso',
      ),
    ],
    partite: [
      Partita(
        id: 'partita-1',
        clubId: _club,
        gruppoId: 'gruppo-u14',
        data: DateTime(2026, 10, 17),
        ora: '15:30',
        luogo: 'Piscina Comunale',
        campionato: 'Serie C',
        squadraCasa: 'Canottieri Milano',
        squadraTrasferta: 'Pro Recco',
        numeroMaxConvocati: 14,
        importanza: 'alta',
      ),
    ],
    distinte: const [
      DistintaGiocatore(
        id: 'distinta-2',
        partitaId: 'partita-1',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        numeroCalottina: 7,
        capitano: false,
        viceCapitano: true,
        portiere: false,
        fuoriquota: true,
      ),
      DistintaGiocatore(
        id: 'distinta-1',
        partitaId: 'partita-1',
        atletaId: 'atleta-rossi',
        clubId: _club,
        numeroCalottina: 1,
        capitano: true,
        viceCapitano: false,
        portiere: true,
        fuoriquota: false,
      ),
    ],
    eventiPartita: [
      _tiro('evento-1', 'nostra', 'atleta-rossi', 'gol'),
      _tiro('evento-2', 'nostra', 'atleta-rossi', 'gol', contesto: 'rigore'),
      _tiro('evento-3', 'avversaria', null, 'gol'),
      _tiro('evento-4', 'nostra', 'atleta-bianchi', 'parato'),
    ],
    referti: const [
      RefertoPartita(
        id: 'referto-1',
        partitaId: 'partita-1',
        clubId: _club,
        squadraCasa: 'Canottieri Milano',
        squadraTrasferta: 'Pro Recco',
        risultatoCasa: 2,
        risultatoTrasferta: 1,
        parziali: [
          ParzialeReferto(casa: 1, trasferta: 0),
          ParzialeReferto(casa: 1, trasferta: 1),
        ],
        giocatoriCasa: [
          GiocatoreReferto(
            numeroCalottina: 1,
            nome: 'M. Rossi',
            reti: 2,
            espulsioni: 0,
            atletaId: 'atleta-rossi',
          ),
        ],
        giocatoriTrasferta: [
          GiocatoreReferto(
            numeroCalottina: 4,
            nome: 'Gigi Verdi',
            reti: 1,
            espulsioni: 1,
          ),
        ],
      ),
    ],
    gare: [
      Gara(
        id: 'gara-vecchia',
        clubId: _club,
        data: DateTime(2025, 3, 1),
        nome: 'Trofeo Città',
        luogo: 'Bergamo',
      ),
    ],
    iscrittiGare: const [
      GaraIscritto(
        id: 'iscritto-1',
        garaId: 'gara-vecchia',
        atletaId: 'atleta-bianchi',
        clubId: _club,
      ),
    ],
    tempiGara: [
      TempoGara(
        id: 'tempo-1',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        stile: 'libero',
        distanzaM: 100,
        vascaM: 25,
        tempoS: 65.2,
        data: DateTime(2026, 10, 5),
        note: 'bella gara',
      ),
      TempoGara(
        id: 'tempo-2',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        stile: 'libero',
        distanzaM: 50,
        vascaM: 25,
        tempoS: 30.1,
        data: DateTime(2025, 5, 5),
        garaId: 'gara-vecchia',
      ),
    ],
    personalBest: [
      const PersonalBest(
        id: 'pb-1',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        stile: 'rana',
        distanzaM: 100,
        tempoS: 80.55,
      ),
      PersonalBest(
        id: 'pb-2',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        stile: 'libero',
        distanzaM: 50,
        tempoS: 29.9,
        data: DateTime(2026, 9, 30),
      ),
      PersonalBest(
        id: 'pb-3',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        stile: 'dorso',
        distanzaM: 50,
        tempoS: 33.3,
        data: DateTime(2025, 6, 1),
      ),
    ],
    testIngresso: [
      TestIngresso(
        id: 'ingresso-1',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        tipo: 'BVS',
        dataTest: DateTime(2026, 9, 20),
        distanzaTotaleM: 400,
        tempoTotaleS: 360,
        passoMedio100S: 90,
      ),
      TestIngresso(
        id: 'ingresso-vecchio',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        tipo: 'T30',
        dataTest: DateTime(2025, 9, 20),
        distanzaTotaleM: 900,
        tempoTotaleS: 1800,
        passoMedio100S: 200,
      ),
    ],
    tabellePassi: const [
      TabellaPasso(
        id: 'passo-2',
        testId: 'ingresso-1',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        zona: 'B2',
        passo100S: 95.5,
      ),
      TabellaPasso(
        id: 'passo-1',
        testId: 'ingresso-1',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        zona: 'A1',
        passo100S: 110,
        percentualeRiferimento: 80,
      ),
      TabellaPasso(
        id: 'passo-3',
        testId: 'ingresso-vecchio',
        atletaId: 'atleta-bianchi',
        clubId: _club,
        zona: 'A1',
        passo100S: 220,
      ),
    ],
    testClub: const [
      TestClub(
        id: 'test-1',
        clubId: _club,
        nome: 'Sprint 15 m',
        unita: UnitaTest.secondi,
        piuBassoMeglio: true,
        prove: 2,
      ),
    ],
    risultatiTest: [
      RisultatoTest(
        id: 'risultato-1',
        testId: 'test-1',
        atletaId: 'atleta-rossi',
        clubId: _club,
        data: DateTime(2026, 10, 1),
        valori: const [8.9, 8.62],
      ),
      RisultatoTest(
        id: 'risultato-2',
        testId: 'test-1',
        atletaId: 'atleta-rossi',
        clubId: _club,
        data: DateTime(2025, 10, 1),
        valori: const [9.4, 9.2],
      ),
    ],
    rpeSedute: [
      RpeSeduta(
        id: 'rpe-1',
        atletaId: 'atleta-rossi',
        clubId: _club,
        eventoTipo: 'allenamento',
        eventoId: 'allenamento-1',
        data: DateTime(2026, 10, 10),
        rpe: 7,
      ),
      RpeSeduta(
        id: 'rpe-2',
        atletaId: 'atleta-rossi',
        clubId: _club,
        eventoTipo: 'partita',
        eventoId: 'partita-1',
        data: DateTime(2026, 10, 17),
        rpe: 8,
      ),
      RpeSeduta(
        id: 'rpe-3',
        atletaId: 'atleta-rossi',
        clubId: _club,
        eventoTipo: 'allenamento',
        eventoId: 'allenamento-vecchio',
        data: DateTime(2025, 11, 5),
        rpe: 5,
      ),
    ],
    schedeBenessere: conSchede
        ? [
            SchedaBenessere(
              id: 'scheda-1',
              atletaId: 'atleta-rossi',
              clubId: _club,
              data: DateTime(2026, 10, 9),
              dolori: true,
              zoneDolore: const ['spalla'],
              intensitaDolore: 4,
              oreSonno: 7.5,
              compilataIl: DateTime(2026, 10, 9, 7, 30),
              eventoTipo: 'allenamento',
              eventoId: 'allenamento-1',
              qualitaSonno: 4,
              energia: 3,
              muscoli: 2,
              stress: 4,
              umore: 5,
              sintomi: const ['raffreddore'],
            ),
            SchedaBenessere(
              id: 'scheda-2',
              atletaId: 'atleta-rossi',
              clubId: _club,
              data: DateTime(2025, 10, 9),
              dolori: false,
              oreSonno: 8,
              compilataIl: DateTime(2025, 10, 9, 7, 30),
            ),
          ]
        : null,
  );
}

final _adesso = DateTime(2026, 10, 18, 14, 5);
const _stagione2026 = PeriodoDati.stagione(2026);

Uint8List _file(
  DatiClub dati, {
  PeriodoDati periodo = _stagione2026,
  bool conBenessere = true,
}) => fileExcelDatiClub(
  dati,
  nomeClub: 'Canottieri Milano',
  scaricatoDa: 'Marco Rossi (marco@example.com)',
  adesso: _adesso,
  periodo: periodo,
  conBenessere: conBenessere,
);

List<List<CellValue?>> _righe(Excel excel, String foglio) {
  final tabella = excel.tables[foglio];
  if (tabella == null) fail('Il foglio "$foglio" non c\'è');
  return [
    for (final riga in tabella.rows) [for (final cella in riga) cella?.value],
  ];
}

String _testo(CellValue? valore) => valore == null ? '' : valore.toString();

/// Il numero di una cella: leggendo il file un 90,0 torna intero.
num? _numero(CellValue? valore) => switch (valore) {
  IntCellValue() => valore.value,
  DoubleCellValue() => valore.value,
  _ => null,
};

/// I titoli del foglio e, per ogni riga, i valori per titolo.
List<Map<String, CellValue?>> _perTitolo(Excel excel, String foglio) {
  final righe = _righe(excel, foglio);
  final titoli = [for (final t in righe.first) _testo(t)];
  return [
    for (final riga in righe.skip(1))
      {for (var c = 0; c < titoli.length; c++) titoli[c]: riga[c]},
  ];
}

void main() {
  group('nomeFileDatiClub', () {
    test('nome del club e giorno', () {
      expect(
        nomeFileDatiClub('Canottieri Milano', DateTime(2026, 10, 18)),
        'WaterTactics Canottieri Milano 18-10-2026.xlsx',
      );
    });

    test('toglie i caratteri che un file non può avere', () {
      expect(
        nomeFileDatiClub('A/B: "C"?  <D>|*', DateTime(2026, 1, 5)),
        'WaterTactics AB C D 05-01-2026.xlsx',
      );
    });

    test('senza nome del club niente spazi in più', () {
      expect(
        nomeFileDatiClub('  ', DateTime(2026, 10, 18)),
        'WaterTactics 18-10-2026.xlsx',
      );
    });
  });

  group('fileExcelDatiClub', () {
    test('i fogli di una stagione, nell\'ordine, senza quelli vuoti', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      expect(excel.tables.keys.toList(), [
        'Leggimi',
        'Atleti',
        'Squadre',
        'Allenatori',
        'Stagioni',
        'Allenamenti',
        'Serie',
        'Presenze',
        'Secco',
        'Secco fatto',
        'Esercizi a secco',
        'Partite',
        'Convocati',
        'Statistiche partite',
        'Referti',
        'Tempi gara',
        'Personal best',
        'Test del passo',
        'Passi per zona',
        'Test del club',
        'Sforzo (RPE)',
        'Benessere',
      ]);
      for (final nome in excel.tables.keys) {
        expect(nome.length, lessThanOrEqualTo(31));
        expect(nome, isNot(matches(r'[\[\]:*?/\\]')));
      }
    });

    test('con "Tutto" ci sono anche le gare dell\'anno prima', () {
      final excel = Excel.decodeBytes(
        _file(_dati(), periodo: const PeriodoDati.tutto()),
      );
      expect(
        excel.tables.keys,
        containsAllInOrder([
          'Statistiche partite',
          'Referti',
          'Gare',
          'Iscrizioni gare',
          'Tempi gara',
          'Personal best',
        ]),
      );
      final gare = _perTitolo(excel, 'Gare');
      expect(gare, hasLength(1));
      expect(_testo(gare.single['Gara']), 'Trofeo Città');
      expect(_testo(gare.single['Squadra']), 'Tutto il club');
      expect(gare.single['Iscritti'], const IntCellValue(1));
      final iscrizioni = _perTitolo(excel, 'Iscrizioni gare');
      expect(_testo(iscrizioni.single['Cognome']), 'Bianchi');
      expect(_testo(iscrizioni.single['Gara']), 'Trofeo Città');
    });

    test('con dati vuoti restano i soli quattro fogli sempre presenti', () {
      final excel = Excel.decodeBytes(
        _file(const DatiClub(), conBenessere: false),
      );
      expect(excel.tables.keys.toList(), [
        'Leggimi',
        'Atleti',
        'Squadre',
        'Allenatori',
      ]);
      // Hanno i titoli anche senza righe.
      expect(_righe(excel, 'Atleti'), hasLength(1));
      expect(_testo(_righe(excel, 'Atleti').first.first), 'Cognome');
      expect(_righe(excel, 'Squadre').first, hasLength(4));
    });

    test('Leggimi: chi, quando, periodo e cosa c\'è in ogni foglio', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final righe = _righe(excel, 'Leggimi');
      String cosa(String etichetta) =>
          _testo(righe.firstWhere((r) => _testo(r.first) == etichetta)[1]);

      expect(cosa('Club'), 'Canottieri Milano');
      expect(cosa('Scaricato il'), '18/10/2026 14:05');
      expect(cosa('Da'), 'Marco Rossi (marco@example.com)');
      expect(
        cosa('Periodo'),
        'Stagione 2026-2027 (dal 01/09/2026 al 31/08/2027)',
      );
      expect(cosa('Benessere e dolori'), 'inclusi');

      final testi = [for (final r in righe) _testo(r.first)];
      expect(
        testi,
        contains(
          'Contiene dati personali di atleti, anche minorenni: conservalo con '
          'cura e non mandarlo in giro.',
        ),
      );
      expect(
        testi,
        contains(
          'Non sono nel file: video e note sui video, lavagne tattiche, '
          'notifiche, codici d\'invito, libreria dei blocchi (ha il suo '
          '«Esporta in Excel»).',
        ),
      );

      // La tabella "Foglio | Cosa c'è | Righe" elenca tutti i fogli, anche
      // quelli lasciati fuori perché vuoti.
      final intestazione = righe.indexWhere((r) => _testo(r.first) == 'Foglio');
      expect(
        [for (final c in righe[intestazione].take(3)) _testo(c)],
        ['Foglio', "Cosa c'è", 'Righe'],
      );
      final tabella = {
        for (final r in righe.skip(intestazione + 1))
          if (_testo(r.first).isNotEmpty && _testo(r[1]).isNotEmpty)
            _testo(r.first): r[2],
      };
      expect(tabella['Atleti'], const IntCellValue(3));
      expect(tabella['Allenamenti'], const IntCellValue(2));
      expect(tabella['Serie'], const IntCellValue(2));
      expect(tabella['Presenze'], const IntCellValue(2));
      expect(tabella['Gare'], TextCellValue('nessuno, foglio non incluso'));
      expect(
        tabella['Iscrizioni gare'],
        TextCellValue('nessuno, foglio non incluso'),
      );
      expect(tabella.keys, containsAll(['Squadre', 'Allenatori', 'Benessere']));
      expect(tabella['Benessere'], const IntCellValue(1));
    });

    test('Leggimi dice cosa manca quando i fogli sono vuoti', () {
      final excel = Excel.decodeBytes(
        _file(const DatiClub(), conBenessere: false),
      );
      final righe = _righe(excel, 'Leggimi');
      final tabella = {
        for (final r in righe)
          if (_testo(r.first).isNotEmpty && r.length > 2 && r[2] != null)
            _testo(r.first): _testo(r[2]),
      };
      expect(tabella['Serie'], 'nessuno, foglio non incluso');
      expect(tabella['Partite'], 'nessuno, foglio non incluso');
      expect(tabella['Benessere'], 'non richiesto');
      expect(tabella['Atleti'], '0');
      expect(
        righe.firstWhere((r) => _testo(r.first) == 'Benessere e dolori')[1],
        TextCellValue('non inclusi'),
      );
    });

    test('Atleti: tutti, anche chi non è attivo, in ordine di cognome', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final atleti = _perTitolo(excel, 'Atleti');
      expect(
        [for (final a in atleti) _testo(a['Cognome'])],
        ['Bianchi', 'Rossi', 'Verdi'],
      );
      final rossi = atleti[1];
      expect(_testo(rossi['Nome']), 'Mario');
      expect(_testo(rossi['Squadra']), 'Under 14');
      expect(_testo(rossi['Seconda squadra']), 'Assoluti');
      expect(_testo(rossi['Giorni nella seconda squadra']), 'mar, gio');
      expect(_testo(rossi['Ruolo']), 'Portiere');
      expect(_testo(rossi['Sport']), 'Pallanuoto');
      expect(_testo(rossi['Consenso privacy']), 'Sì');
      expect(_testo(rossi['Attivo']), 'Sì');
      expect(_testo(rossi['Account nell\'app']), 'No');
      expect(_testo(rossi['Tessera FIN']), '12345');
      expect(_testo(rossi['Telefono genitore']), '333 1234567');
      expect(_testo(atleti[0]['Account nell\'app']), 'Sì');
      expect(_testo(atleti[2]['Attivo']), 'No');
      expect(_testo(atleti[2]['Consenso privacy']), 'No');
      expect(atleti[2]['Data consenso'], isNull);
    });

    test('le date sono date vere, non testo né numeri', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final rossi = _perTitolo(excel, 'Atleti')[1];
      final nascita = rossi['Data di nascita'];
      expect(nascita, isA<DateCellValue>());
      expect(
        (nascita! as DateCellValue).asDateTimeLocal(),
        DateTime(2012, 3, 12),
      );
      expect(rossi['Visita medica fino al'], isA<DateCellValue>());
      final allenamenti = _perTitolo(excel, 'Allenamenti');
      expect(allenamenti.first['Data'], isA<DateCellValue>());
      expect(
        (allenamenti.first['Data']! as DateCellValue).asDateTimeLocal(),
        DateTime(2026, 10, 10),
      );
      // Anche un orario preciso è una data con l'ora.
      expect(
        _perTitolo(excel, 'Secco fatto').single['Fatta il'],
        isA<DateTimeCellValue>(),
      );
    });

    test('le date hanno il formato giorno/mese/anno nel file', () {
      final bytes = _file(_dati());
      final zip = ZipDecoder().decodeBytes(bytes);
      String contenuto(String nome) => utf8.decode(
        zip.files.firstWhere((f) => f.name == nome).content as List<int>,
      );
      final stili = contenuto('xl/styles.xml');

      final formato = RegExp(
        r'<numFmt numFmtId="(\d+)" formatCode="dd/mm/yyyy"/>',
      ).firstMatch(stili);
      expect(formato, isNotNull, reason: stili);
      expect(
        stili,
        contains(
          RegExp(r'<numFmt numFmtId="\d+" formatCode="dd/mm/yyyy hh:mm"/>'),
        ),
      );
      final idFormato = formato!.group(1)!;

      // Lo stile numero k di cellXfs usa quel formato...
      final xfs = RegExp(r'<xf [^>]*numFmtId="(\d+)"[^>]*?/?>')
          .allMatches(stili.substring(stili.indexOf('<cellXfs')))
          .map((m) => m.group(1))
          .toList();
      final stileData = xfs.indexOf(idFormato);
      expect(stileData, greaterThan(0));

      // ...e almeno un foglio ha celle con quello stile (le date).
      final fogli = zip.files.where(
        (f) => RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(f.name),
      );
      final usato = fogli.any(
        (f) => contenuto(f.name).contains('s="$stileData"><v>'),
      );
      expect(usato, isTrue);
    });

    test('i numeri sono numeri', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final serie = _perTitolo(excel, 'Serie');
      expect(serie.first['N°'], const IntCellValue(1));
      expect(serie.first['Ripetute'], const IntCellValue(4));
      expect(serie.first['Distanza (m)'], const IntCellValue(100));
      expect(serie.first['Recupero (s)'], const IntCellValue(20));
      final tempi = _perTitolo(excel, 'Tempi gara');
      expect(tempi.single['Secondi'], const DoubleCellValue(65.2));
      expect(tempi.single['Distanza (m)'], const IntCellValue(100));
      final test = _perTitolo(excel, 'Test del club').single;
      expect(test['Prova 1'], const DoubleCellValue(8.9));
      expect(test['Valore in classifica'], const DoubleCellValue(8.62));
      final squadre = _perTitolo(excel, 'Squadre');
      expect(squadre.first['Atleti'], const IntCellValue(1));
    });

    test('Squadre e Allenatori: i nomi, non gli id', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final squadre = _perTitolo(excel, 'Squadre');
      expect(_testo(squadre[0]['Squadra']), 'Under 14');
      expect(_testo(squadre[0]['Sport']), 'Pallanuoto');
      expect(_testo(squadre[0]['Capo allenatore']), 'Luca Bianchi');
      expect(_testo(squadre[1]['Capo allenatore']), '');
      // Verdi non è attivo: Under 14 ha un solo atleta.
      expect(squadre[0]['Atleti'], const IntCellValue(1));

      final allenatori = _perTitolo(excel, 'Allenatori');
      expect(_testo(allenatori[0]['Nome']), 'Marco Rossi');
      expect(_testo(allenatori[0]['Ruolo']), 'Responsabile');
      expect(_testo(allenatori[0]['Email']), 'marco@example.com');
      expect(_testo(allenatori[0]['Capo di']), '');
      expect(_testo(allenatori[1]['Ruolo']), 'Allenatore');
      expect(_testo(allenatori[1]['Capo di']), 'Under 14');
    });

    test('Stagioni: tutte, con le fasi scritte', () {
      final excel = Excel.decodeBytes(
        _file(_dati(), periodo: const PeriodoDati.stagione(2020)),
      );
      final stagione = _perTitolo(excel, 'Stagioni').single;
      expect(_testo(stagione['Squadra']), 'Under 14');
      expect(_testo(stagione['Campionato']), 'Serie C');
      expect(stagione['Dal'], isA<DateCellValue>());
      expect(
        _testo(stagione['Fasi']),
        'Preparazione 01/09/2026-31/10/2026 (12000 m a settimana)',
      );
    });

    test(
      'il periodo toglie gli allenamenti di un\'altra stagione e i loro figli',
      () {
        final excel = Excel.decodeBytes(_file(_dati()));
        final allenamenti = _perTitolo(excel, 'Allenamenti');
        expect(
          [for (final a in allenamenti) _testo(a['Titolo'])],
          ['Resistenza', 'Seduta a secco'],
        );
        final serie = _perTitolo(excel, 'Serie');
        expect(serie, hasLength(2));
        expect(
          {for (final s in serie) _testo(s['Allenamento'])},
          {'Resistenza'},
        );
        final presenze = _perTitolo(excel, 'Presenze');
        expect(presenze, hasLength(2));
        expect(
          {for (final p in presenze) _testo(p['Allenamento'])},
          {'Resistenza'},
        );
        // L'allenamento dell'anno prima non compare da nessuna parte.
        expect(
          excel.tables.values
              .expand((t) => t.rows)
              .expand((r) => r)
              .any((c) => c?.value.toString() == 'Vecchio'),
          isFalse,
        );
        final tutto = Excel.decodeBytes(
          _file(_dati(), periodo: const PeriodoDati.tutto()),
        );
        expect(_perTitolo(tutto, 'Allenamenti'), hasLength(3));
        expect(_perTitolo(tutto, 'Serie'), hasLength(3));
        expect(_perTitolo(tutto, 'Presenze'), hasLength(3));
      },
    );

    test('il periodo vale anche per tempi, primati, test e sforzo', () {
      final stagione = Excel.decodeBytes(_file(_dati()));
      expect(_perTitolo(stagione, 'Tempi gara'), hasLength(1));
      // Il primato senza data c'è solo in "Tutto"; quello dell'anno prima no.
      final primati = _perTitolo(stagione, 'Personal best');
      expect(primati, hasLength(1));
      expect(_testo(primati.single['Stile']), 'Libero');
      expect(_perTitolo(stagione, 'Test del passo'), hasLength(1));
      expect(_perTitolo(stagione, 'Passi per zona'), hasLength(2));
      expect(_perTitolo(stagione, 'Test del club'), hasLength(1));
      expect(_perTitolo(stagione, 'Sforzo (RPE)'), hasLength(2));
      expect(_perTitolo(stagione, 'Benessere'), hasLength(1));

      final tutto = Excel.decodeBytes(
        _file(_dati(), periodo: const PeriodoDati.tutto()),
      );
      expect(_perTitolo(tutto, 'Tempi gara'), hasLength(2));
      expect(_perTitolo(tutto, 'Personal best'), hasLength(3));
      expect(_perTitolo(tutto, 'Test del passo'), hasLength(2));
      expect(_perTitolo(tutto, 'Passi per zona'), hasLength(3));
      expect(_perTitolo(tutto, 'Test del club'), hasLength(2));
      expect(_perTitolo(tutto, 'Sforzo (RPE)'), hasLength(3));
      expect(_perTitolo(tutto, 'Benessere'), hasLength(2));
    });

    test('Allenamenti: metri, durata e presenze', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final acqua = _perTitolo(excel, 'Allenamenti')[0];
      expect(_testo(acqua['Squadra']), 'Under 14');
      expect(_testo(acqua['Tipo']), 'Acqua');
      // I metri del gruppo: i 4×100 di tutti, non i tiri dei portieri.
      expect(acqua['Metri'], const IntCellValue(400));
      expect(acqua['Durata (min)'], isA<IntCellValue>());
      expect(acqua['Presenti'], const IntCellValue(1));
      expect(acqua['Assenti'], const IntCellValue(1));
      expect(acqua['Giustificati'], const IntCellValue(0));
      expect(_testo(acqua['Note']), 'Bella seduta');

      final secco = _perTitolo(excel, 'Allenamenti')[1];
      expect(_testo(secco['Tipo']), 'Secco');
      expect(_testo(secco['Squadra']), 'Assoluti');
      expect(secco['Metri'], isNull);
      expect(secco['Durata (min)'], const IntCellValue(40));
    });

    test('chi è in ritardo è tra i presenti, e ha la sua colonna', () {
      Presenza presenza(String id, String stato) => Presenza(
        id: 'presenza-$id',
        allenamentoId: 'allenamento-1',
        atletaId: 'atleta-$id',
        clubId: _club,
        stato: stato,
      );
      final dati = DatiClub(
        allenamenti: [
          Allenamento(
            id: 'allenamento-1',
            clubId: _club,
            data: DateTime(2026, 10, 10),
            titolo: 'Resistenza',
          ),
        ],
        presenze: [
          presenza('a', 'presente'),
          presenza('b', 'ritardo'),
          presenza('c', 'assente'),
        ],
        squadre: const [
          Gruppo(id: 'gruppo-1', clubId: _club, nome: 'Under 14', ordine: 1),
        ],
      );
      final excel = Excel.decodeBytes(_file(dati));
      final riga = _perTitolo(excel, 'Allenamenti').single;
      expect(riga['Presenti'], const IntCellValue(2));
      expect(riga['Di cui in ritardo'], const IntCellValue(1));
      expect(riga['Assenti'], const IntCellValue(1));
      expect([
        for (final p in _perTitolo(excel, 'Presenze')) _testo(p['Stato']),
      ], containsAll(['Presente', 'In ritardo', 'Assente']));
    });

    test('Com\'è andata: metri fatti per allenamento e serie «In parte»', () {
      Serie serie(
        String id,
        String allenamentoId, {
        required int ripetute,
        required int distanzaM,
        String? esito,
        int? metriFatti,
      }) => Serie(
        id: id,
        allenamentoId: allenamentoId,
        clubId: _club,
        ordine: int.parse(id.substring(1)),
        blocco: 'principale',
        ripetute: ripetute,
        distanzaM: distanzaM,
        stile: 'libero',
        esecuzione: 'nuoto',
        esito: esito,
        metriFatti: metriFatti,
      );
      final dati = DatiClub(
        allenamenti: [
          Allenamento(id: 'fatto', clubId: _club, data: DateTime(2026, 10, 10)),
          // Dopo il giorno in cui si scarica: niente metri fatti.
          Allenamento(
            id: 'domani',
            clubId: _club,
            data: DateTime(2026, 10, 19),
          ),
        ],
        serie: [
          serie(
            's1',
            'fatto',
            ripetute: 10,
            distanzaM: 100,
            esito: 'fatta',
            metriFatti: 600,
          ),
          serie('s2', 'fatto', ripetute: 4, distanzaM: 200, esito: 'saltata'),
          serie('s3', 'fatto', ripetute: 1, distanzaM: 400),
          serie('s4', 'domani', ripetute: 1, distanzaM: 500),
        ],
      );
      final excel = Excel.decodeBytes(_file(dati));
      final allenamenti = _perTitolo(excel, 'Allenamenti');
      expect(allenamenti[0]['Metri'], const IntCellValue(1000 + 800 + 400));
      expect(allenamenti[0]['Metri fatti'], const IntCellValue(600 + 400));
      expect(allenamenti[1]['Metri'], const IntCellValue(500));
      expect(allenamenti[1]['Metri fatti'], isNull);

      final righe = _perTitolo(excel, 'Serie');
      expect(_testo(righe[0]['Esito']), 'In parte');
      expect(righe[0]['Metri fatti'], const IntCellValue(600));
      expect(righe[0]['Secondi fatti'], isNull);
      expect(_testo(righe[1]['Esito']), 'Saltata');
      expect(righe[1]['Metri fatti'], isNull);
      expect(righe[2]['Esito'], isNull);
    });

    test('Serie: stesse diciture dell\'app e per chi sono', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final serie = _perTitolo(excel, 'Serie');
      final prima = serie[0];
      expect(_testo(prima['Squadra']), 'Under 14');
      expect(_testo(prima['Blocco']), 'Riscaldamento');
      expect(_testo(prima['Stile']), 'Libero');
      expect(_testo(prima['Esecuzione']), 'Nuoto');
      expect(_testo(prima['Zona']), 'A1');
      expect(_testo(prima['Passo']), '1:32,50');
      expect(_testo(prima['Per chi']), 'Tutti');
      expect(prima['Esito'], isNull);
      final seconda = serie[1];
      expect(_testo(seconda['Esecuzione']), 'Tiri');
      // Nei tiri lo stile non conta.
      expect(seconda['Stile'], isNull);
      expect(_testo(seconda['Per chi']), 'Portieri');
      expect(_testo(seconda['Esito']), 'Fatta');
      expect(_testo(seconda['Note']), 'solo portieri');
    });

    test('Presenze: cognome e nome, stato leggibile', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final presenze = _perTitolo(excel, 'Presenze');
      expect(_testo(presenze[0]['Cognome']), 'Bianchi');
      expect(_testo(presenze[0]['Nome']), 'Anna');
      expect(_testo(presenze[0]['Stato']), 'Assente');
      expect(_testo(presenze[0]['Note']), 'influenza');
      expect(_testo(presenze[1]['Cognome']), 'Rossi');
      expect(_testo(presenze[1]['Stato']), 'Presente');
    });

    test('Secco, Secco fatto ed Esercizi a secco', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final secco = _perTitolo(excel, 'Secco');
      expect(secco, hasLength(2));
      expect(_testo(secco[0]['Esercizio']), 'Rotazioni esterne');
      expect(_testo(secco[0]['Categoria']), 'Spalla');
      expect(secco[0]['Serie'], const IntCellValue(3));
      expect(secco[0]['Ripetizioni'], const IntCellValue(12));
      expect(_testo(secco[0]['Carico']), 'elastico rosso');
      expect(secco[1]['Durata (s)'], const IntCellValue(30));

      final fatto = _perTitolo(excel, 'Secco fatto').single;
      expect(_testo(fatto['Cognome']), 'Bianchi');
      expect(_testo(fatto['Esercizio']), 'Rotazioni esterne');
      expect(fatto['Serie n°'], const IntCellValue(1));

      final catalogo = _perTitolo(excel, 'Esercizi a secco');
      expect(catalogo, hasLength(2));
      // In ordine di categoria: la spalla prima del core.
      expect(_testo(catalogo[0]['Esercizio']), 'Rotazioni esterne');
      expect(_testo(catalogo[0]['Archiviato']), 'No');
      expect(
        _testo(catalogo[0]['Video']),
        'https://www.youtube.com/watch?v=abc123&t=12s',
      );
      expect(_testo(catalogo[1]['Esercizio']), 'Plank');
      expect(_testo(catalogo[1]['Si misura a']), 'A tempo');
      expect(_testo(catalogo[1]['Archiviato']), 'Sì');
    });

    test('Partite, Convocati e Statistiche partite', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final partita = _perTitolo(excel, 'Partite').single;
      expect(_testo(partita['Squadra']), 'Under 14');
      expect(_testo(partita['Casa']), 'Canottieri Milano');
      expect(_testo(partita['Trasferta']), 'Pro Recco');
      expect(_testo(partita['Risultato']), '2-1');
      expect(_testo(partita['Importanza']), 'Alta');
      expect(_testo(partita['Ora']), '15:30');
      expect(partita['Convocati'], const IntCellValue(2));

      final convocati = _perTitolo(excel, 'Convocati');
      expect(convocati, hasLength(2));
      // In ordine di calottina.
      expect(convocati[0]['Calottina'], const IntCellValue(1));
      expect(_testo(convocati[0]['Partita']), 'Canottieri Milano – Pro Recco');
      expect(_testo(convocati[0]['Cognome']), 'Rossi');
      expect(_testo(convocati[0]['Capitano']), 'Sì');
      expect(_testo(convocati[0]['Portiere']), 'Sì');
      expect(_testo(convocati[1]['Cognome']), 'Bianchi');
      expect(_testo(convocati[1]['Fuoriquota']), 'Sì');
      expect(_testo(convocati[1]['Vice capitano']), 'Sì');

      final statistiche = _perTitolo(excel, 'Statistiche partite');
      expect(
        [for (final s in statistiche) _testo(s['Cognome'])],
        ['Bianchi', 'Rossi'],
      );
      final rossi = statistiche[1];
      expect(rossi['Tiri'], const IntCellValue(2));
      expect(rossi['Gol'], const IntCellValue(2));
      expect(rossi['Gol su azione'], const IntCellValue(1));
      expect(rossi['Gol su rigore'], const IntCellValue(1));
      expect(statistiche[0]['Tiri'], const IntCellValue(1));
      expect(statistiche[0]['Gol'], const IntCellValue(0));
    });

    test('il risultato senza eventi viene dal referto', () {
      final base = _dati();
      final dati = DatiClub(
        squadre: base.squadre,
        partite: base.partite,
        referti: base.referti,
      );
      final excel = Excel.decodeBytes(_file(dati));
      expect(_testo(_perTitolo(excel, 'Partite').single['Risultato']), '2-1');
      expect(excel.tables.keys, isNot(contains('Statistiche partite')));
    });

    test('Referti: una riga per giocatore', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final referti = _perTitolo(excel, 'Referti');
      expect(referti, hasLength(2));
      expect(_testo(referti[0]['Risultato']), '2-1');
      expect(_testo(referti[0]['Parziali']), '1-0, 1-1');
      expect(_testo(referti[0]['Squadra']), 'Canottieri Milano');
      expect(_testo(referti[0]['Atleta del club']), 'Rossi Mario');
      expect(referti[0]['Reti'], const IntCellValue(2));
      expect(_testo(referti[1]['Squadra']), 'Pro Recco');
      expect(_testo(referti[1]['Giocatore']), 'Gigi Verdi');
      expect(referti[1]['Atleta del club'], isNull);
    });

    test('nuoto: i tempi sono testo leggibile e secondi', () {
      final excel = Excel.decodeBytes(
        _file(_dati(), periodo: const PeriodoDati.tutto()),
      );
      final tempi = _perTitolo(excel, 'Tempi gara');
      // Dal più vecchio.
      expect(_testo(tempi[0]['Gara']), 'Trofeo Città');
      expect(_testo(tempi[0]['Tempo']), '30,10');
      expect(tempi[0]['Secondi'], const DoubleCellValue(30.1));
      expect(_testo(tempi[1]['Tempo']), '1:05,20');
      expect(tempi[1]['Secondi'], const DoubleCellValue(65.2));
      expect(_testo(tempi[1]['Cognome']), 'Bianchi');
      expect(_testo(tempi[1]['Stile']), 'Libero');
      expect(tempi[1]['Vasca (m)'], const IntCellValue(25));

      final primati = _perTitolo(excel, 'Personal best');
      expect(primati, hasLength(3));
      // Senza data: la colonna è vuota.
      final rana = primati.firstWhere((p) => _testo(p['Stile']) == 'Rana');
      expect(rana['Data'], isNull);
      expect(_testo(rana['Tempo']), '1:20,55');

      final test = _perTitolo(excel, 'Test del passo');
      expect(_testo(test[0]['Test']), 'T30');
      expect(_testo(test[1]['Passo medio 100 m']), '1:30,00');
      expect(_numero(test[1]['Passo medio 100 m (secondi)']), 90);

      final passi = _perTitolo(excel, 'Passi per zona');
      expect(passi, hasLength(3));
      expect(_testo(passi[1]['Zona']), 'A1');
      expect(_testo(passi[1]['Passo 100 m']), '1:50,00');
      expect(_numero(passi[1]['% di riferimento']), 80);
      expect(_testo(passi[2]['Zona']), 'B2');
    });

    test('Test del club: prove, valore in classifica e unità', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final risultato = _perTitolo(excel, 'Test del club').single;
      expect(_testo(risultato['Test']), 'Sprint 15 m');
      expect(_testo(risultato['Cognome']), 'Rossi');
      expect(risultato['Prova 1'], const DoubleCellValue(8.9));
      expect(risultato['Prova 2'], const DoubleCellValue(8.62));
      expect(risultato['Valore in classifica'], const DoubleCellValue(8.62));
      expect(_testo(risultato['Unità']), 's');
      expect(_testo(risultato['Come si calcola']), 'Migliore di 2 prove');
    });

    test('Sforzo (RPE): seduta leggibile, minuti e carico', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final sforzo = _perTitolo(excel, 'Sforzo (RPE)');
      expect(sforzo, hasLength(2));
      expect(_testo(sforzo[0]['Cognome']), 'Rossi');
      expect(_testo(sforzo[0]['Seduta']), 'Allenamento: Resistenza');
      expect(sforzo[0]['RPE'], const IntCellValue(7));
      final minuti = (sforzo[0]['Minuti']! as IntCellValue).value;
      expect(minuti, greaterThan(0));
      expect(sforzo[0]['Carico (RPE × minuti)'], IntCellValue(7 * minuti));
      expect(
        _testo(sforzo[1]['Seduta']),
        'Partita: Canottieri Milano – Pro Recco',
      );
      expect(sforzo[1]['Minuti'], const IntCellValue(60));
      expect(sforzo[1]['Carico (RPE × minuti)'], const IntCellValue(480));
    });

    test('Benessere con tutti i campi della scheda', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final scheda = _perTitolo(excel, 'Benessere').single;
      expect(_testo(scheda['Cognome']), 'Rossi');
      expect(_testo(scheda['Prima di']), 'Allenamento: Resistenza');
      expect(scheda['Ore di sonno'], const DoubleCellValue(7.5));
      expect(scheda['Come ha dormito (1-5)'], const IntCellValue(4));
      expect(scheda['Energia (1-5)'], const IntCellValue(3));
      expect(scheda['Muscoli (1-5)'], const IntCellValue(2));
      expect(scheda['Stress (1-5)'], const IntCellValue(4));
      expect(scheda['Umore (1-5)'], const IntCellValue(5));
      expect(_testo(scheda['Dolori']), 'Sì');
      expect(_testo(scheda['Zone del dolore']), 'Spalla');
      expect(scheda['Intensità del dolore (1-10)'], const IntCellValue(4));
      expect(_testo(scheda['Sintomi']), 'Raffreddore / tosse');
      expect(scheda['Compilata il'], isA<DateTimeCellValue>());
    });

    test('Benessere solo se richiesto', () {
      // Le schede ci sono in dati, ma il responsabile non le ha chieste.
      final senza = Excel.decodeBytes(_file(_dati(), conBenessere: false));
      expect(senza.tables.keys, isNot(contains('Benessere')));
      final testi = senza.tables.values
          .expand((t) => t.rows)
          .expand((r) => r)
          .map((c) => c?.value.toString() ?? '')
          .toList();
      expect(testi, isNot(contains('Raffreddore / tosse')));
      expect(testi, isNot(contains('Zone del dolore')));
      expect(testi, isNot(contains('Come ha dormito (1-5)')));
      final leggimi = _righe(senza, 'Leggimi');
      expect(
        leggimi.firstWhere((r) => _testo(r.first) == 'Benessere e dolori')[1],
        TextCellValue('non inclusi'),
      );
      final riga = leggimi.firstWhere((r) => _testo(r.first) == 'Benessere');
      expect(riga[2], TextCellValue('non richiesto'));

      // Chiesto ma senza schede: nessun foglio, scritto in Leggimi.
      final vuoto = Excel.decodeBytes(
        _file(
          _dati(conSchede: false),
          periodo: const PeriodoDati.stagione(2020),
        ),
      );
      expect(vuoto.tables.keys, isNot(contains('Benessere')));
      final rigaVuota = _righe(
        vuoto,
        'Leggimi',
      ).firstWhere((r) => _testo(r.first) == 'Benessere');
      expect(rigaVuota[2], TextCellValue('nessuno, foglio non incluso'));

      final con = Excel.decodeBytes(_file(_dati()));
      expect(con.tables.keys, contains('Benessere'));
    });

    test('un testo che comincia con "=" resta testo', () {
      final excel = Excel.decodeBytes(_file(_dati()));
      final bianchi = _perTitolo(excel, 'Atleti').first;
      expect(bianchi['Note'], isA<TextCellValue>());
      expect(_testo(bianchi['Note']), '=SOMMA(1)');
      // Nel file non c'è nessuna formula.
      final zip = ZipDecoder().decodeBytes(_file(_dati()));
      for (final f in zip.files.where(
        (f) => f.name.contains('worksheets/sheet'),
      )) {
        expect(utf8.decode(f.content as List<int>), isNot(contains('<f>')));
      }
    });

    test('i caratteri di controllo non rovinano il file', () {
      final base = _dati();
      final dati = DatiClub(
        atleti: [_atleta('atleta-x', 'Neri', 'Luigi', note: 'a\u0001b\u000Bc')],
        squadre: base.squadre,
      );
      final excel = Excel.decodeBytes(_file(dati));
      expect(_testo(_perTitolo(excel, 'Atleti').single['Note']), 'abc');
    });

    test('righe che puntano a ciò che non c\'è più: "(eliminato)"', () {
      final dati = DatiClub(
        allenamenti: [
          Allenamento(
            id: 'allenamento-1',
            clubId: _club,
            data: DateTime(2026, 10, 10),
            titolo: 'Resistenza',
            gruppoId: 'gruppo-sparito',
          ),
        ],
        presenze: const [
          Presenza(
            id: 'presenza-1',
            allenamentoId: 'allenamento-1',
            atletaId: 'atleta-sparito',
            clubId: _club,
            stato: 'giustificato',
          ),
        ],
        serie: const [
          Serie(
            id: 'serie-1',
            allenamentoId: 'allenamento-1',
            clubId: _club,
            ordine: 1,
            blocco: 'principale',
            ripetute: 2,
            distanzaM: 50,
            stile: 'libero',
            esecuzione: 'nuoto',
            destinatari: Destinatari.solo(['atleta-sparito']),
          ),
        ],
        rpeSedute: [
          RpeSeduta(
            id: 'rpe-1',
            atletaId: 'atleta-sparito',
            clubId: _club,
            eventoTipo: 'partita',
            eventoId: 'partita-sparita',
            data: DateTime(2026, 10, 11),
            rpe: 6,
          ),
        ],
        squadreConCapo: const [
          SquadraConCapo(id: 'gruppo-1', nome: 'Under 14', capoUserId: 'chi?'),
        ],
        squadre: const [
          Gruppo(id: 'gruppo-1', clubId: _club, nome: 'Under 14', ordine: 1),
        ],
      );
      final excel = Excel.decodeBytes(_file(dati));
      expect(
        _testo(_perTitolo(excel, 'Allenamenti').single['Squadra']),
        '(eliminato)',
      );
      final presenza = _perTitolo(excel, 'Presenze').single;
      expect(_testo(presenza['Cognome']), '(eliminato)');
      expect(_testo(presenza['Stato']), 'Giustificato');
      expect(
        _testo(_perTitolo(excel, 'Serie').single['Per chi']),
        'atleti non più nel gruppo',
      );
      final sforzo = _perTitolo(excel, 'Sforzo (RPE)').single;
      expect(_testo(sforzo['Cognome']), '(eliminato)');
      expect(_testo(sforzo['Seduta']), 'Partita: (eliminato)');
      expect(sforzo['Minuti'], isNull);
      expect(
        _testo(_perTitolo(excel, 'Squadre').single['Capo allenatore']),
        '(eliminato)',
      );
    });

    test('nessun id interno finisce nel file', () {
      final excel = Excel.decodeBytes(
        _file(_dati(), periodo: const PeriodoDati.tutto()),
      );
      final ids = RegExp(
        r'(atleta|gruppo|allenamento|serie|presenza|partita|evento|gara|'
        r'tempo|pb|ingresso|passo|test|risultato|rpe|scheda|esercizio|riga|'
        r'fatta|distinta|iscritto|referto|utente|stagione)-',
      );
      for (final MapEntry(key: nome, value: tabella) in excel.tables.entries) {
        for (final riga in tabella.rows) {
          for (final cella in riga) {
            final testo = cella?.value.toString() ?? '';
            expect(
              ids.hasMatch(testo),
              isFalse,
              reason: 'Nel foglio $nome: "$testo"',
            );
          }
        }
      }
    });

    test('ogni riga ha tante celle quanti sono i titoli', () {
      final excel = Excel.decodeBytes(
        _file(_dati(), periodo: const PeriodoDati.tutto()),
      );
      for (final MapEntry(key: nome, value: tabella) in excel.tables.entries) {
        if (nome == 'Leggimi') continue;
        final titoli = tabella.rows.first.length;
        for (final riga in tabella.rows) {
          expect(riga, hasLength(titoli), reason: nome);
        }
        // I titoli sono tutti scritti e in grassetto.
        for (final cella in tabella.rows.first) {
          expect(cella?.value, isA<TextCellValue>(), reason: nome);
          expect(cella?.cellStyle?.isBold, isTrue, reason: nome);
        }
      }
    });
  });
}
