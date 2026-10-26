import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'voce.dart';

RegistratoreVoce creaRegistratore() => _RegistratoreWeb();

LettoreVoce creaLettore() => _LettoreWeb();

/// I formati in ordine di preferenza: Chrome e Android registrano WebM
/// (Opus), l'iPhone MP4 (AAC).
const _formati = [
  'audio/webm;codecs=opus',
  'audio/webm',
  'audio/mp4',
  'audio/ogg;codecs=opus',
];

/// L'errore del browser (una DOMException) si riconosce dal nome, che
/// compare nel suo testo.
String _messaggio(Object e) {
  final testo = e.toString();
  bool contiene(String nome) => testo.contains(nome);
  if (contiene('NotAllowedError') || contiene('SecurityError')) {
    return 'Permesso per il microfono negato. Consentilo nelle impostazioni '
        'del browser e riprova.';
  }
  if (contiene('NotFoundError') || contiene('OverconstrainedError')) {
    return 'Nessun microfono trovato su questo dispositivo.';
  }
  if (contiene('NotReadableError')) {
    return 'Il microfono è usato da un\'altra app: chiudila e riprova.';
  }
  return 'Registrazione non riuscita. Riprova.';
}

class _RegistratoreWeb implements RegistratoreVoce {
  web.MediaRecorder? _registratore;
  web.MediaStream? _flusso;
  final _pezzi = <web.Blob>[];
  DateTime? _inizio;
  Completer<void>? _fermato;
  String _tipo = 'audio/webm';

  @override
  bool get disponibile =>
      globalContext.has('MediaRecorder') &&
      web.window.navigator.has('mediaDevices');

  @override
  bool get inRegistrazione => _registratore != null;

  @override
  Future<void> avvia() async {
    if (!disponibile) {
      throw const ErroreVoce(
        'Questo browser non sa registrare la voce: prova con Chrome o con '
        'Safari aggiornato.',
      );
    }
    annulla();
    try {
      _flusso = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;
    } catch (e) {
      throw ErroreVoce(_messaggio(e));
    }
    final formato = _formati.firstWhere(
      (f) => web.MediaRecorder.isTypeSupported(f),
      orElse: () => '',
    );
    try {
      final registratore = formato.isEmpty
          ? web.MediaRecorder(_flusso!)
          : web.MediaRecorder(
              _flusso!,
              web.MediaRecorderOptions(
                mimeType: formato,
                audioBitsPerSecond: 48000,
              ),
            );
      _tipo = (registratore.mimeType.isEmpty ? formato : registratore.mimeType)
          .split(';')
          .first
          .trim();
      if (_tipo.isEmpty) _tipo = 'audio/webm';
      _pezzi.clear();
      registratore.ondataavailable = ((web.BlobEvent e) {
        if (e.data.size > 0) _pezzi.add(e.data);
      }).toJS;
      registratore.onstop = ((web.Event _) {
        _fermato?.complete();
      }).toJS;
      registratore.start(1000);
      _registratore = registratore;
      _inizio = DateTime.now();
    } catch (e) {
      _liberaMicrofono();
      throw ErroreVoce(_messaggio(e));
    }
  }

  @override
  Future<VoceRegistrata?> ferma() async {
    final registratore = _registratore;
    if (registratore == null) return null;
    final secondi = DateTime.now().difference(_inizio!).inMilliseconds / 1000;
    _fermato = Completer<void>();
    registratore.stop();
    await _fermato!.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
    _registratore = null;
    _liberaMicrofono();
    if (_pezzi.isEmpty) return null;
    final blob = web.Blob(
      <web.BlobPart>[..._pezzi].toJS,
      web.BlobPropertyBag(type: _tipo),
    );
    _pezzi.clear();
    final buffer = await blob.arrayBuffer().toDart;
    return VoceRegistrata(
      byte: buffer.toDart.asUint8List(),
      tipo: _tipo,
      secondi: secondi,
    );
  }

  void _liberaMicrofono() {
    final flusso = _flusso;
    if (flusso != null) {
      for (final traccia in flusso.getTracks().toDart) {
        traccia.stop();
      }
    }
    _flusso = null;
  }

  @override
  void annulla() {
    final registratore = _registratore;
    _registratore = null;
    if (registratore != null && registratore.state != 'inactive') {
      registratore.stop();
    }
    _pezzi.clear();
    _liberaMicrofono();
  }
}

class _LettoreWeb implements LettoreVoce {
  final _audio = web.HTMLAudioElement()..preload = 'auto';
  String? _locale;

  _LettoreWeb() {
    _audio.onended = ((web.Event _) => allaFine?.call()).toJS;
  }

  @override
  void Function()? allaFine;

  void _liberaLocale() {
    if (_locale case final url?) web.URL.revokeObjectURL(url);
    _locale = null;
  }

  @override
  Future<void> apri(String indirizzo) async {
    _liberaLocale();
    _audio.src = indirizzo;
  }

  @override
  Future<void> apriRegistrata(VoceRegistrata voce) async {
    _liberaLocale();
    final blob = web.Blob(
      <web.BlobPart>[voce.byte.toJS].toJS,
      web.BlobPropertyBag(type: voce.tipo),
    );
    _locale = web.URL.createObjectURL(blob);
    _audio.src = _locale!;
  }

  @override
  Future<void> suona({double secondo = 0}) async {
    try {
      _audio.currentTime = secondo;
      await _audio.play().toDart;
    } catch (e) {
      throw const ErroreVoce(
        'Il commento non parte: controlla la connessione e il volume, poi '
        'riprova.',
      );
    }
  }

  @override
  void pausa() => _audio.pause();

  @override
  double get secondo => _audio.currentTime.toDouble();

  @override
  bool get inRiproduzione => !_audio.paused;

  @override
  void chiudi() {
    _audio
      ..pause()
      ..removeAttribute('src')
      ..load();
    _liberaLocale();
    allaFine = null;
  }
}
