import 'dart:math' as math;
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../core/utils/date_italiane.dart';
import '../../presenze/domain/presenza.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/durata_serie.dart';
import '../../allenamenti/domain/serie.dart';
import '../../allenamenti/domain/volume_allenamento.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/squadre_atleta.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../carico/domain/carico_rpe.dart';
import '../../carico/domain/rpe_seduta.dart';
import '../../club/domain/ruolo_club.dart';
import '../../gruppi/domain/gruppo.dart';
import '../../pallanuoto/domain/evento_partita.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../pallanuoto/domain/risultato_partita.dart';
import '../../pallanuoto/domain/statistiche_eventi.dart';
import '../../referti/domain/referto_letto.dart';
import '../../referti/domain/referto_partita.dart';
import '../../secco/domain/esercizio_secco.dart';
import '../../stagioni/domain/stagione.dart';
import '../../test/domain/test_club.dart';
import '../csv_export.dart' show numeriMomenti;
import '../domain/dati_club.dart';
import '../domain/periodo_dati.dart';

/// Il nome del file da scaricare: "WaterTactics Canottieri Milano
/// 18-10-2026.xlsx". Dal nome del club si tolgono i caratteri che un nome
/// di file non può avere.
String nomeFileDatiClub(String nomeClub, DateTime giorno) {
  final pulito = nomeClub
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final data =
      '${giorno.day.toString().padLeft(2, '0')}-'
      '${giorno.month.toString().padLeft(2, '0')}-${giorno.year}';
  return '${['WaterTactics', if (pulito.isNotEmpty) pulito, data].join(' ')}'
      '.xlsx';
}

/// Il file Excel con i dati del club: un foglio per tipo di dato, preceduto
/// da "Leggimi". Tutto si costruisce qui sul dispositivo.
///
/// I fogli "Leggimi", "Atleti", "Squadre" e "Allenatori" ci sono sempre;
/// gli altri solo se nel [periodo] hanno almeno una riga. Il foglio
/// "Benessere" (la salute degli atleti) solo con [conBenessere]: senza,
/// non entra nel file nemmeno se in [dati] ci sono le schede.
Uint8List fileExcelDatiClub(
  DatiClub dati, {
  required String nomeClub,
  required String scaricatoDa,
  required DateTime adesso,
  required PeriodoDati periodo,
  required bool conBenessere,
}) {
  final fogli = _Fogli(
    dati,
    periodo,
    conBenessere: conBenessere,
    adesso: adesso,
  ).tutti();
  bool incluso(_Foglio f) =>
      f.sempre || (f.righe.isNotEmpty && (conBenessere || !f.benessere));

  final excel = Excel.createExcel();
  final predefinito = excel.getDefaultSheet();
  if (predefinito != null) excel.rename(predefinito, 'Leggimi');

  final stili = _Stili();
  _scriviLeggimi(
    excel['Leggimi'],
    stili,
    fogli: fogli,
    incluso: incluso,
    conBenessere: conBenessere,
    nomeClub: nomeClub,
    scaricatoDa: scaricatoDa,
    adesso: adesso,
    periodo: periodo,
  );
  for (final f in fogli) {
    if (incluso(f)) _scriviFoglio(excel[f.nome], f, stili);
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw Exception('Impossibile generare il file Excel');
  }
  return Uint8List.fromList(bytes);
}

// ---------------------------------------------------------------------------
// Scrittura

/// Gli stili del file: titoli in grassetto e date vere (non numeri) nel
/// formato giorno/mese/anno, uguale in ogni Excel.
class _Stili {
  final titolo = CellStyle(bold: true);
  final data = CellStyle(
    numberFormat: NumFormat.custom(formatCode: 'dd/mm/yyyy'),
  );
  final dataOra = CellStyle(
    numberFormat: NumFormat.custom(formatCode: 'dd/mm/yyyy hh:mm'),
  );

  CellStyle? per(CellValue valore) => switch (valore) {
    DateCellValue() => data,
    DateTimeCellValue() => dataOra,
    _ => null,
  };
}

CellIndex _cella(int colonna, int riga) =>
    CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: riga);

/// Un foglio dei dati: i titoli nella prima riga, poi una riga per volta.
void _scriviFoglio(Sheet foglio, _Foglio f, _Stili stili) {
  for (var c = 0; c < f.titoli.length; c++) {
    foglio.updateCell(
      _cella(c, 0),
      TextCellValue(f.titoli[c]),
      cellStyle: stili.titolo,
    );
  }
  final larghezze = [for (final t in f.titoli) t.length];
  for (var r = 0; r < f.righe.length; r++) {
    final riga = f.righe[r];
    for (var c = 0; c < riga.length; c++) {
      final valore = riga[c];
      if (valore == null) continue;
      foglio.updateCell(_cella(c, r + 1), valore, cellStyle: stili.per(valore));
      larghezze[c] = math.max(larghezze[c], _lunghezza(valore));
    }
  }
  for (var c = 0; c < larghezze.length; c++) {
    foglio.setColumnWidth(c, math.min(math.max(larghezze[c] + 2, 8), 60) * 1.0);
  }
}

/// Quanti caratteri occupa una cella, per la larghezza della colonna.
int _lunghezza(CellValue valore) => switch (valore) {
  DateCellValue() => 11,
  DateTimeCellValue() => 17,
  _ => valore.toString().length,
};

