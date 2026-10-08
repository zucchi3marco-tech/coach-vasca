import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'aggiorna_segmenti.dart';
import 'ricostruisci_trascrizione.dart';

JSObject _prop(JSObject o, String proprieta) =>
    o.getProperty<JSObject>(proprieta.toJS);

String _testo(JSObject o, String proprieta) =>
    o.getProperty<JSString>(proprieta.toJS).toDart;

int _numero(JSObject o, String proprieta) =>
    o.getProperty<JSNumber>(proprieta.toJS).toDartInt;

bool _booleano(JSObject o, String proprieta) =>
    o.getProperty<JSBoolean>(proprieta.toJS).toDart;

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
    this.separatore = ' ',
  });

  /// Fra una frase e l'altra (una pausa di chi parla): uno spazio, o un
  /// a capo per chi detta una riga per volta (l'allenamento).
  final String separatore;

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

  /// I segmenti finali confermati in questa sessione di ascolto (indice
  /// di `event.results` → testo): si azzera ad ogni [avvia] — vedi
  /// [_suRisultato].
  Map<int, String> _segmentiCommittati = {};

  bool get inAscolto => _inAscolto;

  static bool get disponibile =>
      web.window.has('SpeechRecognition') ||
      web.window.has('webkitSpeechRecognition');

  void avvia() {
    if (_inAscolto) return;
    _segmentiCommittati = {};
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

  // La deduplicazione vera sta in `aggiorna_segmenti.dart`: alcuni
  // dispositivi (confermato su Android, con un log grezzo mandato da un
  // coach) segnano OGNI risultato come "finale" fin da subito, mai come
  // provvisorio, sotto un indice sempre nuovo — anche quando è solo la
  // stessa frase con una parola in più. `aggiornaSegmenti` riconosce
  // quando un nuovo segmento finale è la crescita dell'ultimo confermato
  // e lo sostituisce, invece di accumularli entrambi.
  void _suRisultato(JSObject evento) {
    final risultati = _prop(evento, 'results');
    final lunghezza = _numero(risultati, 'length');
    final segmenti = <SegmentoRisultato>[];
    for (var i = 0; i < lunghezza; i++) {
      final risultato = _prop(risultati, '$i');
      final alternativaMigliore = _prop(risultato, '0');
      segmenti.add((
        indice: i,
        finale: _booleano(risultato, 'isFinal'),
        testo: _testo(alternativaMigliore, 'transcript'),
      ));
    }
    final aggiornati = aggiornaSegmenti(
      committatiPrima: _segmentiCommittati,
      segmenti: segmenti,
    );
    _segmentiCommittati = aggiornati.committati;
    onTrascrizione(
      ricostruisciTrascrizione([
        testoCommittato(_segmentiCommittati, separatore),
        aggiornati.interim,
      ], separatore: separatore),
    );
  }

  void ferma() {
    _riconoscimento?.callMethod<JSAny?>('stop'.toJS);
  }

  void dispose() {
    ferma();
  }
}
