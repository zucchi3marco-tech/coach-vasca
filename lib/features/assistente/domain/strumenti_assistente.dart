import '../../../core/utils/date_format.dart';
import '../../../core/utils/giorni.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/testo_allenamento.dart';
import '../../allenamenti/domain/variante_spalla.dart' show giorniDoloreSpalla;
import '../../allenamenti/domain/volume_allenamento.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/squadre_atleta.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../carico/domain/carico_rpe.dart';
import '../../pallanuoto/domain/distinta_giocatore.dart';
import '../../pallanuoto/domain/evento_partita.dart';
import '../../pallanuoto/domain/numeri_distinta.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../pallanuoto/domain/statistiche_eventi.dart';
import '../../presenze/domain/presenza.dart';
import 'pseudonimi.dart';

/// Da dove l'assistente legge i dati del club: sul telefono, con le stesse
/// letture delle schermate (vedi `FonteDatiRiverpod`), finte nei test.
abstract class FonteDatiAssistente {
  /// Il gruppo scelto nell'app (null = tutto il club).
  String? get gruppoId;
  Future<List<Atleta>> atleti();
  Future<List<Partita>> partite();
  Future<List<EventoPartita>> eventi(String partitaId);
  Future<List<DistintaGiocatore>> distinta(String partitaId);
  Future<List<Presenza>> presenze();
  Future<List<Allenamento>> allenamenti();
  Future<Map<String, VolumeAllenamento>> volumi();
  Future<List<SchedaBenessere>> schedeBenessere();
  Future<Map<String, List<CaricoSeduta>>> sedutePerAtleta();
}

/// Quello che uno strumento fa vedere all'allenatore nella chat, oltre a
/// quello che risponde al modello.
sealed class SchedaAssistente {
  const SchedaAssistente();
}

/// Il benessere della squadra, calcolato e mostrato sul telefono: al
/// modello non arriva.
class SchedaSalute extends SchedaAssistente {
  const SchedaSalute({
    required this.titolo,
    required this.righe,
    required this.senzaScheda,
  });

  final String titolo;
  final List<RigaSalute> righe;

  /// Chi non ha compilato la scheda nei giorni guardati.
  final List<Atleta> senzaScheda;
}

class RigaSalute {
  const RigaSalute({
    required this.atleta,
    required this.giorno,
    required this.punteggio,
    required this.scheda,
  });

  final Atleta atleta;
  final DateTime giorno;
  final PunteggioBenessere punteggio;
  final SchedaBenessere scheda;
}

/// La distinta proposta per una partita, da confermare.
class PropostaConvocazione extends SchedaAssistente {
  const PropostaConvocazione({
    required this.partita,
    required this.nuovi,
    required this.giaConvocati,
  });

  final Partita partita;

  /// Chi entra, con il numero di calottina proposto.
  final List<({Atleta atleta, int numero})> nuovi;

  /// Quanti erano già in distinta.
  final int giaConvocati;

  int get totale => nuovi.length + giaConvocati;

  bool get oltreIlMassimo => totale > partita.numeroMaxConvocati;
}

/// Una seduta in acqua scritta dal modello nel formato di "Scrivi
/// l'allenamento", già letta dall'app, da confermare.
class PropostaSeduta extends SchedaAssistente {
  const PropostaSeduta({
    required this.data,
    required this.titolo,
    required this.testo,
    required this.scritto,
  });

  final DateTime data;
  final String? titolo;
  final String testo;
  final AllenamentoScritto scritto;
}

/// Un atleta nell'appello proposto: lo stato di adesso (null se non è
/// ancora segnato) e quello proposto.
class RigaAppello {
  const RigaAppello({
    required this.atleta,
    required this.attuale,
    required this.proposto,
    this.nominato = false,
    this.daFuori = false,
  });

  final Atleta atleta;
  final String? attuale;
  final String proposto;

  /// L'ha nominato l'allenatore.
  final bool nominato;

  /// Non era atteso a questa seduta (un'altra squadra): c'è perché l'ha
  /// nominato l'allenatore.
  final bool daFuori;
}

/// L'appello di una seduta, da confermare. Chi l'allenatore non nomina è
/// presente, chi era già segnato resta com'era (scelta del coach,
/// 2026-10-28); prima di salvare può cambiare chiunque.
class PropostaAppello extends SchedaAssistente {
  const PropostaAppello({required this.allenamento, required this.righe});