void _scriviLeggimi(
  Sheet foglio,
  _Stili stili, {
  required List<_Foglio> fogli,
  required bool Function(_Foglio) incluso,
  required bool conBenessere,
  required String nomeClub,
  required String scaricatoDa,
  required DateTime adesso,
  required PeriodoDati periodo,
}) {
  var riga = 0;
  void scrivi(List<CellValue?> celle, {bool titolo = false}) {
    for (var c = 0; c < celle.length; c++) {
      final valore = celle[c];
      if (valore == null) continue;
      foglio.updateCell(
        _cella(c, riga),
        valore,
        cellStyle: titolo || (c == 0 && celle.length > 1) ? stili.titolo : null,
      );
    }
    riga++;
  }

  foglio.setColumnWidth(0, 24);
  foglio.setColumnWidth(1, 84);
  foglio.setColumnWidth(2, 28);

  String due(int n) => n.toString().padLeft(2, '0');
  scrivi([_testo('Club'), _testo(nomeClub)]);
  scrivi([
    _testo('Scaricato il'),
    _testo('${dataNumerica(adesso)} ${due(adesso.hour)}:${due(adesso.minute)}'),
  ]);
  scrivi([_testo('Da'), _testo(scaricatoDa)]);
  scrivi([
    _testo('Periodo'),
    _testo('${periodo.etichetta} (${periodo.descrizione})'),
  ]);
  scrivi([
    _testo('Benessere e dolori'),
    _testo(conBenessere ? 'inclusi' : 'non inclusi'),
  ]);
  riga++;
  scrivi([
    _testo(
      'Contiene dati personali di atleti, anche minorenni: conservalo con '
      'cura e non mandarlo in giro.',
    ),
  ]);
  riga++;
  scrivi([_testo('Foglio'), _testo("Cosa c'è"), _testo('Righe')], titolo: true);
  for (final f in fogli) {
    final CellValue righe;
    if (f.benessere && !conBenessere) {
      righe = TextCellValue('non richiesto');
    } else if (incluso(f)) {
      righe = IntCellValue(f.righe.length);
    } else {
      righe = TextCellValue('nessuno, foglio non incluso');
    }
    scrivi([TextCellValue(f.nome), TextCellValue(f.contenuto), righe]);
  }
  riga++;
  if (!periodo.eTutto) {
    scrivi([
      _testo(
        'Atleti, squadre, allenatori, stagioni ed esercizi a secco sono '
        'sempre completi, qualunque sia il periodo.',
      ),
    ]);
  }
  scrivi([
    _testo(
      'Non sono nel file: video e note sui video, lavagne tattiche, '
      'notifiche, codici d\'invito, libreria dei blocchi (ha il suo '
      '«Esporta in Excel»).',
    ),
  ]);
}

// ---------------------------------------------------------------------------
// Celle

/// I caratteri di controllo (tranne a capo e tabulazione) non sono ammessi
/// in un file Excel: un appunto incollato da altrove può averne.
final _controllo = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');

/// Il testo; una cella vuota se non c'è nulla da scrivere.
CellValue? _testo(String? valore) {
  if (valore == null) return null;
  final pulito = valore.replaceAll(_controllo, '');
  return pulito.trim().isEmpty ? null : TextCellValue(pulito);
}

CellValue? _intero(int? valore) => valore == null ? null : IntCellValue(valore);

CellValue? _decimale(double? valore) =>
    valore == null ? null : DoubleCellValue(valore);

CellValue? _giorno(DateTime? valore) =>
    valore == null ? null : DateCellValue.fromDateTime(valore);

CellValue? _giornoOra(DateTime? valore) =>
    valore == null ? null : DateTimeCellValue.fromDateTime(valore);

CellValue _siNo(bool valore) => TextCellValue(valore ? 'Sì' : 'No');

/// Un tempo come lo scrive l'app: "28,40", "1:05,20".
String _tempo(double secondi) =>
    formattaValore(UnitaTest.secondi, secondi, sigla: false);

const _eliminato = '(eliminato)';
const _tuttoIlClub = 'Tutto il club';

String _statoPresenza(String stato) => etichettaStatoPresenza(stato);

String _importanza(String valore) => switch (valore) {
  'bassa' => 'Bassa',
  'media' => 'Media',
  'alta' => 'Alta',
  _ => valore,
};

String _ruoloAtleta(String? ruolo) {
  if (ruolo == null) return '';
  for (final (chiave, etichetta) in ruoliAtleta) {
    if (chiave == ruolo) return etichetta;
  }
  return ruolo;
}

// ---------------------------------------------------------------------------
// I fogli

class _Foglio {
  const _Foglio({
    required this.nome,
    required this.contenuto,
    required this.titoli,
    required this.righe,
    this.sempre = false,
    this.benessere = false,
  });

  /// Il nome del foglio (al massimo 31 caratteri, senza `[]:*?/\`).
  final String nome;

  /// Cosa c'è, per la tabella di "Leggimi".
  final String contenuto;
  final List<String> titoli;
  final List<List<CellValue?>> righe;

  /// Il foglio c'è anche senza righe.
  final bool sempre;

  /// La salute degli atleti: c'è solo se il responsabile l'ha chiesta.
  final bool benessere;
}

/// Costruisce i fogli dai [dati], con il [periodo] già applicato.
class _Fogli {
  _Fogli(
    this.dati,
    this.periodo, {
    required this.conBenessere,
    required this.adesso,
  }) : _atleti = {for (final a in dati.atleti) a.id: a},
       _squadre = {for (final g in dati.squadre) g.id: g},
       _membri = {for (final m in dati.membri) m.userId: m},
       _allenamenti = {for (final a in dati.allenamenti) a.id: a},
       _partite = {for (final p in dati.partite) p.id: p},
       _esercizi = {for (final e in dati.eserciziSecco) e.id: e},
       _test = {for (final t in dati.testClub) t.id: t};

  final DatiClub dati;
  final PeriodoDati periodo;
  final bool conBenessere;

  /// Quando si scarica: un allenamento che deve ancora venire non ha metri
  /// fatti.
  final DateTime adesso;

  final Map<String, Atleta> _atleti;
  final Map<String, Gruppo> _squadre;
  final Map<String, MembroClub> _membri;
  final Map<String, Allenamento> _allenamenti;
  final Map<String, Partita> _partite;
  final Map<String, EsercizioSecco> _esercizi;
  final Map<String, TestClub> _test;

  List<_Foglio> tutti() => [
    _atletiFoglio(),
    _squadreFoglio(),
    _allenatoriFoglio(),
    _stagioniFoglio(),
    _allenamentiFoglio(),
    _serieFoglio(),
    _presenzeFoglio(),
    _seccoFoglio(),
    _seccoFattoFoglio(),
    _eserciziSeccoFoglio(),
    _partiteFoglio(),
    _convocatiFoglio(),
    _statistichePartiteFoglio(),
    _refertiFoglio(),
    _impegniFoglio(),
    _avversariFoglio(),
    _personalBestFoglio(),
    _testDelPassoFoglio(),
    _passiPerZonaFoglio(),
    _testDelClubFoglio(),
    _sforzoFoglio(),
    _benessereFoglio(),
  ];

  // --- Nomi al posto degli id -------------------------------------------

  String _cognome(String atletaId) => _atleti[atletaId]?.cognome ?? _eliminato;

  String _nome(String atletaId) => _atleti[atletaId]?.nome ?? '';

  /// Per mettere in ordine le righe di un atleta: cognome e nome; chi non
  /// c'è più in fondo.
  String _chiave(String atletaId) {
    final a = _atleti[atletaId];
    return a == null ? '~' : '${a.cognome} ${a.nome}'.toLowerCase();
  }

