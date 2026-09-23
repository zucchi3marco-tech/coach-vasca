import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

JSObject _prop(JSObject o, String proprieta) =>
    o.getProperty<JSObject>(proprieta.toJS);

String _testo(JSObject o, String proprieta) =>
    o.getProperty<JSString>(proprieta.toJS).toDart;

int _numero(JSObject o, String proprieta) =>
    o.getProperty<JSNumber>(proprieta.toJS).toDartInt;

/// Messaggi in italiano per i codici d'errore della Web Speech API — vedi
/// https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognitionErrorEvent/error
String _messaggioErrore(String codice) => switch (codice) {
  'no-speech' =>
    'Non ho sentito nulla. Riprova parlando più vicino al '
        'microfono.',
  'audio-capture' => 'Nessun microfono trovato su questo dispositivo.',
  'not-allowed' =>
    'Permesso per il microfono negato. Consentilo nelle '
        'impostazioni del browser e riprova.',
  'network' => 'La dettatura ha bisogno di una connessione a Internet.',
  _ =>
    'Dettatura non riuscita ($codice). Riprova, o scrivi il testo a '
        'mano.',
};

/// Riconoscimento vocale continuo in italiano tramite la Web Speech API
/// del browser (`webkitSpeechRecognition`/`SpeechRecognition`): gratuita
/// (non passa da Gemini, costa zero oltre alla connessione), ma
/// disponibile solo dove il browser la implementa — oggi in pratica
/// Chrome/Edge, non Safari né Firefox.
class DettatoreVocale {
  DettatoreVocale({
    required this.onTrascrizione,
    required this.onErrore,
    required this.onFine,
  });

  /// Chiamato ad ogni aggiornamento con l'INTERO testo riconosciuto in
  /// questa sessione di ascolto (non un pezzo da aggiungere al
  /// precedente): rimpiazza sempre quanto dato prima, mai da sommare a
  /// mano dal chiamante — vedi [_suRisultato] sul perché.
  final void Function(String testoSessione) onTrascrizione;
  final void Function(String messaggio) onErrore;

  /// L'ascolto è terminato (tocco su "ferma", errore, o il browser lo ha
  /// chiuso da solo dopo un silenzio prolungato): la UI deve tornare allo
  /// stato "non sto ascoltando".
  final void Function() onFine;

  JSObject? _riconoscimento;
  bool _inAscolto = false;

  bool get inAscolto => _inAscolto;

  static bool get disponibile =>
      web.window.has('SpeechRecognition') ||
      web.window.has('webkitSpeechRecognition');

  void avvia() {
    if (_inAscolto) return;
    final costruttore = web.window.has('SpeechRecognition')
        ? web.window.getProperty<JSFunction>('SpeechRecognition'.toJS)
        : web.window.has('webkitSpeechRecognition')
        ? web.window.getProperty<JSFunction>('webkitSpeechRecognition'.toJS)
        : null;
    if (costruttore == null) {
      onErrore('La dettatura non è disponibile su questo browser.');
      return;
    }

    final riconoscimento = costruttore.callAsConstructor<JSObject>();
    riconoscimento['lang'] = 'it-IT'.toJS;
    // Non si ferma da solo alla prima pausa: il coach detta una scheda
    // intera, con pause naturali fra una serie e l'altra.
    riconoscimento['continuous'] = true.toJS;
    // Mostra il testo provvisorio mentre parla, non solo a fine frase:
    // dà un riscontro immediato che il microfono sta funzionando.
    riconoscimento['interimResults'] = true.toJS;

    riconoscimento.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'result'.toJS,
      ((JSObject evento) => _suRisultato(evento)).toJS,
    );
    riconoscimento.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'error'.toJS,
      ((JSObject evento) => onErrore(
        _messaggioErrore(_testo(evento, 'error')),
      )).toJS,
    );
    riconoscimento.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'end'.toJS,
      (() {
        _inAscolto = false;
        _riconoscimento = null;
        onFine();
      }).toJS,
    );

    _riconoscimento = riconoscimento;
    _inAscolto = true;
    riconoscimento.callMethod<JSAny?>('start'.toJS);
  }

  // Ricostruisce SEMPRE l'intero testo della sessione da `evento.results`
  // (indice 0 → length-1), invece di leggere solo da `evento.resultIndex`
  // e aggiungere quel pezzo al testo già accumulato: con `continuous:
  // true` Chrome a volte rimanda lo stesso indice (o un indice
  // precedente) più di una volta nella stessa sessione, e un'aggiunta
  // incrementale lo duplicherebbe ogni volta che succede — bug osservato
  // dal coach ("la stessa frase trascritta molte volte"). Ricostruire da
  // zero è idempotente: lo stesso `results` dà sempre lo stesso testo,
  // qualunque cosa il browser rimandi.
  void _suRisultato(JSObject evento) {
    final risultati = _prop(evento, 'results');
    final lunghezza = _numero(risultati, 'length');
    final pezzi = <String>[];
    for (var i = 0; i < lunghezza; i++) {
      final risultato = _prop(risultati, '$i');
      final alternativaMigliore = _prop(risultato, '0');
      final pezzo = _testo(alternativaMigliore, 'transcript').trim();
      if (pezzo.isNotEmpty) pezzi.add(pezzo);
    }
    onTrascrizione(pezzi.join(' '));
  }

  void ferma() {
    _riconoscimento?.callMethod<JSAny?>('stop'.toJS);
  }

  void dispose() {
    ferma();
  }
}
