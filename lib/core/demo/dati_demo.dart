import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../utils/giorni.dart';

/// Dati finti per la modalita' demo: un club gia' pronto con gruppi,
/// atleti, allenamenti, presenze, stagione, gare (nuoto) o partite
/// (pallanuoto). Nomi volutamente lunghi, per far emergere i problemi di
/// impaginazione sugli schermi stretti.
///
/// Lo sport si sceglie con `DEMO_SPORT=nuoto|pallanuoto` nel `.env`.
/// Si inserisce solo se la cache locale non ha ancora nessun club: un
/// club creato a mano in demo non viene toccato.
Future<void> inserisciDatiDemo(AppDatabase db) async {
  // Quando i dati demo cambiano forma si riparte da zero una volta:
  // senza, una cache gia' popolata con la versione precedente resterebbe
  // (es. atleti divisi su due gruppi, schede senza oggi).
  final prefs = await SharedPreferences.getInstance();
  if ((prefs.getInt(_chiaveVersione) ?? 1) < _versioneDati) {
    await db.clearAll();
    await prefs.remove('demo_inviti_atleta');
    await prefs.remove('demo_codici_gruppo');
    await prefs.setInt(_chiaveVersione, _versioneDati);
  }
  await _inserisciClubDemo(db);
  await _inserisciPersonalBestPallanuoto(db);
  await _inserisciSchedeBenessereDemo(db);
}

const _chiaveVersione = 'demo_dati_versione';
const _versioneDati = 5;

/// Tempi a stile libero (25-200 m) per gli atleti di pallanuoto: le
/// distanze che il preparatore misura in vasca.
Future<void> _inserisciPersonalBestPallanuoto(AppDatabase db) async {
  if ((await db.select(db.personalBestTable).get()).isNotEmpty) return;
  final atleti = await (db.select(
    db.atletiTable,
  )..where((t) => t.sport.equals('pallanuoto') & t.attivo.equals(true))).get();
  const uuid = Uuid();
  const basi = {25: 13.4, 50: 28.9, 100: 63.5, 200: 141.0};
  await db.batch((b) {
    for (var a = 0; a < atleti.length; a++) {
      for (final MapEntry(key: distanza, value: base) in basi.entries) {
        b.insert(
          db.personalBestTable,
          PersonalBestTableCompanion.insert(
            id: uuid.v4(),
            atletaId: atleti[a].id,
            clubId: atleti[a].clubId,
            stile: 'libero',
            distanzaM: distanza,
            tempoS: base * (1 + a * 0.018),
            data: Value(DateTime(2026, 9, 10 + a)),
          ),
        );
      }
    }
  });
}

