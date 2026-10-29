import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';

/// I codici al posto dei nomi (decisione del 13 ottobre 2026: gli atleti
/// sono minorenni). Ogni atleta del club diventa "G1", "G2"... (G come
/// giocatore: A1 e A2 sono zone di intensità). L'app toglie i nomi da tutto
/// quello che manda al modello e li rimette in quello che gli fa vedere.
/// I codici valgono per una conversazione: non si salvano da nessuna parte.
class Pseudonimi {
  Pseudonimi(List<Atleta> atleti)
    : _atleti = [...atleti]
        ..sort((a, b) {
          final c = a.cognome.toLowerCase().compareTo(b.cognome.toLowerCase());
          return c != 0
              ? c
              : a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        }) {
    for (final (i, a) in _atleti.indexed) {
      final codice = 'G${i + 1}';
      _codici[a.id] = codice;
      _perCodice[codice] = a;
    }
    // Dal più lungo al più corto: "Rossi Mario" prima di "Rossi".
    final nomi = <(String, String)>[];
    final contaNomi = <String, int>{};
    for (final a in _atleti) {
      final n = a.nome.trim().toLowerCase();
      if (n.isNotEmpty) contaNomi[n] = (contaNomi[n] ?? 0) + 1;
    }
    final contaCognomi = <String, int>{};
    for (final a in _atleti) {
      final c = a.cognome.trim().toLowerCase();
      if (c.isNotEmpty) contaCognomi[c] = (contaCognomi[c] ?? 0) + 1;
    }
    for (final a in _atleti) {
      final codice = _codici[a.id]!;
      final nome = a.nome.trim();
      final cognome = a.cognome.trim();
      if (nome.isNotEmpty && cognome.isNotEmpty) {
        nomi
          ..add(('$cognome $nome', codice))
          ..add(('$nome $cognome', codice))
          ..add(('$cognome ${nome[0]}.', codice));
      }
      // Un cognome o un nome da solo solo se è di uno solo: con due Rossi
      // "Rossi" non si sa chi è, ma va tolto lo stesso (sotto).
      if (cognome.length >= 2 && contaCognomi[cognome.toLowerCase()] == 1) {
        nomi.add((cognome, codice));
      }
      if (nome.length >= 3 && contaNomi[nome.toLowerCase()] == 1) {
        nomi.add((nome, codice));
      }
    }
    // Cognomi e nomi di più atleti: il nome sparisce lo stesso, con un
    // segnaposto che non dice chi è.
    for (final MapEntry(key: c, value: n) in contaCognomi.entries) {
      if (n > 1 && c.length >= 2) nomi.add((c, 'un atleta'));
    }
    for (final MapEntry(key: c, value: n) in contaNomi.entries) {
      if (n > 1 && c.length >= 3) nomi.add((c, 'un atleta'));
    }
    nomi.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    _sostituzioni = [
      for (final (testo, codice) in nomi)
        (
          RegExp(
            '(?<![\\p{L}\\p{N}])${RegExp.escape(testo)}(?![\\p{L}\\p{N}])',
            caseSensitive: false,
            unicode: true,
          ),
          codice,
        ),
    ];
  }

  final List<Atleta> _atleti;
  final _codici = <String, String>{};
  final _perCodice = <String, Atleta>{};
  late final List<(RegExp, String)> _sostituzioni;

  static final _codice = RegExp(r'\bG(\d{1,3})\b');

  List<Atleta> get atleti => _atleti;

  String? codice(String atletaId) => _codici[atletaId];

  Atleta? atleta(String codice) => _perCodice[codice.trim().toUpperCase()];

  /// Il testo senza i nomi degli atleti (per la domanda dell'allenatore, i
  /// titoli delle sedute...).
  String anonimizza(String testo) {
    var risultato = testo;
    for (final (re, codice) in _sostituzioni) {
      risultato = risultato.replaceAll(re, codice);
    }
    return risultato;
  }

  /// Il testo del modello con i nomi al posto dei codici: "Rossi", o
  /// "Rossi M." se ci sono due Rossi (come nel resto dell'app). Con
  /// [pieni] cognome e nome, come nella convocazione ("Rossi Mario"): per
  /// i messaggi alle famiglie.
  String conNomi(String testo, {bool pieni = false}) =>
      testo.replaceAllMapped(_codice, (m) {
        final a = _perCodice['G${m[1]}'];
        if (a == null) return m[0]!;
        return pieni ? a.nomeCompleto.trim() : nomeBreve(a, _atleti);
      });

  /// I codici nel [testo] che non sono di nessun atleta.
  Set<String> codiciSconosciuti(String testo) => {
    for (final m in _codice.allMatches(testo))
      if (!_perCodice.containsKey('G${m[1]}')) m[0]!,
  };
}
