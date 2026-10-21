import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../../gruppi/data/gruppi_repository.dart';
import '../data/distinta_repository.dart';
import '../data/eventi_partita_repository.dart';
import '../data/partite_repository.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/evento_partita.dart';
import '../domain/numeri_distinta.dart';
import '../domain/partita.dart';
import '../domain/staff_distinta.dart';

final partiteListProvider = StreamProvider.family<List<Partita>, String>((
  ref,
  clubId,
) {
  final repository = ref.watch(partiteRepositoryProvider);
  return streamConRefreshIniziale(
    refresh: () => repository.refreshFromRemote(clubId),
    watch: () => repository.watchPerClub(clubId),
  );
});

final distintaListProvider =
    StreamProvider.family<List<DistintaGiocatore>, String>((ref, partitaId) {
      final repository = ref.watch(distintaRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemote(partitaId),
        watch: () => repository.watchPerPartita(partitaId),
      );
    });

/// L'ultima partita della stessa squadra con dei convocati (numeri,
/// "Come l'ultima partita", capitano e vice). Usare `chiaveDistinta`.
final ultimaDistintaProvider = FutureProvider.autoDispose
    .family<UltimaDistinta?, ChiavePartitaDistinta>((ref, chiave) {
      return ref.watch(distintaRepositoryProvider).ultimaDellaSquadra(chiave);
    });

/// Lo staff del modulo per una partita: il suo, se l'hanno cambiato per
/// lei, altrimenti quello della squadra.
typedef StaffDellaPartita = ({
  StaffDistinta staff,
  StaffDistinta dellaSquadra,
  bool cambiatoPerLaPartita,
});

final staffDistintaProvider = FutureProvider.autoDispose
    .family<StaffDellaPartita, ({String partitaId, String? gruppoId})>((
      ref,
      chiave,
    ) async {
      final dellaSquadra = chiave.gruppoId == null
          ? StaffDistinta.vuoto
          : await ref
                .watch(gruppiRepositoryProvider)
                .staffDellaSquadra(chiave.gruppoId!);
      final dellaPartita = await ref
          .watch(partiteRepositoryProvider)
          .staffDellaPartita(chiave.partitaId);
      return (
        staff: dellaPartita ?? dellaSquadra,
        dellaSquadra: dellaSquadra,
        cambiatoPerLaPartita: dellaPartita != null,
      );
    });

final eventiPartitaListProvider =
    StreamProvider.family<List<EventoPartita>, String>((ref, partitaId) {
      final repository = ref.watch(eventiPartitaRepositoryProvider);
      return streamConRefreshIniziale(
        refresh: () => repository.refreshFromRemote(partitaId),
        watch: () => repository.watchPerPartita(partitaId),
      );
    });

/// Tutti i tiri di un atleta, per la mappa di calore personale nella
/// pagina Carico.
final tiriAtletaProvider = FutureProvider.family<List<EventoPartita>, String>((
  ref,
  atletaId,
) {
  return ref.watch(eventiPartitaRepositoryProvider).perAtleta(atletaId);
});