/// Schede benessere degli ultimi 7 giorni, oggi compreso (con qualche
/// assente), solo se la tabella e' ancora vuota: per vedere subito lo
/// storico e la situazione di oggi dal lato allenatore.
Future<void> _inserisciSchedeBenessereDemo(AppDatabase db) async {
  if ((await db.select(db.schedeBenessereTable).get()).isNotEmpty) return;
  final atleti = await db.select(db.atletiTable).get();
  const uuid = Uuid();
  final oggi = DateTime.now();
  const zone = [
    ['spalla'],
    ['ginocchio'],
    ['schiena'],
    ['spalla', 'gomito'],
  ];
  // Valore "tipico" 1-5 di ogni atleta per ogni voce, con piccole
  // oscillazioni giornaliere: ognuno ha il proprio solito.
  int voce(int a, int g, int k) {
    final tipico = 3 + (a + k) % 2; // 3 o 4
    final oscillazione = ((a * 5 + g * 3 + k * 7) % 5) - 2; // -2..2
    return (tipico + (oscillazione.abs() == 2 ? oscillazione ~/ 2 : 0)).clamp(
      1,
      5,
    );
  }

  await db.batch((b) {
    for (var a = 0; a < atleti.length; a++) {
      // 4 settimane di storico, per il confronto con il "suo solito".
      for (var g = 0; g <= 27; g++) {
        // Oggi: compilata da quasi tutti. Restano fuori l'atleta con cui
        // si entra in demo (Bianchi, la prima libera per cognome) e due
        // altri, cosi' l'allenatore vede anche chi manca.
        if (g == 0 && (atleti[a].cognome == 'Bianchi' || a == 7 || a == 9)) {
          continue;
        }
        if (g > 0 && (a + g) % 5 == 0) continue; // giorni saltati
        var dolori = g > 0 && (a * 3 + g) % 6 == 0;
        var zoneDolore = dolori ? zone[(a + g) % zone.length] : <String>[];
        int? intensita = dolori ? 2 + (a + g) % 4 : null;
        var sonno = 7.0 + ((a * 7 + g * 3) % 6) * 0.5;
        final voci = [for (var k = 0; k < 5; k++) voce(a, g, k)];
        var sintomi = <String>[];
        // Oggi qualche caso tipico da far vedere all'allenatore.
        if (g == 0) {
          switch (a) {
            case 1: // spalla sovraccarica: rosso
              dolori = true;
              zoneDolore = ['spalla'];
              intensita = 7;
              voci[2] = 2;
            case 2: // notte corta e stanco: rosso per il sonno
              sonno = 4.5;
              voci[0] = 2;
              voci[1] = 2;
            case 4: // febbre
              sintomi = ['febbre'];
              voci[1] = 1;
            case 5: // un po' giu' e stressato: giallo
              voci[3] = 2;
              voci[4] = 2;
              sonno = 7;
            default:
              break;
          }
        }
        b.insert(
          db.schedeBenessereTable,
          SchedeBenessereTableCompanion.insert(
            id: uuid.v4(),
            atletaId: atleti[a].id,
            clubId: atleti[a].clubId,
            data: DateTime(oggi.year, oggi.month, oggi.day - g),
            dolori: dolori,
            zoneDoloreJson: Value(jsonEncode(zoneDolore)),
            intensitaDolore: Value(intensita),
            oreSonno: sonno,
            qualitaSonno: Value(voci[0]),
            energia: Value(voci[1]),
            muscoli: Value(voci[2]),
            stress: Value(voci[3]),
            umore: Value(voci[4]),
            sintomiJson: Value(jsonEncode(sintomi)),
            compilataIl: DateTime(oggi.year, oggi.month, oggi.day - g, 7, 30),
          ),
        );
      }
    }
  });
}

