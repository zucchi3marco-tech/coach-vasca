import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/gruppi_repository.dart';
import '../domain/gruppo.dart';

final gruppiListProvider = StreamProvider.family<List<Gruppo>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(gruppiRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(clubId),
    watch: () => repository.watchPerClub(clubId),
  );
});

/// Il nome della squadra scelta in alto ("Tutti gli atleti" se nessuna):
/// l'occhiello delle testate delle schermate principali.
final nomeSquadraProvider =
    Provider.family<String, ({String clubId, String? gruppoId})>((ref, arg) {
      final gruppi = ref.watch(gruppiListProvider(arg.clubId)).value ?? [];
      return gruppi
              .where((g) => g.id == arg.gruppoId)
              .map((g) => g.nome)
              .firstOrNull ??
          'Tutti gli atleti';
    });
