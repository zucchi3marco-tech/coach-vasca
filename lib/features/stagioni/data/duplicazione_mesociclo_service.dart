import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../domain/mesociclo.dart';
import 'mesocicli_repository.dart';
import 'microcicli_repository.dart';

/// Duplica un mesociclo con tutti i suoi microcicli, allenamenti e serie,
/// subito dopo l'ultimo mesociclo del macrociclo — stessa logica di
/// `DuplicazioneSettimanaService` un livello più in alto: ogni data copiata
/// resta alla stessa distanza dall'inizio del mesociclo sorgente, l'intero
/// blocco viene spostato subito dopo la fine del mesociclo di partenza.
class DuplicazioneMesocicloService {
  DuplicazioneMesocicloService(
    this._mesocicli,
    this._microcicli,
    this._allenamenti,
    this._serie,
  );

  final MesocicliRepository _mesocicli;
  final MicrocicliRepository _microcicli;
  final AllenamentiRepository _allenamenti;
  final SerieRepository _serie;

  Future<Mesociclo> duplica(Mesociclo sorgente) async {
    final fratelli = await _mesocicli
        .watchPerMacrociclo(sorgente.macrocicloId)
        .first;
    final prossimoOrdine = fratelli.isEmpty
        ? 1
        : fratelli.map((m) => m.ordine).reduce((a, b) => a > b ? a : b) + 1;

    final durata = sorgente.dataFine.difference(sorgente.dataInizio);
    final nuovaDataInizio = sorgente.dataFine.add(const Duration(days: 1));
    final nuovaDataFine = nuovaDataInizio.add(durata);

    final nuovoMesociclo = await _mesocicli.createMesociclo(
      macrocicloId: sorgente.macrocicloId,
      nome: sorgente.nome,
      ordine: prossimoOrdine,
      dataInizio: nuovaDataInizio,
      dataFine: nuovaDataFine,
      obiettivo: sorgente.obiettivo,
    );

    final microcicli = await _microcicli.watchPerMesociclo(sorgente.id).first;
    for (final mc in microcicli) {
      final offsetGiorni = mc.dataInizio
          .difference(sorgente.dataInizio)
          .inDays;
      final durataMc = mc.dataFine.difference(mc.dataInizio);
      final nuovaMcInizio = nuovoMesociclo.dataInizio.add(
        Duration(days: offsetGiorni),
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

    return nuovoMesociclo;
  }
}

final duplicazioneMesocicloServiceProvider =
    Provider<DuplicazioneMesocicloService>((ref) {
      return DuplicazioneMesocicloService(
        ref.watch(mesocicliRepositoryProvider),
        ref.watch(microcicliRepositoryProvider),
        ref.watch(allenamentiRepositoryProvider),
        ref.watch(serieRepositoryProvider),
      );
    });