Future<void> _inserisciClubDemo(AppDatabase db) async {
  final esistenti = await db.select(db.clubTable).get();
  if (esistenti.isNotEmpty) return;

  final sport = dotenv.env['DEMO_SPORT'] == 'pallanuoto'
      ? 'pallanuoto'
      : 'nuoto';
  const uuid = Uuid();
  final oggi = DateTime.now();
  final giorno = DateTime(oggi.year, oggi.month, oggi.day);
  final clubId = uuid.v4();

  await db.transaction(() async {
    await db
        .into(db.clubTable)
        .insert(
          ClubTableCompanion.insert(
            id: clubId,
            nome: sport == 'nuoto'
                ? "Società Nuotatori Valle dell'Adige"
                : 'Pallanuoto Riviera Adriatica Sportiva',
            citta: const Value('San Giovanni in Persiceto'),
            sport: Value(sport),
            categorieJson: Value(
              jsonEncode(
                sport == 'nuoto'
                    ? ['Es.B', 'Es.A', 'Ragazzi', 'Juniores', 'Assoluti']
                    : ['U12', 'U14', 'U16', 'U18', 'Serie B'],
              ),
            ),
          ),
        );

    final nomiGruppi = sport == 'nuoto'
        ? ['Esordienti A', 'Agonisti Assoluti e Master', 'Propaganda']
        : ['Under 14', 'Prima squadra Serie B', 'Under 16 femminile'];
    final gruppi = <String>[];
    for (var i = 0; i < nomiGruppi.length; i++) {
      final id = uuid.v4();
      gruppi.add(id);
      await db
          .into(db.gruppiTable)
          .insert(
            GruppiTableCompanion.insert(
              id: id,
              clubId: clubId,
              nome: nomiGruppi[i],
              ordine: Value(i + 1),
              sport: Value(sport),
            ),
          );
    }

    const anagrafiche = [
      ('Maria Francesca', 'Bonaventura-Castiglioni', 'F', 2012),
      ('Leonardo', 'Rossi', 'M', 2011),
      ('Alessandro Maria', 'Dall\'Acqua Montecchi', 'M', 2010),
      ('Sofia', 'Bianchi', 'F', 2012),
      ('Giulia', 'Esposito', 'F', 2009),
      ('Tommaso', 'Ferrari', 'M', 2011),
      ('Beatrice', 'Lombardi Scarpellini', 'F', 2010),
      ('Francesco', 'Romano', 'M', 2012),
      ('Aurora', 'Colombo', 'F', 2011),
      ('Edoardo Giovanni', 'Santangelo', 'M', 2009),
      ('Ginevra', 'Ricci', 'F', 2010),
      ('Matteo', 'Marino', 'M', 2012),
    ];
    final atleti = <String>[];
    for (var i = 0; i < anagrafiche.length; i++) {
      final (nome, cognome, sesso, anno) = anagrafiche[i];
      final id = uuid.v4();
      atleti.add(id);
      await db
          .into(db.atletiTable)
          .insert(
            AtletiTableCompanion.insert(
              id: id,
              clubId: clubId,
              nome: nome,
              cognome: cognome,
              dataNascita: DateTime(anno, 1 + i % 12, 3 + i),
              sesso: Value(sesso),
              sport: sport,
              // Tutti nella prima squadra del club: e' lei ad avere
              // partite, allenamenti e convocazioni.
              gruppoId: Value(gruppi[0]),
              emailGenitore: Value(
                'genitore.${cognome.toLowerCase().replaceAll(RegExp(r"[^a-z]"), "")}@esempio.it',
              ),
              telefonoGenitore: const Value('+39 333 123 4567'),
              consensoPrivacyFirmato: Value(i % 4 != 0),
              consensoPrivacyData: Value(
                i % 4 != 0 ? DateTime(2026, 9, 1) : null,
              ),
              note: Value(
                i == 0
                    ? 'Allergia al cloro: usa occhialini e cuffia in silicone.'
                    : null,
              ),
              attivo: Value(i != 11),
              numeroTesseraFin: Value('FIN-${100200 + i}'),
              visitaMedicaScadenza: Value(
                giorno.add(Duration(days: i * 20 - 30)),
              ),
            ),
          );
    }

    // Stagione in corso.
    final stagioneId = uuid.v4();
    await db
        .into(db.stagioniTable)
        .insert(
          StagioniTableCompanion.insert(
            id: stagioneId,
            clubId: clubId,
            nome: 'Stagione agonistica 2026/2027',
            dataInizio: DateTime(2026, 9, 1),
            dataFine: DateTime(2027, 7, 31),
            obiettivo: const Value(
              'Qualificare almeno sei atleti ai Campionati Regionali di categoria',
            ),
            gruppoId: Value(gruppi[0]),
            campionato: Value(
              sport == 'nuoto'
                  ? 'Campionato Regionale Esordienti'
                  : 'Campionato Under 14 Emilia-Romagna',
            ),
          ),
        );

    // Allenamenti: questa settimana e la scorsa, con serie e presenze.
    const stili = ['libero', 'dorso', 'rana', 'delfino', 'misti'];
    final titoli = sport == 'nuoto'
        ? [
            'Aerobico lungo con lavoro di gambe',
            'Soglia anaerobica',
            'Tecnica dorso e virate',
            'Velocità e partenze dal blocco',
          ]
        : [
            'Superiorità numerica e controfuga',
            'Nuoto con palla e passaggi',
            'Tattica difensiva a zona',
            'Partitella a tema',
          ];
    // Tutta la stagione (1/9 - 30/6): lunedi, martedi, giovedi e venerdi
    // alle 18:30, con la pausa di Natale. Le presenze solo per quelle gia'
    // passate.
    final sedute = [
      for (
        var g = DateTime(2026, 9, 1);
        !g.isAfter(DateTime(2027, 6, 30));
        g = aggiungiGiorni(g, 1)
      )
        if (const {1, 2, 4, 5}.contains(g.weekday) &&
            (g.isBefore(DateTime(2026, 12, 23)) ||
                !g.isBefore(DateTime(2027, 1, 7))))
          DateTime(g.year, g.month, g.day, 18, 30),
    ];
    for (final (n, data) in sedute.indexed) {
      final d = giorniTra(giorno, data);
      final allenamentoId = uuid.v4();
      final indice = n % titoli.length;
      await db
          .into(db.allenamentiTable)
          .insert(
            AllenamentiTableCompanion.insert(
              id: allenamentoId,
              clubId: clubId,
              data: data,
              titolo: Value(titoli[indice]),
              gruppoId: Value(gruppi[0]),
              note: Value(
                indice == 0
                    ? 'Portare pinne corte e boccaglio frontale. Vasca da 25 m, corsie 3-4.'
                    : null,
              ),
            ),
          );
      final serie = sport == 'nuoto'
          ? [
              (
                'riscaldamento',
                1,
                400,
                null,
                'libero',
                'nuoto',
                'A1',
                null,
                20,
                null,
                null,
              ),
              (
                'riscaldamento',
                4,
                50,
                null,
                'misti',
                'gambe',
                'A2',
                null,
                15,
                null,
                'tavola',
              ),
              (
                'principale',
                8,
                100,
                null,
                stili[indice % 5],
                'nuoto',
                'B2',
                78.0,
                null,
                105.0,
                null,
              ),
              (
                'principale',
                6,
                50,
                null,
                'delfino',
                'braccia',
                'C1',
                34.0,
                30,
                null,
                'pull, palette',
              ),
              (
                'principale',
                3,
                null,
                300,
                'libero',
                'tecnica',
                'A2',
                null,
                60,
                null,
                null,
              ),
              (
                'defaticamento',
                1,
                200,
                null,
                'dorso',
                'nuoto',
                'A1',
                null,
                null,
                null,
                null,
              ),
            ]
          : [
              (
                'riscaldamento',
                1,
                600,
                null,
                'libero',
                'nuoto',
                'A1',
                null,
                30,
                null,
                null,
              ),
              (
                'principale',
                10,
                25,
                null,
                'libero',
                'nuoto',
                'C1',
                null,
                20,
                40.0,
                null,
              ),
              (
                'principale',
                4,
                null,
                300,
                'libero',
                'pallanuoto tecnico-tattico',
                null,
                null,
                60,
                null,
                'palloni, calottine',
              ),
              (
                'altro',
                2,
                null,
                600,
                'libero',
                'a secco',
                null,
                null,
                120,
                null,
                'elastici',
              ),
              (
                'defaticamento',
                1,
                200,
                null,
                'dorso',
                'nuoto',
                'A1',
                null,
                null,
                null,
                null,
              ),
            ];
      for (var s = 0; s < serie.length; s++) {
        final (
          blocco,
          rip,
          dist,
          dur,
          stile,
          esec,
          zona,
          passo,
          rec,
          rip2,
          attr,
        ) = serie[s];
        await db
            .into(db.serieTable)
            .insert(
              SerieTableCompanion.insert(
                id: uuid.v4(),
                allenamentoId: allenamentoId,
                clubId: clubId,
                ordine: s + 1,
                blocco: blocco,
                ripetute: rip,
                distanzaM: Value(dist),
                durataS: Value(dur),
                stile: stile,
                esecuzione: esec,
                zona: Value(zona),
                passoObiettivoS: Value(passo),
                recuperoS: Value(rec),
                ripartenzaS: Value(rip2),
                attrezzatura: Value(attr),
                note: Value(
                  s == 2
                      ? 'Tenere il passo costante, respirazione ogni 3 bracciate'
                      : null,
                ),
              ),
            );
      }
      if (data.isBefore(oggi)) {
        for (var a = 0; a < atleti.length; a++) {
          final stato = (a + d) % 5 == 0
              ? 'assente'
              : (a + d) % 7 == 0
              ? 'giustificato'
              : 'presente';
          await db
              .into(db.presenzeTable)
              .insert(
                PresenzeTableCompanion.insert(
                  id: uuid.v4(),
                  allenamentoId: allenamentoId,
                  atletaId: atleti[a],
                  clubId: clubId,
                  stato: stato,
                ),
              );
        }
      }
    }

    if (sport == 'nuoto') {
      // Personal best e tempi gara.
      for (var a = 0; a < 6; a++) {
        for (final (stile, dist, base) in [
          ('libero', 50, 29.4),
          ('libero', 100, 64.1),
          ('dorso', 100, 72.8),
          ('rana', 200, 171.3),
          ('misti', 200, 158.6),
        ]) {
          await db
              .into(db.personalBestTable)
              .insert(
                PersonalBestTableCompanion.insert(
                  id: uuid.v4(),
                  atletaId: atleti[a],
                  clubId: clubId,
                  stile: stile,
                  distanzaM: dist,
                  tempoS: base + a * 0.87,
                  data: Value(DateTime(2026, 6, 10 + a)),
                ),
              );
          await db
              .into(db.tempiGaraTable)
              .insert(
                TempiGaraTableCompanion.insert(
                  id: uuid.v4(),
                  atletaId: atleti[a],
                  clubId: clubId,
                  stile: stile,
                  distanzaM: dist,
                  vascaM: 25,
                  tempoS: base + a * 0.87 + 0.6,
                  data: DateTime(2026, 5, 20 + a),
                  note: Value(
                    a == 0 ? 'Trofeo Città di Bologna – batteria 3' : null,
                  ),
                ),
              );
        }
      }

      // Test di ingresso con tabella dei passi.
      for (var a = 0; a < 3; a++) {
        final testId = uuid.v4();
        await db
            .into(db.testIngressoTable)
            .insert(
              TestIngressoTableCompanion.insert(
                id: testId,
                atletaId: atleti[a],
                clubId: clubId,
                tipo: 'T30',
                dataTest: DateTime(2026, 9, 15),
                distanzaTotaleM: 2050 - a * 75,
                tempoTotaleS: 1800,
                passoMedio100S: 1800 / ((2050 - a * 75) / 100),
              ),
            );
        const percentuali = {
          'A1': 1.15,
          'A2': 1.08,
          'B1': 1.03,
          'B2': 1.0,
          'C1': 0.96,
          'C2': 0.93,
          'C3': 0.9,
          'D': 0.86,
        };
        final passoBase = 1800 / ((2050 - a * 75) / 100);
        for (final zona in percentuali.keys) {
          await db
              .into(db.tabellePassiTable)
              .insert(
                TabellePassiTableCompanion.insert(
                  id: uuid.v4(),
                  testId: testId,
                  atletaId: atleti[a],
                  clubId: clubId,
                  zona: zona,
                  passo100S: passoBase * percentuali[zona]!,
                  percentualeRiferimento: Value(percentuali[zona]! * 100),
                ),
              );
        }
      }

      // Gare: una passata e due in arrivo.
      for (final (giorni, nome, luogo, importanza) in [
        (
          -20,
          'Trofeo Città di Bologna – Memorial Giuseppe Garibaldi',
          'Piscina Comunale Stadio, Bologna',
          'media',
        ),
        (
          12,
          'Campionato Regionale Esordienti A – Prima giornata',
          'Centro Federale Polivalente di Riccione',
          'alta',
        ),
        (
          40,
          'Meeting Internazionale di Natale',
          'Piscine dei Bagni di Lucca',
          'bassa',
        ),
      ]) {
        final garaId = uuid.v4();
        await db
            .into(db.gareTable)
            .insert(
              GareTableCompanion.insert(
                id: garaId,
                clubId: clubId,
                gruppoId: Value(gruppi[0]),
                data: giorno.add(Duration(days: giorni)),
                ora: const Value('09:30'),
                luogo: Value(luogo),
                nome: nome,
                note: const Value(
                  'Ritrovo 45 minuti prima, cuffia e accappatoio del club.',
                ),
                importanza: Value(importanza),
              ),
            );
        for (var a = 0; a < 6; a++) {
          await db
              .into(db.garaIscrittiTable)
              .insert(
                GaraIscrittiTableCompanion.insert(
                  id: uuid.v4(),
                  garaId: garaId,
                  atletaId: atleti[a],
                  clubId: clubId,
                ),
              );
        }
      }
    } else {
      // Il campionato: un sabato si', da ottobre a maggio (pausa di Natale
      // esclusa), andata e ritorno contro gli stessi avversari. Distinta per
      // tutte, eventi per quelle gia' giocate.
      const noi = 'Pallanuoto Riviera Adriatica Sportiva';
      const avversari = [
        'Circolo Nautico Posillipo Napoli',
        'Società Canottieri Lazio Roma',
        'Rari Nantes Florentia',
        'Pallanuoto Trieste',
        'Sportiva Nervi Genova',
        'Rari Nantes Bologna',
        'Circolo Canottieri Ortigia Siracusa',
        'Pallanuoto Brescia',
      ];
      final sabati = [
        for (
          var g = DateTime(2026, 10, 3);
          !g.isAfter(DateTime(2027, 5, 29));
          g = aggiungiGiorni(g, 7)
        )
          if (g.isBefore(DateTime(2026, 12, 23)) ||
              !g.isBefore(DateTime(2027, 1, 7)))
            g,
      ];
      final calendario = [
        for (final (n, sabato) in sabati.indexed)
          (
            giorni: giorniTra(giorno, sabato),
            casa: n.isEven ? noi : avversari[n % avversari.length],
            trasferta: n.isEven ? avversari[n % avversari.length] : noi,
            // Gli scontri diretti di fine andata e di fine campionato.
            alta: n == 7 || n >= sabati.length - 2,
          ),
      ];
      for (final (:giorni, :casa, :trasferta, :alta) in calendario) {
        final partitaId = uuid.v4();
        await db
            .into(db.partiteTable)
            .insert(
              PartiteTableCompanion.insert(
                id: partitaId,
                clubId: clubId,
                gruppoId: Value(gruppi[0]),
                data: aggiungiGiorni(giorno, giorni),
                ora: const Value('15:00'),
                luogo: Value(
                  casa == noi
                      ? 'Piscina Comunale "Ettore Bulgarelli", vasca coperta'
                      : 'In trasferta · ${trasferta == noi ? casa : trasferta}',
                ),
                campionato: const Value('Campionato Under 14 Emilia-Romagna'),
                coloreCalottina: const Value('bianca'),
                squadraCasa: casa,
                squadraTrasferta: trasferta,
                nostraSquadra: Value(
                  casa.startsWith('Pallanuoto Riviera') ? 'casa' : 'trasferta',
                ),
                importanza: Value(alta ? 'alta' : 'media'),
              ),
            );
        for (var a = 0; a < 11; a++) {
          await db
              .into(db.distintaGiocatoriTable)
              .insert(
                DistintaGiocatoriTableCompanion.insert(
                  id: uuid.v4(),
                  partitaId: partitaId,
                  atletaId: atleti[a],
                  clubId: clubId,
                  numeroCalottina: a + 1,
                  capitano: Value(a == 4),
                  portiere: Value(a == 0 || a == 10),
                ),
              );
        }
        if (giorni < 0) {
          const esiti = ['gol', 'non_gol', 'parato', 'palo_fuori'];
          for (var e = 0; e < 24; e++) {
            await db
                .into(db.eventiPartitaTable)
                .insert(
                  EventiPartitaTableCompanion.insert(
                    id: uuid.v4(),
                    partitaId: partitaId,
                    clubId: clubId,
                    tipo: e % 6 == 5 ? 'espulsione' : 'tiro',
                    squadra: Value(e % 3 == 2 ? 'avversaria' : 'nostra'),
                    atletaId: Value(e % 3 == 2 ? null : atleti[1 + e % 10]),
                    periodo: Value(1 + e % 4),
                    esito: Value(e % 6 == 5 ? null : esiti[e % 4]),
                    contestoTiro: Value(e % 5 == 0 ? 'superiorita' : 'azione'),
                    posX: Value(0.2 + (e % 7) / 10),
                    posY: Value(0.15 + (e % 5) / 8),
                    numeroCalottinaAvversario: Value(
                      e % 3 == 2 ? 2 + e % 9 : null,
                    ),
                    creatoIl: aggiungiGiorni(
                      giorno,
                      giorni,
                    ).add(Duration(hours: 15, minutes: e * 2)),
                  ),
                );
          }
        }
      }
    }
  });
}