  /// La squadra col suo nome; [senza] se non c'è (id null).
  String _squadra(String? id, {String senza = ''}) =>
      id == null ? senza : (_squadre[id]?.nome ?? _eliminato);

  String _nomeMembro(String userId) {
    final m = _membri[userId];
    if (m == null) return _eliminato;
    return m.nome ?? m.email ?? '(senza nome)';
  }

  String _titolo(Allenamento a) => a.titoloMostrato;

  String _partita(Partita p) => '${p.squadraCasa} – ${p.squadraTrasferta}';

  /// "Allenamento: Resistenza", "Partita: Casa – Trasferta".
  String _seduta(String? tipo, String? id) {
    if (tipo == null || id == null) return '';
    if (tipo == 'partita') {
      final p = _partite[id];
      return 'Partita: ${p == null ? _eliminato : _partita(p)}';
    }
    final a = _allenamenti[id];
    return 'Allenamento: ${a == null ? _eliminato : _titolo(a)}';
  }

  // --- Periodo ------------------------------------------------------------

  /// Gli allenamenti del periodo, dal più vecchio.
  late final List<Allenamento> _allenamentiPeriodo = [
    for (final a in dati.allenamenti)
      if (periodo.comprende(a.data)) a,
  ]..sort(_perDataSquadraTitolo);

  int _perDataSquadraTitolo(Allenamento a, Allenamento b) {
    final perData = a.data.compareTo(b.data);
    if (perData != 0) return perData;
    final perSquadra = _squadra(a.gruppoId).compareTo(_squadra(b.gruppoId));
    if (perSquadra != 0) return perSquadra;
    return _titolo(a).compareTo(_titolo(b));
  }

  /// Le partite del periodo, dalla più vecchia.
  late final List<Partita> _partitePeriodo = [
    for (final p in dati.partite)
      if (periodo.comprende(p.data)) p,
  ]..sort(_perDataOra);

  int _perDataOra(Partita a, Partita b) {
    final perData = a.data.compareTo(b.data);
    if (perData != 0) return perData;
    return (a.ora ?? '').compareTo(b.ora ?? '');
  }

  /// Le serie di ogni allenamento, nell'ordine.
  late final Map<String, List<Serie>> _seriePer = _raggruppa(
    dati.serie,
    (s) => s.allenamentoId,
    ordina: (a, b) => a.ordine.compareTo(b.ordine),
  );

  static Map<String, List<T>> _raggruppa<T>(
    Iterable<T> righe,
    String Function(T) per, {
    int Function(T, T)? ordina,
  }) {
    final mappa = <String, List<T>>{};
    for (final r in righe) {
      (mappa[per(r)] ??= []).add(r);
    }
    if (ordina != null) {
      for (final lista in mappa.values) {
        lista.sort(ordina);
      }
    }
    return mappa;
  }

  /// Le righe di [id] in una mappa fatta da [_raggruppa]; nessuna se manca.
  static List<T> _di<T>(Map<String, List<T>> mappa, String id) =>
      mappa[id] ?? <T>[];

  // --- Atleti, squadre, allenatori, stagioni -------------------------------

  _Foglio _atletiFoglio() {
    final ordinati = [...dati.atleti]
      ..sort((a, b) {
        final perCognome = a.cognome.toLowerCase().compareTo(
          b.cognome.toLowerCase(),
        );
        if (perCognome != 0) return perCognome;
        return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      });
    return _Foglio(
      nome: 'Atleti',
      contenuto:
          'Tutti gli atleti, anche quelli non più attivi, con squadra, '
          'consenso privacy e dati dei genitori.',
      sempre: true,
      titoli: const [
        'Cognome',
        'Nome',
        'Data di nascita',
        'Sesso',
        'Ruolo',
        'Squadra',
        'Seconda squadra',
        'Giorni nella seconda squadra',
        'Tessera FIN',
        'Visita medica fino al',
        'Email genitore',
        'Telefono genitore',
        'Consenso privacy',
        'Data consenso',
        'Attivo',
        'Account nell\'app',
        'Note',
      ],
      righe: [
        for (final a in ordinati)
          [
            _testo(a.cognome),
            _testo(a.nome),
            _giorno(a.dataNascita),
            _testo(a.sesso),
            _testo(_ruoloAtleta(a.ruolo)),
            _testo(_squadra(a.gruppoId)),
            _testo(_squadra(a.altroGruppoId)),
            _testo(etichettaGiorni(a.giorniAltroGruppo)),
            _testo(a.numeroTesseraFin),
            _giorno(a.visitaMedicaScadenza),
            _testo(a.emailGenitore),
            _testo(a.telefonoGenitore),
            _siNo(a.consensoPrivacyFirmato),
            _giorno(a.consensoPrivacyData),
            _siNo(a.attivo),
            _siNo(a.userId != null),
            _testo(a.note),
          ],
      ],
    );
  }

  _Foglio _squadreFoglio() {
    final capi = {for (final s in dati.squadreConCapo) s.id: s.capoUserId};
    final ordinate = [...dati.squadre]
      ..sort((a, b) {
        final perOrdine = a.ordine.compareTo(b.ordine);
        return perOrdine != 0 ? perOrdine : a.nome.compareTo(b.nome);
      });
    return _Foglio(
      nome: 'Squadre',
      contenuto: 'Le squadre, con capo allenatore e atleti attivi.',
      sempre: true,
      titoli: const ['Squadra', 'Capo allenatore', 'Atleti'],
      righe: [
        for (final g in ordinate)
          [
            _testo(g.nome),
            _testo(capi[g.id] == null ? null : _nomeMembro(capi[g.id]!)),
            IntCellValue(
              dati.atleti.where((a) => a.attivo && a.gruppoId == g.id).length,
            ),
          ],
      ],
    );
  }

  _Foglio _allenatoriFoglio() {
    final ordinati = [...dati.membri]
      ..sort((a, b) {
        final perRuolo = a.ruolo.index.compareTo(b.ruolo.index);
        if (perRuolo != 0) return perRuolo;
        return (a.nome ?? a.email ?? '').toLowerCase().compareTo(
          (b.nome ?? b.email ?? '').toLowerCase(),
        );
      });
    return _Foglio(
      nome: 'Allenatori',
      contenuto:
          'Chi lavora nel club, con ruolo ed email, e di quali squadre è '
          'capo allenatore.',
      sempre: true,
      titoli: const ['Nome', 'Ruolo', 'Email', 'Capo di'],
      righe: [
        for (final m in ordinati)
          [
            _testo(m.nome ?? '(senza nome)'),
            _testo(m.ruolo.etichetta),
            _testo(m.email),
            _testo(
              [
                for (final s in dati.squadre)
                  if (dati.squadreConCapo.any(
                    (c) => c.id == s.id && c.capoUserId == m.userId,
                  ))
                    s.nome,
              ].join(', '),
            ),
          ],
      ],
    );
  }

