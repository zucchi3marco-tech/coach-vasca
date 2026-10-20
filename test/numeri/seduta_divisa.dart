// La seduta di prova delle «Prove sui numeri»: un allenamento in acqua con
// un lavoro in parallelo (i portieri), un "2x" e una variante per un solo
// atleta. Ogni schermata, ogni file e ogni funzione che mostra metri deve
// dare gli stessi numeri su questa seduta.
//
// Non è un test (niente `_test` nel nome): lo importano i test della
// cartella.
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';

/// I metri che si devono leggere ovunque, per chi.
const metriGruppo = 2000; // un giocatore di movimento qualunque
const metriPortiere = 1500;
const metriRossi = 2200; // il gruppo più la sua variante

const idRossi = 'rossi';
const idPortiere = 'verdi';
const idAltro = 'bianchi';

const idAllenamento = 'a1';

Atleta _atleta(String id, String nome, String cognome, {String? ruolo}) =>
    Atleta(
      id: id,
      clubId: 'c1',
      nome: nome,
      cognome: cognome,
      dataNascita: DateTime(2011, 1, 1),
      sport: 'pallanuoto',
      consensoPrivacyFirmato: true,
      attivo: true,
      gruppoId: 'u14',
      ruolo: ruolo,
    );

/// Rossi (movimento, ha la variante), Verdi (portiere) e Bianchi (movimento).
final atletiSeduta = [
  _atleta(idRossi, 'Marco', 'Rossi', ruolo: 'movimento'),
  _atleta(idPortiere, 'Pietro', 'Verdi', ruolo: 'portiere'),
  _atleta(idAltro, 'Sofia', 'Bianchi'),
];

final allenamentoSeduta = Allenamento(
  id: idAllenamento,
  clubId: 'c1',
  data: DateTime(2026, 10, 14), // un mercoledì
  titolo: 'Seduta divisa',
  gruppoId: 'u14',
);

/// Una serie salvata, con i campi che servono ai conti.
Serie serieDi(
  int ordine,
  String blocco,
  int ripetute,
  int distanzaM, {
  String id = '',
  String allenamentoId = idAllenamento,
  String esecuzione = 'nuoto',
  String? zona,
  int? durataS,
  double? ripartenzaS,
  int? recuperoS,
  String? piramideId,
  Destinatari destinatari = Destinatari.tutti,
  String? momentoId,
}) => Serie(
  id: id.isEmpty ? 's$allenamentoId$ordine' : id,
  allenamentoId: allenamentoId,
  clubId: 'c1',
  ordine: ordine,
  blocco: blocco,
  ripetute: ripetute,
  distanzaM: durataS == null ? distanzaM : null,
  durataS: durataS,
  stile: 'libero',
  esecuzione: esecuzione,
  zona: zona,
  ripartenzaS: ripartenzaS,
  recuperoS: recuperoS,
  piramideId: piramideId,
  destinatari: destinatari,
  momentoId: momentoId,
);

/// Le serie salvate della seduta, nell'ordine:
/// - riscaldamento 1×400 (tutti): 400 m
/// - principale, momento m1: 8×100 di tutti (800 m) e, insieme, 6×50 gambe
///   dei portieri (300 m)
/// - principale, "2x(4×50 + 100)": quattro righe dello stesso gruppo: 600 m
/// - principale, variante di Rossi, fuori da ogni momento: 4×50 gambe, 200 m
/// - defaticamento 1×200 (tutti): 200 m
final List<Serie> serieSeduta = [
  serieDi(1, 'riscaldamento', 1, 400, zona: 'A1'),
  serieDi(2, 'principale', 8, 100, zona: 'A2', momentoId: 'm1'),
  serieDi(
    3,
    'principale',
    6,
    50,
    esecuzione: 'gambe',
    destinatari: Destinatari.portieri,
    momentoId: 'm1',
  ),
  serieDi(4, 'principale', 4, 50, piramideId: 'g1'),
  serieDi(5, 'principale', 1, 100, piramideId: 'g1'),
  serieDi(6, 'principale', 4, 50, piramideId: 'g1'),
  serieDi(7, 'principale', 1, 100, piramideId: 'g1'),
  serieDi(
    8,
    'principale',
    4,
    50,
    esecuzione: 'gambe',
    destinatari: const Destinatari.solo([idRossi]),
  ),
  serieDi(9, 'defaticamento', 1, 200),
];

/// La stessa seduta scritta a mano come la scriverebbe il coach: i portieri
/// in parallelo con l'8×100, il "2x" da solo e la variante di Rossi dopo
/// una riga «Tutti», così non si unisce al "2x".
const testoSeduta =
    'Riscaldamento\n'
    '400 sl A1\n'
    '\n'
    'Principale\n'
    '8x100 sl A2\n'
    'Portieri\n'
    '6x50 sl gambe\n'
    '\n'
    'Tutti\n'
    '2x\n'
    '4x50 sl\n'
    '100 sl\n'
    '\n'
    'Tutti\n'
    'Rossi: 4x50 sl gambe\n'
    '\n'
    'Defaticamento\n'
    '200 sl';

/// Le righe di una seduta come le dà il server (`serie_per_carico`): gli
/// elenchi di atleti sono liste di id.
List<Map<String, dynamic>> righeCarico(Iterable<Serie> serie) => [
  for (final s in serie)
    {
      'id': s.id,
      'allenamento_id': s.allenamentoId,
      'ripetute': s.ripetute,
      'distanza_m': s.distanzaM,
      'durata_s': s.durataS,
      'zona': s.zona,
      'esecuzione': s.esecuzione,
      'recupero_s': s.recuperoS,
      'ripartenza_s': s.ripartenzaS,
      'passo_obiettivo_s': s.passoObiettivoS,
      'recupero_dopo_s': s.recuperoDopoS,
      'per_ruolo': s.destinatari.soloAtleti.isEmpty
          ? s.destinatari.ruolo
          : null,
      'solo_atleti': s.destinatari.soloAtleti.isEmpty
          ? null
          : s.destinatari.soloAtleti,
      'tranne_atleti': s.destinatari.tranneAtleti.isEmpty
          ? null
          : s.destinatari.tranneAtleti,
      'momento_id': s.momentoId,
    },
];
