import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/carico_repository.dart';
import '../data/rpe_repository.dart';
import '../domain/banister.dart';
import '../domain/carico_rpe.dart';
import '../domain/monotonia.dart';
import '../domain/rpe_seduta.dart';
import '../domain/volumi_atleta.dart';

typedef _ChiaveCarico = ({String atletaId, String clubId});

/// Le sedute di un atleta con il loro carico (RPE × minuti), dalla più
/// vecchia. Da ricaricare (`invalidate`) quando l'atleta dà un RPE.
final seduteCaricoProvider =
    FutureProvider.family<List<CaricoSeduta>, _ChiaveCarico>((ref, chiave) {
      return ref
          .watch(caricoRepositoryProvider)
          .sedutePerAtleta(atletaId: chiave.atletaId, clubId: chiave.clubId);
    });

final andamentoCaricoProvider =
    FutureProvider.family<List<PuntoBanister>, _ChiaveCarico>((
      ref,
      chiave,
    ) async {
      final sedute = await ref.watch(seduteCaricoProvider(chiave).future);
      return calcolaBanister({
        for (final MapEntry(key: giorno, value: carico) in caricoPerGiorno(
          sedute,
        ).entries)
          giorno: carico.totale,
      });
    });

final volumiAtletaProvider = FutureProvider.family<VolumiAtleta, _ChiaveCarico>(
  (ref, chiave) async {
    final repository = ref.watch(caricoRepositoryProvider);
    return repository.volumiPerAtleta(
      atletaId: chiave.atletaId,
      clubId: chiave.clubId,
    );
  },
);

/// Le sedute di ogni atleta del club (chiave: id atleta), per la vista
/// della squadra dell'allenatore.
final seduteCaricoClubProvider =
    FutureProvider.family<Map<String, List<CaricoSeduta>>, String>((
      ref,
      clubId,
    ) {
      return ref.watch(caricoRepositoryProvider).sedutePerClub(clubId);
    });

/// L'ACWR di oggi di ogni atleta del club che ha delle sedute.
final acwrClubProvider = Provider.family<Map<String, Acwr>, String>((
  ref,
  clubId,
) {
  final sedute = ref.watch(seduteCaricoClubProvider(clubId)).value ?? const {};
  return {
    for (final MapEntry(key: atletaId, value: s) in sedute.entries)
      atletaId: ?calcolaAcwr(s),
  };
});

/// La monotonia degli ultimi 7 giorni di ogni atleta del club che in quei
/// giorni ha un carico.
final monotoniaClubProvider = Provider.family<Map<String, Monotonia>, String>((
  ref,
  clubId,
) {
  final sedute = ref.watch(seduteCaricoClubProvider(clubId)).value ?? const {};
  final oggi = DateTime.now();
  return {
    for (final MapEntry(key: atletaId, value: s) in sedute.entries)
      atletaId: ?monotoniaSettimana(s, fine: oggi),
  };
});

/// Le risposte RPE di un atleta, dalla più recente (dal server al primo
/// ascolto, poi dalla cache locale in tempo reale).
final rpeAtletaProvider = StreamProvider.family<List<RpeSeduta>, String>((
  ref,
  atletaId,
) {
  final repository = ref.watch(rpeRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(atletaId),
    watch: () => repository.watchPerAtleta(atletaId),
  );
});

/// Le risposte RPE di tutto il club (per l'allenatore: chi ha detto quanto
/// è stata dura una seduta).
final rpeClubProvider = StreamProvider.family<List<RpeSeduta>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(rpeRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemoteClub(clubId),
    watch: () => repository.watchPerClub(clubId),
  );
});