  _Foglio _stagioniFoglio() {
    final ordinate = [...dati.stagioni]
      ..sort((a, b) {
        final perInizio = a.dataInizio.compareTo(b.dataInizio);
        if (perInizio != 0) return perInizio;
        return _squadra(a.gruppoId).compareTo(_squadra(b.gruppoId));
      });
    String fase(FaseStagione f) {
      final dettagli = [
        if (f.obiettivoMetri != null) '${f.obiettivoMetri} m a settimana',
        if (f.obiettivoCarico != null)
          'carico ${f.obiettivoCarico} a settimana',
      ];
      return '${f.nome} ${dataNumerica(f.dataInizio)}-'
          '${dataNumerica(f.dataFine)}'
          '${dettagli.isEmpty ? '' : ' (${dettagli.join(', ')})'}';
    }

    return _Foglio(
      nome: 'Stagioni',
      contenuto:
          'Le stagioni di ogni squadra, con date, campionato, obiettivo e '
          'fasi.',
      titoli: const [
        'Squadra',
        'Nome',
        'Dal',
        'Al',
        'Campionato',
        'Obiettivo',
        'Fasi',
      ],
      righe: [
        for (final s in ordinate)
          [
            _testo(_squadra(s.gruppoId, senza: etichettaTuttiGliAtleti)),
            _testo(s.nome),
            _giorno(s.dataInizio),
            _giorno(s.dataFine),
            _testo(s.campionato),
            _testo(s.obiettivo),
            _testo(s.fasi.map(fase).join('; ')),
          ],
      ],
    );
  }

  // --- Allenamenti ----------------------------------------------------------

  _Foglio _allenamentiFoglio() {
    final volumi = volumiPerAllenamento(dati.serie);
    // Senza le serie saltate e con solo la parte fatta di quelle «In
    // parte»; quelle non segnate contano tutte, come nel carico.
    final fatti = volumiPerAllenamento(dati.serie, fatto: true);
    // «Presenti» comprende chi è arrivato in ritardo, che ha anche la sua
    // colonna «Di cui in ritardo».
    final presenti = <String, int>{};
    final ritardi = <String, int>{};
    final assenti = <String, int>{};
    final giustificati = <String, int>{};
    for (final p in dati.presenze) {
      final conto = contaComePresente(p.stato)
          ? presenti
          : p.stato == statoGiustificato
          ? giustificati
          : assenti;
      conto[p.allenamentoId] = (conto[p.allenamentoId] ?? 0) + 1;
      if (p.stato == statoRitardo) {
        ritardi[p.allenamentoId] = (ritardi[p.allenamentoId] ?? 0) + 1;
      }
    }
    return _Foglio(
      nome: 'Allenamenti',
      contenuto:
          'Un allenamento per riga, con metri scritti e fatti, durata (per '
          'l\'acqua è stimata dalle serie) e presenze.',
      titoli: const [
        'Data',
        'Squadra',
        'Tipo',
        'Titolo',
        'Metri',
        'Metri fatti',
        'Durata (min)',
        'Presenti',
        'Di cui in ritardo',
        'Assenti',
        'Giustificati',
        'Note',
      ],
      righe: [
        for (final a in _allenamentiPeriodo)
          [
            _giorno(a.data),
            _testo(_squadra(a.gruppoId, senza: _tuttoIlClub)),
            _testo(a.secco ? 'Secco' : 'Acqua'),
            _testo(_titolo(a)),
            _intero(
              (volumi[a.id]?.metri ?? 0) > 0 ? volumi[a.id]!.metri : null,
            ),
            _intero(
              (volumi[a.id]?.metri ?? 0) > 0 && !a.data.isAfter(adesso)
                  ? fatti[a.id]?.metri ?? 0
                  : null,
            ),
            _intero(
              a.secco
                  ? a.durataMin
                  : (_di(_seriePer, a.id).isEmpty
                        ? null
                        : minutiSeduta(_di(_seriePer, a.id))),
            ),
            IntCellValue(presenti[a.id] ?? 0),
            IntCellValue(ritardi[a.id] ?? 0),
            IntCellValue(assenti[a.id] ?? 0),
            IntCellValue(giustificati[a.id] ?? 0),
            _testo(a.note),
          ],
      ],
    );
  }

  _Foglio _serieFoglio() {
    final righe = <List<CellValue?>>[];
    for (final a in _allenamentiPeriodo) {
      final serie = _di(_seriePer, a.id);
      final momenti = numeriMomenti(serie);
      for (final s in serie) {
        final perChi = etichettaDestinatari(
          s.destinatari,
          (id) => _atleti[id]?.nomeCompleto,
        );
        righe.add([
          _giorno(a.data),
          _testo(_squadra(a.gruppoId, senza: _tuttoIlClub)),
          _testo(_titolo(a)),
          IntCellValue(s.ordine),
          _testo(labelBlocco(s.blocco)),
          IntCellValue(s.ripetute),
          _intero(s.distanzaM),
          _intero(s.durataS),
          _testo(labelStileSerie(s)),
          _testo(labelEsecuzione(s.esecuzione)),
          _testo(s.zona),
          _testo(s.passoObiettivoS == null ? null : _tempo(s.passoObiettivoS!)),
          _intero(s.recuperoS),
          _intero(s.recuperoDopoS),
          _testo(s.ripartenzaS == null ? null : _tempo(s.ripartenzaS!)),
          _testo(s.attrezzatura),
          _testo(perChi ?? 'Tutti'),
          _intero(momenti[s.momentoId]),
          _testo(
            s.metriFatti != null || s.secondiFatti != null
                ? 'In parte'
                : s.fatta
                ? 'Fatta'
                : s.saltata
                ? 'Saltata'
                : null,
          ),
          _intero(s.metriFatti),
          _intero(s.secondiFatti),
          _testo(s.note),
        ]);
      }
    }
    return _Foglio(
      nome: 'Serie',
      contenuto:
          'Le serie di ogni allenamento in acqua, una per riga, con per chi '
          'sono ed esito.',
      titoli: const [
        'Data',
        'Squadra',
        'Allenamento',
        'N°',
        'Blocco',
        'Ripetute',
        'Distanza (m)',
        'Durata (s)',
        'Stile',
        'Esecuzione',
        'Zona',
        'Passo',
        'Recupero (s)',
        'Recupero dopo (s)',
        'Ripartenza',
        'Attrezzatura',
        'Per chi',
        'In parallelo',
        'Esito',
        // Solo per una serie fatta «In parte»: quanto se n'è fatto.
        'Metri fatti',
        'Secondi fatti',
        'Note',
      ],
      righe: righe,
    );
  }

