import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/serie.dart';

/// Vero se, fra gli [allenamenti] con almeno una serie (in [seriePerId],
/// indicizzate per `allenamentoId`), il più vecchio e il più recente
/// distano almeno 60 giorni — non serve che siano consecutivi, solo che
/// il periodo coperto sia abbastanza lungo da avere uno stile
/// riconoscibile da imitare (vedi "Genera settimana con AI").
bool copre60Giorni(
  List<Allenamento> allenamenti,
  Map<String, List<Serie>> seriePerId,
) {
  final conSerie = allenamenti
      .where((a) => (seriePerId[a.id] ?? const []).isNotEmpty)
      .toList();
  if (conSerie.isEmpty) return false;

  var minData = conSerie.first.data;
  var maxData = conSerie.first.data;
  for (final a in conSerie.skip(1)) {
    if (a.data.isBefore(minData)) minData = a.data;
    if (a.data.isAfter(maxData)) maxData = a.data;
  }
  return maxData.difference(minData).inDays >= 60;
}

/// Come il gruppo è stato allenato finora, distillato in poche cifre da
/// mandare al prompt di `genera-settimana` — non i dati grezzi (troppi,
/// costosi da mandare a Gemini), solo un riassunto.
class RiassuntoProgrammazione {
  const RiassuntoProgrammazione({
    required this.sedutePerSettimanaMedia,
    required this.volumeMedioPerSedutaM,
    required this.percentualeMetriPerZona,
    required this.percentualeMetriPerBlocco,
    required this.combinazioniStileEsecuzioneFrequenti,
    required this.attrezzaturaFrequente,
  });

  final double sedutePerSettimanaMedia;
  final double volumeMedioPerSedutaM;

  /// Quota % dei metri totali per zona (zone senza serie assenti dalla
  /// mappa, non a zero).
  final Map<String, double> percentualeMetriPerZona;

  /// Quota % dei metri totali per blocco (riscaldamento/principale/
  /// defaticamento/altro).
  final Map<String, double> percentualeMetriPerBlocco;

  /// Le combinazioni "stile+esecuzione" più frequenti, dalla più comune,
  /// come "libero+pull".
  final List<String> combinazioniStileEsecuzioneFrequenti;

  /// L'attrezzatura più usata, dalla più comune.
  final List<String> attrezzaturaFrequente;

  Map<String, dynamic> toMap() => {
    'sedutePerSettimanaMedia': sedutePerSettimanaMedia,
    'volumeMedioPerSedutaMetri': volumeMedioPerSedutaM,
    'percentualeMetriPerZona': percentualeMetriPerZona,
    'percentualeMetriPerBlocco': percentualeMetriPerBlocco,
    'combinazioniStileEsecuzioneFrequenti':
        combinazioniStileEsecuzioneFrequenti,
    'attrezzaturaFrequente': attrezzaturaFrequente,
  };
}

Map<String, double> _percentuali(Map<String, int> conteggi, int totale) {
  if (totale <= 0) return {};
  return {for (final e in conteggi.entries) e.key: e.value / totale * 100};
}

List<String> _classificaTop(Map<String, int> conteggi, {int massimo = 5}) {
  final voci = conteggi.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return voci.take(massimo).map((e) => e.key).toList();
}

/// Calcola il riassunto da un elenco di allenamenti e le loro serie
/// (indicizzate per `allenamentoId`, come restituite da
/// `SerieRepository.fetchPerAllenamenti`).
RiassuntoProgrammazione calcolaRiassunto(
  List<Allenamento> allenamenti,
  Map<String, List<Serie>> seriePerId,
) {
  final conSerie = allenamenti
      .where((a) => (seriePerId[a.id] ?? const []).isNotEmpty)
      .toList();
  if (conSerie.isEmpty) {
    return const RiassuntoProgrammazione(
      sedutePerSettimanaMedia: 0,
      volumeMedioPerSedutaM: 0,
      percentualeMetriPerZona: {},
      percentualeMetriPerBlocco: {},
      combinazioniStileEsecuzioneFrequenti: [],
      attrezzaturaFrequente: [],
    );
  }

  final tutteSerie = [for (final a in conSerie) ...seriePerId[a.id]!];
  final volumeTotale = tutteSerie.fold(0, (t, s) => t + s.distanzaTotaleM);

  var minData = conSerie.first.data;
  var maxData = conSerie.first.data;
  for (final a in conSerie.skip(1)) {
    if (a.data.isBefore(minData)) minData = a.data;
    if (a.data.isAfter(maxData)) maxData = a.data;
  }
  final giorniCoperti = maxData.difference(minData).inDays + 1;
  final settimane = (giorniCoperti / 7).clamp(1, double.infinity);

  final metriPerZona = <String, int>{};
  final metriPerBlocco = <String, int>{};
  final conteggioCombinazioni = <String, int>{};
  final conteggioAttrezzatura = <String, int>{};
  for (final s in tutteSerie) {
    final metri = s.distanzaTotaleM;
    if (s.zona != null) {
      metriPerZona[s.zona!] = (metriPerZona[s.zona!] ?? 0) + metri;
    }
    metriPerBlocco[s.blocco] = (metriPerBlocco[s.blocco] ?? 0) + metri;

    final combinazione = '${s.stile}+${s.esecuzione}';
    conteggioCombinazioni[combinazione] =
        (conteggioCombinazioni[combinazione] ?? 0) + 1;

    final attrezzatura = s.attrezzatura?.trim();
    if (attrezzatura != null && attrezzatura.isNotEmpty) {
      conteggioAttrezzatura[attrezzatura] =
          (conteggioAttrezzatura[attrezzatura] ?? 0) + 1;
    }
  }

  return RiassuntoProgrammazione(
    sedutePerSettimanaMedia: conSerie.length / settimane,
    volumeMedioPerSedutaM: volumeTotale / conSerie.length,
    percentualeMetriPerZona: _percentuali(metriPerZona, volumeTotale),
    percentualeMetriPerBlocco: _percentuali(metriPerBlocco, volumeTotale),
    combinazioniStileEsecuzioneFrequenti: _classificaTop(conteggioCombinazioni),
    attrezzaturaFrequente: _classificaTop(conteggioAttrezzatura),
  );
}
