import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/test_club_repository.dart';
import '../domain/massimale.dart';
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

/// Il massimale di ogni atleta in ogni esercizio a secco (id esercizio →
/// id atleta → l'ultimo massimale), dai test di massimale del club. A un
/// atleta arrivano solo i suoi risultati, quindi solo i suoi massimali.
final massimaliProvider =
    Provider.family<Map<String, Map<String, Massimale>>, String>(
      (ref, clubId) => massimaliPerEsercizio(
        ref.watch(testClubProvider(clubId)).value ?? const [],
        ref.watch(risultatiTestClubProvider(clubId)).value ?? const [],
      ),
    );