  _Foglio _presenzeFoglio() {
    final perAllenamento = _raggruppa(
      dati.presenze,
      (p) => p.allenamentoId,
      ordina: (a, b) => _chiave(a.atletaId).compareTo(_chiave(b.atletaId)),
    );
    return _Foglio(
      nome: 'Presenze',
      contenuto:
          'Chi era presente, in ritardo, assente o giustificato a ogni '
          'allenamento.',
      titoli: const [
        'Data',
        'Squadra',
        'Allenamento',
        'Cognome',
        'Nome',
        'Stato',
        'Note',
      ],
      righe: [
        for (final a in _allenamentiPeriodo)
          for (final p in _di(perAllenamento, a.id))
            [
              _giorno(a.data),
              _testo(_squadra(a.gruppoId, senza: _tuttoIlClub)),
              _testo(_titolo(a)),
              _testo(_cognome(p.atletaId)),
              _testo(_nome(p.atletaId)),
              _testo(_statoPresenza(p.stato)),
              _testo(p.note),
            ],
      ],
    );
  }

  // --- Secco ---------------------------------------------------------------

  String _esercizio(String id) => _esercizi[id]?.nome ?? _eliminato;

  _Foglio _seccoFoglio() {
    final perAllenamento = _raggruppa(
      dati.eserciziSeduta,
      (r) => r.allenamentoId,
      // Ogni variante subito dopo il suo esercizio (stesso numero).
      ordina: (a, b) {
        final perOrdine = a.ordine.compareTo(b.ordine);
        if (perOrdine != 0) return perOrdine;
        if (a.variante != b.variante) return a.variante ? 1 : -1;
        return a.id.compareTo(b.id);
      },
    );
    final nomiEsercizi = {
      for (final r in dati.eserciziSeduta) r.id: _esercizio(r.esercizioId),
    };
    String perChi(EsercizioSeduta r) {
      final chi =
          etichettaDestinatari(
            r.destinatari,
            (id) => _atleti[id]?.nomeCompleto,
          ) ??
          'Tutti';
      return r.variante
          ? '$chi, al posto di ${nomiEsercizi[r.varianteDi] ?? _eliminato}'
          : chi;
    }

    return _Foglio(
      nome: 'Secco',
      contenuto:
          'Gli esercizi previsti in ogni seduta a secco, con le varianti '
          'per alcuni atleti.',
      titoli: const [
        'Data',
        'Squadra',
        'Seduta',
        'N°',
        'Esercizio',
        'Per chi',
        'Categoria',
        'Serie',
        'Ripetizioni',
        'Durata (s)',
        'Carico',
        'Recupero (s)',
        'Note',
      ],
      righe: [
        for (final a in _allenamentiPeriodo)
          for (final r in _di(perAllenamento, a.id))
            [
              _giorno(a.data),
              _testo(_squadra(a.gruppoId, senza: _tuttoIlClub)),
              _testo(_titolo(a)),
              IntCellValue(r.ordine),
              _testo(_esercizio(r.esercizioId)),
              _testo(perChi(r)),
              _testo(_esercizi[r.esercizioId]?.categoria.etichetta),
              IntCellValue(r.serie),
              _intero(r.ripetizioni),
              _intero(r.durataS),
              _testo(r.carico),
              _intero(r.recuperoS),
              _testo(r.note),
            ],
      ],
    );
  }

  _Foglio _seccoFattoFoglio() {
    final perAllenamento = _raggruppa(
      dati.serieSeccoFatte,
      (f) => f.allenamentoId,
      ordina: (a, b) {
        final perAtleta = _chiave(a.atletaId).compareTo(_chiave(b.atletaId));
        if (perAtleta != 0) return perAtleta;
        final perEsercizio = _esercizio(a.esercizioId)
            .compareTo(_esercizio(b.esercizioId));
        if (perEsercizio != 0) return perEsercizio;
        return a.serie.compareTo(b.serie);
      },
    );
    return _Foglio(
      nome: 'Secco fatto',
      contenuto:
          'Le serie a secco che gli atleti hanno registrato, dal loro '
          'telefono o dal tablet della squadra, con com\'è andata.',
      titoli: const [
        'Data',
        'Squadra',
        'Seduta',
        'Cognome',
        'Nome',
        'Esercizio',
        'Serie n°',
        'Ripetizioni',
        'Durata (s)',
        'Carico',
        'Carico previsto',
        'Com\'è andata',
        'Fatta il',
      ],
      righe: [
        for (final a in _allenamentiPeriodo)
          for (final f in _di(perAllenamento, a.id))
            [
              _giorno(a.data),
              _testo(_squadra(a.gruppoId, senza: _tuttoIlClub)),
              _testo(_titolo(a)),
              _testo(_cognome(f.atletaId)),
              _testo(_nome(f.atletaId)),
              _testo(_esercizio(f.esercizioId)),
              IntCellValue(f.serie),
              _intero(f.ripetizioni),
              _intero(f.durataS),
              _testo(f.carico),
              _testo(f.caricoPrevisto),
              _testo(f.voto?.etichetta),
              _giornoOra(f.fattaIl),
            ],
      ],
    );
  }

  _Foglio _eserciziSeccoFoglio() {
    final ordinati = [...dati.eserciziSecco]
      ..sort((a, b) {
        final perCategoria = a.categoria.index.compareTo(b.categoria.index);
        if (perCategoria != 0) return perCategoria;
        return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      });
    String? video(EsercizioSecco e) {
      final id = e.videoYoutube;
      if (id == null || id.isEmpty) return null;
      final da = e.videoDaS;
      return 'https://www.youtube.com/watch?v=$id${da == null ? '' : '&t=${da}s'}';
    }

    return _Foglio(
      nome: 'Esercizi a secco',
      contenuto: 'L\'elenco degli esercizi a secco del club.',
      titoli: const [
        'Esercizio',
        'Categoria',
        'Si misura a',
        'Attrezzo',
        'Come si fa',
        'Video',
        'Archiviato',
      ],
      righe: [
        for (final e in ordinati)
          [
            _testo(e.nome),
            _testo(e.categoria.etichetta),
            _testo(e.misura.etichetta),
            _testo(e.attrezzo),
            _testo(e.descrizione),
            _testo(video(e)),
            _siNo(e.archiviato),
          ],
      ],
    );
  }

