/// Percentuali di partenza per ciascuna zona, applicate al passo medio
/// del test (100 = stesso passo del test; >100 = piu' lento; <100 = piu'
/// veloce). Sono un punto di partenza generico, NON una metodologia
/// validata: il coach le vede e puo' modificarle prima di generare la
/// tabella, e sono salvate per riga in `tabelle_passi.percentuale_riferimento`.
const defaultPercentualiZona = <String, double>{
  'A1': 112,
  'A2': 108,
  'B1': 104,
  'B2': 100,
  'C': 96,
  'D': 90,
};

/// Ordine di visualizzazione delle zone (coincide con l'ordine dichiarato
/// nell'enum Postgres `zona_intensita`, quindi anche con l'ordinamento
/// naturale di una query `order by zona`).
const ordineZone = ['A1', 'A2', 'B1', 'B2', 'C', 'D'];
