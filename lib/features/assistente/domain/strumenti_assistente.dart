import '../../../core/utils/date_format.dart';
import '../../../core/utils/giorni.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/modifica_allenamento.dart';
import '../../allenamenti/domain/piano_salvataggio_testo.dart';
import '../../allenamenti/domain/serie.dart';
import '../../allenamenti/domain/testo_allenamento.dart';
import '../../allenamenti/domain/variante_spalla.dart' show giorniDoloreSpalla;
import '../../allenamenti/domain/volume_allenamento.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/squadre_atleta.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../carico/domain/carico_rpe.dart';
import '../../impegni/domain/impegno.dart';
import '../../pallanuoto/domain/convocazione.dart' show vociConvocazione;
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

  /// Le serie di una seduta in acqua, nell'ordine.
  Future<List<Serie>> serie(String allenamentoId);
  Future<Map<String, VolumeAllenamento>> volumi();
  Future<List<SchedaBenessere>> schedeBenessere();
  Future<Map<String, List<CaricoSeduta>>> sedutePerAtleta();

  /// Collegiali, trasferte, riposi, tornei del club.
  Future<List<Impegno>> impegni();
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

/// Le modifiche a una seduta in acqua che c'è già, da confermare: le serie
/// riscritte dal modello nel formato di "Scrivi l'allenamento" e, se le
/// cambia, titolo e note (la data no: scelta del coach, 2026-10-29).
class PropostaModificaSeduta extends SchedaAssistente {
  const PropostaModificaSeduta({
    required this.allenamento,
    required this.serie,
    required this.testoPrima,
    required this.testoDopo,
    required this.scritto,
    required this.cambiaSerie,
    required this.metriPrima,
    required this.titolo,
    required this.note,
  });

  final int metriPrima;

  /// La seduta com'era quando l'assistente l'ha letta.
  final Allenamento allenamento;

  /// Le serie salvate allora: prima di salvare l'app controlla che siano
  /// ancora quelle.
  final List<Serie> serie;

  /// Il testo delle serie prima e dopo, scritti allo stesso modo dall'app
  /// (così le righe non toccate restano uguali nel confronto).
  final String testoPrima;
  final String testoDopo;
  final AllenamentoScritto scritto;
  final bool cambiaSerie;

  /// Titolo e note da salvare (uguali a quelli di prima se non cambiano;
  /// null = tolti).
  final String? titolo;
  final String? note;

  bool get cambiaTitolo => titolo != allenamento.titolo;
  bool get cambiaNote => note != allenamento.note;

  /// Il confronto riga per riga delle serie.
  List<RigaConfronto> get righe =>
      confrontaRighe(_righe(testoPrima), _righe(testoDopo));

  static List<String> _righe(String testo) =>
      testo.trim().isEmpty ? const [] : testo.trimRight().split('\n');
}

/// Un messaggio per il gruppo WhatsApp dei genitori, con i nomi già al
/// loro posto: l'allenatore lo può correggere e lo manda con Condividi o
/// Copia (scelte del coach, 2026-10-29). Non si salva.
class PropostaMessaggioFamiglie extends SchedaAssistente {
  const PropostaMessaggioFamiglie({required this.testo});

  final String testo;
}