  final Allenamento allenamento;
  final List<RigaAppello> righe;
}

/// L'esito di uno strumento: il JSON per il modello (mai nomi, mai salute)
/// e, a volte, una scheda per l'allenatore.
typedef EsitoStrumento = ({
  Map<String, Object?> perModello,
  SchedaAssistente? scheda,
});

/// Presenze di un atleta: `presente` comprende i ritardi (`inRitardo`).
typedef _ContiPresenze = ({
  int presente,
  int inRitardo,
  int assente,
  int giustificato,
});

/// Gli strumenti dell'assistente, eseguiti sul telefono. Ognuno legge i
/// dati con la [fonte], li conta come le schermate e restituisce al modello
/// solo codici ([pseudonimi]) e numeri. Benessere e dolori restano qui:
/// [scegli_atleti] li usa come filtro, [mostra_benessere] li mostra
/// all'allenatore.
class StrumentiAssistente {
  StrumentiAssistente({
    required this.fonte,
    required this.pseudonimi,
    required this.oggi,
  });

  final FonteDatiAssistente fonte;
  final Pseudonimi pseudonimi;
  final DateTime oggi;

  DateTime get _oggi => soloData(oggi);

  Future<EsitoStrumento> esegui(String nome, Map<String, dynamic> args) async {
    try {
      return switch (nome) {
        'squadra' => _solo(await _squadraJson()),
        'partite' => _solo(await _partite(args)),
        'statistiche_partite' => _solo(await _statistiche(args)),
        'presenze' => _solo(await _presenze(args)),
        'carico' => _solo(await _carico()),
        'allenamenti' => _solo(await _allenamenti(args)),
        'scegli_atleti' => _solo(await _scegliAtleti(args)),
        'mostra_benessere' => await _mostraBenessere(args),
        'proponi_convocazione' => await _proponiConvocazione(args),
        'proponi_seduta' => await _proponiSeduta(args),
        'proponi_appello' => await _proponiAppello(args),
        _ => _solo({'errore': 'Strumento sconosciuto: $nome'}),
      };
    } catch (e) {
      // Un dato che non si legge: il modello lo dice, invece di inventare.
      return _solo({'errore': 'Dati non disponibili ($nome)'});
    }
  }

  EsitoStrumento _solo(Map<String, Object?> json) =>
      (perModello: json, scheda: null);

  // -------------------------------------------------------------------------
  // Squadra

  Future<List<Atleta>> _squadra() async {
    final gruppo = fonte.gruppoId;
    return [
      for (final a in await fonte.atleti())
        // Anche chi si allena con la squadra in giorni fissi.
        if (a.attivo &&
            (gruppo == null ||
                a.gruppoId == gruppo ||
                a.altroGruppoId == gruppo))
          a,
    ]..sort(
      (a, b) => (pseudonimi.codice(a.id) ?? '').compareTo(
        pseudonimi.codice(b.id) ?? '',
      ),
    );
  }

  String _codice(String atletaId) => pseudonimi.codice(atletaId) ?? '?';

  Future<Map<String, Object?>> _squadraJson() async => {
    'atleti': [
      for (final a in await _squadra())
        {
          'codice': _codice(a.id),
          'ruolo': a.portiere ? 'portiere' : 'movimento',
        },
    ],
  };

  // -------------------------------------------------------------------------
  // Partite

  Future<List<Partita>> _partiteDellaSquadra() async => [
    for (final p in await fonte.partite())
      if (visibileNelGruppo(
        gruppoDelRecord: p.gruppoId,
        gruppoSelezionato: fonte.gruppoId,
      ))
        p,
  ];

  Future<Map<String, Object?>> _partite(Map<String, dynamic> args) async {
    final giocate = args['quali'] == 'giocate';
    final quante = _intero(args['quante'], 5, 1, 20);
    final scelte =
        [
          for (final p in await _partiteDellaSquadra())
            if (giocate ? p.data.isBefore(_oggi) : !p.data.isBefore(_oggi)) p,
        ]..sort(
          (a, b) =>
              giocate ? b.data.compareTo(a.data) : a.data.compareTo(b.data),
        );
    return {
      'partite': [
        for (final p in scelte.take(quante))
          {
            'id': p.id,
            'data': formatDateOnly(p.data),
            'giorno': nomeGiorno(p.data),
            'ora': ?p.ora,
            'avversario': p.avversario,
            'in_casa': p.inCasa,
            'risultato': ?_risultato(await fonte.eventi(p.id)),
            'convocati': (await fonte.distinta(p.id)).length,
            'massimo_convocati': p.numeroMaxConvocati,
            'convocazione_inviata': p.convocazioneInviata,
          },
      ],
    };
  }

