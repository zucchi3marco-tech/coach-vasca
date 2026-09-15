import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/club_repository.dart';
import '../domain/club.dart';

/// Il club "attivo" per la sessione corrente. In V1 un coach opera su un
/// solo club: si prende il primo restituito (ordinato per nome). Se
/// l'utente non e' ancora membro di nessun club, torna null e la UI
/// mostra il flusso di creazione del primo club.
///
/// Aspetta un primo tentativo di refresh dal server prima di leggere la
/// cache locale: altrimenti, su una cache locale ancora vuota (primo
/// avvio), risulterebbe erroneamente "nessun club" anche quando il club
/// esiste gia' su Supabase — e per un FutureProvider (non reattivo come
/// uno StreamProvider) l'errore resterebbe finche' qualcosa non lo
/// invalida esplicitamente.
///
/// `autoDispose`: senza, il valore resterebbe in cache anche dopo un
/// logout, e un secondo account che effettua il login sullo stesso
/// device (stesso avvio dell'app, es. durante un test) si ritroverebbe
/// il club dell'account precedente invece di uno ricalcolato — il bug
/// per cui un atleta appena registrato si è visto proporre la
/// schermata "crea gruppo" del coach.
final currentClubProvider = FutureProvider.autoDispose<Club?>((ref) async {
  final repository = ref.watch(clubRepositoryProvider);
  try {
    await repository.refreshFromRemote();
  } catch (_) {
    // offline al primo avvio: si procede con quel che c'e' in locale.
  }
  final clubs = await repository.fetchMyClubsLocal();
  return clubs.isEmpty ? null : clubs.first;
});