/// Le serie [attuali] sono ancora quelle [lette]: stesse righe, nello
/// stesso ordine, con gli stessi dati. Se no la proposta è vecchia.
bool stesseSerie(List<Serie> attuali, List<Serie> lette) {
  if (attuali.length != lette.length) return false;
  for (var i = 0; i < attuali.length; i++) {
    final a = attuali[i];
    final l = lette[i];
    if (a.id != l.id ||
        !stessaSerie(a, l) ||
        a.recuperoDopoS != l.recuperoDopoS ||
        a.piramideId != l.piramideId ||
        a.momentoId != l.momentoId) {
      return false;
    }
  }
  return true;
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
        'leggi_seduta' => _solo(await _leggiSeduta(args)),
        'proponi_modifica_seduta' => await _proponiModifica(args),
        'impegni' => _solo(await _impegni(args)),
        'proponi_messaggio_famiglie' => _proponiMessaggio(args),
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
            if (!giocate) ..._perLeFamiglie(p),
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

  /// La seduta di cui si parla: quella indicata, o l'unica della squadra in
  /// quel giorno (oggi, se non c'è la data). Con un errore per il modello
  /// se non si sa quale.
  Future<(Allenamento?, Map<String, Object?>?)> _sedutaIndicata(
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
              'Nessuna seduta della squadra il ${formatDateOnly(giorno)}.',
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
    final (seduta, errore) = await _sedutaIndicata(args);
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

  // -------------------------------------------------------------------------
  // Cambiare una seduta che c'è

  /// La seduta in acqua da leggere o cambiare, o l'errore per il modello.
  /// Il secco ha esercizi invece delle serie: arriverà dopo.
  Future<(Allenamento?, Map<String, Object?>?)> _sedutaInAcqua(
    Map<String, dynamic> args,
  ) async {
    final (seduta, errore) = await _sedutaIndicata(args);
    if (seduta == null) return (null, errore);
    if (seduta.secco) {
      return (
        null,
        {
          'errore':
              'È una seduta a secco: per ora l\'assistente cambia solo le '
              'sedute in acqua. L\'allenatore la cambia dalla pagina della '
              'seduta.',
        },
      );
    }
    return (seduta, null);
  }

  /// Le serie scritte come in "Scrivi l'allenamento", con i nomi di tutto
  /// il club: gli stessi che [Pseudonimi] trasforma in codici e ritorno.
  String _testoSerie(List<DatiSerie> serie) =>
      testoDaSerie(serie, atleti: pseudonimi.atleti);

  int _metri(String testo) =>
      interpretaAllenamento(testo, atleti: pseudonimi.atleti).metri;

  Map<String, Object?> _sedutaPerModello(Allenamento s) => {
    'id': s.id,
    'data': formatDateOnly(s.data),
    'giorno': nomeGiorno(s.data),
    if (s.titolo case final t? when t.trim().isNotEmpty)
      'titolo': pseudonimi.anonimizza(t),
    if (s.note case final n? when n.trim().isNotEmpty)
      'note': pseudonimi.anonimizza(n),
  };

  Future<Map<String, Object?>> _leggiSeduta(Map<String, dynamic> args) async {
    final (seduta, errore) = await _sedutaInAcqua(args);
    if (seduta == null) return errore!;
    final serie = await fonte.serie(seduta.id);
    final testo = _testoSerie(serie);
    return {
      'seduta': _sedutaPerModello(seduta),
      'testo': pseudonimi.anonimizza(testo),
      'serie': serie.length,
      'metri': _metri(testo),
    };
  }

  Future<EsitoStrumento> _proponiModifica(Map<String, dynamic> args) async {
    final (seduta, errore) = await _sedutaInAcqua(args);
    if (seduta == null) return _solo(errore!);
    final serie = await fonte.serie(seduta.id);
    final testoPrima = _testoSerie(serie);

    final testo = args['testo'];
    final scritto = interpretaAllenamento(
      testo is String ? pseudonimi.conNomi(testo) : testoPrima,
      atleti: pseudonimi.atleti,
    );
    if (scritto.serie.isEmpty) {
      return _solo({
        'errore':
            'Nessuna serie capita: riscrivi tutto il testo della seduta nel '
            'formato delle istruzioni, una serie per riga. Per togliere tutte '
            'le serie l\'allenatore usa la pagina della seduta.',
      });
    }
    final cambiaSerie =
        testo is String &&
        !pianoSalvataggio(
          vecchie: serie,
          nuove: scritto.serie,
          nuovoId: () => '',
        ).vuoto;

    // Titolo e note: se non li nomina restano; se li riscrive uguali
    // (con i codici) restano com'erano, anche con i nomi scritti a modo suo.
    String? testoLibero(String chiave, String? attuale) {
      if (!args.containsKey(chiave)) return attuale;
      final nuovo = '${args[chiave] ?? ''}'.trim();
      if (nuovo == pseudonimi.anonimizza(attuale ?? '').trim()) return attuale;
      final conNomi = pseudonimi.conNomi(nuovo);
      return conNomi.isEmpty ? null : conNomi;
    }

    final proposta = PropostaModificaSeduta(
      allenamento: seduta,
      serie: serie,
      testoPrima: testoPrima,
      testoDopo: cambiaSerie ? _testoSerie(scritto.serie) : testoPrima,
      scritto: scritto,
      cambiaSerie: cambiaSerie,
      metriPrima: _metri(testoPrima),
      titolo: testoLibero('titolo', seduta.titolo),
      note: testoLibero('note', seduta.note),
    );
    if (!cambiaSerie && !proposta.cambiaTitolo && !proposta.cambiaNote) {
      return _solo({
        'errore':
            'Niente di diverso dalla seduta di adesso: rileggila con '
            'leggi_seduta e riscrivi il testo con le modifiche.',
      });
    }
    return (
      perModello: {
        'stato':
            'Modifiche mostrate all\'allenatore: le controlla e le salva lui. '
            'Non sono ancora salvate.',
        'seduta': {
          'id': seduta.id,
          'data': formatDateOnly(seduta.data),
          'giorno': nomeGiorno(seduta.data),
        },
        'cambia_serie': cambiaSerie,
        'serie_prima': serie.length,
        'serie_dopo': cambiaSerie ? scritto.serie.length : serie.length,
        'metri_prima': proposta.metriPrima,
        'metri_dopo': cambiaSerie ? scritto.metri : proposta.metriPrima,
        // Quello che cambia davvero, per controllarlo e dirlo giusto.
        'righe_tolte': [
          for (final r in proposta.righe)
            if (r.stato == StatoRiga.tolta) pseudonimi.anonimizza(r.testo),
        ],
        'righe_aggiunte': [
          for (final r in proposta.righe)
            if (r.stato == StatoRiga.aggiunta) pseudonimi.anonimizza(r.testo),
        ],
        'cambia_titolo': proposta.cambiaTitolo,
        'cambia_note': proposta.cambiaNote,
        if (testo is String && scritto.righeNonCapite > 0)
          'righe_non_capite': scritto.righeNonCapite,
      },
      scheda: proposta,
    );
  }

  // -------------------------------------------------------------------------
  // Impegni e messaggi alle famiglie

  /// Il testo senza nomi, null se vuoto.
  String? _senzaNomi(String? testo) {
    final t = testo?.trim() ?? '';
    return t.isEmpty ? null : pseudonimi.anonimizza(t);
  }

  Future<Map<String, Object?>> _impegni(Map<String, dynamic> args) async {
    final da = soloData(DateTime.tryParse('${args['da']}') ?? _oggi);
    final a = soloData(
      DateTime.tryParse('${args['a']}') ?? aggiungiGiorni(_oggi, 60),
    );
    final scelti = [
      for (final i in await fonte.impegni())
        if (visibileNelGruppo(
              gruppoDelRecord: i.gruppoId,
              gruppoSelezionato: fonte.gruppoId,
            ) &&
            !soloData(i.al).isBefore(da) &&
            !soloData(i.dal).isAfter(a))
          i,
    ]..sort((x, y) => x.dal.compareTo(y.dal));
    return {
      'da': formatDateOnly(da),
      'a': formatDateOnly(a),
      'impegni': [
        for (final i in scelti.take(40))
          {
            'tipo': i.tipo.etichetta.toLowerCase(),
            'nome': ?_senzaNomi(i.nome),
            'dal': formatDateOnly(i.dal),
            'giorno_inizio': nomeGiorno(i.dal),
            'al': formatDateOnly(i.al),
            'giorno_fine': nomeGiorno(i.al),
            'giorni': i.giorni,
            'luogo': ?_senzaNomi(i.luogo),
            'note': ?_senzaNomi(i.note),
            'di_tutto_il_club': i.diClub,
          },
      ],
    };
  }

  /// Per scrivere alle famiglie di una partita: campionato, ritrovo,
  /// piscina, calottina, rientro, cosa portare e note, senza nomi.
  Map<String, Object?> _perLeFamiglie(Partita p) => {
    'campionato': ?_senzaNomi(p.campionato),
    for (final v in vociConvocazione(p))
      if (v.etichetta != 'Inizio partita')
        v.etichetta.toLowerCase(): pseudonimi.anonimizza(v.valore),
    'note_per_le_famiglie': ?_senzaNomi(p.noteConvocazione),
  };

  /// Il messaggio per il gruppo dei genitori: il testo del modello con
  /// cognome e nome al posto dei codici (solo di chi ha nominato
  /// l'allenatore, dicono le istruzioni). Non si salva e non parte niente:
  /// l'allenatore lo corregge e lo manda lui.
  EsitoStrumento _proponiMessaggio(Map<String, dynamic> args) {
    final testo = '${args['testo'] ?? ''}'.trim();
    if (testo.isEmpty) {
      return _solo({'errore': 'Messaggio vuoto: scrivi il testo intero.'});
    }
    final sconosciuti = pseudonimi.codiciSconosciuti(testo);
    if (sconosciuti.isNotEmpty) {
      return _solo({
        'errore':
            'Codici che non sono atleti: ${sconosciuti.join(', ')}. Usa solo '
            'i codici degli atleti nominati dall\'allenatore.',
      });
    }
    return (
      perModello: {
        'stato':
            'Messaggio mostrato all\'allenatore: lo può correggere e lo '
            'manda lui nel gruppo con Condividi o Copia. Non è ancora '
            'inviato.',
        'caratteri': testo.length,
      },
      scheda: PropostaMessaggioFamiglie(
        testo: pseudonimi.conNomi(testo, pieni: true),
      ),
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
