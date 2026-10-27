import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/date_italiane.dart';
import '../allenamenti/domain/allenamento.dart';
import 'csv_export.dart' show AllenamentoConSerie;
import 'marchio_pdf.dart';
import 'pdf_allenamento.dart';
import 'tema_pdf.dart';

// Colori della stampa: inchiostro scuro, grigi per quello che passa in
// secondo piano, una tinta chiara per i gruppi da ripetere.
const _inchiostro = PdfColor.fromInt(0xFF1A1A1A);
const _grigio = PdfColor.fromInt(0xFF5C5C5C);
const _filetto = PdfColor.fromInt(0xFFD4D4D4);
const _tinta = PdfColor.fromInt(0xFFEFF3F6);

const _margine = 1.5 * PdfPageFormat.cm;

// Larghezze fisse delle colonne (in punti). Il volume non va mai a capo:
// la sua larghezza si calcola dalla riga più lunga ([_larghezzaVolume]).
const _larghezzaLavoro = 92.0;
const _larghezzaZona = 30.0;
const _larghezzaPartenza = 88.0;
const _larghezzaAttrezzi = 66.0;
const _rientro = 14.0;

/// Oltre questi caratteri il volume (una piramide) va su una riga sua.
const _volumeLungo = 11;

const _corpo = 10.5;
const _volume = 12.0;

/// Un PDF con una o più pagine per allenamento (scheda singola o intera
/// settimana): in testa titolo, quando, squadra e totali; poi un blocco
/// alla volta, con le serie in righe larghe e leggibili, i "3x" scritti
/// una volta e i lavori in parallelo affiancati.
/// [nomiGruppi] risolve l'id del gruppo dell'allenamento nel suo nome,
/// [nomiAtleti] gli id degli atleti nelle serie per alcuni di loro.
Future<Uint8List> generaPdf(
  List<AllenamentoConSerie> allenamenti, {
  Map<String, String> nomiGruppi = const {},
  Map<String, String> nomiAtleti = const {},
  MarchioPdf? marchio,
}) async {
  final tema = await temaPdf();
  final doc = pw.Document(theme: tema, title: 'Allenamento');

  for (final (allenamento, serie) in allenamenti) {
    final sezioni = sezioniPdf(serie, nomiAtleti: nomiAtleti);
    final colonne = _Colonne.di(sezioni);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margine),
        theme: tema,
        build: (context) => [
          if (marchio != null) testataClubPdf(marchio),
          ..._intestazione(
            allenamento,
            totali: totaliPdf(serie),
            gruppo: nomiGruppi[allenamento.gruppoId],
          ),
          if (sezioni.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 16),
              child: pw.Text(
                'Nessuna serie',
                style: const pw.TextStyle(fontSize: 12, color: _grigio),
              ),
            )
          else
            for (final sezione in sezioni) ..._sezione(sezione, colonne),
        ],
      ),
    );
  }

  return doc.save();
}

// ---------------------------------------------------------------------------
// Intestazione

