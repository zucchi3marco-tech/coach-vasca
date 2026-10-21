/// I numeri di calottina della distinta (richiesta del coach 2026-10-21):
/// ognuno riprende il numero dell'ultima partita della squadra, i
/// portieri l'1 e il 13, gli altri il primo libero dal 2 in su.
library;

import 'partita.dart';

/// Chi entra in distinta, nell'ordine in cui il coach l'ha scelto.
typedef ConvocatoScelto = ({String atletaId, bool portiere});

/// Com'era un atleta nell'ultima partita della squadra.
typedef NellUltimaPartita = ({int numero, bool capitano, bool viceCapitano});

/// Quello che serve per cercare l'ultima partita della stessa squadra
/// (un record: due chiavi uguali sono la stessa ricerca).
typedef ChiavePartitaDistinta = ({
  String partitaId,
  String clubId,
  String? gruppoId,
  DateTime data,
});

ChiavePartitaDistinta chiaveDistinta(Partita p) =>
    (partitaId: p.id, clubId: p.clubId, gruppoId: p.gruppoId, data: p.data);

/// La distinta dell'ultima partita della squadra.
class UltimaDistinta {
  const UltimaDistinta({
    required this.partitaId,
    required this.data,
    required this.avversario,
    required this.perAtleta,
  });

  final String partitaId;
  final DateTime data;
  final String avversario;

  /// Id dell'atleta → numero, capitano, vice.
  final Map<String, NellUltimaPartita> perAtleta;
}

/// I numeri dei portieri: il titolare e la riserva (regolamento FIN).
const numeriPortieri = [1, 13];

/// I numeri per chi non ha già il suo, in ordine di preferenza: dal 2 al
/// 12, poi dal 14 al massimo dei convocati; il 13 solo dopo (resta al
/// secondo portiere, se c'è), poi l'1, poi oltre il massimo.
Iterable<int> numeriMovimento(int massimo) sync* {
  for (var n = 2; n <= 12; n++) {
    yield n;
  }
  for (var n = 14; n <= massimo; n++) {
    yield n;
  }
  yield 13;
  yield 1;
  for (var n = 14; ; n++) {
    yield n;
  }
}

/// Il numero di ognuno dei [nuovi], senza toccare gli [occupati] (i
/// numeri di chi è già in distinta e resta).
///
/// 1. I portieri: il numero dell'ultima partita se era l'1 o il 13,
///    altrimenti l'1 o il 13 se è libero.
/// 2. Tutti gli altri riprendono il numero dell'ultima partita, se è
///    libero.
/// 3. Chi resta prende il primo libero di [numeriMovimento], nell'ordine
///    in cui è stato scelto.
///
/// I portieri passano per primi anche se il coach li ha toccati per
/// ultimi: così l'1 e il 13 sono loro.
Map<String, int> numeriProposti({
  required Set<int> occupati,
  required List<ConvocatoScelto> nuovi,
  Map<String, NellUltimaPartita> ultimaPartita = const {},
  required int massimo,
}) {
  final usati = {...occupati};
  final numeri = <String, int>{};
  bool prendi(String atletaId, int numero) {
    if (numeri.containsKey(atletaId) || usati.contains(numero)) return false;
    usati.add(numero);
    numeri[atletaId] = numero;
    return true;
  }

  final portieri = [
    for (final c in nuovi)
      if (c.portiere) c,
  ];
  for (final p in portieri) {
    final prima = ultimaPartita[p.atletaId]?.numero;
    if (prima != null && numeriPortieri.contains(prima)) {
      prendi(p.atletaId, prima);
    }
  }
  for (final p in portieri) {
    for (final n in numeriPortieri) {
      if (prendi(p.atletaId, n)) break;
    }
  }
  for (final c in nuovi) {
    final prima = ultimaPartita[c.atletaId]?.numero;
    if (prima != null) prendi(c.atletaId, prima);
  }
  for (final c in nuovi) {
    if (numeri.containsKey(c.atletaId)) continue;
    for (final n in numeriMovimento(massimo)) {
      if (prendi(c.atletaId, n)) break;
    }
  }
  return numeri;
}

/// I numeri dopo "Riordina": i primi due [portieri] all'1 e al 13, gli
/// [altri] nell'ordine della lista dal 2 in su (il 13 resta libero solo
/// se c'è il secondo portiere). Le chiavi sono quelle passate (l'id della
/// riga della distinta).
Map<String, int> numeriInOrdine({
  required List<String> portieri,
  required List<String> altri,
}) {
  final numeri = <String, int>{};
  final fissi = portieri.take(numeriPortieri.length).toList();
  for (var i = 0; i < fissi.length; i++) {
    numeri[fissi[i]] = numeriPortieri[i];
  }
  final usati = numeri.values.toSet();
  var prossimo = 2;
  for (final id in [...portieri.skip(fissi.length), ...altri]) {
    while (usati.contains(prossimo)) {
      prossimo++;
    }
    numeri[id] = prossimo;
    usati.add(prossimo);
  }
  return numeri;
}

/// Capitano e vice dell'ultima partita, se sono fra i [convocati] (id
/// degli atleti) e la distinta non li ha già.
({String? capitano, String? vice}) capitaniProposti({
  required Iterable<String> convocati,
  required Map<String, NellUltimaPartita> ultimaPartita,
  bool haGiaCapitano = false,
  bool haGiaVice = false,
}) {
  final ci = convocati.toSet();
  String? cerca(bool Function(NellUltimaPartita u) ruolo) {
    for (final e in ultimaPartita.entries) {
      if (ruolo(e.value) && ci.contains(e.key)) return e.key;
    }
    return null;
  }

  return (
    capitano: haGiaCapitano ? null : cerca((u) => u.capitano),
    vice: haGiaVice ? null : cerca((u) => u.viceCapitano),
  );
}

/// "Come l'ultima partita": gli atleti di quella distinta, in ordine di
/// numero.
List<String> convocatiUltimaPartita(Map<String, NellUltimaPartita> ultima) {
  final voci = ultima.entries.toList()
    ..sort((a, b) => a.value.numero.compareTo(b.value.numero));
  return [for (final v in voci) v.key];
}
