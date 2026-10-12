import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/test_club_repository.dart';
import '../domain/test_club.dart';

/// I test del club, per nome (aggiornati dal server al primo ascolto,
/// poi dalla copia locale in tempo reale).
final testClubProvider = StreamProvider.family<List<TestClub>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(testClubRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshTest(clubId),
    watch: () => repository.watchTest(clubId),
  );
});

/// Tutti i risultati dei test del club, dal più recente.
final risultatiTestClubProvider =
    StreamProvider.family<List<RisultatoTest>, String>((ref, clubId) {
      final repository = ref.watch(testClubRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshRisultati(clubId),
        watch: () => repository.watchRisultati(clubId),
      );
    });
