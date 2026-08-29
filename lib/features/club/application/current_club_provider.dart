import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/refresh_guard.dart';
import '../data/club_repository.dart';
import '../domain/club.dart';

/// Il club "attivo" per la sessione corrente. In V1 un coach opera su un
/// solo club: si prende il primo restituito (ordinato per nome). Se
/// l'utente non e' ancora membro di nessun club, torna null e la UI
/// mostra il flusso di creazione del primo club.
///
/// Legge sempre dalla cache locale (funziona offline); il refresh dal
/// server parte in background e aggiorna la cache quando c'e' rete.
final currentClubProvider = FutureProvider<Club?>((ref) async {
  final repository = ref.watch(clubRepositoryProvider);
  refreshInBackground(repository.refreshFromRemote);
  final clubs = await repository.fetchMyClubsLocal();
  return clubs.isEmpty ? null : clubs.first;
});
