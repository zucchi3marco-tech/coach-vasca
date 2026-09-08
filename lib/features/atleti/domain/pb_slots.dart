/// Una combinazione stile+distanza valida per un personal best, per lo
/// sport dell'atleta (FASE 10, punto 3) — la lista dei PB mostra sempre
/// tutte le combinazioni possibili, registrate o no, cosi' il coach vede
/// a colpo d'occhio cosa manca.
typedef SlotPersonalBest = ({String stile, int distanzaM});

const stiliNuoto = ['libero', 'dorso', 'rana', 'delfino', 'misti'];

/// Distanze di gara ufficiali per stile (nuoto).
const distanzePerStileNuoto = {
  'libero': [50, 100, 200, 400, 800, 1500],
  'dorso': [50, 100, 200],
  'rana': [50, 100, 200],
  'delfino': [50, 100, 200],
  'misti': [100, 200, 400],
};

/// Distanze dei test di condizionamento per la pallanuoto, sempre a
/// stile libero (non si nuotano gare con altri stili).
const distanzePallanuoto = [25, 50, 100, 200];

String capitalizzaParola(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

List<SlotPersonalBest> slotsPerSport(String sport) {
  if (sport == 'pallanuoto') {
    return [
      for (final d in distanzePallanuoto) (stile: 'libero', distanzaM: d),
    ];
  }
  return [
    for (final s in stiliNuoto)
      for (final d in distanzePerStileNuoto[s]!) (stile: s, distanzaM: d),
  ];
}
