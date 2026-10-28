import '../../../core/utils/giorni.dart';
import 'stagione.dart';

/// Quante settimane di scarico si possono chiedere prima di un obiettivo.
const settimaneScaricoMassime = 4;

/// Quanti obiettivi può avere una stagione.
const obiettiviMassimi = 3;

/// Un obiettivo della stagione: una partita del calendario
/// ([eventoId]), o un giorno scritto a mano. [nome] diventa il nome della
/// sua fase.
class ObiettivoStagione {
  const ObiettivoStagione({
    required this.nome,
    required this.data,
    this.eventoId,
  });

  final String nome;
  final DateTime data;
  final String? eventoId;

  ObiettivoStagione conNome(String nome) =>
      ObiettivoStagione(nome: nome, data: data, eventoId: eventoId);
}

/// Una fase dell'anteprima. [bloccata]: è il giorno di un obiettivo, i suoi
/// confini non si spostano.
class FaseProposta {
  const FaseProposta({
    required this.nome,
    required this.dataInizio,
    required this.dataFine,
    this.bloccata = false,
  });

  final String nome;
  final DateTime dataInizio;
  final DateTime dataFine;
  final bool bloccata;

  /// Quanti giorni dura, estremi compresi.
  int get giorni => giorniTra(dataInizio, dataFine) + 1;

  FaseProposta conDate(DateTime inizio, DateTime fine) => FaseProposta(
    nome: nome,
    dataInizio: inizio,
    dataFine: fine,
    bloccata: bloccata,
  );
}

DateTime _lunedi(DateTime d) => soloData(aggiungiGiorni(d, -(d.weekday - 1)));

DateTime _giorno(DateTime d) => soloData(d);

/// Le fasi del campionato contate a ritroso dagli [obiettivi] (al massimo
/// tre, dentro la stagione), con le [partite] della squadra (i giorni)
/// per l'andata e il ritorno.
///
/// - Dall'inizio della stagione alla settimana prima della prima partita:
///   «Preparazione».
/// - Le partite prima del primo obiettivo, divise a metà: «Andata» dalla
///   settimana della prima, «Ritorno» dalla settimana dopo l'ultima
///   dell'andata. Senza partite, la preparazione arriva fino allo scarico.
/// - Prima di ogni obiettivo «Scarico» per [settimaneScarico] settimane,
///   dal lunedì: la prima è quella dell'obiettivo (se non è di lunedì),
///   poi il giorno dell'obiettivo, con il suo nome.
/// - Fra un obiettivo e il successivo «Verso …», poi «Scarico 2» (o 3).
/// - Dopo l'ultimo obiettivo «Fine stagione»; senza obiettivi, dopo la
///   settimana dell'ultima partita.
///
/// Le fasi sono una dopo l'altra, senza buchi né giorni in comune, dentro
/// la stagione. Gli obiettivi fuori dalla stagione o nello stesso giorno di
/// un altro si saltano.
List<FaseProposta> proponiFasi({
  required DateTime inizioStagione,
  required DateTime fineStagione,
  required Iterable<DateTime> partite,
  required List<ObiettivoStagione> obiettivi,
  int settimaneScarico = 1,
}) {
  final inizio = _giorno(inizioStagione);
  final fine = _giorno(fineStagione);
  if (fine.isBefore(inizio)) return const [];
  final scarico = settimaneScarico.clamp(0, settimaneScaricoMassime);

  final giorniObiettivi = <DateTime>{};
  final scelti = [
    for (final o in [...obiettivi]..sort((a, b) => a.data.compareTo(b.data)))
      // Il primo giorno della stagione non lascia spazio a niente prima.
      if (_giorno(o.data).isAfter(inizio) &&
          !_giorno(o.data).isAfter(fine) &&
          giorniObiettivi.add(_giorno(o.data)))
        o,
  ].take(obiettiviMassimi).toList();

  final fasi = <FaseProposta>[];
  void aggiungi(String nome, DateTime da, DateTime a, {bool bloccata = false}) {
    if (a.isBefore(da)) return;
    fasi.add(
      FaseProposta(nome: nome, dataInizio: da, dataFine: a, bloccata: bloccata),
    );
  }

  /// L'inizio dello scarico prima di [obiettivo], non prima di [da].
  DateTime inizioScarico(DateTime obiettivo, DateTime da) {
    if (scarico == 0) return obiettivo;
    var l = _lunedi(aggiungiGiorni(obiettivo, -7 * scarico));
    // Un obiettivo di lunedì: lo scarico sono le settimane intere prima.
    if (obiettivo.weekday != DateTime.monday) l = aggiungiGiorni(l, 7);
    return l.isBefore(da) ? da : l;
  }

  // Il campionato: dall'inizio della stagione al primo scarico.
  final primo = scelti.isEmpty ? null : _giorno(scelti.first.data);
  final fineCampionato = primo == null
      ? fine
      : aggiungiGiorni(inizioScarico(primo, inizio), -1);
  final esclusi = {for (final o in scelti) _giorno(o.data)};
  final giocate = {
    for (final p in partite)
      if (!_giorno(p).isBefore(inizio) &&
          !_giorno(p).isAfter(fineCampionato) &&
          !esclusi.contains(_giorno(p)))
        _giorno(p),
  }.toList()..sort();

  if (giocate.isEmpty) {
    aggiungi('Preparazione', inizio, fineCampionato);
  } else {
    final primaSettimana = _lunedi(giocate.first);
    final daAndata = primaSettimana.isBefore(inizio) ? inizio : primaSettimana;
    aggiungi('Preparazione', inizio, aggiungiGiorni(daAndata, -1));
    // Senza obiettivi il campionato finisce con la settimana dell'ultima
    // partita, poi «Fine stagione».
    var fineRitorno = fineCampionato;
    if (primo == null) {
      final domenica = aggiungiGiorni(_lunedi(giocate.last), 6);
      if (domenica.isBefore(fineRitorno)) fineRitorno = domenica;
    }
    if (giocate.length == 1) {
      aggiungi('Andata', daAndata, fineRitorno);
    } else {
      final ultimaAndata = giocate[(giocate.length + 1) ~/ 2 - 1];
      var daRitorno = aggiungiGiorni(_lunedi(ultimaAndata), 7);
      if (daRitorno.isAfter(fineRitorno)) daRitorno = fineRitorno;
      aggiungi('Andata', daAndata, aggiungiGiorni(daRitorno, -1));
      aggiungi('Ritorno', daRitorno, fineRitorno);
    }
    if (primo == null) {
      aggiungi('Fine stagione', aggiungiGiorni(fineRitorno, 1), fine);
    }
  }

  // Gli obiettivi, con lo scarico prima e la strada fra l'uno e l'altro.
  for (final (i, o) in scelti.indexed) {
    final giorno = _giorno(o.data);
    if (i > 0) {
      final da = aggiungiGiorni(_giorno(scelti[i - 1].data), 1);
      final daScarico = inizioScarico(giorno, da);
      aggiungi('Verso ${o.nome}', da, aggiungiGiorni(daScarico, -1));
      aggiungi('Scarico ${i + 1}', daScarico, aggiungiGiorni(giorno, -1));
    } else {
      aggiungi(
        'Scarico',
        inizioScarico(giorno, inizio),
        aggiungiGiorni(giorno, -1),
      );
    }
    aggiungi(o.nome, giorno, giorno, bloccata: true);
  }
  if (primo != null) {
    final ultimo = _giorno(scelti.last.data);
    aggiungi('Fine stagione', aggiungiGiorni(ultimo, 1), fine);
  }
  return fasi;
}

