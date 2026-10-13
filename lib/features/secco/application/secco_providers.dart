import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/secco_repository.dart';
import '../domain/esercizio_secco.dart';

/// L'elenco degli esercizi a secco del club (anche gli archiviati).
final eserciziSeccoProvider =
    StreamProvider.family<List<EsercizioSecco>, String>((ref, clubId) {
      final repository = ref.watch(seccoRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshEsercizi(clubId),
        watch: () => repository.watchEsercizi(clubId),
      );
    });

/// Gli esercizi di una seduta a secco, in ordine.
final eserciziSedutaProvider =
    StreamProvider.family<List<EsercizioSeduta>, String>((ref, allenamentoId) {
      final repository = ref.watch(seccoRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshSeduta(allenamentoId),
        watch: () => repository.watchSeduta(allenamentoId),
      );
    });

/// Gli esercizi di una seduta come li vede l'atleta collegato.
final eserciziSedutaAtletaProvider = FutureProvider.autoDispose
    .family<List<EsercizioSedutaAtleta>, String>((ref, allenamentoId) {
      return ref.read(seccoRepositoryProvider).perAtleta(allenamentoId);
    });
