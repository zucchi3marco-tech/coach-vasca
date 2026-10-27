import 'atleta.dart';

/// Le categorie FIN della pallanuoto, calcolate dall'anno di nascita
/// (proposta 27). Non si salvano: cambiano da sole a settembre. Le
/// squadre restano quelle che decide l'allenatore.
///
/// La stagione va dal 1° settembre al 31 agosto e conta l'anno in cui
/// finisce: nel 2026-27 «Under 16» sono i nati dal 2011 (2027 − 16), con
/// le categorie a due anni (U14 2013-14, U16 2011-12, U18 2009-10…).
/// Le categorie a un anno dei campionati regionali (U13, U15…) e il nuoto
/// (che va anche per sesso) non si calcolano: scelta del coach.

/// I limiti d'età delle categorie a due anni, dalla più giovane.
const limitiCategoriePallanuoto = [10, 12, 14, 16, 18, 20];

/// Oltre l'ultima categoria giovanile.
const categoriaAssoluti = 'Assoluti';

/// L'anno della stagione sportiva di [giorno]: dal 1° settembre conta
/// l'anno dopo (il 2026-27 è il 2027).
int annoStagioneSportiva(DateTime giorno) =>
    giorno.month >= 9 ? giorno.year + 1 : giorno.year;

/// «2026-27» per l'anno 2027.
String etichettaStagioneSportiva(int annoStagione) =>
    '${annoStagione - 1}-${(annoStagione % 100).toString().padLeft(2, '0')}';

/// La categoria di chi è nato in [annoNascita] nella stagione
/// [annoStagione]: «U10» per i più piccoli, poi «U12»… «U20», poi
/// «Assoluti». null con una data di nascita dopo la stagione (sbagliata).
String? categoriaPallanuoto(int annoNascita, int annoStagione) {
  final eta = annoStagione - annoNascita;
  if (eta < 0) return null;
  for (final limite in limitiCategoriePallanuoto) {
    if (eta <= limite) return 'U$limite';
  }
  return categoriaAssoluti;
}

/// La categoria dell'atleta oggi; null per il nuoto.
String? categoriaAtleta(Atleta atleta, DateTime oggi) =>
    atleta.sport == 'pallanuoto'
    ? categoriaPallanuoto(atleta.dataNascita.year, annoStagioneSportiva(oggi))
    : null;

final _nomeUnder = RegExp(
  r'^\s*(?:u|under)\s*-?\s*(\d{1,2})\s*$',
  caseSensitive: false,
);

/// La categoria che il nome di una squadra indica: «U16», «Under 16»,
/// «u-16» → «U16». null per un nome che non è una categoria a due anni
/// («Prima squadra», «U15», «Squadra A»): con quelle non si confronta.
String? categoriaDaNomeSquadra(String nome) {
  final trovato = _nomeUnder.firstMatch(nome);
  if (trovato == null) return null;
  final limite = int.parse(trovato.group(1)!);
  return limitiCategoriePallanuoto.contains(limite) ? 'U$limite' : null;
}

/// Il posto della categoria nell'ordine dalla più giovane; -1 se non è
/// una categoria calcolata.
int _ordine(String categoria) => categoria == categoriaAssoluti
    ? limitiCategoriePallanuoto.length
    : limitiCategoriePallanuoto.indexWhere((l) => 'U$l' == categoria);

/// Chi gioca in una squadra di un'altra categoria.
enum FuoriCategoria {
  /// Più giovane della squadra (un 2014 negli U16).
  sottoEta('Sotto età'),

  /// Più grande della squadra (un 2008 negli U18): conta per i limiti
  /// FIN sui fuori quota.
  fuoriQuota('Fuori quota');

  const FuoriCategoria(this.etichetta);

  final String etichetta;
}

/// Se la [categoria] dell'atleta è diversa da quella della squadra
/// [nomeSquadra]; null quando coincidono o la squadra non ha un nome di
/// categoria.
FuoriCategoria? fuoriCategoria(String categoria, String nomeSquadra) {
  final diSquadra = categoriaDaNomeSquadra(nomeSquadra);
  if (diSquadra == null) return null;
  final atleta = _ordine(categoria);
  final squadra = _ordine(diSquadra);
  if (atleta < 0 || atleta == squadra) return null;
  return atleta < squadra ? FuoriCategoria.sottoEta : FuoriCategoria.fuoriQuota;
}