  // --- Pallanuoto ----------------------------------------------------------

  late final Map<String, List<EventoPartita>> _eventiPer = _raggruppa(
    dati.eventiPartita,
    (e) => e.partitaId,
  );

  late final Map<String, RefertoPartita> _refertoPer = {
    for (final r in dati.referti) r.partitaId: r,
  };

  /// "7-5" (casa-trasferta): dagli eventi segnati dal vivo, o dal referto
  /// se gli eventi non hanno gol.
  String _risultato(Partita p) {
    final dalVivo = risultatoPartita(_eventiPer[p.id] ?? const [], p);
    final referto = _refertoPer[p.id];
    if (dalVivo != null &&
        (dalVivo.golCasa + dalVivo.golTrasferta > 0 || referto == null)) {
      return '${dalVivo.golCasa}-${dalVivo.golTrasferta}';
    }
    if (referto != null) {
      return '${referto.risultatoCasa}-${referto.risultatoTrasferta}';
    }
    return '';
  }

  _Foglio _partiteFoglio() {
    final convocati = <String, int>{};
    for (final d in dati.distinte) {
      convocati[d.partitaId] = (convocati[d.partitaId] ?? 0) + 1;
    }
    return _Foglio(
      nome: 'Partite',
      contenuto: 'Le partite con risultato, luogo e numero di convocati.',
      titoli: const [
        'Data',
        'Ora',
        'Squadra',
        'Casa',
        'Trasferta',
        'Risultato',
        'Campionato',
        'Luogo',
        'Importanza',
        'Convocati',
        'Note',
      ],
      righe: [
        for (final p in _partitePeriodo)
          [
            _giorno(p.data),
            _testo(p.ora),
            _testo(_squadra(p.gruppoId, senza: _tuttoIlClub)),
            _testo(p.squadraCasa),
            _testo(p.squadraTrasferta),
            _testo(_risultato(p)),
            _testo(p.campionato),
            _testo(p.luogo),
            _testo(_importanza(p.importanza)),
            IntCellValue(convocati[p.id] ?? 0),
            _testo(p.note),
          ],
      ],
    );
  }

  _Foglio _convocatiFoglio() {
    final perPartita = _raggruppa(
      dati.distinte,
      (d) => d.partitaId,
      ordina: (a, b) => a.numeroCalottina.compareTo(b.numeroCalottina),
    );
    return _Foglio(
      nome: 'Convocati',
      contenuto: 'Chi era convocato a ogni partita, con calottina e ruolo.',
      titoli: const [
        'Data',
        'Partita',
        'Calottina',
        'Cognome',
        'Nome',
        'Capitano',
        'Vice capitano',
        'Portiere',
        'Fuoriquota',
      ],
      righe: [
        for (final p in _partitePeriodo)
          for (final d in _di(perPartita, p.id))
            [
              _giorno(p.data),
              _testo(_partita(p)),
              IntCellValue(d.numeroCalottina),
              _testo(_cognome(d.atletaId)),
              _testo(_nome(d.atletaId)),
              _siNo(d.capitano),
              _siNo(d.viceCapitano),
              _siNo(d.portiere),
              _siNo(d.fuoriquota),
            ],
      ],
    );
  }

  _Foglio _statistichePartiteFoglio() {
    final righe = <List<CellValue?>>[];
    for (final p in _partitePeriodo) {
      final eventi = _eventiPer[p.id];
      if (eventi == null) continue;
      final perAtleta = StatisticheEventi.da(eventi).perAtleta;
      final atleti = perAtleta.keys.toList()
        ..sort((a, b) => _chiave(a).compareTo(_chiave(b)));
      for (final id in atleti) {
        final n = perAtleta[id]!;
        righe.add([
          _giorno(p.data),
          _testo(_partita(p)),
          _testo(_cognome(id)),
          _testo(_nome(id)),
          IntCellValue(n.tiri),
          IntCellValue(n.gol),
          IntCellValue(n.golAzione),
          IntCellValue(n.golSuperiorita),
          IntCellValue(n.golRigore),
          IntCellValue(n.golControfuga),
          IntCellValue(n.assist),
          IntCellValue(n.pallePerse),
          IntCellValue(n.palleRecuperate),
          IntCellValue(n.espulsioni),
          IntCellValue(n.espulsioniGuadagnate),
          IntCellValue(n.rigoriGuadagnati),
        ]);
      }
    }
    return _Foglio(
      nome: 'Statistiche partite',
      contenuto:
          'Per ogni atleta e partita: tiri, gol, assist, palle ed '
          'espulsioni, contati dalle azioni segnate dal vivo.',
      titoli: const [
        'Data',
        'Partita',
        'Cognome',
        'Nome',
        'Tiri',
        'Gol',
        'Gol su azione',
        'Gol in superiorità',
        'Gol su rigore',
        'Gol in controfuga',
        'Assist',
        'Palle perse',
        'Palle recuperate',
        'Espulsioni',
        'Espulsioni guadagnate',
        'Rigori guadagnati',
      ],
      righe: righe,
    );
  }

  _Foglio _refertiFoglio() {
    final righe = <List<CellValue?>>[];
    for (final p in _partitePeriodo) {
      final r = _refertoPer[p.id];
      if (r == null) continue;
      final parziali = r.parziali.map((x) => '${x.casa}-${x.trasferta}');
      List<CellValue?> riga(String squadra, [GiocatoreReferto? g]) => [
        _giorno(p.data),
        _testo(_partita(p)),
        _testo('${r.risultatoCasa}-${r.risultatoTrasferta}'),
        _testo(parziali.join(', ')),
        _testo(squadra),
        _intero(g?.numeroCalottina),
        _testo(g?.nome),
        _testo(g?.atletaId == null ? null : _atletaNomeCompleto(g!.atletaId!)),
        _intero(g?.reti),
        _intero(g?.espulsioni),
      ];
      final giocatori = [
        for (final g in r.giocatoriCasa) (r.squadraCasa, g),
        for (final g in r.giocatoriTrasferta) (r.squadraTrasferta, g),
      ];
      if (giocatori.isEmpty) {
        righe.add(riga(''));
      } else {
        for (final (squadra, g) in giocatori) {
          righe.add(riga(squadra, g));
        }
      }
    }
    return _Foglio(
      nome: 'Referti',
      contenuto:
          'I referti salvati: risultato, parziali e reti ed espulsioni di '
          'ogni giocatore.',
      titoli: const [
        'Data',
        'Partita',
        'Risultato',
        'Parziali',
        'Squadra',
        'Calottina',
        'Giocatore',
        'Atleta del club',
        'Reti',
        'Espulsioni',
      ],
      righe: righe,
    );
  }

