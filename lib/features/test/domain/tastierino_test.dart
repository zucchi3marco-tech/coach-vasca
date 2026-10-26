import 'massimale.dart';
import 'test_club.dart';

/// Quello che si digita sul tastierino di "Inserisci risultati" per una
/// prova, come al cronometro: per un tempo solo cifre, e la virgola la
/// mette l'app ("862" è 8,62; "10520" è 1:05,20); per le altre misure le
/// cifre e, se ha senso, la virgola.

/// Le cifre al massimo: 99:59,99 per un tempo.
const _massimoCifre = 6;

/// Il testo dopo aver premuto [tasto] ('0'…'9', ',' o '⌫').
String conTasto(UnitaTest unita, String testo, String tasto) {
  if (tasto == '⌫') {
    return testo.isEmpty ? testo : testo.substring(0, testo.length - 1);
  }
  if (tasto == ',') {
    final virgolaAmmessa = unita.conDecimali;
    if (!virgolaAmmessa || testo.contains(',')) return testo;
    return testo.isEmpty ? '0,' : '$testo,';
  }
  if (!RegExp(r'^\d$').hasMatch(tasto)) return testo;
  final cifre = testo.replaceAll(',', '').length;
  if (cifre >= _massimoCifre) return testo;
  // Dopo la virgola, al massimo due cifre.
  final virgola = testo.indexOf(',');
  if (virgola != -1 && testo.length - virgola > 2) return testo;
  // Niente zeri inutili davanti ("007").
  if (testo == '0' && unita != UnitaTest.secondi) return tasto;
  return '$testo$tasto';
}

/// Il valore della prova, nell'unità del test; null se non c'è o non ha
/// senso (un tempo con più di 59 secondi oltre il minuto).
double? valoreDigitato(UnitaTest unita, String testo) {
  if (testo.isEmpty) return null;
  if (unita == UnitaTest.secondi) {
    final cifre = int.tryParse(testo);
    if (cifre == null || cifre == 0) return null;
    if (testo.length <= 4) return cifre / 100;
    final minuti = cifre ~/ 10000;
    final centesimi = cifre % 10000;
    if (centesimi >= 6000) return null;
    return minuti * 60 + centesimi / 100;
  }
  final v = double.tryParse(testo.replaceAll(',', '.'));
  if (v == null || v <= 0) return null;
  return v;
}

/// Come si vede quello che si è digitato: "8,62", "1:05,20", "58,4".
String testoMostrato(UnitaTest unita, String testo) {
  if (testo.isEmpty) return '';
  if (unita != UnitaTest.secondi) return testo;
  final cifre = testo.padLeft(3, '0');
  final centesimi = cifre.substring(cifre.length - 2);
  final secondiEMinuti = cifre.substring(0, cifre.length - 2);
  if (secondiEMinuti.length <= 2) {
    return '${int.parse(secondiEMinuti)},$centesimi';
  }
  final secondi = secondiEMinuti.substring(secondiEMinuti.length - 2);
  final minuti = secondiEMinuti.substring(0, secondiEMinuti.length - 2);
  return '${int.parse(minuti)}:$secondi,$centesimi';
}

/// Il testo da modificare per un valore già registrato (per correggere
/// l'ultima prova).
String testoDaValore(UnitaTest unita, double valore) {
  if (unita == UnitaTest.secondi) {
    final centesimi = (valore * 100).round();
    final minuti = centesimi ~/ 6000;
    final resto = centesimi % 6000;
    return minuti == 0
        ? '$resto'
        : '$minuti${resto.toString().padLeft(4, '0')}';
  }
  if (!unita.conDecimali) return '${valore.round()}';
  final testo = valore
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return testo.replaceAll('.', ',');
}

/// Quanti campi si scrivono per un atleta: le prove del test o, per un
/// massimale, i chili sollevati e le ripetizioni.
int campiPerAtleta(TestClub test) => test.massimale ? 2 : test.prove;

/// L'unità del campo [indice] (dallo 0): per un massimale prima i chili,
/// poi le ripetizioni; per gli altri test quella del test.
UnitaTest unitaDelCampo(TestClub test, int indice) => test.massimale
    ? (indice == 0 ? UnitaTest.chili : UnitaTest.ripetizioni)
    : test.unita;

/// Il valore del campo [indice] digitato come [testo]; null se non c'è o
/// non va bene (le ripetizioni di un massimale da 1 a
/// [ripetizioniMassimeStima]).
double? valoreDelCampo(TestClub test, int indice, String testo) {
  final unita = unitaDelCampo(test, indice);
  final v = valoreDigitato(unita, testo);
  if (v == null) return null;
  if (test.massimale && indice == 1 && v > ripetizioniMassimeStima) {
    return null;
  }
  if (test.massimale && indice == 0 && v > 500) return null;
  return v;
}

/// Il valore scritto in un campo di testo (l'atleta dal suo telefono):
/// un tempo come "8,62", "8.62", "45" (secondi) o "1:05,20"; le altre
/// misure con la virgola dove ha senso, intere per punti e ripetizioni.
/// null se non c'è o non va bene.
double? valoreScritto(UnitaTest unita, String testo) {
  final t = testo.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  if (unita == UnitaTest.secondi) {
    final parti = t.split(':');
    if (parti.length > 2) return null;
    final secondi = double.tryParse(parti.last.replaceAll(',', '.'));
    if (secondi == null || secondi < 0) return null;
    if (parti.length == 1) return secondi > 0 ? secondi : null;
    final minuti = int.tryParse(parti.first);
    if (minuti == null || minuti < 0 || secondi >= 60) return null;
    final v = minuti * 60 + secondi;
    return v > 0 ? v : null;
  }
  if (unita.intera) {
    final v = int.tryParse(t);
    return v == null || v <= 0 ? null : v.toDouble();
  }
  final v = double.tryParse(t.replaceAll(',', '.'));
  return v == null || v <= 0 ? null : v;
}

/// Come [valoreDelCampo], per un campo di testo ([valoreScritto]).
double? valoreDelCampoScritto(TestClub test, int indice, String testo) {
  final v = valoreScritto(unitaDelCampo(test, indice), testo);
  if (v == null) return null;
  if (test.massimale && indice == 1 && v > ripetizioniMassimeStima) {
    return null;
  }
  if (test.massimale && indice == 0 && v > 500) return null;
  return v;
}
