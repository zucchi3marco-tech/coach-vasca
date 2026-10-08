import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/scarica_file.dart';
import '../pdf/schema_tattico_pdf.dart';
import 'water_polo_tactics_board.dart';

enum _Formato { pdf, immagine }

/// Il nome del file esportato: il titolo in minuscolo, con trattini al
/// posto di spazi e simboli (es. "Superiorità 6 vs 5" →
/// "superiorita-6-vs-5"). "schema" se non resta niente.
String nomeFileSchema(String titolo) {
  const accenti = {
    'à': 'a', 'á': 'a', 'è': 'e', 'é': 'e', 'ì': 'i', 'í': 'i', //
    'ò': 'o', 'ó': 'o', 'ù': 'u', 'ú': 'u',
  };
  final minuscolo = [
    for (final c in titolo.toLowerCase().split('')) accenti[c] ?? c,
  ].join();
  final nome = minuscolo
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return nome.isEmpty ? 'schema' : nome;
}

/// Che cosa vuol dire ogni tratto usato nello schema, per il PDF.
List<String> legendaFrecce(List<PassoLavagna> passi) {
  final usati = {
    for (final p in passi)
      for (final f in p.frecce) f.tipo,
  };
  return [
    for (final t in TipoFreccia.values)
      if (usati.contains(t))
        switch (t) {
          TipoFreccia.nuotata => 'linea piena = nuotata',
          TipoFreccia.passaggio => 'tratteggiata = passaggio',
          TipoFreccia.conPalla => 'ondulata = nuotata con palla',
          TipoFreccia.tiro => 'doppia = tiro',
        },
  ];
}

/// "Esporta": il PDF con tutti i passi (da stampare o mandare alla
/// squadra) o l'immagine del passo [passoCorrente] (da mandare in chat).
Future<void> mostraEsportaSchema(
  BuildContext context, {
  required String titolo,
  required String categoria,
  required CampoLavagna campo,
  required List<PassoLavagna> passi,
  int passoCorrente = 0,
}) async {
  final scelta = await showModalBottomSheet<_Formato>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('PDF con tutti i passi'),
            subtitle: const Text('Da stampare o mandare alla squadra'),
            onTap: () => Navigator.of(context).pop(_Formato.pdf),
          ),
          // Lo scaricamento di un file esiste solo nel browser.
          if (scaricaFileDisponibile)
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text('Immagine del passo ${passoCorrente + 1}'),
              subtitle: const Text('Da mandare in chat'),
              onTap: () => Navigator.of(context).pop(_Formato.immagine),
            ),
        ],
      ),
    ),
  );
  if (scelta == null || !context.mounted) return;

  final messaggero = ScaffoldMessenger.of(context);
  final nome = nomeFileSchema(titolo);
  try {
    switch (scelta) {
      case _Formato.pdf:
        final immagini = [for (final p in passi) await immaginePasso(p, campo)];
        final pdf = await generaSchemaPdf(
          titolo: titolo,
          categoria: categoria,
          campo: campo.nome,
          immaginiPassi: immagini,
          legenda: legendaFrecce(passi),
        );
        await Printing.sharePdf(bytes: pdf, filename: '$nome.pdf');
      case _Formato.immagine:
        final indice = passoCorrente.clamp(0, passi.length - 1);
        final png = await immaginePasso(passi[indice], campo);
        scaricaFile(
          png,
          '$nome-passo-${indice + 1}.png',
          mimeType: 'image/png',
        );
    }
  } catch (e) {
    messaggero.showSnackBar(
      SnackBar(
        content: Text('Esportazione non riuscita: ${messaggioErrore(e)}'),
      ),
    );
  }
}
