import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/club_repository.dart';
import '../domain/club.dart';

/// Il club "attivo" per la sessione corrente. In V1 un coach opera su un
/// solo club: si prende il primo restituito (ordinato per nome). Se
/// l'utente non e' ancora membro di nessun club, torna null e la UI
/// mostra il flusso di creazione del primo club.
final currentClubProvider = FutureProvider<Club?>((ref) async {
  final clubs = await ref.watch(clubRepositoryProvider).fetchMyClubs();
  return clubs.isEmpty ? null : clubs.first;
});