  String _atletaNomeCompleto(String id) =>
      _atleti[id]?.nomeCompleto ?? _eliminato;

  _Foglio _impegniFoglio() {
    final impegni = [
      for (final i in dati.impegni)
        if (i.elencoGiorni.any(periodo.comprende)) i,
    ]..sort((a, b) => a.dal.compareTo(b.dal));
    return _Foglio(
      nome: 'Impegni',
      contenuto: 'Collegiali, trasferte, riposi, tornei e gli altri impegni.',
      titoli: const ['Dal', 'Al', 'Tipo', 'Nome', 'Squadra', 'Luogo', 'Note'],
      righe: [
        for (final i in impegni)
          [
            _giorno(i.dal),
            _giorno(i.al),
            _testo(i.tipo.etichetta),
            _testo(i.nome),
            _testo(_squadra(i.gruppoId, senza: _tuttoIlClub)),
            _testo(i.luogo),
            _testo(i.note),
          ],
      ],
    );
  }

  /// Le note non hanno una data: ci sono tutte, qualunque periodo.
  _Foglio _avversariFoglio() {
    final note = [...dati.noteAvversari]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return _Foglio(
      nome: 'Avversari',
      contenuto: 'Le note dello staff sugli avversari, per squadra.',
      titoli: const [
        'Avversario',
        'Squadra',
        'Nome sul sito FIN',
        'Come giocano',
        'Giocatori',
      ],
      righe: [
        for (final n in note)
          [
            _testo(n.nome),
            _testo(_squadra(n.gruppoId, senza: _tuttoIlClub)),
            _testo(n.nomeFin),
            _testo(n.nota),
            _testo(
              [
                for (final g in n.giocatori)
                  if (!g.vuoto)
                    [
                      [
                        ?g.numero?.toString(),
                        g.nome.trim(),
                      ].where((s) => s.isNotEmpty).join(' '),
                      if (g.nota.trim().isNotEmpty) g.nota.trim(),
                    ].join(': '),
              ].join('; '),
            ),
          ],
      ],
    );
  }

  _Foglio _personalBestFoglio() {
    // Senza data un primato conta solo in "Tutto".
    final primati =
        [
          for (final p in dati.personalBest)
            if (p.data == null ? periodo.eTutto : periodo.comprende(p.data!)) p,
        ]..sort((a, b) {
          final perAtleta = _chiave(a.atletaId).compareTo(_chiave(b.atletaId));
          if (perAtleta != 0) return perAtleta;
          final perStile = a.stile.compareTo(b.stile);
          return perStile != 0 ? perStile : a.distanzaM.compareTo(b.distanzaM);
        });
    return _Foglio(
      nome: 'Personal best',
      contenuto: 'Il primato di ogni atleta per stile e distanza.',
      titoli: const [
        'Cognome',
        'Nome',
        'Stile',
        'Distanza (m)',
        'Tempo',
        'Secondi',
        'Data',
        'Note',
      ],
      righe: [
        for (final p in primati)
          [
            _testo(_cognome(p.atletaId)),
            _testo(_nome(p.atletaId)),
            _testo(labelStile(p.stile)),
            IntCellValue(p.distanzaM),
            _testo(_tempo(p.tempoS)),
            DoubleCellValue(p.tempoS),
            _giorno(p.data),
            _testo(p.note),
          ],
      ],
    );
  }

  _Foglio _testDelPassoFoglio() {
    final test =
        [
          for (final t in dati.testIngresso)
            if (periodo.comprende(t.dataTest)) t,
        ]..sort((a, b) {
          final perData = a.dataTest.compareTo(b.dataTest);
          return perData != 0
              ? perData
              : _chiave(a.atletaId).compareTo(_chiave(b.atletaId));
        });
    return _Foglio(
      nome: 'Test del passo',
      contenuto:
          'I test di ingresso (BVS e T30): distanza, tempo e passo medio '
          'sui 100 m.',
      titoli: const [
        'Data',
        'Cognome',
        'Nome',
        'Test',
        'Distanza totale (m)',
        'Tempo totale',
        'Secondi totali',
        'Passo medio 100 m',
        'Passo medio 100 m (secondi)',
        'Note',
      ],
      righe: [
        for (final t in test)
          [
            _giorno(t.dataTest),
            _testo(_cognome(t.atletaId)),
            _testo(_nome(t.atletaId)),
            _testo(t.tipo),
            IntCellValue(t.distanzaTotaleM),
            _testo(_tempo(t.tempoTotaleS)),
            DoubleCellValue(t.tempoTotaleS),
            _testo(_tempo(t.passoMedio100S)),
            DoubleCellValue(t.passoMedio100S),
            _testo(t.note),
          ],
      ],
    );
  }

  _Foglio _passiPerZonaFoglio() {
    final perTest = _raggruppa(
      dati.tabellePassi,
      (t) => t.testId,
      ordina: (a, b) {
        final perAtleta = _chiave(a.atletaId).compareTo(_chiave(b.atletaId));
        return perAtleta != 0 ? perAtleta : a.zona.compareTo(b.zona);
      },
    );
    final test = [
      for (final t in dati.testIngresso)
        if (periodo.comprende(t.dataTest)) t,
    ]..sort((a, b) => a.dataTest.compareTo(b.dataTest));
    return _Foglio(
      nome: 'Passi per zona',
      contenuto:
          'Il passo sui 100 m che ogni test di ingresso dà per ogni zona di '
          'lavoro.',
      titoli: const [
        'Data',
        'Test',
        'Cognome',
        'Nome',
        'Zona',
        'Passo 100 m',
        'Passo 100 m (secondi)',
        '% di riferimento',
      ],
      righe: [
        for (final t in test)
          for (final p in _di(perTest, t.id))
            [
              _giorno(t.dataTest),
              _testo(t.tipo),
              _testo(_cognome(p.atletaId)),
              _testo(_nome(p.atletaId)),
              _testo(p.zona),
              _testo(_tempo(p.passo100S)),
              DoubleCellValue(p.passo100S),
              _decimale(p.percentualeRiferimento),
            ],
      ],
    );
  }

