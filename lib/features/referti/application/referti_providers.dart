import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pallanuoto/application/pallanuoto_providers.dart';
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

/// I referti salvati delle partite del club: servono alla dashboard
/// dell'atleta per contare i gol anche delle partite non seguite dal vivo.
/// Si rilegge quando cambia l'elenco delle partite, a ogni salvataggio di
/// un referto e quando si torna nell'app.
final refertiDelClubProvider = FutureProvider.autoDispose
    .family<List<RefertoPartita>, String>((ref, clubId) async {
      final partite = await ref.watch(partiteListProvider(clubId).future);
      return ref.watch(refertiRepositoryProvider).perPartite([
        for (final p in partite) p.id,
      ]);
    });
