/// Registrare e riascoltare la voce (il commento a voce sulle clip del
/// video). Sul web usa il registratore del browser (`MediaRecorder`) e un
/// elemento audio; altrove (e nei test, che girano sulla VM) non c'è:
/// [RegistratoreVoce.disponibile] è false e la schermata non mostra il
/// tasto. Nei test si sostituiscono con [creaRegistratoreVoceProvider] e
/// [creaLettoreVoceProvider].
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voce_stub.dart'
    if (dart.library.js_interop) 'voce_web.dart'
    as piattaforma;

/// Quanto può durare un commento (scelta del coach: 3 minuti).
const durataMassimaVoce = Duration(minutes: 3);

/// Una registrazione appena fatta, non ancora caricata.
class VoceRegistrata {
  const VoceRegistrata({
    required this.byte,
    required this.tipo,
    required this.secondi,
  });

  final Uint8List byte;

  /// Il tipo del file senza i codec, per esempio `audio/webm` o
  /// `audio/mp4` (iPhone).
  final String tipo;
  final double secondi;

  String get estensione => switch (tipo) {
    'audio/mp4' || 'audio/aac' => 'm4a',
    'audio/ogg' => 'ogg',
    'audio/mpeg' => 'mp3',
    _ => 'webm',
  };
}

/// Un errore da mostrare così com'è (il microfono negato, nessun
/// microfono...).
class ErroreVoce implements Exception {
  const ErroreVoce(this.messaggio);

  final String messaggio;

  @override
  String toString() => messaggio;
}

abstract class RegistratoreVoce {
  /// Il browser sa registrare.
  bool get disponibile;

  bool get inRegistrazione;

  /// Chiede il microfono (la prima volta il browser lo domanda) e
  /// comincia. Lancia [ErroreVoce].
  Future<void> avvia();

  /// Si ferma e restituisce la registrazione (null se non stava
  /// registrando o non c'è audio).
  Future<VoceRegistrata?> ferma();

  /// Butta via quello che sta registrando e libera il microfono.
  void annulla();
}

abstract class LettoreVoce {
  /// Un file sul server (indirizzo firmato) ...
  Future<void> apri(String indirizzo);

  /// ... o la registrazione appena fatta, prima di salvarla.
  Future<void> apriRegistrata(VoceRegistrata voce);

  /// Parte da [secondo] (dall'inizio del commento). Lancia [ErroreVoce].
  Future<void> suona({double secondo = 0});

  void pausa();

  double get secondo;

  bool get inRiproduzione;

  /// Quando il commento arriva in fondo.
  void Function()? allaFine;

  void chiudi();
}

/// Chi li usa se ne crea uno e lo chiude quando ha finito
/// ([RegistratoreVoce.annulla], [LettoreVoce.chiudi]).
final creaRegistratoreVoceProvider = Provider<RegistratoreVoce Function()>(
  (ref) => piattaforma.creaRegistratore,
);

final creaLettoreVoceProvider = Provider<LettoreVoce Function()>(
  (ref) => piattaforma.creaLettore,
);