  // --- Test del club, sforzo, benessere -----------------------------------

  _Foglio _testDelClubFoglio() {
    final risultati =
        [
          for (final r in dati.risultatiTest)
            if (periodo.comprende(r.data)) r,
        ]..sort((a, b) {
          final perData = a.data.compareTo(b.data);
          if (perData != 0) return perData;
          final perTest = (_test[a.testId]?.nome ?? _eliminato).compareTo(
            _test[b.testId]?.nome ?? _eliminato,
          );
          return perTest != 0
              ? perTest
              : _chiave(a.atletaId).compareTo(_chiave(b.atletaId));
        });
    final prove = risultati.fold<int>(
      0,
      (massimo, r) => math.max(massimo, r.valori.length),
    );
    return _Foglio(
      nome: 'Test del club',
      contenuto:
          'I risultati dei test e dei massimali: ogni prova, il valore che '
          'va in classifica e l\'unità di misura.',
      titoli: [
        'Data',
        'Test',
        'Cognome',
        'Nome',
        for (var i = 1; i <= prove; i++) 'Prova $i',
        'Valore in classifica',
        'Unità',
        'Come si calcola',
        'Chili sollevati',
        'Ripetizioni',
        'Note',
      ],
      righe: [
        for (final r in risultati)
          [
            _giorno(r.data),
            _testo(_test[r.testId]?.nome ?? _eliminato),
            _testo(_cognome(r.atletaId)),
            _testo(_nome(r.atletaId)),
            for (var i = 0; i < prove; i++)
              i < r.valori.length ? DoubleCellValue(r.valori[i]) : null,
            _decimale(
              _test[r.testId] == null || r.valori.isEmpty
                  ? null
                  : _test[r.testId]!.punteggioDi(r.valori),
            ),
            _testo(_test[r.testId]?.unita.sigla),
            _testo(_test[r.testId]?.comeSiLegge),
            _decimale(r.caricoKg),
            _intero(r.ripetizioni),
            _testo(r.note),
          ],
      ],
    );
  }

  _Foglio _sforzoFoglio() {
    final sedute =
        [
          for (final r in dati.rpeSedute)
            if (periodo.comprende(r.data)) r,
        ]..sort((a, b) {
          final perData = a.data.compareTo(b.data);
          return perData != 0
              ? perData
              : _chiave(a.atletaId).compareTo(_chiave(b.atletaId));
        });

    /// Minuti e carico della seduta per quell'atleta, come li conta l'app.
    CaricoSeduta? carico(RpeSeduta r) {
      final rpe = r.rpe;
      final eventoId = r.eventoId;
      final giorno = r.data;
      if (r.eventoTipo == 'partita') {
        if (!_partite.containsKey(eventoId)) return null;
        return caricoPartita(id: eventoId, giorno: giorno, rpe: rpe);
      }
      final a = _allenamenti[eventoId];
      if (a == null) return null;
      if (a.secco) {
        return caricoSecco(
          id: eventoId,
          giorno: giorno,
          minuti: a.durataMin ?? minutiSeccoPredefiniti,
          rpe: rpe,
        );
      }
      final atleta = _atleti[r.atletaId];
      final sue = serieDellAtleta(
        [
          for (final s in _seriePer[eventoId] ?? const <Serie>[])
            if (!s.saltata) s,
        ],
        atleta?.id,
        atleta?.ruolo,
      );
      return caricoAllenamento(
        id: eventoId,
        giorno: giorno,
        serie: sue,
        rpe: rpe,
      );
    }

    return _Foglio(
      nome: 'Sforzo (RPE)',
      contenuto:
          'Quanto è stata dura ogni seduta per ogni atleta (da 0 a 10), con '
          'minuti e carico stimati come nel resto dell\'app.',
      titoli: const [
        'Data',
        'Cognome',
        'Nome',
        'Seduta',
        'RPE',
        'Minuti',
        'Carico (RPE × minuti)',
      ],
      righe: [
        for (final r in sedute)
          [
            _giorno(r.data),
            _testo(_cognome(r.atletaId)),
            _testo(_nome(r.atletaId)),
            _testo(_seduta(r.eventoTipo, r.eventoId)),
            IntCellValue(r.rpe),
            _intero(carico(r)?.minuti),
            _intero(carico(r)?.totale.round()),
          ],
      ],
    );
  }

  _Foglio _benessereFoglio() {
    final schede =
        [
          if (conBenessere)
            for (final s in dati.schedeBenessere ?? const <SchedaBenessere>[])
              if (periodo.comprende(s.data)) s,
        ]..sort((a, b) {
          final perData = a.data.compareTo(b.data);
          return perData != 0
              ? perData
              : _chiave(a.atletaId).compareTo(_chiave(b.atletaId));
        });
    return _Foglio(
      nome: 'Benessere',
      benessere: true,
      contenuto:
          'Le schede benessere: sonno, energia, muscoli, stress e umore '
          '(da 1 a 5, 5 = meglio), dolori e sintomi.',
      titoli: const [
        'Data',
        'Cognome',
        'Nome',
        'Prima di',
        'Ore di sonno',
        'Come ha dormito (1-5)',
        'Energia (1-5)',
        'Muscoli (1-5)',
        'Stress (1-5)',
        'Umore (1-5)',
        'Dolori',
        'Zone del dolore',
        'Intensità del dolore (1-10)',
        'Sintomi',
        'Compilata il',
      ],
      righe: [
        for (final s in schede)
          [
            _giorno(s.data),
            _testo(_cognome(s.atletaId)),
            _testo(_nome(s.atletaId)),
            _testo(_seduta(s.eventoTipo, s.eventoId)),
            DoubleCellValue(s.oreSonno),
            _intero(s.qualitaSonno),
            _intero(s.energia),
            _intero(s.muscoli),
            _intero(s.stress),
            _intero(s.umore),
            _siNo(s.dolori),
            _testo(s.zoneDolore.map(etichettaZona).join(', ')),
            _intero(s.intensitaDolore),
            _testo(s.sintomi.map(etichettaSintomo).join(', ')),
            _giornoOra(s.compilataIl),
          ],
      ],
    );
  }
}
