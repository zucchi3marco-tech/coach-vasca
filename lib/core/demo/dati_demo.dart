import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/secco/domain/esercizio_secco.dart';
import '../../features/secco/domain/programma_secco.dart';
import '../../features/test/domain/massimale.dart';
import '../../features/test/domain/spiegazioni_test.dart';
import '../db/app_database.dart';
import '../sport_app.dart';
import '../utils/giorni.dart';

/// Dati finti per la modalita' demo: un club di pallanuoto gia' pronto con
/// gruppi, atleti, allenamenti, presenze, stagione e partite. Nomi
/// volutamente lunghi, per far emergere i problemi di impaginazione sugli
/// schermi stretti.
///
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
// 21: solo pallanuoto (2026-10-28), con i test T30 e le tabelle dei passi.
const _versioneDati = 21;

/// Com'è andata la serie [s] (nell'ordine in cui la demo le scrive) di una
/// seduta di [fa] sedute fa (0: l'ultima già svolta; meno di 0: non ancora
/// svolta): nelle ultime due ci sono serie fatte in parte e saltate, così
/// «Com'è andata» ha qualcosa da mostrare. Le altre sono fatte tutte; le
/// sedute più indietro non sono segnate. Chi è fatto in parte ha sempre
/// l'esito 'fatta'.
({String? esito, int? metriFatti, int? secondiFatti}) _comEAndataDemo(
  int fa,
  int s,
) {
  if (fa < 0 || fa > 1) {
    return (esito: null, metriFatti: null, secondiFatti: null);
  }
  const fatta = (esito: 'fatta', metriFatti: null, secondiFatti: null);
  const saltata = (esito: 'saltata', metriFatti: null, secondiFatti: null);
  if (fa == 0) {
    return switch (s) {
      // 6 ripetute su 10 da 25 m, 12 minuti su 20 di tattica.
      1 => (esito: 'fatta', metriFatti: 150, secondiFatti: null),
      2 => (esito: 'fatta', metriFatti: null, secondiFatti: 720),
      3 => saltata,
      _ => fatta,
    };
  }
  // Una distanza sola fatta in parte: 150 m su 200.
  return switch (s) {
    3 => saltata,
    4 => (esito: 'fatta', metriFatti: 150, secondiFatti: null),
    _ => fatta,
  };
}

/// Gli atleti (per posizione) che il martedì e il giovedì si allenano con
/// la prima squadra: Rossi e Bianchi, l'atleta della demo.
const _conLaPrima = {1, 3};

