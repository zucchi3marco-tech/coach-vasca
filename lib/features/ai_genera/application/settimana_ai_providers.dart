import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/domain/serie.dart';
import 'storico_settimana_service.dart';

typedef GateSettimanaAi = ({bool sbloccato, RiassuntoProgrammazione riassunto});

/// Se "Genera settimana con AI" è disponibile per un gruppo (o "Tutti
/// gli atleti" se `gruppoId` è null): serve almeno 60 giorni di
/// calendario coperti da allenamenti con serie vere (vedi
/// `copre60Giorni`), perché la generazione analizza quello storico per
/// imitare lo stile del coach. Il riassunto è comunque calcolato anche
/// se il gate non è ancora sbloccato, così il chiamante può ignorarlo.
///
/// `autoDispose`: il calcolo dipende da quanti allenamenti esistono in
/// questo momento, non ha senso tenerlo in cache oltre la schermata che
/// lo chiede.
final gateSettimanaAiProvider = FutureProvider.autoDispose
    .family<GateSettimanaAi, ({String clubId, String? gruppoId})>((
      ref,
      args,
    ) async {
      final oggi = DateTime.now();
      // Margine oltre i 60 giorni richiesti: un allenamento di oggi non
      // deve sfuggire per un errore di arrotondamento del periodo.
      final inizio = oggi.subtract(const Duration(days: 70));

      final tutti = await ref
          .watch(allenamentiRepositoryProvider)
          .fetchPerClubEPeriodo(
            clubId: args.clubId,
            dataInizio: inizio,
            dataFine: oggi,
          );
      final delGruppo = args.gruppoId == null
          ? tutti
          : tutti.where((a) => a.gruppoId == args.gruppoId).toList();

      final serie = await ref
          .watch(serieRepositoryProvider)
          .fetchPerAllenamenti([for (final a in delGruppo) a.id]);
      final seriePerId = <String, List<Serie>>{};
      for (final s in serie) {
        (seriePerId[s.allenamentoId] ??= []).add(s);
      }

      return (
        sbloccato: copre60Giorni(delGruppo, seriePerId),
        riassunto: calcolaRiassunto(delGruppo, seriePerId),
      );
    });
