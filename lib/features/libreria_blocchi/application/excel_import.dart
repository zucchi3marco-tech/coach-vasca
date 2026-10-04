import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Un blocco letto dal file Excel, pronto per essere confrontato con
/// quelli già in libreria (dall'[codice]) e inserito/aggiornato.
class BloccoImportato {
  const BloccoImportato({
    required this.codice,
    required this.sport,
    required this.fase,
    required this.obiettivo,
    required this.zoneCoinvolte,
    required this.titolo,
    required this.descrizione,
    this.stilePrincipale,
    required this.livelli,
    this.attrezzi,
    required this.metriTotali,
    required this.durataStimataMin,
    this.note,
    required this.stato,
    required this.fonte,
    required this.parti,
  });

  final String codice;
  final String sport;
  final String fase;
  final String obiettivo;
  final String zoneCoinvolte;
  final String titolo;
  final String descrizione;
  final String? stilePrincipale;
  final String livelli;
  final String? attrezzi;
  final int metriTotali;
  final int durataStimataMin;
  final String? note;
  final String stato;
  final String fonte;
  final List<ParteImportata> parti;
}

class ParteImportata {
  const ParteImportata({
    required this.ordine,
    required this.giri,
    required this.ripetizioni,
    this.distanzaM,
    this.durataS,
    this.stile,
    this.esercizio,
    required this.zona,
    required this.esecuzione,
    this.recuperoS,
    this.attrezzi,
    this.note,
  });

  final int ordine;
  final int giri;
  final int ripetizioni;
  final int? distanzaM;
  final int? durataS;
  final String? stile;
  final String? esercizio;
  final String zona;
  final String esecuzione;
  final int? recuperoS;
  final String? attrezzi;
  final String? note;

  bool get aTempo => durataS != null;
}

class RigaErrore {
  const RigaErrore({
    required this.foglio,
    required this.riga,
    required this.messaggio,
  });

  final String foglio;

  /// Numero di riga come lo vede il coach nel file (1 = intestazione).
  final int riga;
  final String messaggio;

  @override
  String toString() => '$foglio, riga $riga: $messaggio';
}

class RisultatoParsingLibreria {
  const RisultatoParsingLibreria({required this.blocchi, required this.errori});

  final List<BloccoImportato> blocchi;
  final List<RigaErrore> errori;
}

const _zoneValideParte = {
  'A1',
  'A2',
  'B1',
  'B2',
  'C1',
  'C2',
  'V',
  'RG',
  'T',
  'TT',
  'TEST',
};

const _sportValidi = {'nuoto', 'pallanuoto', 'entrambi'};

