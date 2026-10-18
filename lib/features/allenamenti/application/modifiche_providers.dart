import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/modalita_demo.dart';
import '../data/modifiche_repository.dart';
import '../domain/modifica_allenamento.dart';

bool get _inDemo => dotenv.isInitialized && modalitaDemo;

/// Le modifiche agli allenamenti ancora da vedere, per "Da controllare"
/// in "Oggi". Nella demo non c'è nessun altro allenatore: vuoto, senza
/// rete. Senza rete l'errore resta un errore (nessun nuovo tentativo): chi
/// legge usa `.value` e non mostra nulla.
final modificheDaControllareProvider = FutureProvider.autoDispose
    .family<List<ModificaAllenamento>, String>((ref, clubId) async {
      if (_inDemo) return const [];
      return ref.watch(modificheRepositoryProvider).daControllare(clubId);
    }, retry: (_, _) => null);

/// La modifica ancora da vedere di un allenamento (per la fascia nel suo
/// dettaglio), null se non c'è.
final modificaApertaProvider = FutureProvider.autoDispose
    .family<ModificaAllenamento?, String>((ref, allenamentoId) async {
      if (_inDemo) return null;
      return ref.watch(modificheRepositoryProvider).aperta(allenamentoId);
    }, retry: (_, _) => null);
