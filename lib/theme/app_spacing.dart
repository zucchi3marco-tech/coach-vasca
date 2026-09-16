import 'package:flutter/animation.dart';

/// Scala di spaziatura e raggi — vedi DESIGN.md sezioni 5 e 6. Nessuna
/// dimensione va scritta a mano dentro una schermata: si usa una di
/// queste costanti.
///
/// `s32`, `s48`, `s64` completano la scala a base 4 della sezione 9 del
/// nuovo DESIGN.md (versione 2): non usati da nessuna costante qui sotto
/// finché le schermate non li adottano direttamente.
abstract final class AppSpacing {
  // Scala a base 4.
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s28 = 28.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const s48 = 48.0;
  static const s56 = 56.0;
  static const s64 = 64.0;

  // Valori con un ruolo preciso (sezione 5).
  static const margineLateraleTelefono = s16;
  static const margineLateraleTablet = s24;
  static const paddingPannello = s16;
  static const spazioCampiForm = s16;
  static const spazioGruppiForm = s28;
  static const spazioPannelli = s12;
  static const altezzaMinimaRiga = s56;
  static const spazioBersagli = s12;

  // Bersagli toccabili (sezioni 9 e 11).
  static const altezzaMinimaBersaglio = 48.0;
  static const altezzaMinimaBersaglioVasca = 64.0;

  // Raggi (sezione 6). Vedi anche [AppRadius] sotto per i nomi della
  // sezione 11 del nuovo DESIGN.md (versione 2): stessi concetti, valori
  // leggermente rifiniti (`sheet` passa da 20 a 24) — questi restano
  // finché le schermate non migrano ad [AppRadius].
  static const raggioPannello = 12.0;
  static const raggioControllo = 8.0;
  static const raggioPillola = 999.0;
  static const raggioSheet = 20.0;
}

/// Raggi — DESIGN.md (versione 2) sezione 11. Il raggio dipende dal
/// ruolo dell'elemento, non da "è un riquadro": in pratica ne convivono
/// due, 8 per i controlli e 12 per i contenitori.
abstract final class AppRadius {
  /// Pulsante, campo di testo, scheletro di caricamento.
  static const controllo = 8.0;

  /// Pannello, riga di elenco raggruppata, chip rettangolare.
  static const pannello = 12.0;

  /// Blocco in evidenza, pannello statistica, blocco vasca.
  static const evidenza = 16.0;

  /// Bottom sheet, dialog — solo gli angoli superiori per gli sheet.
  static const sheet = 24.0;

  /// Chip a pillola, badge, punto, avatar, cerchio calottina.
  static const pillola = 999.0;
}

/// Durate e curve del movimento — DESIGN.md (versione 2) sezione 16. Il
/// movimento risponde a un'azione della persona: nessuna animazione
/// d'ingresso non richiesta, a parte le due eccezioni della sezione 16
/// (punto rosso "in corso" e onda dello scheletro di caricamento).
abstract final class AppMotion {
  /// Pressione di un pulsante, riempimento di un'icona, apertura di un
  /// menu.
  static const microinterazione = Duration(milliseconds: 120);

  /// Transizione fra schermate, apertura di un pannello o bottom sheet.
  static const transizione = Duration(milliseconds: 220);

  /// Chiusura — sempre più veloce dell'apertura.
  static const chiusura = Duration(milliseconds: 180);

  /// Curva in entrata. Niente rimbalzi, niente molle.
  static const curvaEntrata = Curves.easeOutCubic;

  /// Curva in uscita.
  static const curvaUscita = Curves.easeInCubic;
}