String? _testo(Data? cella) {
  final v = cella?.value;
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _intero(Data? cella) {
  final v = cella?.value;
  if (v == null) return null;
  if (v is IntCellValue) return v.value;
  if (v is DoubleCellValue) return v.value.round();
  return int.tryParse(v.toString().trim());
}

/// Fasi del blocco che, da sole, non bastano a dedurre l'esecuzione
/// nemmeno al terzo livello (restano "nuoto", il valore di base).
const _fasiTattiche = {
  'Tiro',
  'Passaggi',
  'Portiere',
  'Attacco',
  'Difesa',
  'Partita a tema',
  'Tattica',
};

/// Deduce l'esecuzione di una parte in tre passi (priorità in ordine),
/// come deciso nel piano di FASE 1: prima la zona della parte, poi il
/// testo dell'esercizio, infine la fase del blocco. Il testo originale
/// non va mai perso: resta comunque in [ParteImportata.esercizio] e
/// [ParteImportata.zona], qualunque cosa venga dedotta qui.
String deduciEsecuzione({
  required String zona,
  required String? esercizio,
  required String faseBlocco,
}) {
  if (zona == 'T') return 'tecnica';
  if (zona == 'TT') return 'pallanuoto tecnico-tattico';

  final testo = esercizio?.toLowerCase() ?? '';
  if (testo.isNotEmpty) {
    if (testo.contains('gambe')) return 'gambe';
    final haPull = testo.contains('pull') || testo.contains('palette');
    if (testo.contains('braccia') && !haPull) return 'braccia';
    if (haPull) return 'pull';
    if (testo.contains('tecnica') || testo.contains('drill')) return 'tecnica';
  }

  switch (faseBlocco) {
    case 'Gambe':
      return 'gambe';
    case 'Braccia':
      return 'pull';
    case 'Tecnica':
      return 'tecnica';
    case 'Nuoto specifico':
    case 'Condizionamento':
      return 'nuoto';
    case 'A secco':
      return 'a secco';
  }
  if (_fasiTattiche.contains(faseBlocco)) return 'pallanuoto tecnico-tattico';
  return 'nuoto';
}

/// Passo medio (secondi per 100m) usato per stimare la durata di un
/// blocco dai suoi metri — foglio "Legenda", riga "Passo medio per
/// stimare la durata": stessa formula della cella-formula "Durata
/// stimata" del foglio Blocchi, che il package `excel` non valuta.
/// 110 è il valore di fabbrica del file attuale, usato solo se il
/// foglio Legenda manca o non lo contiene.
int _passoMedioDaLegenda(Sheet? legenda) {
  if (legenda == null) return 110;
  for (var i = 1; i < legenda.maxRows; i++) {
    final riga = legenda.row(i);
    final parametro = _testo(riga.elementAtOrNull(6));
    if (parametro != null && parametro.toLowerCase().contains('passo medio')) {
      return _intero(riga.elementAtOrNull(7)) ?? 110;
    }
  }
  return 110;
}

String _sportDaExcel(String testo) => switch (testo.trim().toLowerCase()) {
  'nuoto' => 'nuoto',
  'pallanuoto' => 'pallanuoto',
  'entrambi' => 'entrambi',
  _ => testo.trim().toLowerCase(),
};

/// Interpreta il file Excel della libreria blocchi (fogli "Blocchi" e
/// "Parti", stesso formato di `libreria_blocchi_nuoto_pallanuoto.xlsx`).
/// Un blocco con anche una sola parte non valida viene scartato per
/// intero (meglio niente che una scheda a metà), con l'errore riportato
/// riga per riga — mai un'eccezione che blocca tutto il file.
RisultatoParsingLibreria parseLibreriaExcel(Uint8List bytes) {
  final wb = Excel.decodeBytes(bytes);
  final erroriGlobali = <RigaErrore>[];

  final foglioBlocchi = wb.tables['Blocchi'];
  final foglioParti = wb.tables['Parti'];
  if (foglioBlocchi == null || foglioParti == null) {
    return const RisultatoParsingLibreria(
      blocchi: [],
      errori: [
        RigaErrore(
          foglio: 'file',
          riga: 0,
          messaggio: 'Mancano i fogli "Blocchi" e/o "Parti": file non valido.',
        ),
      ],
    );
  }

  final passoMedioS100 = _passoMedioDaLegenda(wb.tables['Legenda']);

  // Parti raggruppate per "ID blocco", nell'ordine del file.
  final partiPerBlocco = <String, List<(int, List<Data?>)>>{};
  for (var i = 1; i < foglioParti.maxRows; i++) {
    final riga = foglioParti.row(i);
    final idBlocco = _testo(riga.elementAtOrNull(0));
    if (idBlocco == null) continue;
    (partiPerBlocco[idBlocco] ??= []).add((i + 1, riga));
  }

  final blocchi = <BloccoImportato>[];
  for (var i = 1; i < foglioBlocchi.maxRows; i++) {
    final rigaNum = i + 1;
    final riga = foglioBlocchi.row(i);
    final codice = _testo(riga.elementAtOrNull(0));
    if (codice == null) continue;

    final sportTesto = _testo(riga.elementAtOrNull(1));
    final sport = sportTesto == null ? null : _sportDaExcel(sportTesto);
    if (sport == null || !_sportValidi.contains(sport)) {
      erroriGlobali.add(
        RigaErrore(
          foglio: 'Blocchi',
          riga: rigaNum,
          messaggio: 'Sport non riconosciuto ("$sportTesto") per $codice.',
        ),
      );
      continue;
    }

    final fase = _testo(riga.elementAtOrNull(2)) ?? '';
    final obiettivo = _testo(riga.elementAtOrNull(3)) ?? '';
    final zoneCoinvolte = _testo(riga.elementAtOrNull(4)) ?? '';
    final titolo = _testo(riga.elementAtOrNull(5));
    final descrizione = _testo(riga.elementAtOrNull(6)) ?? '';
    final stilePrincipale = _testo(riga.elementAtOrNull(7));
    final livelli = _testo(riga.elementAtOrNull(8)) ?? '';
    final attrezzi = _testo(riga.elementAtOrNull(9));
    // "Metri totali" e "Durata stimata" sono celle-formula nell'Excel
    // (calcolate dal foglio Parti): il package excel non le valuta, le
    // ricalcoliamo noi dalle parti già lette, con la stessa formula.
    final noteBlocco = _testo(riga.elementAtOrNull(12));
    final stato = _testo(riga.elementAtOrNull(13)) ?? 'bozza';
    final fonte = _testo(riga.elementAtOrNull(14)) ?? 'Allenatore';

    if (titolo == null) {
      erroriGlobali.add(
        RigaErrore(
          foglio: 'Blocchi',
          riga: rigaNum,
          messaggio: 'Titolo mancante per $codice.',
        ),
      );
      continue;
    }

    final righeParte = partiPerBlocco[codice] ?? const [];
    if (righeParte.isEmpty) {
      erroriGlobali.add(
        RigaErrore(
          foglio: 'Blocchi',
          riga: rigaNum,
          messaggio: 'Nessuna parte trovata per $codice: blocco scartato.',
        ),
      );
      continue;
    }

    final parti = <ParteImportata>[];
    var bloccoValido = true;
    for (final (numRigaParte, rigaParte) in righeParte) {
      final giri = _intero(rigaParte.elementAtOrNull(2)) ?? 1;
      final ripetizioni = _intero(rigaParte.elementAtOrNull(3)) ?? 1;
      final distanzaM = _intero(rigaParte.elementAtOrNull(4));
      final durataS = _intero(rigaParte.elementAtOrNull(5));
      final stile = _testo(rigaParte.elementAtOrNull(6));
      final esercizio = _testo(rigaParte.elementAtOrNull(7));
      final zonaTesto = _testo(rigaParte.elementAtOrNull(8));
      final zona = zonaTesto?.trim().toUpperCase();
      final recuperoS = _intero(rigaParte.elementAtOrNull(9));
      final attrezziParte = _testo(rigaParte.elementAtOrNull(10));
      final noteParte = _testo(rigaParte.elementAtOrNull(11));

      if (zona == null || !_zoneValideParte.contains(zona)) {
        erroriGlobali.add(
          RigaErrore(
            foglio: 'Parti',
            riga: numRigaParte,
            messaggio: 'Zona non valida ("$zonaTesto") per $codice.',
          ),
        );
        bloccoValido = false;
        continue;
      }
      if ((distanzaM == null) == (durataS == null)) {
        erroriGlobali.add(
          RigaErrore(
            foglio: 'Parti',
            riga: numRigaParte,
            messaggio: distanzaM == null
                ? 'Manca sia la distanza che la durata per $codice.'
                : 'Distanza e durata non possono stare insieme per $codice.',
          ),
        );
        bloccoValido = false;
        continue;
      }

      parti.add(
        ParteImportata(
          ordine: parti.length + 1,
          giri: giri,
          ripetizioni: ripetizioni,
          distanzaM: distanzaM,
          durataS: durataS,
          stile: stile,
          esercizio: esercizio,
          zona: zona,
          esecuzione: deduciEsecuzione(
            zona: zona,
            esercizio: esercizio,
            faseBlocco: fase,
          ),
          recuperoS: recuperoS,
          attrezzi: attrezziParte,
          note: noteParte,
        ),
      );
    }

    if (!bloccoValido) continue;

    final metriTotali = parti.fold<int>(
      0,
      (t, p) => t + p.giri * p.ripetizioni * (p.distanzaM ?? 0),
    );
    final secondiRecuperoETempo = parti.fold<int>(
      0,
      (t, p) =>
          t + p.giri * p.ripetizioni * ((p.durataS ?? 0) + (p.recuperoS ?? 0)),
    );
    final durataStimataMin =
        ((metriTotali * passoMedioS100 / 100 + secondiRecuperoETempo) / 60)
            .round();

    blocchi.add(
      BloccoImportato(
        codice: codice,
        sport: sport,
        fase: fase,
        obiettivo: obiettivo,
        zoneCoinvolte: zoneCoinvolte,
        titolo: titolo,
        descrizione: descrizione,
        stilePrincipale: stilePrincipale,
        livelli: livelli,
        attrezzi: attrezzi,
        metriTotali: metriTotali,
        durataStimataMin: durataStimataMin,
        note: noteBlocco,
        stato: stato == 'approvato' ? 'approvato' : 'bozza',
        fonte: fonte,
        parti: parti,
      ),
    );
  }

  return RisultatoParsingLibreria(blocchi: blocchi, errori: erroriGlobali);
}
