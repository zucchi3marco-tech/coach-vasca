import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/referti_repository.dart';
import '../domain/referto_partita.dart';

/// Referto salvato per una partita (null se non ancora salvato). A
/// differenza delle liste di pallanuoto non e' uno StreamProvider: va
/// invalidato esplicitamente dopo un salvataggio riuscito (vedi
/// leggi_referto_screen.dart) perche' e' una lettura una tantum, non un
/// watch continuo su Supabase/Drift.
final refertoPerPartitaProvider =
    FutureProvider.family<RefertoPartita?, String>((ref, partitaId) {
      return ref.watch(refertiRepositoryProvider).perPartita(partitaId);
    });
