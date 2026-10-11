import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/giorni.dart';

import '../domain/stagione.dart';
import 'stagioni_repository.dart';

/// Duplica una stagione (per riusare un template anno su anno): copia
/// nome/obiettivo/gruppo/campionato in una nuova stagione con le date
/// scelte dal coach, e le fasi con i loro obiettivi spostate delle
/// stesse settimane.
class DuplicazioneStagioneService {
  DuplicazioneStagioneService(this._stagioni);

  final StagioniRepository _stagioni;

  Future<Stagione> duplica(Stagione sorgente, DateTime nuovaDataInizio) async {
    final delta = nuovaDataInizio.difference(sorgente.dataInizio);
    // Le fasi si spostano degli stessi giorni di calendario.
    final giorni = giorniTra(sorgente.dataInizio, nuovaDataInizio);

    return _stagioni.createStagione(
      clubId: sorgente.clubId,
      nome: sorgente.nome,
      dataInizio: nuovaDataInizio,
      dataFine: sorgente.dataFine.add(delta),
      obiettivo: sorgente.obiettivo,
      gruppoId: sorgente.gruppoId,
      campionato: sorgente.campionato,
      fasi: [for (final f in sorgente.fasi) f.spostata(giorni)],
    );
  }
}

final duplicazioneStagioneServiceProvider =
    Provider<DuplicazioneStagioneService>((ref) {
      return DuplicazioneStagioneService(ref.watch(stagioniRepositoryProvider));
    });
