import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/allenamenti_repository.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/serie.dart';
import '../domain/volume_allenamento.dart';

final allenamentiListProvider =
    StreamProvider.family<List<Allenamento>, String>((ref, clubId) {
      final repository = ref.watch(allenamentiRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemote(clubId),
        watch: () => repository.watchPerClub(clubId),
      );
    });

/// Per l'atleta collegato (FASE 13, punto 3) — vedi
/// `AllenamentiRepository.fetchPerAtleta`.
final allenamentiAtletaProvider = FutureProvider.autoDispose
    .family<List<Allenamento>, String>((ref, clubId) {
      return ref.read(allenamentiRepositoryProvider).fetchPerAtleta(clubId);
    });

/// Le serie di un allenamento viste dall'atleta (senza `note`) — vedi
/// `SerieRepository.fetchPerAtleta`.
final serieAtletaProvider = FutureProvider.autoDispose
    .family<List<Serie>, String>((ref, allenamentoId) {
      return ref.read(serieRepositoryProvider).fetchPerAtleta(allenamentoId);
    });

final serieListProvider = StreamProvider.family<List<Serie>, String>((
  ref,
  allenamentoId,
) {
  final repository = ref.watch(serieRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(allenamentoId),
    watch: () => repository.watchPerAllenamento(allenamentoId),
  );
});

/// Metri e lavoro a tempo di ogni allenamento del club (chiave: id), per
/// l'elenco e i totali delle settimane: le serie di tutto il club in una
/// lettura, invece di una chiamata per allenamento.
final volumiAllenamentiProvider =
    StreamProvider.family<Map<String, VolumeAllenamento>, String>((
      ref,
      clubId,
    ) {
      final repository = ref.watch(serieRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshPerClub(clubId),
        watch: () => repository.watchPerClub(clubId).map(volumiPerAllenamento),
      );
    });
