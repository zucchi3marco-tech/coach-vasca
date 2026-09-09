import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pace_format.dart';
import '../../atleti/application/personal_best_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../domain/parametri_generazione.dart';
import '../domain/scheda_generata.dart';

/// Media dei personal best sui 100 stile libero (e il differenziale di
/// gara T200-T100, dove disponibile) degli atleti indicati — vedi FASE 10
/// punto 4. Ignora chi non ha almeno il PB sui 100. Se lo scarto di passo
/// nel gruppo supera il 10% della media, divide in due corsie (Veloci/
/// Lenti) invece di restituirne una sola.
Future<List<CorsiaGenerazione>> calcolaCorsie(
  WidgetRef ref,
  List<Atleta> atleti,
) async {
  final dati = <({double passo100S, double? differenzialeS})>[];
  for (final atleta in atleti) {
    final pb = await ref.read(personalBestListProvider(atleta.id).future);
    double? tempo100;
    double? tempo200;
    for (final p in pb) {
      if (p.stile != 'libero') continue;
      if (p.distanzaM == 100) tempo100 = p.tempoS;
      if (p.distanzaM == 200) tempo200 = p.tempoS;
    }
    if (tempo100 != null) {
      dati.add((
        passo100S: tempo100,
        differenzialeS: tempo200 != null ? tempo200 - tempo100 : null,
      ));
    }
  }
  if (dati.isEmpty) return const [];

  double media(Iterable<double> valori) =>
      valori.reduce((a, b) => a + b) / valori.length;
  double? mediaDifferenziali(
    Iterable<({double passo100S, double? differenzialeS})> voci,
  ) {
    final valori = voci
        .map((v) => v.differenzialeS)
        .whereType<double>()
        .toList();
    return valori.isEmpty ? null : media(valori);
  }

  final passi = dati.map((d) => d.passo100S).toList();
  final passoMedio = media(passi);
  final scarto =
      passi.reduce((a, b) => a > b ? a : b) -
      passi.reduce((a, b) => a < b ? a : b);

  // Scarto oltre il 10% del passo medio: PB troppo eterogenei per un'unica
  // ripartenza, si dividono gli atleti in due corsie per passo.
  if (dati.length > 1 && scarto / passoMedio > 0.10) {
    final ordinati = [...dati]
      ..sort((a, b) => a.passo100S.compareTo(b.passo100S));
    final meta = (ordinati.length / 2).ceil();
    final veloci = ordinati.sublist(0, meta);
    final lenti = ordinati.sublist(meta);
    return [
      CorsiaGenerazione(
        nome: 'Veloci',
        passo100S: media(veloci.map((v) => v.passo100S)),
        differenzialeS: mediaDifferenziali(veloci),
      ),
      CorsiaGenerazione(
        nome: 'Lenti',
        passo100S: media(lenti.map((v) => v.passo100S)),
        differenzialeS: mediaDifferenziali(lenti),
      ),
    ];
  }

  return [
    CorsiaGenerazione(
      nome: 'Gruppo',
      passo100S: passoMedio,
      differenzialeS: mediaDifferenziali(dati),
    ),
  ];
}

/// Es. "Veloci: rip 1:25 · Lenti: rip 1:40" — stringa vuota se non ci
/// sono ripartenze per corsia (niente passi di riferimento, o zona a
/// bassa intensità che non ne prevede una).
String formattaRipartenzeCorsia(List<RipartenzaCorsia> ripartenzePerCorsia) {
  if (ripartenzePerCorsia.isEmpty) return '';
  return ripartenzePerCorsia
      .map((r) => '${r.nome}: rip ${formatPaceSeconds(r.ripartenzaS)}')
      .join(' · ');
}

/// Ripartenza e nota da salvare su una `Serie` a partire da una
/// `SerieGenerata`: con più corsie si tiene come riferimento la più
/// veloce (ripartenza più stretta), il dettaglio di tutte resta in nota
/// perché il campo ripartenza della serie ne ammette una sola.
({double? ripartenzaS, String? note}) risolviRipartenza(
  List<RipartenzaCorsia> ripartenzePerCorsia,
  String? notaBase,
) {
  if (ripartenzePerCorsia.isEmpty) {
    return (ripartenzaS: null, note: notaBase);
  }
  final ripartenzaS = ripartenzePerCorsia
      .map((r) => r.ripartenzaS)
      .reduce((a, b) => a < b ? a : b);
  final dettaglio = formattaRipartenzeCorsia(ripartenzePerCorsia);
  final note = notaBase == null || notaBase.isEmpty
      ? dettaglio
      : '$notaBase — $dettaglio';
  return (ripartenzaS: ripartenzaS, note: note);
}