  /// "8-6": prima i gol nostri. Null senza eventi.
  String? _risultato(List<EventoPartita> eventi) {
    if (eventi.isEmpty) return null;
    var nostri = 0;
    var loro = 0;
    for (final e in eventi) {
      if (e.tipo != 'tiro' || e.esito != 'gol') continue;
      if (e.squadra == 'nostra') {
        nostri++;
      } else {
        loro++;
      }
    }
    return '$nostri-$loro';
  }

  Future<Map<String, Object?>> _statistiche(Map<String, dynamic> args) async {
    final ids = [
      for (final id in (args['partite_id'] as List?) ?? const []) '$id',
    ];
    final tutte = await _partiteDellaSquadra();
    final List<Partita> scelte;
    if (ids.isNotEmpty) {
      scelte = [
        for (final p in tutte)
          if (ids.contains(p.id)) p,
      ];
    } else {
      scelte = [
        for (final p in tutte)
          if (p.data.isBefore(_oggi)) p,
      ]..sort((a, b) => b.data.compareTo(a.data));
      final quante = _intero(args['ultime'], 5, 1, 30);
      if (scelte.length > quante) scelte.removeRange(quante, scelte.length);
    }
    final eventi = <EventoPartita>[
      for (final p in scelte) ...await fonte.eventi(p.id),
    ];
    final st = StatisticheEventi.da(eventi);
    Map<String, int> numeri(NumeriEventi n) => {
      'gol': n.gol,
      'tiri': n.tiri,
      'gol_in_superiorita': n.golSuperiorita,
      'gol_su_rigore': n.golRigore,
      'gol_in_controfuga': n.golControfuga,
      'assist': n.assist,
      'espulsioni': n.espulsioni,
      'palle_perse': n.pallePerse,
      'palle_recuperate': n.palleRecuperate,
      'espulsioni_guadagnate': n.espulsioniGuadagnate,
      'rigori_guadagnati': n.rigoriGuadagnati,
    };
    final s = st.squadra;
    return {
      'partite': [
        for (final p in scelte)
          {
            'id': p.id,
            'data': formatDateOnly(p.data),
            'avversario': p.avversario,
            'risultato': ?_risultato(await fonte.eventi(p.id)),
          },
      ],
      'partite_con_eventi': st.partite,
      'squadra': {
        ...numeri(s),
        'tiri_subiti': s.tiriSubiti,
        'gol_subiti': s.golSubiti,
        'gol_subiti_in_controfuga': s.golSubitiControfuga,
        'superiorita': s.superiorita,
        'superiorita_segnate': s.golInSuperiorita,
        'inferiorita': s.inferiorita,
        'gol_subiti_in_inferiorita': s.golSubitiInInferiorita,
        'rigori_avuti': s.rigoriAvuti,
        'rigori_tirati': s.rigoriTirati,
        'rigori_concessi': s.rigoriConcessi,
      },
      'per_atleta': [
        for (final MapEntry(key: id, value: n) in st.perAtleta.entries)
          if (pseudonimi.codice(id) != null)
            {'codice': _codice(id), ...numeri(n)},
      ],
    };
  }

  // -------------------------------------------------------------------------
  // Allenamenti, presenze, carico

  Future<List<Allenamento>> _allenamentiDellaSquadra() async => [
    for (final a in await fonte.allenamenti())
      if (visibileNelGruppo(
        gruppoDelRecord: a.gruppoId,
        gruppoSelezionato: fonte.gruppoId,
      ))
        a,
  ];