List<pw.Widget> _intestazione(
  Allenamento allenamento, {
  required String totali,
  required String? gruppo,
}) {
  final d = allenamento.data;
  final ora = d.hour == 0 && d.minute == 0
      ? null
      : 'ore ${d.hour.toString().padLeft(2, '0')}:'
            '${d.minute.toString().padLeft(2, '0')}';
  final quando = ['${dataEstesa(d)} ${d.year}', ?ora].join(', ');
  final info = [
    quando,
    if (gruppo != null && gruppo.isNotEmpty) gruppo,
    if (totali.isNotEmpty) totali,
  ].join('  ·  ');
  final note = allenamento.note?.trim() ?? '';
  return [
    pw.Text(
      allenamento.titolo?.trim().isNotEmpty == true
          ? allenamento.titolo!.trim()
          : 'Allenamento',
      style: pw.TextStyle(
        fontSize: 20,
        fontWeight: pw.FontWeight.bold,
        color: _inchiostro,
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Text(info, style: const pw.TextStyle(fontSize: 11.5, color: _grigio)),
    if (note.isNotEmpty) ...[
      pw.SizedBox(height: 8),
      pw.Text(
        note,
        style: const pw.TextStyle(fontSize: _corpo, color: _inchiostro),
      ),
    ],
    pw.SizedBox(height: 6),
  ];
}

// ---------------------------------------------------------------------------
// Colonne

/// Quali colonne servono in questo allenamento e quanto sono larghe: una
/// colonna senza niente in nessuna riga non si disegna (più spazio alle
/// note), e il volume è largo quanto la riga più lunga, così non va mai a
/// capo.
class _Colonne {
  const _Colonne({
    required this.volume,
    required this.zona,
    required this.partenza,
    required this.attrezzi,
  });

  final double volume;
  final bool zona;
  final bool partenza;
  final bool attrezzi;

  factory _Colonne.di(List<SezionePdf> sezioni) {
    final righe = [
      for (final s in sezioni)
        for (final e in s.elementi)
          if (e is RigaPdf) e,
    ];
    return _Colonne(
      volume: _larghezzaVolume(sezioni),
      zona: righe.any((r) => r.zona.isNotEmpty),
      partenza: righe.any((r) => r.partenza.isNotEmpty),
      attrezzi: righe.any((r) => r.attrezzi.isNotEmpty),
    );
  }
}

/// Il volume in grassetto a 12 pt: una cifra sta in circa 6.7 pt e gli
/// altri segni in meno; si conta 7 a carattere, più il rientro dei "3x".
double _larghezzaVolume(List<SezionePdf> sezioni) {
  var caratteri = 4;
  var livello = 0;
  for (final s in sezioni) {
    for (final e in s.elementi) {
      if (e is RigaPdf) {
        if (e.volume.length <= _volumeLungo && e.volume.length > caratteri) {
          caratteri = e.volume.length;
        }
        if (e.livello > livello) livello = e.livello;
      } else if (e is RipetiPdf && e.livello + 1 > livello) {
        livello = e.livello + 1;
      }
    }
  }
  return caratteri * 7.0 + 10 + livello * _rientro;
}

// ---------------------------------------------------------------------------
// Sezioni

List<pw.Widget> _sezione(SezionePdf sezione, _Colonne colonne) {
  final titolo = pw.Container(
    margin: const pw.EdgeInsets.only(top: 16),
    padding: const pw.EdgeInsets.only(bottom: 3),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _inchiostro, width: 1.2)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          sezione.titolo,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _inchiostro,
          ),
        ),
        if (sezione.riepilogo.isNotEmpty)
          pw.Text(
            sezione.riepilogo,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _grigio,
            ),
          ),
      ],
    ),
  );
  final elementi = [for (final e in sezione.elementi) _elemento(e, colonne)];
  if (elementi.isEmpty) return [titolo];
  // Il titolo non resta solo in fondo a una pagina: sta con la prima
  // riga (se è un lavoro in parallelo, che può spezzarsi, no).
  if (sezione.elementi.first is ParallelaPdf) {
    return [titolo, ...elementi.expand((w) => w)];
  }
  return [
    pw.Column(children: [titolo, ...elementi.first]),
    for (final w in elementi.skip(1)) ...w,
  ];
}

List<pw.Widget> _elemento(ElementoPdf e, _Colonne colonne) => switch (e) {
  RigaPdf() => [_riga(e, colonne)],
  RecuperoPdf() => [_recupero(e, colonne)],
  RipetiPdf() => [_ripeti(e)],
  ParallelaPdf() => _parallela(e),
};

/// Il filetto chiaro sotto ogni riga, al posto di una griglia pesante.
pw.BoxDecoration get _sotto => const pw.BoxDecoration(
  border: pw.Border(bottom: pw.BorderSide(color: _filetto, width: 0.6)),
);

