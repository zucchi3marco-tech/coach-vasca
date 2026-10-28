/// Una combinazione stile+distanza valida per un personal best (FASE 10,
/// punto 3) — la lista dei PB mostra sempre tutte le combinazioni
/// possibili, registrate o no, cosi' il coach vede a colpo d'occhio cosa
/// manca.
typedef SlotPersonalBest = ({String stile, int distanzaM});

/// Distanze dei test di condizionamento, sempre a stile libero.
const distanzePallanuoto = [25, 50, 100, 200];

String capitalizzaParola(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Le combinazioni dei personal best: i test di condizionamento della
/// pallanuoto, tutti a stile libero.
final List<SlotPersonalBest> slotsPersonalBest = [
  for (final d in distanzePallanuoto) (stile: 'libero', distanzaM: d),
];
