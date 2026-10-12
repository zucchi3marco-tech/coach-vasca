import 'atleta.dart';

const _accenti = {
  'à': 'a',
  'á': 'a',
  'è': 'e',
  'é': 'e',
  'ì': 'i',
  'í': 'i',
  'ò': 'o',
  'ó': 'o',
  'ù': 'u',
  'ú': 'u',
};

List<String> _parole(String testo) {
  var t = testo.toLowerCase();
  for (final MapEntry(key: da, value: a) in _accenti.entries) {
    t = t.replaceAll(da, a);
  }
  return t
      .replaceAll(RegExp(r'[^a-z]+'), ' ')
      .split(' ')
      .where((p) => p.isNotEmpty)
      .toList();
}

/// L'atleta a cui si riferisce il [nome] scritto (sul foglio dei tempi,
/// nel testo di un allenamento): cognome, nome, entrambi in qualsiasi
/// ordine, o il cognome con l'iniziale ("Rossi M."). null se nessuno
/// corrisponde o se più atleti corrispondono allo stesso modo: lo sceglie
/// l'allenatore.
Atleta? abbinaAtleta(String nome, List<Atleta> atleti) {
  final scritte = _parole(nome);
  if (scritte.isEmpty) return null;
  int punteggio(Atleta a) {
    final cognome = _parole(a.cognome);
    final nomi = _parole(a.nome);
    var punti = 0;
    for (final p in scritte) {
      if (cognome.contains(p)) {
        punti += 3;
      } else if (nomi.contains(p)) {
        punti += 2;
      } else if (p.length == 1 && nomi.any((n) => n.startsWith(p))) {
        punti += 1;
      } else {
        // Una parola che non è sua: è un altro atleta.
        return 0;
      }
    }
    return punti;
  }

  Atleta? migliore;
  var massimo = 0;
  var pari = false;
  for (final a in atleti) {
    final p = punteggio(a);
    if (p > massimo) {
      migliore = a;
      massimo = p;
      pari = false;
    } else if (p == massimo && p > 0) {
      pari = true;
    }
  }
  return massimo >= 2 && !pari ? migliore : null;
}

/// Il modo più corto di scrivere [atleta] perché [abbinaAtleta] lo
/// ritrovi fra gli [atleti]: il cognome, se basta; poi con l'iniziale del
/// nome ("Rossi M."); poi cognome e nome.
String nomeBreve(Atleta atleta, List<Atleta> atleti) {
  final iniziale = atleta.nome.trim().isEmpty
      ? ''
      : ' ${atleta.nome.trim()[0].toUpperCase()}.';
  for (final candidato in [
    atleta.cognome,
    '${atleta.cognome}$iniziale',
    '${atleta.cognome} ${atleta.nome}',
  ]) {
    if (abbinaAtleta(candidato, atleti)?.id == atleta.id) return candidato;
  }
  return '${atleta.cognome} ${atleta.nome}';
}
