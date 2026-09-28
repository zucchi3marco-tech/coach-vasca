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
    this.onEventoGrezzo,
  });

  /// Chiamato ad ogni aggiornamento con l'INTERO testo riconosciuto in
  /// questa sessione di ascolto (non un pezzo da aggiungere al
  /// precedente): rimpiazza sempre quanto dato prima, mai da sommare a
  /// mano dal chiamante — vedi [_suRisultato] sul perché.
  final void Function(String testoSessione) onTrascrizione;
  final void Function(String messaggio) onErrore;

  /// Diagnostica TEMPORANEA (da togliere una volta risolto per sempre il
  /// difetto della dettatura ripetuta): se non nullo, riceve una riga
  /// grezza per ogni evento `result` del browser, PRIMA di qualunque
  /// nostra deduplicazione — serve a vedere esattamente cosa manda il
  /// motore vocale del dispositivo del coach, invece di continuare a
  /// indovinare da qui.
  final void Function(String riga)? onEventoGrezzo;

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

  // Un segmento diventato finale resta quello per tutta la sessione, per
  // il suo indice: se il browser lo ripropone — identico o con una minima
  // differenza — altrove nell'evento o in un evento successivo, in coda o
  // intercalato ad altro, non lo si aggiunge una seconda volta. È il
  // difetto reale di Chrome in `continuous`: non lo ripropone sempre
  // subito consecutivo, quindi un confronto solo col pezzo appena
  // aggiunto (versione precedente di questo metodo) non lo scartava
  // sempre — il sintomo era la stessa frase trascritta molte volte,
  // segnalato più volte dal coach. Vedi `aggiorna_segmenti.dart`.
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
    if (onEventoGrezzo != null) {
      final resultIndex = _numero(evento, 'resultIndex');
      final adesso = DateTime.now();
      final ora =
          '${adesso.hour.toString().padLeft(2, '0')}:'
          '${adesso.minute.toString().padLeft(2, '0')}:'
          '${adesso.second.toString().padLeft(2, '0')}.'
          '${adesso.millisecond.toString().padLeft(3, '0')}';
      final voci = segmenti
          .map((s) => '[${s.indice}${s.finale ? "F" : "I"}:"${s.testo}"]')
          .join(' ');
      onEventoGrezzo!('$ora ri=$resultIndex $voci');
    }
    final aggiornati = aggiornaSegmenti(
      committatiPrima: _segmentiCommittati,
      segmenti: segmenti,
    );
    _segmentiCommittati = aggiornati.committati;
    onTrascrizione(
      ricostruisciTrascrizione([
        testoCommittato(_segmentiCommittati),
        aggiornati.interim,
      ]),
    );
  }

  void ferma() {
    _riconoscimento?.callMethod<JSAny?>('stop'.toJS);
  }

  void dispose() {
    ferma();
  }
}