/// Tempi a stile libero (25-200 m) per gli atleti attivi: le distanze che
/// il preparatore misura in vasca.
Future<void> _inserisciPersonalBestPallanuoto(AppDatabase db) async {
  if ((await db.select(db.personalBestTable).get()).isNotEmpty) return;
  final atleti = await (db.select(
    db.atletiTable,
  )..where((t) => t.attivo.equals(true))).get();
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
            nome: 'Pallanuoto Riviera Adriatica Sportiva',
            citta: const Value('San Giovanni in Persiceto'),
            sport: const Value(sportApp),
            categorieJson: Value(
              jsonEncode(['U12', 'U14', 'U16', 'U18', 'Serie B']),
            ),
          ),
        );

    const nomiGruppi = [
      'Under 14',
      'Prima squadra Serie B',
      'Under 16 femminile',
    ];
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
              sport: const Value(sportApp),
              // Lo staff del modulo della distinta, già scritto per la
              // prima squadra.
              staffDistintaJson: Value(
                i == 0
                    ? '{"tecnico":{"nome":"Ferri Marco","tessera":"100231"},'
                          '"vice_tecnico":{"nome":"Galli Luca",'
                          '"tessera":"100847"},'
                          '"accompagnatore":{"nome":"Conti Paola",'
                          '"tessera":""}}'
                    : null,
              ),
            ),
          );
    }

    // Impegni: un collegiale della prima squadra fra due settimane e le
    // vacanze di tutto il club.
    for (final (tipo, nome, dal, giorni, gruppo, luogo) in [
      ('collegiale', 'Collegiale a Lignano', 14, 3, gruppi[0], 'Lignano'),
      ('riposo', 'Vacanze', 30, 5, null, null),
    ]) {
      final inizio = giorno.add(Duration(days: dal));
      await db
          .into(db.impegniTable)
          .insert(
            ImpegniTableCompanion.insert(
              id: uuid.v4(),
              clubId: clubId,
              gruppoId: Value(gruppo),
              tipo: tipo,
              dal: inizio,
              al: inizio.add(Duration(days: giorni - 1)),
              nome: Value(nome),
              luogo: Value(luogo),
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
              sport: sportApp,
              // Tutti nella prima squadra del club: e' lei ad avere
              // partite, allenamenti e convocazioni.
              gruppoId: Value(gruppi[0]),
              emailGenitore: Value(
                'genitore.${cognome.toLowerCase().replaceAll(RegExp(r"[^a-z]"), "")}@esempio.it',
              ),
              telefonoGenitore: const Value('+39 333 123 4567'),
              // Come in distinta: i due portieri della squadra; due
              // centroboa e un marcatore per il lavoro specializzato.
              ruolo: Value(switch (i) {
                0 || 10 => 'portiere',
                3 || 7 => 'centroboa',
                5 => 'marcatore',
                _ => null,
              }),
              // Rossi e Bianchi (l'atleta della demo) il martedì e il
              // giovedì si allenano con la prima squadra.
              altroGruppoId: Value(_conLaPrima.contains(i) ? gruppi[1] : null),
              giorniAltroGruppo: Value(_conLaPrima.contains(i) ? '2,4' : null),
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
            campionato: const Value('Campionato Under 14 Emilia-Romagna'),
          ),
        );

    // Allenamenti: questa settimana e la scorsa, con serie e presenze.
    const titoli = [
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
    // Quante sedute fa è andata una già svolta (0: l'ultima), per dire
    // com'è andata nelle ultime due.
    final svolte = sedute.where((x) => x.isBefore(oggi)).length;
    for (final (n, data) in sedute.indexed) {
      final d = giorniTra(giorno, data);
      final fa = data.isBefore(oggi) ? svolte - 1 - n : -1;
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
      final serie = [
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
      // Lo sprint e la tattica del gruppo sono un momento in parallelo,
      // mentre i portieri parano e i centroboa lottano in posizione
      // (lavori in parallelo, 2026-10-15).
      final momento = uuid.v4();
      final righe = <SerieTableCompanion>[];
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
        final andata = _comEAndataDemo(fa, s);
        righe.add(
          SerieTableCompanion.insert(
            id: uuid.v4(),
            allenamentoId: allenamentoId,
            clubId: clubId,
            ordine: 0,
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
            momentoId: Value(s == 1 || s == 2 ? momento : null),
            esito: Value(andata.esito),
            metriFatti: Value(andata.metriFatti),
            secondiFatti: Value(andata.secondiFatti),
          ),
        );
        if (s == 2) {
          for (final (ruolo, ripetute, durata, esecuzione, nota) in [
            ('portiere', 3, 360, 'tiri', 'Parate sui tiri dalla distanza'),
            (
              'portiere',
              1,
              300,
              'gambe',
              'Gambe a bicicletta con le braccia fuori',
            ),
            (
              'centroboa',
              6,
              150,
              'pallanuoto tecnico-tattico',
              'Lotta in posizione con il marcatore',
            ),
          ]) {
            righe.add(
              SerieTableCompanion.insert(
                id: uuid.v4(),
                allenamentoId: allenamentoId,
                clubId: clubId,
                ordine: 0,
                blocco: 'principale',
                ripetute: ripetute,
                durataS: Value(durata),
                stile: 'libero',
                esecuzione: esecuzione,
                recuperoS: const Value(30),
                note: Value(nota),
                perRuolo: Value(ruolo),
                momentoId: Value(momento),
              ),
            );
          }
        }
      }
      for (final (i, riga) in righe.indexed) {
        await db
            .into(db.serieTable)
            .insert(riga.copyWith(ordine: Value(i + 1)));
      }
      if (data.isBefore(oggi)) {
        for (var a = 0; a < atleti.length; a++) {
          // Il martedì e il giovedì Rossi e Bianchi sono con la prima
          // squadra: qui non sono attesi.
          if (_conLaPrima.contains(a) && const {2, 4}.contains(data.weekday)) {
            continue;
          }
          final stato = (a + d) % 5 == 0
              ? 'assente'
              : (a + d) % 7 == 0
              ? 'giustificato'
              : (a + d) % 9 == 4
              ? 'ritardo'
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

    // La prima squadra si allena il martedì e il giovedì alle 20, fino
    // a Natale: Rossi e Bianchi vengono dall'Under 14 (altra squadra in
    // giorni fissi, 2026-10-15). Le presenze solo le loro.
    const titoliPrima = [
      'Superiorità e tiri da fuori',
      'Contropiede e difesa a zona',
    ];
    var n = 0;
    for (
      var g = DateTime(2026, 9, 1);
      g.isBefore(DateTime(2026, 12, 23));
      g = aggiungiGiorni(g, 1)
    ) {
      if (!const {2, 4}.contains(g.weekday)) continue;
      final data = DateTime(g.year, g.month, g.day, 20);
      final allenamentoId = uuid.v4();
      await db
          .into(db.allenamentiTable)
          .insert(
            AllenamentiTableCompanion.insert(
              id: allenamentoId,
              clubId: clubId,
              data: data,
              titolo: Value(titoliPrima[n++ % titoliPrima.length]),
              gruppoId: Value(gruppi[1]),
            ),
          );
      for (final (i, (blocco, rip, dist, dur, esec, zona)) in [
        ('riscaldamento', 1, 800, null, 'nuoto', 'A1'),
        ('principale', 4, null, 360, 'gioco da schierati', null),
        ('principale', 3, null, 300, 'tiri', null),
        ('defaticamento', 1, 300, null, 'nuoto', 'A1'),
      ].indexed) {
        await db
            .into(db.serieTable)
            .insert(
              SerieTableCompanion.insert(
                id: uuid.v4(),
                allenamentoId: allenamentoId,
                clubId: clubId,
                ordine: i + 1,
                blocco: blocco,
                ripetute: rip,
                distanzaM: Value(dist),
                durataS: Value(dur),
                stile: 'libero',
                esecuzione: esec,
                zona: Value(zona),
                recuperoS: const Value(30),
              ),
            );
      }
      if (data.isBefore(oggi)) {
        for (final a in _conLaPrima) {
          await db
              .into(db.presenzeTable)
              .insert(
                PresenzeTableCompanion.insert(
                  id: uuid.v4(),
                  allenamentoId: allenamentoId,
                  atletaId: atleti[a],
                  clubId: clubId,
                  stato: (n + a) % 6 == 0 ? 'assente' : 'presente',
                ),
              );
        }
      }
    }

    // L'elenco degli esercizi a secco (quelli pronti) e, il mercoledì,
    // una seduta a secco di prevenzione per la squadra.
    final esercizi = <String, String>{};
    for (final m in modelliEsercizi) {
      final id = uuid.v4();
      esercizi[m.chiave] = id;
      await db
          .into(db.eserciziSeccoTable)
          .insert(
            EserciziSeccoTableCompanion.insert(
              id: id,
              clubId: clubId,
              nome: m.nome,
              categoria: m.categoria.name,
              misura: Value(m.misura.name),
              attrezzo: Value(m.attrezzo),
              descrizione: Value(m.descrizione),
              modello: Value(m.chiave),
            ),
          );
    }
    const programma = [
      ('extrarotazione_elastico', 'elastico rosso'),
      ('ytw_prono', null),
      ('plank_frontale', null),
      ('squat_muro', null),
      ('sleeper_stretch', null),
    ];
    for (
      var g = DateTime(2026, 9, 2);
      !g.isAfter(DateTime(2027, 6, 30));
      g = aggiungiGiorni(g, 7)
    ) {
      if (!g.isBefore(DateTime(2026, 12, 23)) &&
          g.isBefore(DateTime(2027, 1, 7))) {
        continue;
      }
      final data = DateTime(g.year, g.month, g.day, 17, 30);
      final d = giorniTra(giorno, data);
      final sedutaId = uuid.v4();
      await db
          .into(db.allenamentiTable)
          .insert(
            AllenamentiTableCompanion.insert(
              id: sedutaId,
              clubId: clubId,
              data: data,
              titolo: const Value('Prevenzione spalla e core'),
              gruppoId: Value(gruppi[0]),
              tipo: const Value('secco'),
              durataMin: const Value(40),
            ),
          );
      // Nelle tre settimane prima di oggi le varianti (proposta 12): il
      // primo atleta, con la spalla, fa il rematore con l'elastico giallo
      // al posto dell'YTW; il quinto non fa lo squat al muro. Oggi e
      // dopo no: chi ha segnato male alla spalla fa vedere la proposta.
      final conVarianti = d < 0 && d >= -21;
      final righe = <(String, ModelloEsercizio, String?)>[];
      (String, ModelloEsercizio, String?)? variante;
      for (final (i, (chiave, carico)) in programma.indexed) {
        final m = modelliEsercizi.firstWhere((m) => m.chiave == chiave);
        final rigaId = uuid.v4();
        righe.add((rigaId, m, carico));
        await db
            .into(db.eserciziSedutaTable)
            .insert(
              EserciziSedutaTableCompanion.insert(
                id: rigaId,
                allenamentoId: sedutaId,
                clubId: clubId,
                esercizioId: esercizi[chiave]!,
                ordine: i + 1,
                serie: Value(m.serie),
                ripetizioni: Value(m.ripetizioni),
                durataS: Value(m.durataS),
                carico: Value(carico),
                recuperoS: Value(m.recuperoS),
                tranneAtletiJson: Value(
                  conVarianti && chiave == 'squat_muro'
                      ? jsonEncode([atleti[4]])
                      : null,
                ),
              ),
            );
        if (conVarianti && chiave == 'ytw_prono') {
          final r = modelliEsercizi.firstWhere(
            (m) => m.chiave == 'rematore_elastico',
          );
          final varianteId = uuid.v4();
          variante = (varianteId, r, 'elastico giallo');
          await db
              .into(db.eserciziSedutaTable)
              .insert(
                EserciziSedutaTableCompanion.insert(
                  id: varianteId,
                  allenamentoId: sedutaId,
                  clubId: clubId,
                  esercizioId: esercizi[r.chiave]!,
                  ordine: i + 1,
                  serie: const Value(2),
                  ripetizioni: const Value(12),
                  carico: const Value('elastico giallo'),
                  recuperoS: Value(r.recuperoS),
                  varianteDi: Value(rigaId),
                  soloAtletiJson: Value(jsonEncode([atleti[0]])),
                ),
              );
        }
      }
      if (data.isBefore(oggi)) {
        for (var a = 0; a < atleti.length; a++) {
          final presente = (a + d) % 6 != 0;
          await db
              .into(db.presenzeTable)
              .insert(
                PresenzeTableCompanion.insert(
                  id: uuid.v4(),
                  allenamentoId: sedutaId,
                  atletaId: atleti[a],
                  clubId: clubId,
                  stato: presente ? 'presente' : 'assente',
                ),
              );
          // Le ultime tre settimane: metà dei presenti l'ha registrata
          // dal telefono, uno a metà; i più grandi con l'elastico verde.
          // Ognuno i suoi esercizi (con la variante), e il voto di quasi
          // ogni serie: l'ultima più dura.
          if (!presente || d < -21 || a.isOdd) continue;
          for (final (k, riga) in righe.indexed) {
            if (a == 2 && k >= 3) break;
            if (conVarianti && a == 4 && riga.$2.chiave == 'squat_muro') {
              continue;
            }
            final (
              rigaId,
              m,
              carico,
            ) = a == 0 && riga.$2.chiave == 'ytw_prono' && variante != null
                ? variante
                : riga;
            final quante = rigaId == variante?.$1 ? 2 : m.serie;
            for (var s = 1; s <= quante; s++) {
              final voto = a == 6
                  ? null
                  : s == quante
                  ? (a == 0 ? 'dura' : 'giusta')
                  : (k == 0 && a == 2 ? 'facile' : 'giusta');
              final usato = carico == null
                  ? null
                  : a < 4 && rigaId != variante?.$1
                  ? 'elastico verde'
                  : carico;
              await db
                  .into(db.serieSeccoFatteTable)
                  .insert(
                    SerieSeccoFatteTableCompanion.insert(
                      id: uuid.v4(),
                      atletaId: atleti[a],
                      clubId: clubId,
                      allenamentoId: sedutaId,
                      rigaId: rigaId,
                      esercizioId: esercizi[m.chiave]!,
                      serie: s,
                      ripetizioni: Value(
                        rigaId == variante?.$1
                            ? 12
                            : m.ripetizioni == null
                            ? null
                            : m.ripetizioni! - (s == m.serie && a == 6 ? 2 : 0),
                      ),
                      durataS: Value(m.durataS),
                      carico: Value(usato),
                      caricoPrevisto: Value(carico),
                      fattaIl: data.add(Duration(minutes: 3 * k + s)),
                      voto: Value(voto),
                    ),
                  );
            }
          }
        }
      }
    }
    // Un programma pronto già nel club, da mettere nel calendario.
    final spalla = modelliProgrammi.first;
    await db
        .into(db.programmiSeccoTable)
        .insert(
          ProgrammiSeccoTableCompanion.insert(
            id: uuid.v4(),
            clubId: clubId,
            nome: spalla.nome,
            descrizione: Value(spalla.descrizione),
            durataMin: Value(spalla.durataMin),
            settimaneJson: Value(
              jsonEncode([
                for (final s in spalla.settimaneCon(esercizi)) s.toMap(),
              ]),
            ),
            modello: Value(spalla.chiave),
          ),
        );

    // I massimali di squat e panca dei più grandi (nati entro il 2010),
    // misurati due volte, e il lunedì una seduta di forza con i carichi
    // in percentuale.
    final testMassimale = <String, String>{};
    for (final m in modelliMassimali.take(2)) {
      final id = uuid.v4();
      testMassimale[m.esercizio] = id;
      await db
          .into(db.testClubTable)
          .insert(
            TestClubTableCompanion.insert(
              id: id,
              clubId: clubId,
              nome: m.nome,
              descrizione: Value(spiegazioneOriginale(m.chiave)),
              unita: 'chili',
              migliore: 'maggiore',
              modello: Value(m.chiave),
              esercizioId: Value(esercizi[m.esercizio]),
            ),
          );
    }
    final grandi = [
      for (final (i, (_, _, _, anno)) in anagrafiche.indexed)
        if (anno <= 2010) i,
    ];
    // L'ultimo massimale di ognuno, per i chili delle sedute.
    final massimaleOra = <(String, int), double>{};
    for (final (k, a) in grandi.indexed) {
      for (final (esercizio, base) in const [
        ('squat_bilanciere', 50.0),
        ('panca_piana', 35.0),
      ]) {
        for (final (quando, inPiu) in const [(-42, 0.0), (-14, 5.0)]) {
          final kg = base + 2.5 * k + inPiu;
          const ripetizioni = 5;
          final massimale = stimaMassimale(kg, ripetizioni);
          massimaleOra[(esercizio, a)] = massimale;
          await db
              .into(db.testRisultatiTable)
              .insert(
                TestRisultatiTableCompanion.insert(
                  id: uuid.v4(),
                  testId: testMassimale[esercizio]!,
                  atletaId: atleti[a],
                  clubId: clubId,
                  data: aggiungiGiorni(giorno, quando),
                  valoriJson: jsonEncode([massimale]),
                  caricoKg: Value(kg),
                  ripetizioni: const Value(ripetizioni),
                ),
              );
        }
      }
    }
    const forza = [
      ('squat_bilanciere', '70%'),
      ('panca_piana', '70%'),
      ('rematore_manubrio', '12 kg'),
    ];
    for (
      var g = DateTime(2026, 9, 7);
      !g.isAfter(DateTime(2027, 6, 28));
      g = aggiungiGiorni(g, 7)
    ) {
      if (!g.isBefore(DateTime(2026, 12, 23)) &&
          g.isBefore(DateTime(2027, 1, 7))) {
        continue;
      }
      final data = DateTime(g.year, g.month, g.day, 17, 30);
      final d = giorniTra(giorno, data);
      final sedutaId = uuid.v4();
      await db
          .into(db.allenamentiTable)
          .insert(
            AllenamentiTableCompanion.insert(
              id: sedutaId,
              clubId: clubId,
              data: data,
              titolo: const Value('Forza'),
              gruppoId: Value(gruppi[0]),
              tipo: const Value('secco'),
              durataMin: const Value(45),
            ),
          );
      final righe = <(String, ModelloEsercizio, String)>[];
      for (final (i, (chiave, carico)) in forza.indexed) {
        final m = modelliEsercizi.firstWhere((m) => m.chiave == chiave);
        final rigaId = uuid.v4();
        righe.add((rigaId, m, carico));
        await db
            .into(db.eserciziSedutaTable)
            .insert(
              EserciziSedutaTableCompanion.insert(
                id: rigaId,
                allenamentoId: sedutaId,
                clubId: clubId,
                esercizioId: esercizi[chiave]!,
                ordine: i + 1,
                serie: Value(m.serie),
                ripetizioni: Value(m.ripetizioni),
                carico: Value(carico),
                recuperoS: Value(m.recuperoS),
              ),
            );
      }
      if (!data.isBefore(oggi)) continue;
      for (var a = 0; a < atleti.length; a++) {
        final presente = (a + d) % 6 != 0;
        await db
            .into(db.presenzeTable)
            .insert(
              PresenzeTableCompanion.insert(
                id: uuid.v4(),
                allenamentoId: sedutaId,
                atletaId: atleti[a],
                clubId: clubId,
                stato: presente ? 'presente' : 'assente',
              ),
            );
        // Le ultime due settimane i più grandi l'hanno registrata dal
        // telefono, con i chili dal loro massimale.
        if (!presente || d < -14 || !grandi.contains(a)) continue;
        for (final (k, (rigaId, m, carico)) in righe.indexed) {
          final massimale = massimaleOra[(m.chiave, a)];
          final usato = massimale == null
              ? carico
              : chiliProposti(carico, massimale) ?? carico;
          for (var s = 1; s <= m.serie; s++) {
            await db
                .into(db.serieSeccoFatteTable)
                .insert(
                  SerieSeccoFatteTableCompanion.insert(
                    id: uuid.v4(),
                    atletaId: atleti[a],
                    clubId: clubId,
                    allenamentoId: sedutaId,
                    rigaId: rigaId,
                    esercizioId: esercizi[m.chiave]!,
                    serie: s,
                    ripetizioni: Value(m.ripetizioni),
                    carico: Value(usato),
                    caricoPrevisto: Value(carico),
                    fattaIl: data.add(Duration(minutes: 4 * k + 2 * s)),
                  ),
                );
          }
        }
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
                    : 'Piscina della squadra ospitante',
              ),
              campionato: const Value('Campionato Under 14 Emilia-Romagna'),
              coloreCalottina: const Value('bianca'),
              squadraCasa: casa,
              squadraTrasferta: trasferta,
              nostraSquadra: Value(
                casa.startsWith('Pallanuoto Riviera') ? 'casa' : 'trasferta',
              ),
              importanza: Value(alta ? 'alta' : 'media'),
              // Le partite si seguono con gli eventi completi.
              eventiLive: const Value('completa'),
              // Le giocate erano state convocate: la prossima
              // convocazione ripropone il loro "da portare".
              ritrovoOra: Value(giorni < 0 ? '14:00' : null),
              daPortare: Value(
                giorni < 0
                    ? 'Accappatoio, ciabatte, cuffia di riserva, documento'
                    : null,
              ),
              convocazioneInviataIl: Value(
                giorni < 0 ? aggiungiGiorni(giorno, giorni - 2) : null,
              ),
            ),
          );
      // Le distinte delle giocate e della prossima: le altre sono da
      // fare, per provare "Scegli i convocati" e "Come l'ultima
      // partita". Portieri all'1 e al 13, capitano e vice.
      for (var a = 0; a < 11 && giorni <= 7; a++) {
        await db
            .into(db.distintaGiocatoriTable)
            .insert(
              DistintaGiocatoriTableCompanion.insert(
                id: uuid.v4(),
                partitaId: partitaId,
                atletaId: atleti[a],
                clubId: clubId,
                numeroCalottina: a == 10 ? 13 : a + 1,
                capitano: Value(a == 4),
                viceCapitano: Value(a == 8),
                portiere: Value(a == 0 || a == 10),
                // Nelle giocate: l'1 in porta nei primi due tempi, il
                // 13 negli ultimi due.
                tempiInPortaJson: Value(
                  giorni >= 0
                      ? null
                      : a == 0
                      ? '[1,2]'
                      : a == 10
                      ? '[3,4]'
                      : null,
                ),
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
                  // Un evento ogni 2 minuti, 6 per tempo: come dal vivo,
                  // e il video della partita li ritrova in ordine.
                  periodo: Value(1 + e ~/ 6),
                  esito: Value(e % 6 == 5 ? null : esiti[e % 4]),
                  contestoTiro: Value(e % 5 == 0 ? 'superiorita' : 'azione'),
                  posX: Value(0.2 + (e % 7) / 10),
                  posY: Value(0.15 + (e % 5) / 8),
                  numeroCalottinaAvversario: Value(
                    e % 3 == 2 ? 2 + e % 9 : null,
                  ),
                  // Ogni gol nostro con un assist, ogni espulsione
                  // avversaria guadagnata da qualcuno (mai chi tira).
                  assistDi: Value(
                    e % 3 != 2 && e % 6 != 5 && e % 4 == 0
                        ? atleti[1 + (e + 3) % 10]
                        : null,
                  ),
                  guadagnataDa: Value(
                    e % 6 == 5 ? atleti[1 + (e + 3) % 10] : null,
                  ),
                  // Sui tiri avversari, il portiere in acqua.
                  portiereId: Value(
                    e % 3 == 2 && e % 6 != 5
                        ? atleti[e ~/ 6 < 2 ? 0 : 10]
                        : null,
                  ),
                  creatoIl: aggiungiGiorni(
                    giorno,
                    giorni,
                  ).add(Duration(hours: 15, minutes: e * 2)),
                ),
              );
        }
        // Palle perse e recuperate (modalità completa).
        for (var e = 0; e < 8; e++) {
          await db
              .into(db.eventiPartitaTable)
              .insert(
                EventiPartitaTableCompanion.insert(
                  id: uuid.v4(),
                  partitaId: partitaId,
                  clubId: clubId,
                  tipo: e.isEven ? 'palla_persa' : 'palla_recuperata',
                  atletaId: Value(e == 6 ? null : atleti[1 + (e * 3) % 10]),
                  periodo: Value(1 + (1 + e * 6) ~/ 12),
                  creatoIl: aggiungiGiorni(
                    giorno,
                    giorni,
                  ).add(Duration(hours: 15, minutes: 1 + e * 6)),
                ),
              );
        }
      }
    }
  });
}
