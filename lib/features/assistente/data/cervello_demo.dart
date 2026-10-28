import 'dart:convert';

import '../../../core/utils/date_format.dart';

/// Il "cervello" dell'assistente nella modalità demo, dove l'AI non c'è
/// (la funzione `assistente` esiste solo sul server). Risponde alle
/// domande d'esempio della pagina con gli stessi strumenti e le stesse
/// schede della versione vera, per poter provare la chat senza Supabase.
/// Non è AI: segue una traccia fissa.
Map<String, dynamic> cervelloDemo(
  List<Map<String, dynamic>> messaggi, {
  DateTime? oggi,
}) {
  final indiceDomanda = messaggi.lastIndexWhere(
    (m) =>
        m['role'] == 'user' && !'${m['content']}'.startsWith('[Nota dell\'app'),
  );
  final domanda = indiceDomanda < 0
      ? ''
      : '${messaggi[indiceDomanda]['content']}'.toLowerCase();
  // Gli strumenti già chiesti dopo la domanda, con il loro risultato.
  final nomi = <String, String>{};
  final risultati = <String, Map<String, dynamic>>{};
  for (final m in messaggi.skip(indiceDomanda + 1)) {
    if (m['role'] == 'assistant') {
      for (final c in (m['tool_calls'] as List?) ?? const []) {
        final chiamata = c as Map;
        nomi['${chiamata['id']}'] = '${(chiamata['function'] as Map)['name']}';
      }
    } else if (m['role'] == 'tool') {
      final nome = nomi['${m['tool_call_id']}'];
      if (nome != null) {
        risultati[nome] = (jsonDecode('${m['content']}') as Map)
            .cast<String, dynamic>();
      }
    }
  }

  Map<String, dynamic> chiama(String nome, Map<String, Object?> args) => {
    'role': 'assistant',
    'content': null,
    'tool_calls': [
      {
        'id': 'demo-$nome',
        'type': 'function',
        'function': {'name': nome, 'arguments': jsonEncode(args)},
      },
    ],
  };
  Map<String, dynamic> scrivi(String testo) => {
    'role': 'assistant',
    'content': testo,
  };

  // "Assenti G3 e G1, G4 in ritardo": ogni pezzo fra le virgole dice per
  // chi vale, e chi non ha la parola prende quella di prima.
  if (domanda.contains('appello') ||
      domanda.contains('assent') ||
      domanda.contains('ritard')) {
    final esito = risultati['proponi_appello'];
    if (esito == null) {
      final elenchi = <String, List<String>>{
        'assenti': [],
        'in_ritardo': [],
        'giustificati': [],
      };
      String? chiave;
      for (final pezzo in domanda.split(RegExp('[,.;:]'))) {
        if (pezzo.contains('ritard')) {
          chiave = 'in_ritardo';
        } else if (pezzo.contains('giustific')) {
          chiave = 'giustificati';
        } else if (pezzo.contains('assent')) {
          chiave = 'assenti';
        }
        if (chiave == null) continue;
        elenchi[chiave]!.addAll([
          for (final m in RegExp(r'\bg(\d{1,3})\b').allMatches(pezzo))
            'G${m[1]}',
        ]);
      }
      final adesso = oggi ?? DateTime.now();
      return chiama('proponi_appello', {
        'data': formatDateOnly(
          domanda.contains('ieri')
              ? DateTime(adesso.year, adesso.month, adesso.day - 1)
              : adesso,
        ),
        for (final MapEntry(:key, :value) in elenchi.entries)
          if (value.isNotEmpty) key: value,
      });
    }
    final errore = esito['errore'];
    if (errore != null) {
      return scrivi(
        '$errore'.startsWith('Nessuna seduta')
            ? 'Oggi la squadra non ha una seduta: crea l\'allenamento e poi '
                  'rifacciamo l\'appello.'
            : 'Non so su quale seduta fare l\'appello: nella demo aprilo '
                  'dalle presenze della seduta.',
      );
    }
    final assenti = esito['assenti'];
    return scrivi(
      'Ecco l\'appello: ${esito['presenti']} presenti, '
      '${assenti == 1 ? '1 assente' : '$assenti assenti'}. Controllalo, '
      'cambia chi serve e salvalo.',
    );
  }

  if (domanda.contains('superiorit')) {
    final st = risultati['statistiche_partite'];
    if (st == null) return chiama('statistiche_partite', {'ultime': 5});
    final s = (st['squadra'] as Map?) ?? const {};
    final sup = (s['superiorita'] as num?)?.toInt() ?? 0;
    final segnate = (s['superiorita_segnate'] as num?)?.toInt() ?? 0;
    final inf = (s['inferiorita'] as num?)?.toInt() ?? 0;
    final subiti = (s['gol_subiti_in_inferiorita'] as num?)?.toInt() ?? 0;
    final partite = (st['partite'] as List?)?.length ?? 0;
    if (sup == 0) {
      return scrivi(
        'Nelle ultime $partite partite non ci sono superiorità registrate dal '
        'vivo.',
      );
    }
    return scrivi(
      'Nelle ultime $partite partite: $segnate superiorità segnate su $sup '
      '(${(segnate * 100 / sup).round()}%). In inferiorità $subiti gol '
      'subiti su $inf.',
    );
  }

  if (domanda.contains('convoc')) {
    final partite = risultati['partite'];
    if (partite == null) {
      return chiama('partite', {'quali': 'prossime', 'quante': 1});
    }
    final elenco = (partite['partite'] as List?) ?? const [];
    if (elenco.isEmpty) return scrivi('Non ci sono partite in programma.');
    final partita = elenco.first as Map;
    final scelti = risultati['scegli_atleti'];
    if (scelti == null) {
      return chiama('scegli_atleti', {
        'escludi_dolore_spalla': domanda.contains('spalla'),
        'ordina_per': 'presenze',
        'quanti': partita['massimo_convocati'] ?? 15,
      });
    }
    if (!risultati.containsKey('proponi_convocazione')) {
      return chiama('proponi_convocazione', {
        'partita_id': partita['id'],
        'atleti': scelti['atleti'],
      });
    }
    return scrivi(
      'Ti ho proposto la distinta per ${partita['giorno']} con '
      '${partita['avversario']}, scegliendo i più presenti'
      '${domanda.contains('spalla') ? ' e lasciando fuori chi ha segnato la spalla' : ''}. '
      'Controllala e conferma.',
    );
  }

  if (domanda.contains('dolor') ||
      domanda.contains('benessere') ||
      domanda.contains('salute')) {
    if (!risultati.containsKey('mostra_benessere')) {
      return chiama('mostra_benessere', {
        'cosa': domanda.contains('dolor') ? 'dolori' : 'tutto',
        'giorni': 7,
      });
    }
    return scrivi(
      'Li trovi nella scheda qui sopra: quei dati restano sul telefono, io '
      'non li vedo.',
    );
  }

  if (domanda.contains('seduta') || domanda.contains('prepara')) {
    if (!risultati.containsKey('proponi_seduta')) {
      final adesso = oggi ?? DateTime.now();
      // Il prossimo giovedì.
      final giorni = (DateTime.thursday - adesso.weekday + 7) % 7;
      final data = adesso.add(Duration(days: giorni == 0 ? 7 : giorni));
      return chiama('proponi_seduta', {
        'data': formatDateOnly(data),
        'titolo': 'Superiorità e portieri',
        'testo':
            "Riscaldamento\n400 mix A1\n4x50 gambe A2 r15\n\nPrincipale\n"
            "Portieri: 10' tiri\n6x5' uomo in + \n8x25 sl C3 r30\n\n"
            "Defaticamento\n200 sl A1",
      });
    }
    return scrivi(
      'Ecco una proposta per giovedì: rivedila e creala se va bene.',
    );
  }

  return scrivi(
    'Nella demo rispondo solo alle domande d\'esempio: superiorità, '
    'convocazione, dolori, seduta e appello. Con l\'AI vera rispondo a quello che '
    'chiedi.',
  );
}