pw.Widget _riga(RigaPdf r, _Colonne colonne) {
  final rientro = r.livello * _rientro;
  pw.Widget cella(String testo, double larghezza, {pw.TextStyle? stile}) =>
      pw.SizedBox(
        width: larghezza,
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(right: 6),
          child: pw.Text(
            testo,
            style: stile ?? const pw.TextStyle(fontSize: _corpo),
          ),
        ),
      );
  final volume = pw.Text(
    r.volume,
    softWrap: false,
    style: pw.TextStyle(
      fontSize: _volume,
      fontWeight: pw.FontWeight.bold,
      color: _inchiostro,
    ),
  );
  // Una piramide lunga ("50-100-150-200-150-100-50") non starebbe nella
  // colonna: ha una riga sua, sopra il resto.
  final lungo = r.volume.length > _volumeLungo;
  final dettagli = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: colonne.volume,
        child: lungo
            ? null
            : pw.Padding(
                padding: pw.EdgeInsets.only(left: rientro, right: 6),
                child: volume,
              ),
      ),
      cella(
        r.lavoro,
        _larghezzaLavoro,
        stile: pw.TextStyle(fontSize: _corpo, fontWeight: pw.FontWeight.bold),
      ),
      if (colonne.zona) cella(r.zona, _larghezzaZona),
      if (colonne.partenza) cella(r.partenza, _larghezzaPartenza),
      if (colonne.attrezzi) cella(r.attrezzi, _larghezzaAttrezzi),
      pw.Expanded(
        child: pw.Text(
          r.note,
          style: pw.TextStyle(
            fontSize: _corpo - 0.5,
            fontStyle: pw.FontStyle.italic,
            color: _grigio,
          ),
        ),
      ),
    ],
  );
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    decoration: _sotto,
    child: lungo
        ? pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(left: rientro, bottom: 2),
                child: volume,
              ),
              dettagli,
            ],
          )
        : dettagli,
  );
}

pw.Widget _recupero(RecuperoPdf r, _Colonne colonne) => pw.Container(
  width: double.infinity,
  padding: pw.EdgeInsets.only(
    left: r.livello * _rientro + 4,
    top: 3,
    bottom: 3,
  ),
  decoration: _sotto,
  child: pw.Text(
    r.testo,
    style: pw.TextStyle(
      fontSize: _corpo - 0.5,
      fontStyle: pw.FontStyle.italic,
      color: _grigio,
    ),
  ),
);

/// "3×" una volta, con una tinta chiara: le righe che seguono, rientrate,
/// sono il giro da ripetere.
pw.Widget _ripeti(RipetiPdf r) => pw.Container(
  margin: pw.EdgeInsets.only(left: r.livello * _rientro),
  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
  color: _tinta,
  child: pw.Row(
    children: [
      pw.Text(
        r.testo,
        style: pw.TextStyle(
          fontSize: _volume,
          fontWeight: pw.FontWeight.bold,
          color: _inchiostro,
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Text(
        'da ripetere ${r.volte} volte, in quest\'ordine',
        style: const pw.TextStyle(fontSize: _corpo - 1, color: _grigio),
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Lavori in parallelo

/// Le colonne affiancate in un riquadro: in testa per chi sono e quanto
/// durano, sotto le loro serie, compatte.
List<pw.Widget> _parallela(ParallelaPdf p) {
  final titolo = pw.Text(
    'IN PARALLELO',
    style: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 0.8,
      color: _grigio,
    ),
  );
  if (_altezzaStimata(p) <= _altezzaMassimaRiquadro) {
    // Sta in una pagina: un riquadro con le colonne affiancate.
    return [
      pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 6),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _grigio, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            titolo,
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final (i, c) in p.colonne.indexed) ...[
                  if (i > 0) pw.SizedBox(width: 10),
                  pw.Expanded(child: _colonnaParallela(c)),
                ],
              ],
            ),
          ],
        ),
      ),
    ];
  }
  // Troppo lungo per una pagina: un riquadro non si spezza, le colonne
  // sì. Restano affiancate e proseguono sulla pagina dopo.
  return [
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
      child: titolo,
    ),
    pw.Partitions(
      children: [
        for (final (i, c) in p.colonne.indexed) ...[
          if (i > 0)
            pw.Partition(width: 10, child: pw.Column(children: const [])),
          pw.Partition(child: _colonnaParallela(c)),
        ],
      ],
    ),
    pw.SizedBox(height: 8),
  ];
}

