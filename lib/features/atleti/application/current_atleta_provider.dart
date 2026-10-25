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
  // Senza rete il repository usa la copia del telefono. Un errore vero
  // (il server rifiuta, una scheda che non si legge) resta un errore: la
  // home mostra "riprova" invece di proporre a un atleta di creare un
  // club (segnalazione del coach 2026-10-25).
  try {
    return await repository.fetchAtletaCollegato();
  } catch (e) {
    if (modalitaDemo) {
      // ignore: avoid_print
      print('[demo] atleta collegato non trovato: $e');
      return null;
    }
    rethrow;
  }
});
