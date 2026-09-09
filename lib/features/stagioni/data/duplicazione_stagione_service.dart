import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../domain/stagione.dart';
import 'macrocicli_repository.dart';
import 'mesocicli_repository.dart';
import 'microcicli_repository.dart';
import 'stagioni_repository.dart';

/// Duplica un'intera stagione (per riusare un template anno su anno):
/// macrocicli, mesocicli, microcicli, allenamenti e serie vengono copiati
/// tutti, con ogni data spostata della stessa differenza fra la data di
/// inizio della stagione sorgente e quella scelta per la nuova stagione —
/// a differenza degli altri livelli, qui la nuova data di inizio la sceglie
/// il coach, non viene calcolata "subito dopo" la sorgente.
class DuplicazioneStagioneService {
  DuplicazioneStagioneService(
    this._stagioni,
    this._macrocicli,
    this._mesocicli,
    this._microcicli,
    this._allenamenti,
    this._serie,
  );

  final StagioniRepository _stagioni;
  final MacrocicliRepository _macrocicli;
  final MesocicliRepository _mesocicli;
  final MicrocicliRepository _microcicli;
  final AllenamentiRepository _allenamenti;
  final SerieRepository _serie;

  Future<Stagione> duplica(Stagione sorgente, DateTime nuovaDataInizio) async {
    final delta = nuovaDataInizio.difference(sorgente.dataInizio);

    final nuovaStagione = await _stagioni.createStagione(
      clubId: sorgente.clubId,
      nome: sorgente.nome,
      dataInizio: nuovaDataInizio,
      dataFine: sorgente.dataFine.add(delta),
      obiettivo: sorgente.obiettivo,
      gruppo: sorgente.gruppo,
      campionato: sorgente.campionato,
    );

    final macrocicli = await _macrocicli.watchPerStagione(sorgente.id).first;
    for (final ma in macrocicli) {
      final nuovoMacrociclo = await _macrocicli.createMacrociclo(
        stagioneId: nuovaStagione.id,
        nome: ma.nome,
        ordine: ma.ordine,
        dataInizio: ma.dataInizio.add(delta),
        dataFine: ma.dataFine.add(delta),
        obiettivo: ma.obiettivo,
      );

      final mesocicli = await _mesocicli.watchPerMacrociclo(ma.id).first;
      for (final me in mesocicli) {
        final nuovoMesociclo = await _mesocicli.createMesociclo(
          macrocicloId: nuovoMacrociclo.id,
          nome: me.nome,
          ordine: me.ordine,
          dataInizio: me.dataInizio.add(delta),
          dataFine: me.dataFine.add(delta),
          obiettivo: me.obiettivo,
        );

        final microcicli = await _microcicli.watchPerMesociclo(me.id).first;
        for (final mc in microcicli) {
          final nuovoMicrociclo = await _microcicli.createMicrociclo(
            mesocicloId: nuovoMesociclo.id,
            nome: mc.nome,
            numeroSettimana: mc.numeroSettimana,
            ordine: mc.ordine,
            dataInizio: mc.dataInizio.add(delta),
            dataFine: mc.dataFine.add(delta),
            tipo: mc.tipo,
          );

          final allenamenti = await _allenamenti.fetchPerMicrociclo(mc.id);
          for (final a in allenamenti) {
            final nuovoAllenamento = await _allenamenti.createAllenamento(
              clubId: a.clubId,
              data: a.data.add(delta),
              microcicloId: nuovoMicrociclo.id,
              titolo: a.titolo,
              gruppo: a.gruppo,
              note: a.note,
            );
            final serie = await _serie.fetchPerAllenamento(a.id);
            for (final s in serie) {
              await _serie.createSerie(
                allenamentoId: nuovoAllenamento.id,
                ordine: s.ordine,
                blocco: s.blocco,
                ripetute: s.ripetute,
                distanzaM: s.distanzaM,
                stile: s.stile,
                esecuzione: s.esecuzione,
                zona: s.zona,
                passoObiettivoS: s.passoObiettivoS,
                recuperoS: s.recuperoS,
                ripartenzaS: s.ripartenzaS,
                attrezzatura: s.attrezzatura,
                note: s.note,
              );
            }
          }
        }
      }
    }

    return nuovaStagione;
  }
}

final duplicazioneStagioneServiceProvider =
    Provider<DuplicazioneStagioneService>((ref) {
      return DuplicazioneStagioneService(
        ref.watch(stagioniRepositoryProvider),
        ref.watch(macrocicliRepositoryProvider),
        ref.watch(mesocicliRepositoryProvider),
        ref.watch(microcicliRepositoryProvider),
        ref.watch(allenamentiRepositoryProvider),
        ref.watch(serieRepositoryProvider),
      );
    });
