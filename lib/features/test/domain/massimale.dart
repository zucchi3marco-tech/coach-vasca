import 'dart:math' as math;

import 'spiegazioni_test.dart';
import 'test_club.dart';

/// I massimali (fase 4 del "Mako della pallanuoto", proposta 10): il
/// massimale di un atleta in un esercizio di forza è un test del club
/// legato a quell'esercizio ([TestClub.massimale]). Nessun ragazzo deve
/// sollevare il suo massimo vero: si scrivono i chili sollevati e le
/// ripetizioni fatte e l'app stima il massimale ([stimaMassimale]). Nelle
/// sedute a secco un carico "70%" diventa i chili di ogni atleta
/// ([caricoPerAtleta]).

/// Le ripetizioni al massimo per stimare un massimale: oltre, la stima
/// non regge più.
const ripetizioniMassimeStima = 10;

/// Il massimale stimato da [chili] sollevati per [ripetizioni], con la
/// formula di Brzycki (chili × 36 / (37 − ripetizioni)), al mezzo chilo;
/// con una ripetizione è quello provato. Mai meno dei chili sollevati.
/// Brzycki stima un po' meno di altre formule con poche ripetizioni: per
/// i carichi in percentuale dei ragazzi è meglio così.
double stimaMassimale(double chili, int ripetizioni) {
  if (ripetizioni <= 1) return chili;
  final r = math.min(ripetizioni, ripetizioniMassimeStima);
  final stima = (chili * 36 / (37 - r) * 2).round() / 2;
  return math.max(chili, stima);
}

/// Il massimale attuale di un atleta in un esercizio: l'ultimo risultato
/// del suo test.
class Massimale {
  const Massimale({
    required this.kg,
    required this.data,
    this.caricoKg,
    this.ripetizioni,
  });

  final double kg;
  final DateTime data;

  /// Da cosa è stimato: i chili sollevati e le ripetizioni.
  final double? caricoKg;
  final int? ripetizioni;
}

/// Il massimale di ogni atleta in ogni esercizio: id esercizio → id
/// atleta → l'ultimo risultato del test di massimale di quell'esercizio.
/// Il carico in percentuale usa l'ultimo, non il migliore: è quello di
/// adesso.
Map<String, Map<String, Massimale>> massimaliPerEsercizio(
  Iterable<TestClub> test,
  Iterable<RisultatoTest> risultati,
) {
  final esercizioDelTest = {for (final t in test) t.id: ?t.esercizioId};
  final ultimi = <String, Map<String, RisultatoTest>>{};
  for (final r in risultati) {
    final esercizio = esercizioDelTest[r.testId];
    if (esercizio == null || r.valori.isEmpty) continue;
    final perAtleta = ultimi[esercizio] ??= {};
    final prima = perAtleta[r.atletaId];
    if (prima == null || r.data.isAfter(prima.data)) perAtleta[r.atletaId] = r;
  }
  return {
    for (final MapEntry(key: esercizio, value: perAtleta) in ultimi.entries)
      esercizio: {
        for (final MapEntry(key: atleta, value: r) in perAtleta.entries)
          atleta: Massimale(
            kg: r.valori.first,
            data: r.data,
            caricoKg: r.caricoKg,
            ripetizioni: r.ripetizioni,
          ),
      },
  };
}

final _percentuale = RegExp(
  r'^(\d{1,3}(?:[.,]\d{1,2})?)\s*%(?:\s*(?:del\s+)?(?:massimale|max|1\s*rm))?$',
  caseSensitive: false,
);

/// La percentuale del massimale scritta come carico: "70%", "70 %",
/// "72,5%", "70% del massimale", "70% 1RM" → 70 (72,5). Null per un
/// carico che non lo è ("8 kg", "elastico rosso").
double? percentualeDelCarico(String? carico) {
  final m = _percentuale.firstMatch(carico?.trim() ?? '');
  if (m == null) return null;
  final p = double.parse(m.group(1)!.replaceAll(',', '.'));
  return p <= 0 || p > 120 ? null : p;
}

/// I chili per [percentuale] del [massimale], arrotondati al chilo.
double chiliDaPercentuale(double percentuale, double massimale) =>
    math.max(1, (massimale * percentuale / 100).round()).toDouble();

/// "70%", "72,5%".
String formattaPercentualeCarico(double p) =>
    '${formattaValore(UnitaTest.chili, p, sigla: false)}%';

/// Il carico di una riga per un atleta: "28 kg (70%)" se è una
/// percentuale e l'atleta ha il massimale ([massimaleKg]); se no il
/// carico com'è scritto.
String? caricoPerAtleta(String? carico, double? massimaleKg) {
  final p = percentualeDelCarico(carico);
  if (p == null || massimaleKg == null) return carico;
  return '${formattaValore(UnitaTest.chili, chiliDaPercentuale(p, massimaleKg))} '
      '(${formattaPercentualeCarico(p)})';
}

/// I chili da proporre all'atleta per una riga in percentuale: "28 kg";
/// null se non è una percentuale o l'atleta non ha il massimale.
String? chiliProposti(String? carico, double? massimaleKg) {
  final p = percentualeDelCarico(carico);
  if (p == null || massimaleKg == null) return null;
  return formattaValore(UnitaTest.chili, chiliDaPercentuale(p, massimaleKg));
}

/// Da cosa viene un massimale: "40 kg × 5"; null se non si sa.
String? descriviSollevato(double? caricoKg, int? ripetizioni) {
  if (caricoKg == null || ripetizioni == null) return null;
  return '${formattaValore(UnitaTest.chili, caricoKg)} × $ripetizioni';
}

/// Come si fa un massimale inventato dall'allenatore; quelli pronti hanno
/// anche la tecnica dell'esercizio (vedi `spiegazioneOriginale`).
String get comeSiFaMassimale => spiegazioneMassimale();

/// Un massimale pronto: il test e l'esercizio pronto (la chiave di
/// `modelliEsercizi`) a cui si lega.
typedef ModelloMassimale = ({String chiave, String nome, String esercizio});

/// I massimali pronti, sugli esercizi con il bilanciere e sul rematore.
const modelliMassimali = <ModelloMassimale>[
  (
    chiave: 'massimale_squat',
    nome: 'Massimale squat',
    esercizio: 'squat_bilanciere',
  ),
  (
    chiave: 'massimale_panca',
    nome: 'Massimale panca piana',
    esercizio: 'panca_piana',
  ),
  (
    chiave: 'massimale_stacco',
    nome: 'Massimale stacco da terra',
    esercizio: 'stacco_terra',
  ),
  (
    chiave: 'massimale_rematore',
    nome: 'Massimale rematore',
    esercizio: 'rematore_manubrio',
  ),
];
