/// I campionati regionali di pallanuoto della FIN Lombardia, letti dal
/// sito pubblico (finlombardia.net): l'elenco dei gironi di una stagione
/// e, per ogni girone, la classifica e il calendario con i risultati.
/// Sono dati pubblici della federazione: l'app li legge e basta.
library;

/// Indirizzo della pagina di un girone sul sito FIN, per il link "Fonte".
String indirizzoGironeFin(int cmpId) =>
    'https://www.finlombardia.net/PHP/PN-Incontri.php?CMPid=$cmpId';

/// Una riga dell'elenco dei campionati: un girone di una fase.
class VoceElencoFin {
  const VoceElencoFin({
    required this.cmpId,
    required this.campionato,
    required this.fase,
    required this.girone,
  });

  /// L'identificativo del girone sul sito FIN (`CMPid`).
  final int cmpId;
  final String campionato;
  final String fase;
  final String girone;

  /// "Fase 1 · Girone 2".
  String get faseEGirone =>
      [fase, girone].where((s) => s.isNotEmpty).join(' · ');
}

/// L'elenco dei campionati di una stagione.
class ElencoFin {
  const ElencoFin({
    required this.stagione,
    required this.stagioni,
    required this.voci,
  });

  /// La stagione mostrata, es. "2026-2027".
  final String stagione;

  /// Tutte le stagioni che il sito offre, dalla più vecchia.
  final List<String> stagioni;
  final List<VoceElencoFin> voci;

  /// I gironi raggruppati per campionato, nell'ordine del sito.
  Map<String, List<VoceElencoFin>> get perCampionato {
    final gruppi = <String, List<VoceElencoFin>>{};
    for (final v in voci) {
      gruppi.putIfAbsent(v.campionato, () => []).add(v);
    }
    return gruppi;
  }
}

class RigaClassificaFin {
  const RigaClassificaFin({
    required this.posizione,
    required this.squadra,
    required this.punti,
    required this.giocate,
    required this.vinte,
    required this.pareggiate,
    required this.perse,
    required this.golFatti,
    required this.golSubiti,
    required this.differenza,
  });

  final int posizione;
  final String squadra;
  final int punti;
  final int giocate;
  final int vinte;
  final int pareggiate;
  final int perse;
  final int golFatti;
  final int golSubiti;
  final int differenza;
}

class IncontroFin {
  const IncontroFin({
    required this.casa,
    required this.ospite,
    this.piscina,
    this.ora,
    this.data,
    this.dataTesto,
    this.golCasa,
    this.golOspite,
    this.risultatoTesto,
    this.arbitro,
  });

  final String casa;
  final String ospite;
  final String? piscina;

  /// "19:30".
  final String? ora;
  final DateTime? data;

  /// La data come la scrive il sito ("sabato 7/3/2026"), quando non si
  /// riesce a leggerla.
  final String? dataTesto;
  final int? golCasa;
  final int? golOspite;

  /// Quello che il sito scrive al posto del risultato quando non è un
  /// punteggio (es. "rinviata").
  final String? risultatoTesto;
  final String? arbitro;

  bool get giocato => golCasa != null && golOspite != null;

  /// La giornata di riposo di una squadra: il sito la scrive come un
  /// incontro con "riposo" al posto dell'avversaria.
  bool get riposo => _chiave(casa) == 'riposo' || _chiave(ospite) == 'riposo';

  bool coinvolge(String squadra) =>
      stessaSquadra(casa, squadra) || stessaSquadra(ospite, squadra);
}

class GiornataFin {
  const GiornataFin({required this.nome, required this.incontri});

  /// "1a giornata".
  final String nome;
  final List<IncontroFin> incontri;
}

class GironeFin {
  const GironeFin({
    required this.cmpId,
    required this.stagione,
    required this.titolo,
    required this.classifica,
    required this.giornate,
  });

  final int cmpId;

  /// "2025-2026", dall'intestazione della pagina.
  final String? stagione;

  /// "Cadetti (M) - Fase1 - Girone1".
  final String titolo;
  final List<RigaClassificaFin> classifica;
  final List<GiornataFin> giornate;

  /// Le squadre del girone: quelle in classifica o, se la classifica
  /// non c'è ancora, quelle del calendario.
  List<String> get squadre {
    if (classifica.isNotEmpty) return [for (final r in classifica) r.squadra];
    final nomi = <String>{};
    for (final g in giornate) {
      for (final i in g.incontri) {
        nomi
          ..add(i.casa)
          ..add(i.ospite);
      }
    }
    nomi.removeWhere((n) => _chiave(n) == 'riposo');
    return nomi.toList()..sort();
  }

  RigaClassificaFin? rigaDi(String squadra) {
    for (final r in classifica) {
      if (stessaSquadra(r.squadra, squadra)) return r;
    }
    return null;
  }

  /// Gli incontri di [squadra], in ordine di calendario.
  List<IncontroFin> incontriDi(String squadra) => [
    for (final g in giornate)
      for (final i in g.incontri)
        if (i.coinvolge(squadra)) i,
  ];

  /// Il primo incontro di [squadra] ancora da giocare.
  IncontroFin? prossimoDi(String squadra) {
    for (final i in incontriDi(squadra)) {
      if (!i.giocato && !i.riposo && i.risultatoTesto == null) return i;
    }
    return null;
  }
}

/// Un girone FIN collegato a una squadra del club: lo sceglie
/// l'allenatore, con il nome della squadra come lo scrive il sito.
class GironeCollegato {
  const GironeCollegato({
    required this.id,
    required this.clubId,
    required this.cmpId,
    required this.stagione,
    required this.campionato,
    required this.squadra,
    this.gruppoId,
    this.fase,
    this.girone,
    this.creatoIl,
  });

  final String id;
  final String clubId;

  /// null = vale per tutto il club.
  final String? gruppoId;
  final int cmpId;
  final String stagione;
  final String campionato;
  final String? fase;
  final String? girone;

  /// Il nome della squadra del club come lo scrive il sito FIN.
  final String squadra;
  final DateTime? creatoIl;

  /// "Fase 1 · Girone 2".
  String get faseEGirone =>
      [fase, girone].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

  factory GironeCollegato.daMap(Map<String, dynamic> m) => GironeCollegato(
    id: m['id'] as String,
    clubId: m['club_id'] as String,
    gruppoId: m['gruppo_id'] as String?,
    cmpId: (m['cmp_id'] as num).toInt(),
    stagione: m['stagione'] as String,
    campionato: m['campionato'] as String,
    fase: m['fase'] as String?,
    girone: m['girone'] as String?,
    squadra: m['squadra'] as String,
    creatoIl: m['created_at'] == null
        ? null
        : DateTime.tryParse(m['created_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'club_id': clubId,
    'gruppo_id': gruppoId,
    'cmp_id': cmpId,
    'stagione': stagione,
    'campionato': campionato,
    'fase': fase,
    'girone': girone,
    'squadra': squadra,
    if (creatoIl != null) 'created_at': creatoIl!.toIso8601String(),
  };
}

/// Lo stesso nome di squadra a meno di maiuscole e spazi.
bool stessaSquadra(String a, String b) => _chiave(a) == _chiave(b);

String _chiave(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
