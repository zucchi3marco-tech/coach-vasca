import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../domain/macrociclo.dart';
import 'macrocicli_repository.dart';
import 'mesocicli_repository.dart';
import 'microcicli_repository.dart';

/// Duplica un macrociclo con tutti i suoi mesocicli, microcicli, allenamenti
/// e serie, subito dopo l'ultimo macrociclo della stagione — stessa logica
/// di `DuplicazioneSettimanaService` e `DuplicazioneMesocicloService`, un
/// livello più in alto ancora.
class DuplicazioneMacrocicloService {
  DuplicazioneMacrocicloService(
    this._macrocicli,
    this._mesocicli,
    this._microcicli,
    this._allenamenti,
    this._serie,
  );

  final MacrocicliRepository _macrocicli;
  final MesocicliRepository _mesocicli;
  final MicrocicliRepository _microcicli;
  final AllenamentiRepository _allenamenti;
  final SerieRepository _serie;

  Future<Macrociclo> duplica(Macrociclo sorgente) async {
    final fratelli = await _macrocicli
        .watchPerStagione(sorgente.stagioneId)
        .first;
    final prossimoOrdine = fratelli.isEmpty
        ? 1
        : fratelli.map((m) => m.ordine).reduce((a, b) => a > b ? a : b) + 1;

    final durata = sorgente.dataFine.difference(sorgente.dataInizio);
    final nuovaDataInizio = sorgente.dataFine.add(const Duration(days: 1));
    final nuovaDataFine = nuovaDataInizio.add(durata);

    final nuovoMacrociclo = await _macrocicli.createMacrociclo(
      stagioneId: sorgente.stagioneId,
      nome: sorgente.nome,
      ordine: prossimoOrdine,
      dataInizio: nuovaDataInizio,
      dataFine: nuovaDataFine,
      obiettivo: sorgente.obiettivo,
    );

    final mesocicli = await _mesocicli.watchPerMacrociclo(sorgente.id).first;
    for (final me in mesocicli) {
      final offsetMe = me.dataInizio.difference(sorgente.dataInizio).inDays;
      final durataMe = me.dataFine.difference(me.dataInizio);
      final nuovaMeInizio = nuovoMacrociclo.dataInizio.add(
        Duration(days: offsetMe),
      );
      final nuovoMesociclo = await _mesocicli.createMesociclo(
        macrocicloId: nuovoMacrociclo.id,
        nome: me.nome,
        ordine: me.ordine,
        dataInizio: nuovaMeInizio,
        dataFine: nuovaMeInizio.add(durataMe),
        obiettivo: me.obiettivo,
      );

      final microcicli = await _microcicli.watchPerMesociclo(me.id).first;
      for (final mc in microcicli) {
        final offsetMc = mc.dataInizio.difference(me.dataInizio).inDays;
        final durataMc = mc.dataFine.difference(mc.dataInizio);
        final nuovaMcInizio = nuovoMesociclo.dataInizio.add(
          Duration(days: offsetMc),
        );
        final nuovoMicrociclo = await _microcicli.createMicrociclo(
          mesocicloId: nuovoMesociclo.id,
          nome: mc.nome,
          numeroSettimana: mc.numeroSettimana,
          ordine: mc.ordine,
          dataInizio: nuovaMcInizio,
          dataFine: nuovaMcInizio.add(durataMc),
          tipo: mc.tipo,
        );

        final allenamenti = await _allenamenti.fetchPerMicrociclo(mc.id);
        for (final a in allenamenti) {
          final offsetA = a.data.difference(mc.dataInizio).inDays;
          final nuovoAllenamento = await _allenamenti.createAllenamento(
            clubId: a.clubId,
            data: nuovoMicrociclo.dataInizio.add(Duration(days: offsetA)),
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

    return nuovoMacrociclo;
  }
}

final duplicazioneMacrocicloServiceProvider =
    Provider<DuplicazioneMacrocicloService>((ref) {
      return DuplicazioneMacrocicloService(
        ref.watch(macrocicliRepositoryProvider),
        ref.watch(mesocicliRepositoryProvider),
        ref.watch(microcicliRepositoryProvider),
        ref.watch(allenamentiRepositoryProvider),
        ref.watch(serieRepositoryProvider),
      );
    });
