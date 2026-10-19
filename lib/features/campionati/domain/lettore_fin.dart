import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import 'campionato_fin.dart';

/// Legge le pagine del sito FIN Lombardia (finlombardia.net/PHP): l'elenco
/// dei campionati (`PN-ElencoCampionati.php`) e la pagina di un girone
/// (`PN-Incontri.php`, classifica e calendario). Le pagine sono tabelle
/// HTML semplici; se il sito cambia forma, quello che non si riconosce si
/// salta invece di inventarlo.
///
/// A ottobre 2026 il sito ha cambiato forma: il campionato in una riga a
/// sé sopra i suoi gironi, squadre e piscina nella stessa cella, la
/// posizione davanti al nome in classifica, «da disputare» al posto del
/// risultato. Si leggono tutte e due le forme, la nuova e quella di prima.

/// "Cadetti   (M) " → "Cadetti (M)".
String _pulito(String s) =>
    s.replaceAll(' ', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

/// "Fase1" → "Fase 1", "Girone1" → "Girone 1": il sito li scrive in tutti
/// e due i modi.
String _conSpazio(String s) => _pulito(s).replaceAllMapped(
  RegExp(r'^(fase|girone)(\d)', caseSensitive: false),
  (m) => '${m[1]} ${m[2]}',
);

final _soloStagione = RegExp(r'^\d{4}-\d{4}$');

String? _stagioneDa(Document doc) {
  // Il sito nuovo la scrive accanto al titolo ("Stagione: 2025-2026");
  // tutti e due la mettono nell'intestazione della pagina.
  final dichiarata = RegExp(r'Stagione:\s*(\d{4}-\d{4})')
      .firstMatch(doc.body?.text ?? '');
  if (dichiarata != null) return dichiarata.group(1);
  for (final e in doc.querySelectorAll('h1, .page-header-title')) {
    final m = RegExp(r'\d{4}-\d{4}').firstMatch(e.text);
    if (m != null) return m.group(0);
  }
  return null;
}

ElencoFin leggiElencoFin(String pagina) {
  final doc = html.parse(pagina);
  final stagioni = [
    for (final a in doc.querySelectorAll('a.dropdown-item'))
      if (_soloStagione.hasMatch(_pulito(a.text))) _pulito(a.text),
  ];
  final scelta = _pulito(doc.querySelector('.dropdown-toggle')?.text ?? '');
  final stagione = _soloStagione.hasMatch(scelta)
      ? scelta
      : _stagioneDa(doc) ?? (stagioni.isEmpty ? '' : stagioni.last);

  final voci = <VoceElencoFin>[];
  var campionato = '';
  var fase = '';
  for (final riga in doc.querySelectorAll('tr')) {
    final celle = riga.querySelectorAll('td');
    if (celle.isEmpty) continue;
    final id = RegExp(r'CMPid=(\d+)')
        .firstMatch(riga.attributes['onclick'] ?? '')
        ?.group(1);
    if (id == null) {
      // Il sito nuovo scrive il campionato in una riga a sé, sopra i suoi
      // gironi; quello di prima lasciava una riga vuota fra un campionato
      // e l'altro.
      final nome = _pulito(riga.text);
      if (celle.length == 1 && nome.isNotEmpty) {
        campionato = nome;
        fase = '';
      }
      continue;
    }
    // Prima: campionato, fase e girone. Ora: fase e girone.
    if (celle.length < 2) continue;
    final conCampionato = celle.length >= 3;
    if (conCampionato) {
      final nome = _pulito(celle[0].text);
      if (nome.isNotEmpty && nome != campionato) {
        campionato = nome;
        fase = '';
      }
    }
    if (campionato.isEmpty) continue;
    // Le righe dopo la prima di un campionato lasciano vuoti il nome
    // (prima) o la fase (ora): valgono quelli della riga sopra.
    final faseRiga = _conSpazio(celle[conCampionato ? 1 : 0].text);
    if (faseRiga.isNotEmpty) fase = faseRiga;
    voci.add(
      VoceElencoFin(
        cmpId: int.parse(id),
        campionato: campionato,
        fase: fase,
        girone: _testo(_conSpazio(celle[conCampionato ? 2 : 1].text)) ?? '',
      ),
    );
  }
  return ElencoFin(stagione: stagione, stagioni: stagioni, voci: voci);
}

int _intero(String s) => int.tryParse(_pulito(s).replaceAll('+', '')) ?? 0;

DateTime? _data(String s) {
  final m = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(s);
  if (m == null) return null;
  return DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
}

String? _ora(String s) {
  final m = RegExp(r'^(\d{1,2})[.:](\d{2})$').firstMatch(_pulito(s));
  if (m == null) return null;
  // "00:00" è l'orario non ancora deciso.
  if (int.parse(m[1]!) == 0 && m[2] == '00') return null;
  return '${m[1]!.padLeft(2, '0')}:${m[2]}';
}

/// Quello che il sito scrive dove non c'è niente: un punto o un trattino
/// al posto dell'arbitro, «da disputare» al posto del risultato.
const _vuoti = {'', '.', '-', '–', '—', 'da disputare'};

String? _testo(String s) {
  final t = _pulito(s);
  return _vuoti.contains(t.toLowerCase()) ? null : t;
}

/// "Onde Verdi — Rari Nantes Sud-Est": il sito nuovo divide le squadre con
/// una lineetta, quello di prima con " - ". Il trattino dentro un nome non
/// le divide.
(String, String)? _dueSquadre(String s) {
  final t = _pulito(s);
  var parti = t.split(RegExp(r'\s[—–]\s'));
  if (parti.length != 2) parti = t.split(' - ');
  if (parti.length != 2) return null;
  return (parti[0].trim(), parti[1].trim());
}

/// Una riga del calendario. Il sito nuovo mette squadre e piscina nella
/// prima cella, una sotto l'altra, poi orario, data, risultato e arbitro;
/// quello di prima aveva la piscina in una cella a sé.
IncontroFin? _incontro(List<Element> celle) {
  final righe = celle.first.querySelectorAll('div');
  final String squadre;
  final String? piscina;
  final List<Element> resto;
  if (righe.isNotEmpty) {
    squadre = righe.first.text;
    piscina = righe.length > 1 ? _testo(righe[1].text) : null;
    resto = celle.sublist(1);
  } else {
    if (celle.length < 2) return null;
    squadre = celle.first.text;
    piscina = _testo(celle[1].text);
    resto = celle.sublist(2);
  }
  if (resto.length < 3) return null;
  final nomi = _dueSquadre(squadre);
  if (nomi == null) return null;
  final risultato = _pulito(resto[2].text);
  final punteggio = RegExp(r'^(\d+)\s*[-–]\s*(\d+)$').firstMatch(risultato);
  return IncontroFin(
    casa: nomi.$1,
    ospite: nomi.$2,
    piscina: piscina,
    ora: _ora(resto[0].text),
    data: _data(resto[1].text),
    dataTesto: _testo(resto[1].text),
    golCasa: punteggio == null ? null : int.parse(punteggio[1]!),
    golOspite: punteggio == null ? null : int.parse(punteggio[2]!),
    risultatoTesto: punteggio == null ? _testo(risultato) : null,
    arbitro: resto.length > 3 ? _testo(resto[3].text) : null,
  );
}

GironeFin leggiGironeFin(String pagina, {required int cmpId}) {
  final doc = html.parse(pagina);
  final titolo = _pulito(
    (doc.querySelector('h5') ??
                doc.querySelector('.container p') ??
                doc.querySelector('p'))
            ?.text ??
        '',
  );

  final classifica = <RigaClassificaFin>[];
  final giornate = <GiornataFin>[];
  for (final tabella in doc.querySelectorAll('table')) {
    final intestazioni = [
      for (final th in tabella.querySelectorAll('thead th')) _pulito(th.text),
    ];
    if (intestazioni.contains('Punti')) {
      for (final riga in tabella.querySelectorAll('tbody tr')) {
        final c = [for (final td in riga.querySelectorAll('td')) td.text];
        if (c.length < 9) continue;
        // Il sito nuovo scrive la posizione davanti al nome: "1. NC Monza".
        final squadra = _pulito(c[0]).replaceFirst(RegExp(r'^\d+\.\s+'), '');
        if (squadra.isEmpty) continue;
        classifica.add(
          RigaClassificaFin(
            posizione: classifica.length + 1,
            squadra: squadra,
            punti: _intero(c[1]),
            giocate: _intero(c[2]),
            vinte: _intero(c[3]),
            pareggiate: _intero(c[4]),
            perse: _intero(c[5]),
            golFatti: _intero(c[6]),
            golSubiti: _intero(c[7]),
            differenza: _intero(c[8]),
          ),
        );
      }
      continue;
    }
    // Il calendario: una riga con il nome della giornata, poi gli incontri.
    String? nomeGiornata;
    var incontri = <IncontroFin>[];
    void chiudi() {
      if (nomeGiornata != null && incontri.isNotEmpty) {
        giornate.add(GiornataFin(nome: nomeGiornata, incontri: incontri));
      }
      incontri = [];
    }

    for (final riga in tabella.querySelectorAll('tr')) {
      final celle = riga.querySelectorAll('td');
      if (celle.isEmpty) continue;
      // Il nome della giornata: in corsivo (prima) o in una cella sola che
      // prende tutta la riga (ora).
      if (celle.first.classes.contains('fst-italic') ||
          (celle.length == 1 && _pulito(celle.first.text).isNotEmpty)) {
        chiudi();
        nomeGiornata = _pulito(celle.first.text);
        continue;
      }
      final incontro = _incontro(celle);
      if (incontro == null) continue;
      incontri.add(incontro);
      nomeGiornata ??= 'Calendario';
    }
    chiudi();
  }

  return GironeFin(
    cmpId: cmpId,
    stagione: _stagioneDa(doc),
    titolo: titolo,
    classifica: classifica,
    giornate: giornate,
  );
}
