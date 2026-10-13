import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/volume_allenamento.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../benessere/application/benessere_providers.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../carico/application/carico_providers.dart';
import '../../carico/domain/carico_rpe.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/domain/distinta_giocatore.dart';
import '../../pallanuoto/domain/evento_partita.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../presenze/application/presenze_providers.dart';
import '../../presenze/domain/presenza.dart';
import '../domain/strumenti_assistente.dart';

/// I dati dell'assistente letti come nelle schermate: dalla copia sul
/// telefono, aggiornata dal server quando c'è rete.
class FonteDatiRiverpod implements FonteDatiAssistente {
  FonteDatiRiverpod(this._ref, {required this.clubId, required this.gruppoId});

  final WidgetRef _ref;
  final String clubId;

  @override
  final String? gruppoId;

  /// Legge un dato tenendolo in ascolto fino a quando arriva: con Riverpod 3 un
  /// dato che nessuno ascolta resta in pausa (in una schermata li ascolta
  /// la schermata, qui no).
  Future<T> _leggi<T>(ProviderListenable<Future<T>> futuro) async {
    final ascolto = _ref.listenManual(futuro, (_, _) {});
    try {
      return await ascolto.read();
    } finally {
      ascolto.close();
    }
  }

  @override
  Future<List<Atleta>> atleti() => _leggi(
    atletiListProvider((clubId: clubId, includeInactive: false)).future,
  );

  @override
  Future<List<Partita>> partite() => _leggi(partiteListProvider(clubId).future);

  @override
  Future<List<EventoPartita>> eventi(String partitaId) =>
      _leggi(eventiPartitaListProvider(partitaId).future);

  @override
  Future<List<DistintaGiocatore>> distinta(String partitaId) =>
      _leggi(distintaListProvider(partitaId).future);

  @override
  Future<List<Presenza>> presenze() =>
      _leggi(presenzeClubProvider(clubId).future);

  @override
  Future<List<Allenamento>> allenamenti() =>
      _leggi(allenamentiListProvider(clubId).future);

  @override
  Future<Map<String, VolumeAllenamento>> volumi() =>
      _leggi(volumiAllenamentiProvider(clubId).future);

  @override
  Future<List<SchedaBenessere>> schedeBenessere() =>
      _leggi(schedeBenessereClubProvider(clubId).future);

  @override
  Future<Map<String, List<CaricoSeduta>>> sedutePerAtleta() =>
      _leggi(seduteCaricoClubProvider(clubId).future);
}
