import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/atleti_repository.dart';
import '../domain/atleta.dart';

/// L'atleta collegato all'account attualmente autenticato (FASE 9), o
/// null se questo login è un coach (o un account non ancora collegato a
/// nessun atleta). Usato da HomeScreen per decidere quale area mostrare
/// quando l'utente non è membro di nessun club.
///
/// `autoDispose`: senza, il valore resterebbe in cache anche dopo un
/// logout, e un secondo account che effettua il login sullo stesso
/// device (stesso avvio dell'app, es. durante un test) si ritroverebbe
/// il risultato del login precedente invece di uno ricalcolato.
final currentAtletaProvider = FutureProvider.autoDispose<Atleta?>((ref) async {
  // Si ricalcola a ogni login/logout: la barra del club lo ascolta gia'
  // dalla schermata di accesso, e senza questo restava fermo al "nessun
  // atleta" letto prima del login (l'atleta finiva nell'area allenatore).
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(atletiRepositoryProvider);
  try {
    return await repository.fetchAtletaCollegato();
  } catch (e) {
    // offline al primo avvio: nessuna cache locale ancora disponibile.
    // ignore: avoid_print
    if (modalitaDemo) print('[demo] atleta collegato non trovato: $e');
    return null;
  }
});