/// Fin dove un lavoro in parallelo sta in un riquadro (in punti: una
/// pagina utile è circa 740).
const _altezzaMassimaRiquadro = 520.0;

/// Quanto è alta la colonna più alta, a occhio: una riga di serie
/// compatta, più una per i dettagli e una per le note.
double _altezzaStimata(ParallelaPdf p) {
  double colonna(ColonnaPdf c) => c.elementi.fold(
    30.0,
    (t, e) =>
        t +
        switch (e) {
          RigaPdf() =>
            24 +
                (e.zona.isNotEmpty ||
                        e.partenza.isNotEmpty ||
                        e.attrezzi.isNotEmpty
                    ? 14
                    : 0) +
                (e.note.isEmpty ? 0 : 14 * (1 + e.note.length ~/ 45)),
          _ => 22,
        },
  );
  return p.colonne.map(colonna).fold(0.0, (a, b) => b > a ? b : a) + 30;
}

pw.Column _colonnaParallela(ColonnaPdf c) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(5, 3, 5, 3),
      color: _tinta,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Flexible(
            child: pw.Text(
              c.titolo,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _inchiostro,
              ),
            ),
          ),
          if (c.minuti > 0)
            pw.Text(
              "circa ${c.minuti}'",
              style: const pw.TextStyle(fontSize: 9.5, color: _grigio),
            ),
        ],
      ),
    ),
    for (final e in c.elementi) _elementoColonna(e),
  ],
);

pw.Widget _elementoColonna(ElementoPdf e) => switch (e) {
  RigaPdf() => _rigaColonna(e),
  RecuperoPdf() => pw.Padding(
    padding: pw.EdgeInsets.only(left: e.livello * _rientro + 5, top: 2),
    child: pw.Text(
      e.testo,
      style: pw.TextStyle(
        fontSize: _corpo - 1,
        fontStyle: pw.FontStyle.italic,
        color: _grigio,
      ),
    ),
  ),
  RipetiPdf() => pw.Container(
    margin: pw.EdgeInsets.only(left: e.livello * _rientro, top: 3),
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    color: _tinta,
    child: pw.Text(
      '${e.testo} da ripetere',
      style: pw.TextStyle(
        fontSize: _corpo,
        fontWeight: pw.FontWeight.bold,
        color: _inchiostro,
      ),
    ),
  ),
  // Un momento dentro un momento non esiste.
  ParallelaPdf() => pw.SizedBox(),
};

/// Una serie nella colonna stretta: volume e lavoro sulla prima riga,
/// poi zona, partenza e attrezzi, poi le note.
pw.Widget _rigaColonna(RigaPdf r) {
  final dettagli = [
    if (r.zona.isNotEmpty) r.zona,
    if (r.partenza.isNotEmpty) r.partenza,
    if (r.attrezzi.isNotEmpty) r.attrezzi,
  ].join('   ');
  return pw.Container(
    width: double.infinity,
    padding: pw.EdgeInsets.fromLTRB(5 + r.livello * _rientro, 4, 5, 4),
    decoration: _sotto,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: r.volume,
                style: pw.TextStyle(
                  fontSize: _volume,
                  fontWeight: pw.FontWeight.bold,
                  color: _inchiostro,
                ),
              ),
              if (r.lavoro.isNotEmpty)
                pw.TextSpan(
                  text: '   ${r.lavoro}',
                  style: pw.TextStyle(
                    fontSize: _corpo,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        if (dettagli.isNotEmpty)
          pw.Text(
            dettagli,
            style: const pw.TextStyle(
              fontSize: _corpo - 0.5,
              color: _inchiostro,
            ),
          ),
        if (r.note.isNotEmpty)
          pw.Text(
            r.note,
            style: pw.TextStyle(
              fontSize: _corpo - 1,
              fontStyle: pw.FontStyle.italic,
              color: _grigio,
            ),
          ),
      ],
    ),
  );
}
