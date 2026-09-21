import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../atleti/data/personal_best_repository.dart';
import '../../atleti/domain/personal_best.dart';

/// Dopo aver registrato il risultato di una gara: se il tempo batte il
/// personal best dello slot stile+distanza (o non ce n'è uno), il PB si
/// aggiorna da solo — così Record del club e PB restano allineati. Un
/// risultato eliminato o modificato in seguito non riporta indietro il PB.
class RisultatoGaraService {
  RisultatoGaraService(this._ref);

  final Ref _ref;

  /// Torna true se il personal best è stato creato o aggiornato.
  Future<bool> aggiornaPbSeMigliore({
    required String atletaId,
    required String stile,
    required int distanzaM,
    required double tempoS,
    required DateTime data,
    String? nomeGara,
  }) async {
    final repository = _ref.read(personalBestRepositoryProvider);
    try {
      // Il PB attuale va letto dal server, non dalla sola cache: una cache
      // vuota non deve far creare un secondo PB per lo stesso slot.
      await repository.refreshFromRemote(atletaId);
    } catch (_) {
      // Offline: si confronta con quello che c'è in cache.
    }
    final attuali = await repository.watchPerAtleta(atletaId).first;
    final attuale = pbDelloSlot(attuali, stile, distanzaM);
    if (!superaPersonalBest(attuale, tempoS)) return false;
    final nota = nomeGara == null ? null : 'Da gara: $nomeGara';
    if (attuale == null) {
      await repository.creaPersonalBest(
        atletaId: atletaId,
        stile: stile,
        distanzaM: distanzaM,
        tempoS: tempoS,
        data: data,
        note: nota,
      );
    } else {
      await repository.aggiornaPersonalBest(
        id: attuale.id,
        stile: stile,
        distanzaM: distanzaM,
        tempoS: tempoS,
        data: data,
        note: nota,
      );
    }
    return true;
  }
}

final risultatoGaraServiceProvider = Provider<RisultatoGaraService>(
  RisultatoGaraService.new,
);
