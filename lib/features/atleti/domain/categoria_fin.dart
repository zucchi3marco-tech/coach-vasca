import '../../gruppi/domain/gruppo.dart';
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

/// La categoria dell'atleta oggi (vedi [categoriaPallanuoto]).
String? categoriaAtleta(Atleta atleta, DateTime oggi) =>
    categoriaPallanuoto(atleta.dataNascita.year, annoStagioneSportiva(oggi));

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

/// Chi sale di categoria nella stagione e la squadra proposta (passo B).
class CambioCategoria {
  const CambioCategoria({
    required this.atleta,
    required this.da,
    required this.a,
    this.squadraProposta,
  });

  final Atleta atleta;

  /// La categoria della stagione prima («U14»).
  final String da;

  /// Quella nuova («U16»).
  final String a;

  /// La squadra con il nome della nuova categoria; null se il club non
  /// ne ha una.
  final Gruppo? squadraProposta;
}

/// Gli atleti attivi che nella stagione [annoStagione]
/// cambiano categoria rispetto a quella prima. Solo chi è ancora nella
/// squadra della categoria di prima, o senza squadra: chi gioca sotto età
/// o fuori quota l'ha messo lì l'allenatore, e chi è già stato spostato
/// non compare più. In ordine di categoria nuova, poi di cognome.
List<CambioCategoria> cambiDiCategoria({
  required List<Atleta> atleti,
  required List<Gruppo> squadre,
  required int annoStagione,
}) {
  final perId = {for (final s in squadre) s.id: s};
  final ordinate = [...squadre]..sort((x, y) => x.ordine.compareTo(y.ordine));
  Gruppo? squadraDi(String categoria) => ordinate
      .where((s) => categoriaDaNomeSquadra(s.nome) == categoria)
      .firstOrNull;

  final cambi = <CambioCategoria>[];
  for (final atleta in atleti) {
    if (!atleta.attivo) continue;
    final anno = atleta.dataNascita.year;
    final da = categoriaPallanuoto(anno, annoStagione - 1);
    final a = categoriaPallanuoto(anno, annoStagione);
    if (da == null || a == null || da == a) continue;
    final attuale = perId[atleta.gruppoId];
    if (attuale != null && categoriaDaNomeSquadra(attuale.nome) != da) {
      continue;
    }
    cambi.add(
      CambioCategoria(
        atleta: atleta,
        da: da,
        a: a,
        squadraProposta: squadraDi(a),
      ),
    );
  }
  cambi.sort((x, y) {
    final perCategoria = _ordine(x.a).compareTo(_ordine(y.a));
    if (perCategoria != 0) return perCategoria;
    final perCognome = x.atleta.cognome.compareTo(y.atleta.cognome);
    return perCognome != 0
        ? perCognome
        : x.atleta.nome.compareTo(y.atleta.nome);
  });
  return cambi;
}

/// Il riquadro del cambio di categoria si vede a settembre e ottobre.
bool inizioStagioneSportiva(DateTime oggi) =>
    oggi.month == 9 || oggi.month == 10;
