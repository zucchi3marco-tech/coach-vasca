import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/modalita_demo.dart';
import '../data/membri_club_repository.dart';
import '../domain/ruolo_club.dart';

/// Il mio ruolo nel club. Nella demo il club è solo mio: responsabile,
/// senza toccare la rete. Null se non risulto membro.
final mioRuoloProvider = FutureProvider.autoDispose.family<RuoloClub?, String>((
  ref,
  clubId,
) async {
  if (dotenv.isInitialized && modalitaDemo) {
    return RuoloClub.responsabile;
  }
  return ref.watch(membriClubRepositoryProvider).mioRuolo(clubId);
}, retry: (_, _) => null);

/// Chi lavora nel club (per "Il mio club").
final membriClubProvider = FutureProvider.autoDispose
    .family<List<MembroClub>, String>(
      (ref, clubId) => ref.watch(membriClubRepositoryProvider).membri(clubId),
      // Senza rete l'errore si vede subito, con "Riprova".
      retry: (_, _) => null,
    );

/// Le squadre del club con il loro capo allenatore (per "Il mio club").
final squadreConCapoProvider = FutureProvider.autoDispose
    .family<List<SquadraConCapo>, String>(
      (ref, clubId) => ref.watch(membriClubRepositoryProvider).squadre(clubId),
      retry: (_, _) => null,
    );

/// Si possono mostrare le azioni che aggiungono o tolgono atleti e squadre
/// (e i codici per farli entrare)? No per un assistente, e nemmeno finché
/// non si sa il ruolo. Se il ruolo non si riesce a leggere (offline) sì: il
/// database rifiuta comunque quello che a un assistente non spetta, e un
/// allenatore senza rete non deve perdere i suoi pulsanti.
final puoGestireAtletiESquadreProvider = Provider.autoDispose
    .family<bool, String>((ref, clubId) {
      final ruolo = ref.watch(mioRuoloProvider(clubId));
      return ruolo.when(
        data: (r) => r == null || r.puoGestireAtletiESquadre,
        loading: () => false,
        error: (_, _) => true,
      );
    });