  /// Le presenze di ogni atleta (chiave: id) negli allenamenti degli
  /// ultimi [giorni] giorni. `presente` comprende chi è arrivato in
  /// ritardo (`inRitardo` ne dice quanti erano).
  Future<Map<String, _ContiPresenze>> _contaPresenze(int giorni) async {
    final inizio = aggiungiGiorni(_oggi, -giorni);
    final sedute = {
      for (final a in await _allenamentiDellaSquadra())
        if (!soloData(a.data).isBefore(inizio) &&
            !soloData(a.data).isAfter(_oggi))
          a.id,
    };
    final conti = <String, _ContiPresenze>{};
    for (final p in await fonte.presenze()) {
      if (!sedute.contains(p.allenamentoId)) continue;
      final c =
          conti[p.atletaId] ??
          (presente: 0, inRitardo: 0, assente: 0, giustificato: 0);
      conti[p.atletaId] = (
        presente: c.presente + (contaComePresente(p.stato) ? 1 : 0),
        inRitardo: c.inRitardo + (p.stato == statoRitardo ? 1 : 0),
        assente: c.assente + (p.stato == statoAssente ? 1 : 0),
        // Qualunque altro stato (giustificato) come prima.
        giustificato:
            c.giustificato +
            (contaComePresente(p.stato) || p.stato == statoAssente ? 0 : 1),
      );
    }
    return conti;
  }

  int? _percentuale(_ContiPresenze? c) {
    if (c == null) return null;
    final totale = c.presente + c.assente + c.giustificato;
    return totale == 0 ? null : (c.presente * 100 / totale).round();
  }

  Future<Map<String, Object?>> _presenze(Map<String, dynamic> args) async {
    final giorni = _intero(args['giorni'], 28, 1, 365);
    final conti = await _contaPresenze(giorni);
    return {
      'giorni': giorni,
      'per_atleta': [
        for (final a in await _squadra())
          {
            'codice': _codice(a.id),
            'presente': conti[a.id]?.presente ?? 0,
            'di_cui_in_ritardo': conti[a.id]?.inRitardo ?? 0,
            'assente': conti[a.id]?.assente ?? 0,
            'giustificato': conti[a.id]?.giustificato ?? 0,
            'percentuale': ?_percentuale(conti[a.id]),
          },
      ],
    };
  }

  Future<Map<String, Object?>> _carico() async {
    final sedute = await fonte.sedutePerAtleta();
    return {
      'per_atleta': [
        for (final a in await _squadra())
          if (calcolaAcwr(sedute[a.id] ?? const [], oggi: oggi)
              case final acwr?)
            {
              'codice': _codice(a.id),
              'carico_7_giorni': acwr.acuto.round(),
              'media_settimanale_4_settimane': acwr.cronico.round(),
              if (acwr.rapporto case final r? when acwr.affidabile)
                'rapporto': double.parse(r.toStringAsFixed(2)),
              'fascia':
                  acwr.fascia?.etichetta ?? 'storico non ancora sufficiente',
            },
      ],
    };
  }

  Future<Map<String, Object?>> _allenamenti(Map<String, dynamic> args) async {
    final da = DateTime.tryParse('${args['da']}') ?? aggiungiGiorni(_oggi, -7);
    final a = DateTime.tryParse('${args['a']}') ?? _oggi;
    final volumi = await fonte.volumi();
    final presenti = <String, int>{};
    for (final p in await fonte.presenze()) {
      if (contaComePresente(p.stato)) {
        presenti[p.allenamentoId] = (presenti[p.allenamentoId] ?? 0) + 1;
      }
    }
    final scelti = [
      for (final s in await _allenamentiDellaSquadra())
        if (!soloData(s.data).isBefore(soloData(da)) &&
            !soloData(s.data).isAfter(soloData(a)))
          s,
    ]..sort((x, y) => x.data.compareTo(y.data));
    return {
      'sedute': [
        for (final s in scelti.take(60))
          {
            'id': s.id,
            'data': formatDateOnly(s.data),
            'giorno': nomeGiorno(s.data),
            'tipo': s.tipo,
            'titolo': pseudonimi.anonimizza(s.titoloMostrato),
            if (s.secco) 'durata_minuti': s.durataMin ?? minutiSeccoPredefiniti,
            if (!s.secco) 'metri': volumi[s.id]?.metri ?? 0,
            if (!s.secco && (volumi[s.id]?.secondi ?? 0) > 0)
              'minuti_a_tempo': (volumi[s.id]!.secondi / 60).round(),
            'presenti': presenti[s.id] ?? 0,
          },
      ],
    };
  }

  // -------------------------------------------------------------------------
  // Salute: resta sul telefono

