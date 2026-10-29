part of 'strumenti_assistente.dart';

// Il secco dell'assistente (passo D, scelte del coach del 2026-10-29): una
// seduta o un programma a settimane da una frase, solo con gli esercizi
// dell'elenco del club, e le modifiche a voce di una seduta a secco. Al
// modello arrivano gli esercizi con un codice (E1, E2...) e le dosi: mai
// atleti, mai salute.

/// Una seduta a secco proposta dall'assistente, da creare.
class PropostaSedutaSecco extends SchedaAssistente {
  const PropostaSedutaSecco({
    required this.data,
    required this.titolo,
    required this.durataMin,
    required this.dosi,
    required this.esercizi,
  });

  final DateTime data;
  final String? titolo;
  final int durataMin;
  final List<DoseEsercizio> dosi;

  /// Gli esercizi del club per id, per i nomi.
  final Map<String, EsercizioSecco> esercizi;
}

/// Un programma a secco a settimane proposto dall'assistente, da creare
/// fra i programmi del club (poi «Metti nel calendario»). Le settimane
/// dopo la prima le fa l'app, come «Aggiungi la settimana».
class PropostaProgrammaSecco extends SchedaAssistente {
  const PropostaProgrammaSecco({
    required this.programma,
    required this.esercizi,
  });

  final ProgrammaSecco programma;
  final Map<String, EsercizioSecco> esercizi;

  /// Le settimane di scarico, da 1.
  List<int> get scarico => [
    for (final (i, s) in programma.settimane.indexed)
      if (s.scarico) i + 1,
  ];
}

/// Le modifiche a una seduta a secco che c'è, da confermare: gli esercizi
/// (quelli di tutti; le varianti seguono il loro esercizio), titolo, note e
/// durata.
class PropostaModificaSecco extends SchedaAssistente {
  const PropostaModificaSecco({
    required this.allenamento,
    required this.righe,
    required this.dosi,
    required this.cambiaEsercizi,
    required this.titolo,
    required this.note,
    required this.durataMin,
    required this.esercizi,
  });

  /// La seduta com'era quando l'assistente l'ha letta.
  final Allenamento allenamento;

  /// Tutte le righe salvate allora (anche le varianti): prima di salvare
  /// l'app controlla che siano ancora quelle.
  final List<EsercizioSeduta> righe;

  /// Gli esercizi di tutti dopo la modifica, nell'ordine.
  final List<DoseEsercizio> dosi;
  final bool cambiaEsercizi;
  final String? titolo;
  final String? note;
  final int? durataMin;
  final Map<String, EsercizioSecco> esercizi;

  bool get cambiaTitolo => titolo != allenamento.titolo;
  bool get cambiaNote => note != allenamento.note;
  bool get cambiaDurata => durataMin != allenamento.durataMin;

  List<EsercizioSeduta> get principaliPrima => righePrincipali(righe);

  /// Il confronto riga per riga degli esercizi.
  List<RigaConfronto> get confronto => confrontaRighe(
    [for (final r in principaliPrima) rigaSecco(esercizi[r.esercizioId], r)],
    [
      for (final (i, d) in dosi.indexed)
        rigaSecco(esercizi[d.esercizioId], d.comeRiga(ordine: i + 1)),
    ],
  );
}

/// "Squat: 3 × 12, 70% · recupero 45''".
String rigaSecco(EsercizioSecco? esercizio, EsercizioSeduta r) =>
    '${esercizio?.nome ?? 'Esercizio'}: ${prescrizioneEsercizio(r)}';

/// Cosa fare per passare dalle righe di adesso agli esercizi [dosi]: le
/// righe dello stesso esercizio nello stesso ordine restano (con le serie
/// fatte e le varianti), cambiate solo se cambia la dose o il posto; le
/// altre si tolgono (con le loro varianti) o si creano.
typedef PianoSecco = ({
  List<String> elimina,
  List<EsercizioSeduta> aggiorna,
  List<EsercizioSeduta> crea,
});

