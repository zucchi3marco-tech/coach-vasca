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
  'C1': 97,
  'C2': 94,
  'C3': 91,
  'D': 90,
};

/// Ordine di visualizzazione delle zone per una nuova tabella passi.
/// "C" (zona storica prima dello split in C1/C2/C3) non compare piu'
/// qui: le tabelle gia' generate con quella zona restano leggibili,
/// semplicemente non si rigenera piu' una riga per quel valore.
const ordineZone = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'C3', 'D'];