  /// L'ultima scheda di ogni atleta degli ultimi [giorni] giorni.
  Future<Map<String, SchedaBenessere>> _ultimeSchede(int giorni) async {
    final inizio = aggiungiGiorni(_oggi, -(giorni - 1));
    final ultime = <String, SchedaBenessere>{};
    for (final s in await fonte.schedeBenessere()) {
      final g = soloData(s.data);
      if (g.isBefore(inizio) || g.isAfter(_oggi)) continue;
      final prima = ultime[s.atletaId];
      if (prima == null || s.data.isAfter(prima.data)) ultime[s.atletaId] = s;
    }
    return ultime;
  }

  Future<Map<String, Object?>> _scegliAtleti(Map<String, dynamic> args) async {
    final schede = await _ultimeSchede(giorniDoloreSpalla);
    final ruolo = args['ruolo'];
    bool passa(Atleta a) {
      if (ruolo == 'portieri' && !a.portiere) return false;
      if (ruolo == 'movimento' && a.portiere) return false;
      final s = schede[a.id];
      if (s == null) return true;
      if (args['escludi_dolore_spalla'] == true &&
          s.dolori &&
          s.zoneDolore.contains('spalla')) {
        return false;
      }
      if (args['escludi_dolori'] == true && s.dolori) return false;
      if (args['escludi_sintomi'] == true && s.sintomi.isNotEmpty) return false;
      if (args['escludi_da_sentire'] == true &&
          calcolaPunteggio(s, dataNascita: a.dataNascita).livello >= 2) {
        return false;
      }
      return true;
    }

    var scelti = [
      for (final a in await _squadra())
        if (passa(a)) a,
    ];
    switch (args['ordina_per']) {
      case 'presenze':
        final conti = await _contaPresenze(28);
        scelti.sort(
          (a, b) => (_percentuale(conti[b.id]) ?? -1).compareTo(
            _percentuale(conti[a.id]) ?? -1,
          ),
        );
      case 'carico_basso':
        final sedute = await fonte.sedutePerAtleta();
        double acuto(Atleta a) =>
            calcolaAcwr(sedute[a.id] ?? const [], oggi: oggi)?.acuto ?? 0;
        scelti.sort((a, b) => acuto(a).compareTo(acuto(b)));
    }
    if (args['quanti'] case final int quanti when quanti < scelti.length) {
      scelti = scelti.sublist(0, quanti);
    }
    return {
      'atleti': [for (final a in scelti) _codice(a.id)],
      'nota':
          'I filtri sulla salute li ha applicati l\'app: i motivi non sono '
          'disponibili.',
    };
  }