/// Sposta di [giorni] il confine fra la fase [indice] e la successiva:
/// la prima finisce più tardi (o prima) e la seconda comincia di
/// conseguenza. Null se non si può: una delle due è un obiettivo, o una
/// resterebbe senza giorni.
List<FaseProposta>? spostaConfine(
  List<FaseProposta> fasi,
  int indice,
  int giorni,
) {
  if (indice < 0 || indice + 1 >= fasi.length) return null;
  final prima = fasi[indice];
  final dopo = fasi[indice + 1];
  if (prima.bloccata || dopo.bloccata) return null;
  final nuovaFine = aggiungiGiorni(prima.dataFine, giorni);
  final nuovoInizio = aggiungiGiorni(nuovaFine, 1);
  if (nuovaFine.isBefore(prima.dataInizio)) return null;
  if (nuovoInizio.isAfter(dopo.dataFine)) return null;
  return [
    for (final (i, f) in fasi.indexed)
      if (i == indice)
        f.conDate(f.dataInizio, nuovaFine)
      else if (i == indice + 1)
        f.conDate(nuovoInizio, f.dataFine)
      else
        f,
  ];
}

/// Le fasi dell'anteprima come fasi della stagione. Una fase di adesso con
/// lo stesso nome passa le sue cose: «A cosa serve», gli obiettivi di
/// volume e carico e le righe delle settimane che restano dentro.
List<FaseStagione> fasiDaProposta(
  List<FaseProposta> proposta,
  List<FaseStagione> attuali,
) {
  final perNome = {for (final f in attuali) f.nome.trim().toLowerCase(): f};
  return [
    for (final p in proposta)
      () {
        final vecchia = perNome[p.nome.trim().toLowerCase()];
        final nuova = FaseStagione(
          nome: p.nome,
          dataInizio: p.dataInizio,
          dataFine: p.dataFine,
        );
        if (vecchia == null) return nuova;
        final settimane = nuova.settimane.toSet();
        return FaseStagione(
          nome: p.nome,
          dataInizio: p.dataInizio,
          dataFine: p.dataFine,
          obiettivoMetri: vecchia.obiettivoMetri,
          obiettivoCarico: vecchia.obiettivoCarico,
          scopo: vecchia.scopo,
          righeSettimane: {
            for (final MapEntry(:key, :value) in vecchia.righeSettimane.entries)
              if (settimane.contains(key)) key: value,
          },
        );
      }(),
  ];
}