PianoSecco pianoSecco({
  required List<EsercizioSeduta> righe,
  required List<DoseEsercizio> dosi,
  required String allenamentoId,
  required String clubId,
  required String Function() nuovoId,
}) {
  final prima = righePrincipali(righe);
  // La sottosequenza comune più lunga, per esercizio.
  final n = prima.length;
  final m = dosi.length;
  final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = prima[i].esercizioId == dosi[j].esercizioId
          ? lcs[i + 1][j + 1] + 1
          : math.max(lcs[i + 1][j], lcs[i][j + 1]);
    }
  }
  final coppie = <int, EsercizioSeduta>{};
  var i = 0;
  var j = 0;
  while (i < n && j < m) {
    if (prima[i].esercizioId == dosi[j].esercizioId) {
      coppie[j] = prima[i];
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  final tenute = {for (final r in coppie.values) r.id};
  final aggiorna = <EsercizioSeduta>[];
  final crea = <EsercizioSeduta>[];
  for (final (k, d) in dosi.indexed) {
    final ordine = k + 1;
    final vecchia = coppie[k];
    if (vecchia == null) {
      crea.add(
        d.comeRiga(
          ordine: ordine,
          id: nuovoId(),
          allenamentoId: allenamentoId,
          clubId: clubId,
        ),
      );
      continue;
    }
    final nuova = vecchia
        .conPrescrizione(
          serie: d.serie,
          ripetizioni: d.ripetizioni,
          durataS: d.durataS,
          carico: d.carico,
          recuperoS: d.recuperoS,
          note: d.note,
        )
        .copyWith(ordine: ordine);
    if (!_stessaRiga(nuova, vecchia)) aggiorna.add(nuova);
    // Le varianti stanno al posto del loro esercizio.
    for (final v in righe) {
      if (v.varianteDi == vecchia.id && v.ordine != ordine) {
        aggiorna.add(v.copyWith(ordine: ordine));
      }
    }
  }
  return (
    elimina: [
      for (final r in prima)
        if (!tenute.contains(r.id)) r.id,
    ],
    aggiorna: aggiorna,
    crea: crea,
  );
}

bool _stessaRiga(EsercizioSeduta a, EsercizioSeduta b) {
  final pa = a.toPayload();
  final pb = b.toPayload();
  if (a.id != b.id || a.esercizioId != b.esercizioId) return false;
  for (final k in {...pa.keys, ...pb.keys}) {
    if ('${pa[k]}' != '${pb[k]}') return false;
  }
  return true;
}

/// Le righe [attuali] sono ancora quelle [lette]: le stesse, con gli
/// stessi dati. Se no la proposta è vecchia.
bool stessiEsercizi(
  List<EsercizioSeduta> attuali,
  List<EsercizioSeduta> lette,
) {
  if (attuali.length != lette.length) return false;
  final perId = {for (final r in lette) r.id: r};
  for (final a in attuali) {
    final l = perId[a.id];
    if (l == null || !_stessaRiga(a, l)) return false;
  }
  return true;
}

/// Una dose scritta male dal modello.
class _DoseNonValida implements Exception {
  const _DoseNonValida(this.messaggio);
  final String messaggio;
}

extension _Secco on StrumentiAssistente {
  /// Gli esercizi del club con il loro codice: E1, E2... nell'ordine
  /// dell'elenco (per categoria e nome), fissi per la conversazione; uno
  /// aggiunto dopo prende il codice dopo l'ultimo.
  Future<Map<String, EsercizioSecco>> _esercizi() async {
    final tutti =
        [
          for (final e in await fonte.eserciziSecco())
            if (!e.archiviato) e,
        ]..sort((a, b) {
          final c = a.categoria.index.compareTo(b.categoria.index);
          return c != 0
              ? c
              : a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        });
    for (final e in tutti) {
      if (_codicePerEsercizio.containsKey(e.id)) continue;
      final codice = 'E${_codicePerEsercizio.length + 1}';
      _codicePerEsercizio[e.id] = codice;
      _eserciziPerCodice[codice] = e;
    }
    return {for (final e in tutti) e.id: e};
  }

  String _codiceEsercizio(String id) => _codicePerEsercizio[id] ?? '?';

  Future<Map<String, Object?>> _eserciziSecco() async {
    final esercizi = await _esercizi();
    final conMassimale = await fonte.eserciziConMassimale();
    return {
      'esercizi': [
        for (final e in esercizi.values)
          {
            'codice': _codiceEsercizio(e.id),
            'nome': pseudonimi.anonimizza(e.nome),
            'categoria': e.categoria.etichetta.toLowerCase(),
            'misura': e.aTempo ? 'tempo' : 'ripetizioni',
            'attrezzo': ?_senzaNomi(e.attrezzo),
            if (conMassimale.contains(e.id)) 'massimale': true,
          },
      ],
      if (esercizi.isEmpty)
        'nota':
            'L\'elenco del club è vuoto: l\'allenatore aggiunge gli esercizi '
            'dalla pagina «Elenco esercizi del club».',
    };
  }

  /// La dose scritta dal modello, controllata: l'esercizio dev'essere
  /// dell'elenco del club; i numeri restano in un intervallo sensato. Una
  /// percentuale per un esercizio senza massimale si toglie (in
  /// [carichiTolti]). Quello che manca lo prende dalla [prima] (la stessa
  /// riga prima della modifica), se c'è.
  DoseEsercizio _dose(
    Object? grezza, {
    required Set<String> conMassimale,
    required List<String> carichiTolti,
    DoseEsercizio? Function(String esercizioId)? prima,
  }) {
    if (grezza is! Map) throw const _DoseNonValida('Esercizio senza dati.');
    final codice = '${grezza['esercizio'] ?? ''}'.trim().toUpperCase();
    final esercizio = _eserciziPerCodice[codice];
    if (esercizio == null || esercizio.archiviato) {
      throw _DoseNonValida(
        'Esercizio sconosciuto: "$codice". Usa solo i codici di '
        'esercizi_secco.',
      );
    }
    final vecchia = prima?.call(esercizio.id);
    int? intero(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    final serie = (intero(grezza['serie']) ?? vecchia?.serie ?? 3).clamp(1, 10);
    int? ripetizioni;
    int? durataS;
    if (esercizio.aTempo) {
      durataS =
          (intero(grezza['secondi']) ??
                  intero(grezza['ripetizioni']) ??
                  vecchia?.durataS ??
                  30)
              .clamp(5, 3600);
    } else {
      ripetizioni =
          (intero(grezza['ripetizioni']) ?? vecchia?.ripetizioni ?? 12).clamp(
            1,
            500,
          );
    }
    final recupero =
        (intero(grezza['recupero_secondi']) ?? vecchia?.recuperoS ?? 45).clamp(
          0,
          600,
        );
    String? testo(String chiave, String? attuale, int massimo) {
      if (!grezza.containsKey(chiave)) return attuale;
      final t = '${grezza[chiave] ?? ''}'.trim();
      if (t.isEmpty) return null;
      // Riscritto uguale (con i codici): resta com'era.
      if (attuale != null && t == pseudonimi.anonimizza(attuale).trim()) {
        return attuale;
      }
      final conNomi = pseudonimi.conNomi(t);
      return conNomi.length > massimo ? conNomi.substring(0, massimo) : conNomi;
    }

    var carico = testo('carico', vecchia?.carico, 40);
    if (percentualeDelCarico(carico) != null &&
        !conMassimale.contains(esercizio.id)) {
      carichiTolti.add(codice);
      carico = null;
    }
    return DoseEsercizio(
      esercizioId: esercizio.id,
      serie: serie,
      ripetizioni: ripetizioni,
      durataS: durataS,
      carico: carico,
      recuperoS: recupero,
      note: testo('note', vecchia?.note, 200),
    );
  }

  /// Le dosi di una lista del modello, o l'errore per il modello.
  Future<(List<DoseEsercizio>?, Map<String, Object?>?)> _dosi(
    Object? lista, {
    required List<String> carichiTolti,
    int massimo = 20,
    List<DoseEsercizio> prima = const [],
  }) async {
    await _esercizi();
    if (lista is! List || lista.isEmpty) {
      return (
        null,
        {'errore': 'Nessun esercizio: scegli gli esercizi con esercizi_secco.'},
      );
    }
    if (lista.length > massimo) {
      return (
        null,
        {'errore': 'Troppi esercizi: al massimo $massimo per seduta.'},
      );
    }
    final conMassimale = await fonte.eserciziConMassimale();
    // Per ogni esercizio, le sue righe di prima ancora da usare.
    final daUsare = <String, List<DoseEsercizio>>{};
    for (final d in prima) {
      (daUsare[d.esercizioId] ??= []).add(d);
    }
    DoseEsercizio? primaDi(String id) {
      final l = daUsare[id];
      return l == null || l.isEmpty ? null : l.removeAt(0);
    }

    try {
      return (
        [
          for (final d in lista)
            _dose(
              d,
              conMassimale: conMassimale,
              carichiTolti: carichiTolti,
              prima: primaDi,
            ),
        ],
        null,
      );
    } on _DoseNonValida catch (e) {
      return (null, {'errore': e.messaggio});
    }
  }

  /// Le dosi per il modello: codice, nome e quanto.
  List<Map<String, Object?>> _dosiPerModello(List<DoseEsercizio> dosi) => [
    for (final d in dosi)
      {
        'esercizio': _codiceEsercizio(d.esercizioId),
        'nome': pseudonimi.anonimizza(
          _eserciziPerCodice[_codiceEsercizio(d.esercizioId)]?.nome ?? '',
        ),
        'serie': d.serie,
        'ripetizioni': ?d.ripetizioni,
        'secondi': ?d.durataS,
        'recupero_secondi': ?d.recuperoS,
        'carico': ?_senzaNomi(d.carico),
        'note': ?_senzaNomi(d.note),
      },
  ];

  int _minuti(Object? valore, int predefinito, int minimo, int massimo) =>
      _intero(valore, predefinito, minimo, massimo);

  Future<EsitoStrumento> _proponiSedutaSecco(Map<String, dynamic> args) async {
    final data = DateTime.tryParse('${args['data']}');
    if (data == null) {
      return _solo({'errore': 'Data non valida: usa AAAA-MM-GG.'});
    }
    final carichiTolti = <String>[];
    final (dosi, errore) = await _dosi(
      args['esercizi'],
      carichiTolti: carichiTolti,
    );
    if (dosi == null) return _solo(errore!);
    final stima = math.max(5, minutiDosi(dosi));
    final minuti = _minuti(args['minuti'], stima, 5, 600);
    final titolo = args['titolo'] == null
        ? null
        : pseudonimi.conNomi('${args['titolo']}').trim();
    final esercizi = await _esercizi();
    return (
      perModello: {
        'stato':
            'Proposta mostrata all\'allenatore: la crea lui. Non è ancora '
            'creata.',
        'data': formatDateOnly(data),
        'esercizi': _dosiPerModello(dosi),
        'minuti': minuti,
        'minuti_stimati_fatti_come_scritto': stima,
        if (carichiTolti.isNotEmpty)
          'carichi_tolti':
              'Percentuali tolte a ${carichiTolti.join(', ')}: senza '
              'massimale non si possono calcolare i chili.',
      },
      scheda: PropostaSedutaSecco(
        data: soloData(data),
        titolo: titolo == null || titolo.isEmpty ? null : titolo,
        durataMin: minuti,
        dosi: dosi,
        esercizi: esercizi,
      ),
    );
  }

  Future<EsitoStrumento> _proponiProgrammaSecco(
    Map<String, dynamic> args,
  ) async {
    final nome = pseudonimi.conNomi('${args['nome'] ?? ''}').trim();
    if (nome.isEmpty) {
      return _solo({'errore': 'Manca il nome del programma.'});
    }
    final grezze = args['sedute'];
    if (grezze is! List || grezze.isEmpty || grezze.length > 4) {
      return _solo({
        'errore':
            'Le sedute della prima settimana: da 1 a 4 liste di esercizi '
            '(la A, la B...).',
      });
    }
    final carichiTolti = <String>[];
    final sedute = <List<DoseEsercizio>>[];
    for (final s in grezze) {
      final (dosi, errore) = await _dosi(
        s,
        carichiTolti: carichiTolti,
        massimo: 15,
      );
      if (dosi == null) return _solo(errore!);
      sedute.add(dosi);
    }
    final quante = _intero(args['settimane'], 4, 1, 12);
    final scarico = {
      for (final w in (args['scarico'] as List?) ?? const [])
        if (w is num && w.toInt() >= 2 && w.toInt() <= quante) w.toInt(),
    };
    final esercizi = await _esercizi();
    final settimane = <SettimanaProgramma>[SettimanaProgramma(sedute: sedute)];
    for (var w = 2; w <= quante; w++) {
      if (scarico.contains(w)) {
        final base = settimane.lastWhere((s) => !s.scarico);
        settimane.add(
          SettimanaProgramma(
            scarico: true,
            sedute: [
              for (final s in base.sedute)
                [for (final d in s) unaSerieInMeno(d)],
            ],
          ),
        );
      } else {
        settimane.add(settimanaSuccessiva(settimane, esercizi: esercizi));
      }
    }
    final stima = [for (final s in sedute) math.max(5, minutiDosi(s))];
    final minuti = _minuti(args['minuti'], stima.reduce(math.max), 5, 120);
    final descrizione = args['descrizione'] == null
        ? null
        : pseudonimi.conNomi('${args['descrizione']}').trim();
    final programma = ProgrammaSecco(
      id: '',
      clubId: '',
      nome: nome,
      descrizione: descrizione == null || descrizione.isEmpty
          ? null
          : descrizione,
      durataMin: minuti,
      settimane: settimane,
    );
    return (
      perModello: {
        'stato':
            'Programma mostrato all\'allenatore: lo crea lui fra i programmi '
            'a secco del club, poi lo mette nel calendario della squadra. '
            'Non è ancora creato.',
        'settimane': quante,
        'sedute_per_settimana': sedute.length,
        'settimane_di_scarico': (scarico.toList()..sort()),
        'minuti_per_seduta': minuti,
        'minuti_stimati_per_seduta': stima,
        'progressione':
            'Dalla seconda settimana l\'app aggiunge un po\' ogni settimana '
            '(una serie fino a 4, poi +2 ripetizioni o +5 secondi; la '
            'mobilità resta uguale); lo scarico ha una serie in meno.',
        'prima_settimana': [for (final s in sedute) _dosiPerModello(s)],
        if (carichiTolti.isNotEmpty)
          'carichi_tolti':
              'Percentuali tolte a ${carichiTolti.toSet().join(', ')}: senza '
              'massimale non si possono calcolare i chili.',
      },
      scheda: PropostaProgrammaSecco(programma: programma, esercizi: esercizi),
    );
  }

  /// Una seduta a secco come la legge il modello: gli esercizi di tutti
  /// con codice e dose; delle varianti per gli atleti solo quante sono.
  Future<Map<String, Object?>> _leggiSecco(Allenamento seduta) async {
    await _esercizi();
    final righe = await fonte.eserciziSeduta(seduta.id);
    final principali = righePrincipali(righe);
    return {
      'seduta': {
        ..._sedutaPerModello(seduta),
        'tipo': 'secco',
        'minuti': seduta.durataMin ?? minutiSeccoPredefiniti,
      },
      'esercizi': [
        for (final (i, r) in principali.indexed)
          {
            ..._dosiPerModello([DoseEsercizio.daRiga(r)]).single,
            if (!r.destinatari.perTutti) 'non_per_tutti': true,
            if (righe.where((v) => v.varianteDi == r.id).length case final n
                when n > 0)
              'varianti_per_atleti': n,
            'posto': i + 1,
          },
      ],
    };
  }

  Future<EsitoStrumento> _proponiModificaSecco(
    Allenamento seduta,
    Map<String, dynamic> args,
  ) async {
    final righe = await fonte.eserciziSeduta(seduta.id);
    final prima = [
      for (final r in righePrincipali(righe)) DoseEsercizio.daRiga(r),
    ];
    final carichiTolti = <String>[];
    var dosi = prima;
    if (args.containsKey('esercizi')) {
      final (nuove, errore) = await _dosi(
        args['esercizi'],
        carichiTolti: carichiTolti,
        prima: prima,
      );
      if (nuove == null) return _solo(errore!);
      dosi = nuove;
    } else {
      await _esercizi();
    }
    final cambiaEsercizi =
        dosi.length != prima.length ||
        [
          for (final (i, d) in dosi.indexed)
            '${d.toMap()}' != '${prima[i].toMap()}',
        ].any((x) => x);

    String? testoLibero(String chiave, String? attuale) {
      if (!args.containsKey(chiave)) return attuale;
      final nuovo = '${args[chiave] ?? ''}'.trim();
      if (nuovo == pseudonimi.anonimizza(attuale ?? '').trim()) return attuale;
      final conNomi = pseudonimi.conNomi(nuovo);
      return conNomi.isEmpty ? null : conNomi;
    }

    final durata = args.containsKey('minuti')
        ? _intero(args['minuti'], seduta.durataMin ?? 45, 5, 600)
        : seduta.durataMin;
    final proposta = PropostaModificaSecco(
      allenamento: seduta,
      righe: righe,
      dosi: dosi,
      cambiaEsercizi: cambiaEsercizi,
      titolo: testoLibero('titolo', seduta.titolo),
      note: testoLibero('note', seduta.note),
      durataMin: durata,
      esercizi: await _esercizi(),
    );
    if (!cambiaEsercizi &&
        !proposta.cambiaTitolo &&
        !proposta.cambiaNote &&
        !proposta.cambiaDurata) {
      return _solo({
        'errore':
            'Niente di diverso dalla seduta di adesso: rileggila con '
            'leggi_seduta e riscrivi gli esercizi con le modifiche.',
      });
    }
    final confronto = proposta.confronto;
    return (
      perModello: {
        'stato':
            'Modifiche mostrate all\'allenatore: le controlla e le salva lui. '
            'Non sono ancora salvate.',
        'seduta': {
          'id': seduta.id,
          'data': formatDateOnly(seduta.data),
          'giorno': nomeGiorno(seduta.data),
          'tipo': 'secco',
        },
        'cambia_esercizi': cambiaEsercizi,
        'esercizi_prima': prima.length,
        'esercizi_dopo': dosi.length,
        // Quello che cambia davvero, per controllarlo e dirlo giusto.
        'righe_tolte': [
          for (final r in confronto)
            if (r.stato == StatoRiga.tolta) pseudonimi.anonimizza(r.testo),
        ],
        'righe_aggiunte': [
          for (final r in confronto)
            if (r.stato == StatoRiga.aggiunta) pseudonimi.anonimizza(r.testo),
        ],
        'cambia_titolo': proposta.cambiaTitolo,
        'cambia_note': proposta.cambiaNote,
        if (proposta.cambiaDurata) 'minuti': durata,
        if (carichiTolti.isNotEmpty)
          'carichi_tolti':
              'Percentuali tolte a ${carichiTolti.join(', ')}: senza '
              'massimale non si possono calcolare i chili.',
      },
      scheda: proposta,
    );
  }
}
