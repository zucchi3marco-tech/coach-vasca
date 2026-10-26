import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/video_partite_repository.dart';
import '../domain/video_partita.dart';

/// Il video della partita (null se non è collegato, o per un atleta non
/// convocato), aggiornato dal server al primo ascolto insieme alle note.
final videoPartitaProvider = StreamProvider.family<VideoPartita?, String>((
  ref,
  partitaId,
) {
  final repository = ref.watch(videoPartiteRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refresh(partitaId),
    watch: () => repository.watchVideo(partitaId),
  );
});

/// Le note del video, in ordine di fotogramma (le aggiorna dal server
/// [videoPartitaProvider]).
final noteVideoProvider = StreamProvider.family<List<NotaVideo>, String>((
  ref,
  videoId,
) {
  return ref.watch(videoPartiteRepositoryProvider).watchNote(videoId);
});

/// Le risposte dei giocatori alle note della partita (solo con la rete;
/// senza, nessuna).
final risposteNoteProvider = FutureProvider.autoDispose
    .family<List<RispostaNota>, String>((ref, partitaId) async {
      try {
        return await ref
            .watch(videoPartiteRepositoryProvider)
            .risposteNote(partitaId);
      } catch (_) {
        return const [];
      }
    });
