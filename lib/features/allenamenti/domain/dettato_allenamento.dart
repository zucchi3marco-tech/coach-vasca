/// Quello che scrive la dettatura del browser, riportato a come si scrive
/// un allenamento — senza AI (segnalazione del coach 2026-10-08: "la
/// dettatura commette errori anche senza rumore di fondo"). Il
/// riconoscimento vocale sente bene, ma scrive come si parla:
///
/// - i numeri piccoli in lettere ("otto da cento" → "otto da 100");
/// - "otto per cento" come percentuale ("8%");
/// - i tempi a parole ("1 minuto e 30", "ripartenza 1 e 30");
/// - le zone staccate ("a 1", "b due");
/// - qualche parola simile ("pool" per "pull").
///
/// Qui si rimette tutto nella forma che l'interprete del testo capisce.
library;

const _unita = {
  'zero': 0,
  'uno': 1,
  'un': 1,
  'due': 2,
  'tre': 3,
  'tré': 3,
  'quattro': 4,
  'cinque': 5,
  'sei': 6,
  'sette': 7,
  'otto': 8,
  'nove': 9,
};

const _decina = {
  'dieci': 10,
  'undici': 11,
  'dodici': 12,
  'tredici': 13,
  'quattordici': 14,
  'quindici': 15,
  'sedici': 16,
  'diciassette': 17,
  'diciotto': 18,
  'diciannove': 19,
};

const _decine = {
  'venti': 20,
  'trenta': 30,
  'quaranta': 40,
  'cinquanta': 50,
  'sessanta': 60,
  'settanta': 70,
  'ottanta': 80,
  'novanta': 90,
};

/// Un numero scritto in lettere, anche composto ("venticinque",
/// "duecentocinquanta", "milleduecento"); `null` se non è un numero.
int? numeroDaParola(String parola) {
  final w = parola.toLowerCase();
  if (w.isEmpty) return null;
  return _finoA9999(w);
}

int? _finoA9999(String w) {
  if (w.isEmpty) return 0;
  if (w.startsWith('mille')) {
    final resto = _finoA999(w.substring(5));
    return resto == null ? null : 1000 + resto;
  }
  final mila = w.indexOf('mila');
  if (mila > 0) {
    final migliaia = _finoA999(w.substring(0, mila));
    final resto = _finoA999(w.substring(mila + 4));
    if (migliaia == null || migliaia < 2 || resto == null) return null;
    return migliaia * 1000 + resto;
  }
  return _finoA999(w);
}

int? _finoA999(String w) {
  if (w.isEmpty) return 0;
  final cento = w.indexOf('cento');
  if (cento >= 0) {
    final prima = w.substring(0, cento);
    final centinaia = prima.isEmpty ? 1 : _unita[prima];
    if (centinaia == null || (prima.isNotEmpty && centinaia < 2)) return null;
    final resto = _finoA99(w.substring(cento + 5));
    return resto == null ? null : centinaia * 100 + resto;
  }
  return _finoA99(w);
}

int? _finoA99(String w) {
  if (w.isEmpty) return 0;
  if (_unita[w] case final u?) return u;
  if (_decina[w] case final d?) return d;
  for (final MapEntry(key: nome, value: valore) in _decine.entries) {
    if (w == nome) return valore;
    // "ventitré", "trentadue"; con l'elisione "ventuno", "trentotto".
    if (w.startsWith(nome)) {
      final u = _unita[w.substring(nome.length)];
      if (u != null && u > 0) return valore + u;
    }
    final radice = nome.substring(0, nome.length - 1);
    if (w.startsWith(radice)) {
      final resto = w.substring(radice.length);
      if (resto == 'uno' || resto == 'otto') return valore + _unita[resto]!;
    }
  }
  return null;
}

String _dueCifre(String s) => s.padLeft(2, '0');

/// Un pezzo di dettato nella forma dell'interprete (vedi la nota in cima
/// al file).
String normalizzaDettato(String pezzo) {
  var t = pezzo
      // I numeri in lettere ("una" no: è quasi sempre un articolo).
      .replaceAllMapped(RegExp(r'[A-Za-zÀ-ÿ]+'), (m) {
        final parola = m[0]!;
        if (parola.toLowerCase() == 'una') return parola;
        return numeroDaParola(parola)?.toString() ?? parola;
      })
      // "otto per cento" scritto come percentuale (o "percento").
      .replaceAllMapped(
        RegExp(r'(\d+)\s*(?:%|percento\b)', caseSensitive: false),
        (m) => '${m[1]}x100',
      )
      // "1,30" come "1.30" (un tempo).
      .replaceAllMapped(
        RegExp(r'(\d+),(\d{2})(?!\d)'),
        (m) => '${m[1]}.${m[2]}',
      );

  // I tempi: "1 minuto e 30 (secondi)" → 1'30'', "2 minuti" → 2',
  // "30 secondi" → 30'', "ripartenza 1 e 30" → ripartenza 1'30''.
  t = t
      .replaceAllMapped(
        RegExp(
          r'(\d+)\s*minut[oi]\s+e\s+(\d{1,2})(?:\s*second[oi])?',
          caseSensitive: false,
        ),
        (m) => "${m[1]}'${_dueCifre(m[2]!)}''",
      )
      .replaceAllMapped(
        RegExp(r'(\d+)\s*minut[oi]\b', caseSensitive: false),
        (m) => "${m[1]}'",
      )
      .replaceAllMapped(
        RegExp(r'(\d+)\s*second[oi]\b', caseSensitive: false),
        (m) => "${m[1]}''",
      )
      .replaceAllMapped(
        RegExp(
          r'\b(ripartenza|partenza|ogni|passo|recupero|rec)\s+(\d{1,2})\s+e\s+(\d{1,2})\b',
          caseSensitive: false,
        ),
        (m) => "${m[1]} ${m[2]}'${_dueCifre(m[3]!)}''",
      );

  // Le zone: "a 1" → A1, "zona d" → D (non "a 1:30", "a 1'").
  t = t
      .replaceAllMapped(
        RegExp(
          r"(?<![\wÀ-ÿ])([ab]\s*[12]|c\s*[123])(?![\d:.,'’])",
          caseSensitive: false,
        ),
        (m) => m[1]!.replaceAll(RegExp(r'\s'), '').toUpperCase(),
      )
      .replaceAllMapped(
        RegExp(r'\bzona\s+d\b', caseSensitive: false),
        (_) => 'D',
      );

  // Parole che il riconoscimento confonde.
  return t
      .replaceAll(RegExp(r'\b(pool|pul|poll)\b', caseSensitive: false), 'pull')
      .replaceAll(
        RegExp(r'\bdefatigamento\b', caseSensitive: false),
        'defaticamento',
      );
}