  Future<EsitoStrumento> _mostraBenessere(Map<String, dynamic> args) async {
    final giorni = _intero(args['giorni'], 3, 1, 14);
    final cosa = '${args['cosa'] ?? 'tutto'}';
    final schede = await _ultimeSchede(giorni);
    final squadra = await _squadra();
    final righe = <RigaSalute>[];
    for (final a in squadra) {
      final s = schede[a.id];
      if (s == null) continue;
      final p = calcolaPunteggio(s, dataNascita: a.dataNascita);
      final tiene = switch (cosa) {
        'dolori' => s.dolori,
        'sintomi' => s.sintomi.isNotEmpty,
        'da_sentire' => p.livello >= 2,
        _ => true,
      };
      if (tiene) {
        righe.add(
          RigaSalute(
            atleta: a,
            giorno: soloData(s.data),
            punteggio: p,
            scheda: s,
          ),
        );
      }
    }
    righe.sort((x, y) => x.punteggio.valore.compareTo(y.punteggio.valore));
    final titolo = switch (cosa) {
      'dolori' => 'Chi ha segnato dolori',
      'sintomi' => 'Chi ha segnato sintomi',
      'da_sentire' => 'Chi è da sentire',
      _ => 'Il benessere della squadra',
    };
    return (
      perModello: {
        'stato':
            'Scheda mostrata all\'allenatore. I dati sulla salute restano '
            'nell\'app e non sono disponibili per te: digli che li trova '
            'nella scheda.',
      },
      scheda: SchedaSalute(
        titolo: giorni == 1
            ? '$titolo oggi'
            : '$titolo negli ultimi $giorni giorni',
        righe: righe,
        senzaScheda: cosa == 'tutto'
            ? [
                for (final a in squadra)
                  if (!schede.containsKey(a.id)) a,
              ]
            : const [],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Azioni: proposte da confermare

  Future<EsitoStrumento> _proponiConvocazione(Map<String, dynamic> args) async {
    final id = '${args['partita_id']}';
    final partita = (await fonte.partite())
        .where((p) => p.id == id)
        .firstOrNull;
    if (partita == null) {
      return _solo({'errore': 'Partita non trovata: usa un id di "partite".'});
    }
    if (partita.data.isBefore(_oggi)) {
      return _solo({'errore': 'La partita è già stata giocata.'});
    }
    final distinta = await fonte.distinta(partita.id);
    final gia = {for (final g in distinta) g.atletaId};
    final sconosciuti = <String>[];
    final scelti = <Atleta>[];
    final visti = <String>{};
    for (final c in (args['atleti'] as List?) ?? const []) {
      final a = pseudonimi.atleta('$c');
      if (a == null) {
        sconosciuti.add('$c');
        continue;
      }
      if (gia.contains(a.id) || !visti.add(a.id)) continue;
      scelti.add(a);
    }
    // La stessa regola della distinta: portieri all'1 e al 13, gli altri
    // dal 2 in su.
    final numeri = numeriProposti(
      occupati: {for (final g in distinta) g.numeroCalottina},
      nuovi: [for (final a in scelti) (atletaId: a.id, portiere: a.portiere)],
      massimo: partita.numeroMaxConvocati,
    );
    final nuovi = [for (final a in scelti) (atleta: a, numero: numeri[a.id]!)];
    final proposta = PropostaConvocazione(
      partita: partita,
      nuovi: nuovi,
      giaConvocati: gia.length,
    );
    return (
      perModello: {
        'stato':
            'Proposta mostrata all\'allenatore: la conferma lui. Non è '
            'ancora fatta.',
        'nuovi': nuovi.length,
        'gia_in_distinta': gia.length,
        'totale': proposta.totale,
        'massimo': partita.numeroMaxConvocati,
        if (proposta.oltreIlMassimo)
          'attenzione': 'Oltre il massimo: l\'allenatore deve toglierne.',
        if (sconosciuti.isNotEmpty) 'codici_sconosciuti': sconosciuti,
      },
      scheda: nuovi.isEmpty ? null : proposta,
    );
  }

  Future<EsitoStrumento> _proponiSeduta(Map<String, dynamic> args) async {
    final data = DateTime.tryParse('${args['data']}');
    if (data == null) {
      return _solo({'errore': 'Data non valida: usa AAAA-MM-GG.'});
    }
    // I codici diventano i nomi che "Scrivi l'allenamento" riconosce.
    final testo = pseudonimi.conNomi('${args['testo'] ?? ''}');
    final titolo = args['titolo'] == null
        ? null
        : pseudonimi.conNomi('${args['titolo']}').trim();
    final scritto = interpretaAllenamento(testo, atleti: await _squadra());
    if (scritto.serie.isEmpty) {
      return _solo({
        'errore':
            'Nessuna serie capita: riscrivi il testo nel formato delle '
            'istruzioni, una serie per riga.',
      });
    }
    return (
      perModello: {
        'stato':
            'Proposta mostrata all\'allenatore: la crea lui. Non è ancora '
            'creata.',
        'serie': scritto.serie.length,
        'metri': scritto.metri,
        'righe_non_capite': scritto.righeNonCapite,
      },
      scheda: PropostaSeduta(
        data: soloData(data),
        titolo: titolo == null || titolo.isEmpty ? null : titolo,
        testo: testo,
        scritto: scritto,
      ),
    );
  }

  /// La seduta dell'appello: quella indicata, o l'unica della squadra in
  /// quel giorno (oggi, se non c'è la data). Con un errore per il modello
  /// se non si sa quale.
  Future<(Allenamento?, Map<String, Object?>?)> _sedutaAppello(
    Map<String, dynamic> args,
  ) async {
    final id = args['allenamento_id'];
    if (id is String && id.isNotEmpty) {
      final seduta = (await fonte.allenamenti())
          .where((a) => a.id == id)
          .firstOrNull;
      return seduta == null
          ? (
              null,
              {
                'errore':
                    'Seduta non trovata: usa un id di "allenamenti", o la '
                    'data.',
              },
            )
          : (seduta, null);
    }
    final giorno = args['data'] == null
        ? _oggi
        : DateTime.tryParse('${args['data']}');
    if (giorno == null) {
      return (null, {'errore': 'Data non valida: usa AAAA-MM-GG.'});
    }
    final delGiorno = [
      for (final a in await _allenamentiDellaSquadra())
        if (soloData(a.data) == soloData(giorno)) a,
    ];
    if (delGiorno.isEmpty) {
      return (
        null,
        {
          'errore':
              'Nessuna seduta della squadra il ${formatDateOnly(giorno)}: '
              'l\'appello si fa su una seduta che c\'è.',
        },
      );
    }
    if (delGiorno.length > 1) {
      return (
        null,
        {
          'errore':
              'Quel giorno le sedute sono ${delGiorno.length}: chiedi '
              'all\'allenatore quale e rifai con allenamento_id.',
          'sedute': [
            for (final s in delGiorno)
              {
                'id': s.id,
                'tipo': s.tipo,
                'titolo': pseudonimi.anonimizza(s.titoloMostrato),
              },
          ],
        },
      );
    }
    return (delGiorno.single, null);
  }

  Future<EsitoStrumento> _proponiAppello(Map<String, dynamic> args) async {
    final (seduta, errore) = await _sedutaAppello(args);
    if (seduta == null) return _solo(errore!);
    if (soloData(seduta.data).isAfter(_oggi)) {
      return _solo({
        'errore':
            'La seduta è il ${formatDateOnly(seduta.data)}: l\'appello si fa '
            'il giorno stesso o dopo.',
      });
    }
    final segnate = {
      for (final p in await fonte.presenze())
        if (p.allenamentoId == seduta.id) p.atletaId: p.stato,
    };
    // Un atleta in due elenchi prende l'ultimo: assente vince su tutto.
    final nominati = <String, String>{};
    final sconosciuti = <String>[];
    for (final (chiave, stato) in const [
      ('presenti', statoPresente),
      ('in_ritardo', statoRitardo),
      ('giustificati', statoGiustificato),
      ('assenti', statoAssente),
    ]) {
      for (final c in (args[chiave] as List?) ?? const []) {
        final a = pseudonimi.atleta('$c');
        if (a == null) {
          sconosciuti.add('$c');
        } else {
          nominati[a.id] = stato;
        }
      }
    }
    final righe = <RigaAppello>[];
    for (final a in pseudonimi.atleti) {
      final atteso = a.attivo && a.attesoA(seduta.gruppoId, seduta.data);
      final attuale = segnate[a.id];
      final nominato = nominati[a.id];
      if (!atteso && attuale == null && nominato == null) continue;
      righe.add(
        RigaAppello(
          atleta: a,
          attuale: attuale,
          proposto: nominato ?? attuale ?? statoPresente,
          nominato: nominato != null,
          daFuori: !atteso && attuale == null,
        ),
      );
    }
    if (righe.isEmpty) {
      return _solo({'errore': 'Nessun atleta atteso a questa seduta.'});
    }
    int quanti(bool Function(String) vale) =>
        righe.where((r) => vale(r.proposto)).length;
    return (
      perModello: {
        'stato':
            'Appello mostrato all\'allenatore: lo controlla, può cambiare '
            'qualcuno e lo salva lui. Non è ancora salvato.',
        'seduta': {
          'id': seduta.id,
          'data': formatDateOnly(seduta.data),
          'giorno': nomeGiorno(seduta.data),
          'tipo': seduta.tipo,
        },
        'presenti': quanti(contaComePresente),
        'di_cui_in_ritardo': quanti((s) => s == statoRitardo),
        'assenti': quanti((s) => s == statoAssente),
        'giustificati': quanti((s) => s == statoGiustificato),
        'gia_segnati_e_non_nominati': righe
            .where((r) => r.attuale != null && !r.nominato)
            .length,
        if (righe.any((r) => r.daFuori))
          'da_altre_squadre': [
            for (final r in righe)
              if (r.daFuori) _codice(r.atleta.id),
          ],
        if (sconosciuti.isNotEmpty) 'codici_sconosciuti': sconosciuti,
      },
      scheda: PropostaAppello(allenamento: seduta, righe: righe),
    );
  }

  int _intero(Object? valore, int predefinito, int minimo, int massimo) =>
      ((valore is num) ? valore.toInt() : predefinito).clamp(minimo, massimo);
}

const _giorni = [
  'lunedì',
  'martedì',
  'mercoledì',
  'giovedì',
  'venerdì',
  'sabato',
  'domenica',
];

/// "sabato": per il modello, che sbaglia i giorni della settimana.
String nomeGiorno(DateTime d) => _giorni[d.weekday - 1];
