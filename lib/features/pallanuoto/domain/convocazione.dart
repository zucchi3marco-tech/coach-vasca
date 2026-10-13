import 'partita.dart';

/// Un convocato come compare nel messaggio per le famiglie: numero,
/// cognome e nome (scelta del coach), "(portiere)" per i portieri.
typedef ConvocatoMessaggio = ({
  int numero,
  String cognome,
  String nome,
  bool portiere,
});

const _mesi = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

const _giorni = [
  'Lunedì',
  'Martedì',
  'Mercoledì',
  'Giovedì',
  'Venerdì',
  'Sabato',
  'Domenica',
];

/// "Sabato 18 ottobre": nel messaggio per le famiglie la data per intero.
String dataConvocazione(DateTime d) =>
    '${_giorni[d.weekday - 1]} ${d.day} ${_mesi[d.month - 1]}';

String? _pieno(String? t) => t == null || t.trim().isEmpty ? null : t.trim();

/// "15:00" meno [minuti] ("14:00"): il ritrovo proposto prima della
/// partita. Null se l'ora non si legge o si andrebbe al giorno prima.
String? oraMeno(String? ora, int minuti) {
  final m = RegExp(r'^(\d{1,2})[:.](\d{2})$').firstMatch(ora?.trim() ?? '');
  if (m == null) return null;
  final totale = int.parse(m[1]!) * 60 + int.parse(m[2]!) - minuti;
  if (totale < 0) return null;
  return '${(totale ~/ 60).toString().padLeft(2, '0')}:'
      '${(totale % 60).toString().padLeft(2, '0')}';
}

/// Le voci della convocazione, nell'ordine in cui servono a chi deve
/// arrivare in tempo: ritrovo, inizio, piscina, calottina, rientro, cosa
/// portare. Solo quelle compilate. Le stesse nel messaggio per WhatsApp e
/// nella home dell'atleta.
List<({String etichetta, String valore})> vociConvocazione(Partita p) {
  final ritrovoOra = _pieno(p.ritrovoOra);
  final ritrovoLuogo = _pieno(p.ritrovoLuogo);
  final ora = _pieno(p.ora);
  final luogo = _pieno(p.luogo);
  final rientro = _pieno(p.rientroOra);
  final daPortare = _pieno(p.daPortare);
  final calottina = switch (p.coloreCalottina) {
    'blu' => 'blu',
    'bianca' => 'bianca',
    _ => null,
  };
  return [
    if (ritrovoOra != null || ritrovoLuogo != null)
      (
        etichetta: 'Ritrovo',
        valore: [
          if (ritrovoOra != null) 'ore $ritrovoOra',
          ?ritrovoLuogo,
        ].join(', '),
      ),
    if (ora != null) (etichetta: 'Inizio partita', valore: 'ore $ora'),
    if (luogo != null) (etichetta: 'Piscina', valore: luogo),
    if (calottina != null) (etichetta: 'Calottina', valore: calottina),
    if (rientro != null)
      (etichetta: 'Rientro previsto', valore: 'ore $rientro'),
    if (daPortare != null) (etichetta: 'Da portare', valore: daPortare),
  ];
}

/// Le voci per l'atleta nella sua home, dove data, ora, piscina e
/// calottine si vedono già nel tabellone: ritrovo, rientro, cosa portare
/// e le note.
List<({String etichetta, String valore})> vociConvocazioneAtleta(Partita p) {
  final note = _pieno(p.noteConvocazione);
  return [
    for (final v in vociConvocazione(p))
      if (v.etichetta case 'Ritrovo' || 'Rientro previsto' || 'Da portare') v,
    if (note != null) (etichetta: 'Note', valore: note),
  ];
}

/// Il messaggio per il gruppo WhatsApp dei genitori, pronto da incollare
/// (gli asterischi sono il grassetto di WhatsApp):
///
/// ```text
/// *Convocazione Under 14*
/// Pallanuoto Riviera – Rari Nantes Bologna
/// Sabato 18 ottobre, in trasferta
///
/// Ritrovo: ore 14:15, davanti alla piscina del club
/// Inizio partita: ore 16:00
/// ...
///
/// *Convocati (13)*
/// 1 Rossi Mario (portiere)
/// 2 Bianchi Luca
/// ```
String testoConvocazione({
  required Partita partita,
  String? squadra,
  required List<ConvocatoMessaggio> convocati,
}) {
  final nomeSquadra = _pieno(squadra);
  final campionato = _pieno(partita.campionato);
  final note = _pieno(partita.noteConvocazione);
  final ordinati = [...convocati]..sort((a, b) => a.numero.compareTo(b.numero));
  final righe = <String>[
    nomeSquadra == null ? '*Convocazione*' : '*Convocazione $nomeSquadra*',
    '${partita.squadraCasa} – ${partita.squadraTrasferta}',
    '${dataConvocazione(partita.data)}, '
        '${partita.inCasa ? 'in casa' : 'in trasferta'}',
    ?campionato,
  ];
  final voci = vociConvocazione(partita);
  if (voci.isNotEmpty) {
    righe
      ..add('')
      ..addAll([for (final v in voci) '${v.etichetta}: ${v.valore}']);
  }
  if (ordinati.isNotEmpty) {
    righe
      ..add('')
      ..add('*Convocati (${ordinati.length})*')
      ..addAll([
        for (final c in ordinati)
          '${c.numero} ${c.cognome} ${c.nome}'
              '${c.portiere ? ' (portiere)' : ''}',
      ]);
  }
  if (note != null) {
    righe
      ..add('')
      ..add(note);
  }
  return righe.join('\n');
}
