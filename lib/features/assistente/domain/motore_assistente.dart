import 'dart:convert';

import 'pseudonimi.dart';
import 'strumenti_assistente.dart';

/// Chiede al modello il prossimo passo della conversazione (formato chat
/// con strumenti): la risposta è un messaggio dell'assistente, con testo o
/// con chiamate agli strumenti. Vedi la funzione `assistente`.
typedef ChiamaModello = Future<Map<String, dynamic>> Function(
  List<Map<String, dynamic>> messaggi,
);

/// Una voce della chat, come la vede l'allenatore (con i nomi).
sealed class VoceChat {
  const VoceChat();
}

class DomandaAllenatore extends VoceChat {
  const DomandaAllenatore(this.testo);
  final String testo;
}

class RispostaAssistente extends VoceChat {
  const RispostaAssistente(this.testo, {this.datiLetti = const []});
  final String testo;

  /// Cosa ha letto per rispondere ("partite", "presenze"...): per sapere
  /// da dove vengono i numeri.
  final List<String> datiLetti;
}

class VoceScheda extends VoceChat {
  const VoceScheda(this.scheda);
  final SchedaAssistente scheda;
}

class ErroreAssistente extends VoceChat {
  const ErroreAssistente(this.messaggio, {required this.domanda});
  final String messaggio;

  /// La domanda da rifare con "Riprova".
  final String domanda;
}

/// Cosa ha letto uno strumento, detto all'allenatore.
const etichetteStrumenti = {
  'squadra': 'squadra',
  'partite': 'partite',
  'statistiche_partite': 'statistiche delle partite',
  'presenze': 'presenze',
  'carico': 'carico',
  'allenamenti': 'allenamenti',
  'scegli_atleti': 'benessere (sul telefono)',
  'mostra_benessere': 'benessere (sul telefono)',
  'proponi_convocazione': 'distinta',
  'proponi_seduta': 'scrittura della seduta',
  'proponi_appello': 'appello',
};

/// La conversazione con l'assistente: tiene la storia nel formato del
/// modello (con i codici, mai i nomi), esegue sul telefono gli strumenti
/// che chiede e rimette i nomi in quello che mostra. Al massimo
/// [passaggiMassimi] giri di strumenti per domanda. Non si salva: chiusa
/// la pagina, sparisce.
class MotoreAssistente {
  MotoreAssistente({
    required this.chiama,
    required this.strumenti,
    required this.pseudonimi,
    this.passaggiMassimi = 6,
  });

  final ChiamaModello chiama;
  final StrumentiAssistente strumenti;
  final Pseudonimi pseudonimi;
  final int passaggiMassimi;

  final _storia = <Map<String, dynamic>>[];

  /// La storia mandata al modello (per i test).
  List<Map<String, dynamic>> get storia => List.unmodifiable(_storia);

  /// Fa la domanda e torna quello che c'è da mostrare: le schede degli
  /// strumenti e la risposta. Con un errore la storia torna com'era, così
  /// la domanda si può rifare.
  Future<List<VoceChat>> chiedi(
    String domanda, {
    void Function(String strumento)? suStrumento,
  }) async {
    final prima = _storia.length;
    _storia.add({'role': 'user', 'content': pseudonimi.anonimizza(domanda)});
    final voci = <VoceChat>[];
    final letti = <String>[];
    try {
      for (var giro = 0; giro < passaggiMassimi; giro++) {
        final messaggio = await chiama(List.of(_storia));
        _storia.add(messaggio);
        final chiamate = (messaggio['tool_calls'] as List?) ?? const [];
        if (chiamate.isEmpty) {
          voci.add(
            RispostaAssistente(
              pseudonimi.conNomi('${messaggio['content'] ?? ''}'.trim()),
              datiLetti: letti,
            ),
          );
          return voci;
        }
        for (final c in chiamate) {
          final chiamata = c as Map<String, dynamic>;
          final funzione = chiamata['function'] as Map<String, dynamic>;
          final nome = '${funzione['name']}';
          Map<String, dynamic> argomenti;
          try {
            argomenti = (jsonDecode('${funzione['arguments'] ?? '{}'}') as Map)
                .cast<String, dynamic>();
          } catch (_) {
            argomenti = const {};
          }
          suStrumento?.call(nome);
          final etichetta = etichetteStrumenti[nome];
          if (etichetta != null && !letti.contains(etichetta)) {
            letti.add(etichetta);
          }
          final esito = await strumenti.esegui(nome, argomenti);
          if (esito.scheda case final scheda?) voci.add(VoceScheda(scheda));
          _storia.add({
            'role': 'tool',
            'tool_call_id': chiamata['id'],
            'content': jsonEncode(esito.perModello),
          });
        }
      }
      voci.add(
        RispostaAssistente(
          'Mi servirebbero troppi passaggi: prova a chiedere una cosa alla '
          'volta.',
          datiLetti: letti,
        ),
      );
      return voci;
    } catch (_) {
      _storia.removeRange(prima, _storia.length);
      rethrow;
    }
  }

  /// Quello che l'allenatore ha fatto con una proposta, perché il modello
  /// lo sappia alla domanda dopo ("convocazione salvata").
  void annota(String testo) => _storia.add({
    'role': 'user',
    'content':
        '[Nota dell\'app, non dell\'allenatore] '
        '${pseudonimi.anonimizza(testo)}',
  });
}
