import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/campionati_repository.dart';
import '../domain/campionato_fin.dart';

/// I gironi FIN collegati alle squadre del club, dal più recente.
final gironiCollegatiProvider = FutureProvider.autoDispose
    .family<List<GironeCollegato>, String>(
      (ref, clubId) => ref.read(campionatiRepositoryProvider).collegati(clubId),
    );

/// Classifica e calendario di un girone FIN (`CMPid`).
final gironeFinProvider = FutureProvider.autoDispose.family<LetturaGirone, int>(
  (ref, cmpId) => ref.read(campionatiRepositoryProvider).girone(cmpId),
);

/// L'elenco dei gironi di una stagione FIN (null = la più recente).
final elencoFinProvider = FutureProvider.autoDispose.family<ElencoFin, String?>(
  (ref, stagione) =>
      ref.read(campionatiRepositoryProvider).elenco(stagione: stagione),
);

/// I gironi di [gruppoId]: quelli della squadra e quelli di tutto il club.
/// Con [gruppoId] null, tutti.
List<GironeCollegato> gironiDellaSquadra(
  List<GironeCollegato> collegati,
  String? gruppoId,
) => [
  for (final g in collegati)
    if (gruppoId == null || g.gruppoId == null || g.gruppoId == gruppoId) g,
];
