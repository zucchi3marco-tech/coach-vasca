import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dati_club_repository.dart';

/// Quando è nato il club: serve a offrire, in "Scarica i dati del club", le
/// stagioni da cui scegliere (vedi `periodiDisponibili`). Null se il server
/// non lo mostra; se la lettura fallisce la schermata offre le stagioni di
/// base, senza bloccarsi.
final creatoIlClubProvider = FutureProvider.autoDispose
    .family<DateTime?, String>(
      (ref, clubId) => ref.watch(datiClubRepositoryProvider).creatoIl(clubId),
      // Un errore non si ritenta: le stagioni di base bastano.
      retry: (_, _) => null,
    );
