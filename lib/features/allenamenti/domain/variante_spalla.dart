import '../../../core/utils/giorni.dart';
import '../../benessere/domain/scheda_benessere.dart';
import 'riordino_serie.dart';
import 'serie.dart';
import 'testo_allenamento.dart';

/// Il lavoro che carica la spalla: il tiro, i passaggi e il gioco con la
/// palla, le braccia. Con un dolore alla spalla l'app propone di farlo
/// con le gambe (fase 2 del "Mako della pallanuoto", proposta 2).
const esecuzioniSpalla = {
  'tiri',
  'palleggio',
  'uomo in più',
  'uomo in meno',
  'gioco da schierati',
  'schemi',
  'partita',
  'pallanuoto tecnico-tattico',
  'braccia',
  'pull',
};

/// Per quanti giorni una scheda con il dolore alla spalla fa proporre la
/// variante: oggi, ieri e l'altro ieri.
const giorniDoloreSpalla = 3;

/// Gli atleti (fra gli [atleti]) che nell'ultima scheda benessere, di
/// non più di [giorniDoloreSpalla] giorni prima di [oggi], hanno segnato
/// un dolore alla spalla: chiave l'id, valore il giorno della scheda.
Map<String, DateTime> conDoloreSpalla(
  Iterable<SchedaBenessere> schede,
  Set<String> atleti, {
  required DateTime oggi,
}) {
  final fine = soloData(oggi);
  final inizio = aggiungiGiorni(fine, -(giorniDoloreSpalla - 1));
  final ultime = <String, SchedaBenessere>{};
  for (final s in schede) {
    if (!atleti.contains(s.atletaId)) continue;
    final giorno = soloData(s.data);
    if (giorno.isBefore(inizio) || giorno.isAfter(fine)) continue;
    final prima = ultime[s.atletaId];
    if (prima == null || s.data.isAfter(prima.data)) ultime[s.atletaId] = s;
  }
  return {
    for (final MapEntry(key: id, value: s) in ultime.entries)
      if (s.dolori && s.zoneDolore.contains('spalla')) id: soloData(s.data),
  };
}

/// Cosa cambia per fare la variante di un atleta.
class PianoVariante {
  const PianoVariante({
    required this.esclusioni,
    required this.inGambe,
    required this.nuove,
  });

  /// Le serie da cui l'atleta esce, con i loro nuovi destinatari.
  final List<({Serie serie, Destinatari destinatari})> esclusioni;

  /// Le serie solo sue: diventano gambe dove sono.
  final List<Serie> inGambe;

  /// Le serie nuove, solo per lui, dopo il gruppo di serie che
  /// sostituiscono (chiave: la posizione del gruppo, vedi
  /// `raggruppaPerPiramide`). Le serie di un gruppo con più righe hanno
  /// lo stesso `piramideId` segnaposto. In un momento in parallelo sono la
  /// sua colonna, dopo l'ultimo gruppo del momento e con il suo
  /// `momentoId` (quello vero).
  final Map<int, List<SerieScritta>> nuove;

  bool get vuoto => esclusioni.isEmpty && inGambe.isEmpty;

  /// Quante serie dell'allenamento cambiano per lui.
  int get serieToccate => esclusioni.length + inGambe.length;
}

