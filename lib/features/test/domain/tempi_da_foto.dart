import '../../../core/utils/pace_format.dart';
import '../../atleti/domain/atleta.dart';

/// Una riga del foglio dei tempi letta dalla foto (Edge Function
/// `leggi-tempi`): il nome come è scritto, i tempi della riga in secondi
/// e, se c'è, la distanza.
class RigaTempiLetta {
  const RigaTempiLetta({
    required this.nome,
    required this.tempiS,
    this.distanzaM,
  });

  factory RigaTempiLetta.fromMap(Map<String, dynamic> m) => RigaTempiLetta(
    nome: m['nome'] as String,
    tempiS: [for (final t in m['tempiS'] as List) (t as num).toDouble()],
    distanzaM: (m['distanzaM'] as num?)?.round(),
  );

  final String nome;
  final List<double> tempiS;
  final int? distanzaM;

  /// Il tempo migliore della riga (il più basso), se ce n'è uno.
  double? get migliore =>
      tempiS.isEmpty ? null : tempiS.reduce((a, b) => a < b ? a : b);
}

/// Dove vanno i tempi del foglio.
enum DestinazioneTempi {
  /// Un tempo su una distanza e uno stile: va fra i tempi dell'atleta
  /// (personal best).
  tempi('Tempi'),

  /// Test BVS: distanza e tempo di ogni atleta.
  bvs('Test BVS'),

  /// Test T30: i metri nuotati in 30 minuti.
  t30('Test T30');

  const DestinazioneTempi(this.etichetta);

  final String etichetta;
}

/// Un tempo scritto a mano o a tastiera: "1'05\"20", "1'05.2", "1:05.2",
/// "65,2" o "32\"5". null se non è un tempo.
double? leggiTempo(String testo) {
  final t = testo
      .trim()
      .replaceAll(',', '.')
      .replaceAll('\'', ':')
      .replaceAll('"', '.')
      .replaceAll(RegExp(r'\.$'), '');
  final secondi = parsePaceMmSs(t);
  return secondi == null || secondi <= 0 ? null : secondi;
}

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

/// L'atleta a cui si riferisce il [nome] scritto sul foglio: cognome,
/// nome, entrambi in qualsiasi ordine, o il cognome con l'iniziale
/// ("Rossi M."). null se nessuno corrisponde o se più atleti
/// corrispondono allo stesso modo: lo sceglie l'allenatore.
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
