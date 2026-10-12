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
  /// lo stesso `piramideId` segnaposto.
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
PianoVariante pianoVarianteSpalla(
  List<Serie> serie, {
  required String atletaId,
  required String? ruolo,
}) {
  final esclusioni = <({Serie serie, Destinatari destinatari})>[];
  final inGambe = <Serie>[];
  final nuove = <int, List<SerieScritta>>{};
  final gruppi = raggruppaPerPiramide(serie);
  for (final (i, gruppo) in gruppi.indexed) {
    final daCambiare = [
      for (final s in gruppo)
        if (esecuzioniSpalla.contains(s.esecuzione) &&
            s.destinatari.perAtleta(atletaId, ruolo))
          s,
    ];
    if (daCambiare.isEmpty) continue;
    final copie = <SerieScritta>[];
    for (final s in daCambiare) {
      final senza = s.destinatari.senza(atletaId);
      if (senza == null) {
        inGambe.add(s);
        continue;
      }
      esclusioni.add((serie: s, destinatari: senza));
      copie.add(_inGambe(s, atletaId));
    }
    if (copie.isEmpty) continue;
    nuove[i] = copie.length > 1
        ? [
            for (final c in copie)
              SerieScritta(
                blocco: c.blocco,
                ripetute: c.ripetute,
                distanzaM: c.distanzaM,
                durataS: c.durataS,
                stile: c.stile,
                esecuzione: c.esecuzione,
                zona: c.zona,
                recuperoS: c.recuperoS,
                note: c.note,
                piramideId: 'g$i',
                destinatari: c.destinatari,
              ),
          ]
        : copie;
  }
  return PianoVariante(esclusioni: esclusioni, inGambe: inGambe, nuove: nuove);
}

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
