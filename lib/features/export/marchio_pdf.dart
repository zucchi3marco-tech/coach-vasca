import 'dart:typed_data';

import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../club/data/club_repository.dart';
import '../club/data/logo_club_repository.dart';

/// Il club in testa a un PDF: il nome e, se c'è, il logo.
class MarchioPdf {
  const MarchioPdf({required this.nomeClub, this.logo});

  final String nomeClub;
  final Uint8List? logo;
}

/// Prepara la lettura del club per un PDF. Si chiama subito, con il
/// [context] della schermata; la funzione che torna si può chiamare dopo,
/// anche dietro un caricamento. Un logo che non si legge non ferma mai il
/// PDF: si stampa senza.
Future<MarchioPdf?> Function() lettoreMarchioPdf(
  BuildContext context,
  String clubId,
) {
  final ProviderContainer container;
  try {
    container = ProviderScope.containerOf(context, listen: false);
  } catch (_) {
    return () async => null;
  }
  return () async {
    String nome = '';
    Uint8List? logo;
    try {
      final club = await container
          .read(clubRepositoryProvider)
          .fetchByIdLocal(clubId);
      nome = club?.nome ?? '';
    } catch (_) {}
    try {
      logo = await container
          .read(logoClubRepositoryProvider)
          .logo(clubId, attesa: const Duration(seconds: 4));
    } catch (_) {}
    if (nome.isEmpty && logo == null) return null;
    return MarchioPdf(nomeClub: nome, logo: logo);
  };
}

/// Il logo pronto per il PDF, o null se manca o non si legge.
pw.ImageProvider? immagineLogoPdf(Uint8List? logo) {
  if (logo == null || tipoLogo(logo) == null) return null;
  try {
    return pw.MemoryImage(logo);
  } catch (_) {
    return null;
  }
}

const _grigio = PdfColor.fromInt(0xFF5C5C5C);
const _filetto = PdfColor.fromInt(0xFFD4D4D4);

/// La riga in testa alla prima pagina: il logo a sinistra, accanto il
/// nome del club, sotto un filetto.
pw.Widget testataClubPdf(MarchioPdf marchio) {
  final immagine = immagineLogoPdf(marchio.logo);
  final nome = marchio.nomeClub.trim();
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.only(bottom: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _filetto, width: 0.6)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (immagine != null) ...[
          pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(maxHeight: 36, maxWidth: 120),
            child: pw.Image(immagine, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 10),
        ],
        if (nome.isNotEmpty)
          pw.Expanded(
            child: pw.Text(
              nome,
              maxLines: 2,
              style: const pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: _grigio,
              ),
            ),
          ),
      ],
    ),
  );
}
