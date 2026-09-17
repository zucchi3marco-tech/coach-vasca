import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/schemi_tattici_repository.dart';
import '../domain/schema_tattico.dart';

final schemiTatticiListProvider =
    StreamProvider.family<List<SchemaTattico>, String>((ref, clubId) {
      final repository = ref.watch(schemiTatticiRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemote(clubId),
        watch: () => repository.watchPerClub(clubId),
      );
    });
