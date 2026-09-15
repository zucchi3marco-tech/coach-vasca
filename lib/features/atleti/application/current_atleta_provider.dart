import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final repository = ref.watch(atletiRepositoryProvider);
  try {
    return await repository.fetchAtletaCollegato();
  } catch (_) {
    // offline al primo avvio: nessuna cache locale ancora disponibile.
    return null;
  }
});
