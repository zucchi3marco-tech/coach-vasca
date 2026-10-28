import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/giorni.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../atleti/data/atleti_repository.dart';
import '../../benessere/data/schede_benessere_repository.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../campionati/application/campionati_providers.dart';
import '../../campionati/data/campionati_repository.dart';
import '../../carico/data/rpe_repository.dart';
import '../../pallanuoto/data/eventi_partita_repository.dart';
import '../../pallanuoto/data/partite_repository.dart';
import '../../presenze/data/presenze_repository.dart';
import '../../referti/data/referti_repository.dart';
import '../domain/report_atleta.dart';
import '../domain/report_squadra.dart';

/// Legge tutto quello che serve al report di una squadra. Senza rete usa
/// le copie sul telefono; la classifica FIN senza rete c'è solo se è già
/// stata aperta una volta, e se no il report lo dice.
class LettoreReportSquadra {
  const LettoreReportSquadra(this._ref);

  final Ref _ref;

  /// Prova [fai]; se fallisce (di solito la rete) va avanti con [altrimenti].
  static Future<T> _oppure<T>(Future<T> Function() fai, T altrimenti) async {
    try {
      return await fai();
    } catch (_) {
      return altrimenti;
    }
  }

  Future<DatiReportSquadra> leggi({
    required String clubId,
    required String? gruppoId,
    required PeriodoReport periodo,
    bool conBenessere = false,
  }) async {
    final atletiRepo = _ref.read(atletiRepositoryProvider);
    await _oppure(() => atletiRepo.refreshFromRemote(clubId), null);
    final atleti = await atletiRepo
        .watchAtleti(clubId: clubId, includeInactive: true)
        .first;

    // Il giorno dopo la fine: allenamenti e partite con l'ora entrano
    // tutti; quelli in più li toglie il report.
    final finoA = aggiungiGiorni(periodo.al, 1);
    final allenamenti = await _ref
        .read(allenamentiRepositoryProvider)
        .fetchPerClubEPeriodo(
          clubId: clubId,
          dataInizio: periodo.dal,
          dataFine: finoA,
        );
    final presenzeRepo = _ref.read(presenzeRepositoryProvider);
    await _oppure(() => presenzeRepo.refreshFromRemotePerClub(clubId), null);
    final presenze = await presenzeRepo.watchPerClub(clubId).first;

    final partite = await _ref
        .read(partiteRepositoryProvider)
        .perClubEPeriodo(
          clubId: clubId,
          dataInizio: periodo.dal,
          dataFine: finoA,
        );
    final idPartite = [for (final p in partite) p.id];
    final referti = idPartite.isEmpty
        ? const <Never>[]
        : await _ref.read(refertiRepositoryProvider).perPartite(idPartite);
    final eventi = idPartite.isEmpty
        ? const <Never>[]
        : await _ref
              .read(eventiPartitaRepositoryProvider)
              .perPartite(idPartite);

    // I gironi FIN della squadra e la loro classifica, uno per uno: un
    // girone che non si legge non toglie gli altri.
    final campionati = _ref.read(campionatiRepositoryProvider);
    final collegati = await _oppure(() => campionati.collegati(clubId), null);
    final gironi = <GironeLetto>[];
    for (final c in gironiDellaSquadra(collegati ?? const [], gruppoId)) {
      final lettura = await _oppure(
        () => campionati.girone(c.cmpId).timeout(const Duration(seconds: 20)),
        null,
      );
      gironi.add(
        GironeLetto(
          collegato: c,
          girone: lettura?.girone,
          lettoIl: lettura?.lettoIl,
          daCopia: lettura?.daCopia ?? false,
        ),
      );
    }

    List<SchedaBenessere>? benessere;
    if (conBenessere) {
      final repo = _ref.read(schedeBenessereRepositoryProvider);
      await _oppure(() => repo.refreshFromRemoteClub(clubId), null);
      benessere = await repo.watchPerClub(clubId).first;
    }
    final rpe = conBenessere
        ? await _oppure(
            () => _ref.read(rpeRepositoryProvider).perClub(clubId),
            null,
          )
        : null;

    return DatiReportSquadra(
      atleti: atleti,
      allenamenti: allenamenti,
      presenze: presenze,
      partite: partite,
      referti: referti,
      eventi: eventi,
      gironi: gironi,
      gironiLetti: collegati != null,
      benessere: benessere ?? const [],
      rpe: rpe ?? const [],
    );
  }
}

final lettoreReportSquadraProvider = Provider<LettoreReportSquadra>(
  (ref) => LettoreReportSquadra(ref),
);
