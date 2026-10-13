import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import 'campionato_fin.dart';

/// Legge le pagine del sito FIN Lombardia (finlombardia.net/PHP): l'elenco
/// dei campionati (`PN-ElencoCampionati.php`) e la pagina di un girone
/// (`PN-Incontri.php`, classifica e calendario). Le pagine sono tabelle
/// HTML semplici; se il sito cambia forma, quello che non si riconosce si
/// salta invece di inventarlo.

/// "Cadetti   (M) " → "Cadetti (M)".
String _pulito(String s) =>
    s.replaceAll(' ', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

/// "Fase1" → "Fase 1", "Girone1" → "Girone 1": il sito li scrive in tutti
/// e due i modi.
String _conSpazio(String s) => _pulito(s).replaceAllMapped(
  RegExp(r'^(fase|girone)(\d)', caseSensitive: false),
  (m) => '${m[1]} ${m[2]}',
);

String? _stagioneDa(Document doc) {
  final intestazione = doc.querySelector('h1')?.text ?? '';
  return RegExp(r'\d{4}-\d{4}').firstMatch(intestazione)?.group(0);
}

ElencoFin leggiElencoFin(String pagina) {
  final doc = html.parse(pagina);
  final stagioni = [
    for (final a in doc.querySelectorAll('a.dropdown-item'))
      if (RegExp(r'^\d{4}-\d{4}$').hasMatch(_pulito(a.text))) _pulito(a.text),
  ];
  final scelta = _pulito(doc.querySelector('#dropdownMenuLink')?.text ?? '');
  final stagione = RegExp(r'^\d{4}-\d{4}$').hasMatch(scelta)
      ? scelta
      : _stagioneDa(doc) ?? (stagioni.isEmpty ? '' : stagioni.last);

  final voci = <VoceElencoFin>[];
  var campionato = '';
  for (final riga in doc.querySelectorAll('tr[onclick]')) {
    final id = RegExp(r'CMPid=(\d+)')
        .firstMatch(riga.attributes['onclick'] ?? '')
        ?.group(1);
    final celle = riga.querySelectorAll('td');
    if (id == null || celle.length < 3) continue;
    // Le righe dopo la prima di un campionato lasciano vuoto il nome.
    final nome = _pulito(celle[0].text);
    if (nome.isNotEmpty) campionato = nome;
    if (campionato.isEmpty) continue;
    voci.add(
      VoceElencoFin(
        cmpId: int.parse(id),
        campionato: campionato,
        fase: _conSpazio(celle[1].text),
        girone: _conSpazio(celle[2].text),
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
  return '${m[1]!.padLeft(2, '0')}:${m[2]}';
}

String? _testo(String s) {
  final t = _pulito(s);
  // Il sito mette un punto dove non c'è l'arbitro.
  return t.isEmpty || t == '.' || t == '-' ? null : t;
}

GironeFin leggiGironeFin(String pagina, {required int cmpId}) {
  final doc = html.parse(pagina);
  final titolo = _pulito(
    (doc.querySelector('.container p') ?? doc.querySelector('p'))?.text ?? '',
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
        if (c.length < 9 || _pulito(c[0]).isEmpty) continue;
        classifica.add(
          RigaClassificaFin(
            posizione: classifica.length + 1,
            squadra: _pulito(c[0]),
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
      if (celle.first.classes.contains('fst-italic')) {
        chiudi();
        nomeGiornata = _pulito(celle.first.text);
        continue;
      }
      if (celle.length < 5) continue;
      final squadre = _pulito(celle[0].text).split(' - ');
      if (squadre.length != 2) continue;
      final risultato = _pulito(celle[4].text);
      final punteggio = RegExp(r'^(\d+)\s*-\s*(\d+)$').firstMatch(risultato);
      final testoData = _pulito(celle[3].text);
      incontri.add(
        IncontroFin(
          casa: squadre[0].trim(),
          ospite: squadre[1].trim(),
          piscina: _testo(celle[1].text),
          ora: _ora(celle[2].text),
          data: _data(testoData),
          dataTesto: testoData.isEmpty ? null : testoData,
          golCasa: punteggio == null ? null : int.parse(punteggio[1]!),
          golOspite: punteggio == null ? null : int.parse(punteggio[2]!),
          risultatoTesto: punteggio == null ? _testo(risultato) : null,
          arbitro: celle.length > 5 ? _testo(celle[5].text) : null,
        ),
      );
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
