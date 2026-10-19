import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../widgets/testata_pagina.dart';

/// Il riquadro che «Scrivimi» fotografa: tutta l'app sotto la barra del
/// club (il Navigator), avvolto in un `RepaintBoundary` in
/// `BarraClubHost`. La barra resta fuori: il nome del club c'è già nella
/// segnalazione.
final chiaveSchermataApp = GlobalKey(debugLabel: 'schermataApp');

/// La schermata in cui si trova l'utente, in PNG, larga al massimo
/// [larghezzaMassima] pixel (basta per leggerla, e pesa poco). Null se non
/// si riesce. Quello che non disegna Flutter, come il video di YouTube,
/// viene vuoto.
Future<Uint8List?> catturaSchermata({double larghezzaMassima = 720}) async {
  try {
    // Il menu appena chiuso deve sparire dall'immagine, e in debug
    // `toImage` vuole un riquadro già disegnato.
    await WidgetsBinding.instance.endOfFrame;
    final contesto = chiaveSchermataApp.currentContext;
    if (contesto == null || !contesto.mounted) return null;
    final oggetto = contesto.findRenderObject();
    if (oggetto is! RenderRepaintBoundary || !oggetto.hasSize) return null;
    final larghezza = oggetto.size.width;
    if (larghezza <= 0) return null;
    final rapporto = math.min(
      View.of(contesto).devicePixelRatio,
      larghezzaMassima / larghezza,
    );
    final immagine = await oggetto.toImage(pixelRatio: rapporto);
    try {
      final dati = await immagine.toByteData(format: ui.ImageByteFormat.png);
      return dati?.buffer.asUint8List();
    } finally {
      immagine.dispose();
    }
  } catch (_) {
    return null;
  }
}

/// La pila delle pagine aperte nel Navigator dell'app, per dire in una
/// segnalazione dove si trovava l'utente (registrato in `MaterialApp`).
class OsservatorePagine extends NavigatorObserver {
  final _pile = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _pile.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _pile.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _pile.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _pile.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) {
      _pile[i] = newRoute;
    } else if (i >= 0) {
      _pile.removeAt(i);
    } else if (newRoute != null) {
      _pile.add(newRoute);
    }
  }

  /// Aperta c'è solo la prima pagina (la home).
  bool get soloLaPrima => _pile.whereType<PageRoute<dynamic>>().length <= 1;

  /// Il titolo della pagina in cima (non i dialoghi né i menu): quello
  /// della barra della pagina o della testata. Null se non se ne trova uno.
  String? titoloPaginaInCima() {
    for (final pagina in _pile.reversed) {
      if (pagina is! PageRoute) continue;
      final contesto = pagina.subtreeContext;
      if (contesto == null || !contesto.mounted) return null;
      return titoloDellaPagina(contesto);
    }
    return null;
  }
}

final osservatorePagine = OsservatorePagine();

/// Il titolo della pagina sotto [contesto]: il testo della prima `AppBar`
/// o la prima `TestataPagina`. Di uno `IndexedStack` (le schede della
/// home) guarda solo la scheda in vista.
String? titoloDellaPagina(BuildContext contesto) {
  String? trovato;

  String? primoTesto(Element radice) {
    String? testo;
    void cerca(Element e) {
      if (testo != null) return;
      final w = e.widget;
      if (w is Text) {
        testo = w.data ?? w.textSpan?.toPlainText();
        return;
      }
      e.visitChildren(cerca);
    }

    radice.visitChildren(cerca);
    return testo;
  }

  void visita(Element e) {
    if (trovato != null) return;
    final w = e.widget;
    if (w is AppBar) {
      final titolo = w.title;
      trovato = titolo is Text
          ? titolo.data ?? titolo.textSpan?.toPlainText()
          : (titolo == null ? null : primoTesto(e));
      if (trovato != null) return;
    }
    if (w is TestataPagina) {
      trovato = w.titolo;
      return;
    }
    if (w is IndexedStack) {
      final inVista = w.index ?? 0;
      var i = 0;
      e.visitChildren((figlio) {
        if (i++ == inVista) visita(figlio);
      });
      return;
    }
    e.visitChildren(visita);
  }

  (contesto as Element).visitChildren(visita);
  final pulito = trovato?.replaceAll('­', '').trim();
  return pulito == null || pulito.isEmpty ? null : pulito;
}
