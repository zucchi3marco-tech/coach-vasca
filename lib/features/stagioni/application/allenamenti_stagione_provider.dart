import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../data/macrocicli_repository.dart';
import '../data/mesocicli_repository.dart';
import '../data/microcicli_repository.dart';
import '../domain/microciclo.dart';

/// Un allenamento della stagione insieme al microciclo (settimana) a cui è
/// collegato, per poterli raggruppare nella vista d'insieme.
typedef AllenamentoConMicrociclo = (Allenamento allenamento, Microciclo microciclo);

/// Tutti gli allenamenti collegati a un microciclo della stagione, in ordine
/// di data — componendo le query già esistenti (macrocicli → mesocicli →
/// microcicli → allenamenti) invece di aggiungere una colonna `stagione_id`
/// denormalizzata sui livelli intermedi.
final allenamentiStagioneProvider =
    FutureProvider.family<List<AllenamentoConMicrociclo>, String>((
      ref,
      stagioneId,
    ) async {
      final macrocicli = ref.watch(macrocicliRepositoryProvider);
      final mesocicli = ref.watch(mesocicliRepositoryProvider);
      final microcicli = ref.watch(microcicliRepositoryProvider);
      final allenamenti = ref.watch(allenamentiRepositoryProvider);

      final risultato = <AllenamentoConMicrociclo>[];
      for (final ma in await macrocicli.watchPerStagione(stagioneId).first) {
        for (final me in await mesocicli.watchPerMacrociclo(ma.id).first) {
          for (final mc in await microcicli.watchPerMesociclo(me.id).first) {
            final delMicrociclo = await allenamenti.fetchPerMicrociclo(mc.id);
            for (final a in delMicrociclo) {
              risultato.add((a, mc));
            }
          }
        }
      }
      risultato.sort((a, b) => a.$1.data.compareTo(b.$1.data));
      return risultato;
    });