/// La variante con le gambe per [atletaId] (con il suo [ruolo]): le serie
/// di [serie] (nell'ordine) che fa e che caricano la spalla
/// ([esecuzioniSpalla]) le fanno gli altri, lui le stesse con le gambe
/// (stessa distanza o durata, stessa zona, senza attrezzi). Vuoto se non
/// ne fa nessuna.
///
/// In un momento in parallelo riceve una colonna sua con tutto quello che
/// faceva nel momento, le serie per la spalla con le gambe: così resta in
/// parallelo con gli altri, e la sua colonna (la più precisa) non gli fa
/// saltare il resto del momento.
PianoVariante pianoVarianteSpalla(
  List<Serie> serie, {
  required String atletaId,
  required String? ruolo,
}) {
  final esclusioni = <({Serie serie, Destinatari destinatari})>[];
  final inGambe = <Serie>[];
  final nuove = <int, List<SerieScritta>>{};
  final fatte = serieDellAtleta(serie, atletaId, ruolo).toSet();
  bool daCambiare(Serie s) =>
      esecuzioniSpalla.contains(s.esecuzione) && fatte.contains(s);

  // Esce dalle serie per la spalla (o, se sono solo sue, le fa con le
  // gambe): true se gli serve una copia.
  bool togli(Serie s) {
    final senza = s.destinatari.senza(atletaId);
    if (senza == null) {
      inGambe.add(s);
      return false;
    }
    esclusioni.add((serie: s, destinatari: senza));
    return true;
  }

  final gruppi = raggruppaPerPiramide(serie);
  final momentiFatti = <String>{};
  for (final (i, gruppo) in gruppi.indexed) {
    final momento = gruppo.first.momentoId;
    if (momento == null) {
      final copie = <SerieScritta>[
        for (final s in gruppo)
          if (daCambiare(s) && togli(s)) _inGambe(s, atletaId),
      ];
      if (copie.isEmpty) continue;
      nuove[i] = copie.length > 1
          ? [for (final c in copie) c._conGruppo('g$i')]
          : copie;
      continue;
    }
    if (!momentiFatti.add(momento)) continue;
    // Tutto il momento: i suoi gruppi, fino all'ultimo.
    var ultimo = i;
    while (ultimo + 1 < gruppi.length &&
        gruppi[ultimo + 1].first.momentoId == momento) {
      ultimo++;
    }
    final delMomento = gruppi.sublist(i, ultimo + 1);
    if (!delMomento.any((g) => g.any(daCambiare))) continue;
    final copie = <SerieScritta>[];
    for (final (j, g) in delMomento.indexed) {
      final sue = [
        for (final s in g)
          if (fatte.contains(s))
            if (daCambiare(s))
              // Solo sua: con le gambe dov'è; se no, la sua copia.
              if (togli(s)) _inGambe(s, atletaId) else null
            // Una colonna di nomi con lui la fa ancora: vale quanto la sua.
            else if (s.destinatari.precedenza < 3)
              _copia(s, atletaId)
            else
              null,
      ].nonNulls.toList();
      final gruppo = sue.length > 1 ? 'g${i + j}' : null;
      for (final c in sue) {
        copie.add(c._conGruppo(gruppo)._nelMomento(momento));
      }
    }
    if (copie.isNotEmpty) nuove[ultimo] = copie;
  }
  return PianoVariante(esclusioni: esclusioni, inGambe: inGambe, nuove: nuove);
}

extension on SerieScritta {
  SerieScritta _conGruppo(String? gruppo) => _rifai(piramideId: gruppo);
  SerieScritta _nelMomento(String momento) =>
      _rifai(piramideId: piramideId, momentoId: momento);

  SerieScritta _rifai({String? piramideId, String? momentoId}) => SerieScritta(
    blocco: blocco,
    ripetute: ripetute,
    distanzaM: distanzaM,
    durataS: durataS,
    stile: stile,
    esecuzione: esecuzione,
    zona: zona,
    passoObiettivoS: passoObiettivoS,
    recuperoS: recuperoS,
    ripartenzaS: ripartenzaS,
    attrezzatura: attrezzatura,
    note: note,
    piramideId: piramideId,
    recuperoDopoS: recuperoDopoS,
    destinatari: destinatari,
    momentoId: momentoId ?? this.momentoId,
  );
}

/// La stessa serie, solo per lui: nella sua colonna di un momento.
SerieScritta _copia(Serie s, String atletaId) => SerieScritta(
  blocco: s.blocco,
  ripetute: s.ripetute,
  distanzaM: s.distanzaM,
  durataS: s.durataS,
  stile: s.stile,
  esecuzione: s.esecuzione,
  zona: s.zona,
  passoObiettivoS: s.passoObiettivoS,
  recuperoS: s.recuperoS,
  ripartenzaS: s.ripartenzaS,
  attrezzatura: s.attrezzatura,
  note: s.note,
  recuperoDopoS: s.recuperoDopoS,
  destinatari: Destinatari(soloAtleti: [atletaId]),
);

SerieScritta _inGambe(Serie s, String atletaId) => SerieScritta(
  blocco: s.blocco,
  ripetute: s.ripetute,
  distanzaM: s.distanzaM,
  durataS: s.durataS,
  // Le braccia a stile restano a quello stile; il lavoro con la palla
  // diventa gambe a stile libero.
  stile: s.esecuzione == 'braccia' || s.esecuzione == 'pull'
      ? s.stile
      : 'libero',
  esecuzione: 'gambe',
  zona: s.zona,
  recuperoS: s.recuperoS,
  note: 'Al posto di: ${_nomeEsecuzione(s.esecuzione)}',
  destinatari: Destinatari(soloAtleti: [atletaId]),
);

String _nomeEsecuzione(String esecuzione) => switch (esecuzione) {
  'pallanuoto tecnico-tattico' => 'tecnico-tattico',
  _ => esecuzione,
};
