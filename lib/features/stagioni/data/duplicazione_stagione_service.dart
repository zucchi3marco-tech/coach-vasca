import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/stagione.dart';
import 'stagioni_repository.dart';

/// Duplica una stagione (per riusare un template anno su anno): copia
/// nome/obiettivo/gruppo/campionato in una nuova stagione con le date
/// scelte dal coach — non c'e' più nessuna gerarchia di programmazione da
/// copiare in cascata.
class DuplicazioneStagioneService {
  DuplicazioneStagioneService(this._stagioni);

  final StagioniRepository _stagioni;

  Future<Stagione> duplica(Stagione sorgente, DateTime nuovaDataInizio) async {
    final delta = nuovaDataInizio.difference(sorgente.dataInizio);

    return _stagioni.createStagione(
      clubId: sorgente.clubId,
      nome: sorgente.nome,
      dataInizio: nuovaDataInizio,
      dataFine: sorgente.dataFine.add(delta),
      obiettivo: sorgente.obiettivo,
      gruppoId: sorgente.gruppoId,
      campionato: sorgente.campionato,
    );
  }
}

final duplicazioneStagioneServiceProvider =
    Provider<DuplicazioneStagioneService>((ref) {
      return DuplicazioneStagioneService(ref.watch(stagioniRepositoryProvider));
    });
