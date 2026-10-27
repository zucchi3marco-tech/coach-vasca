import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/giorni.dart';
import '../../referti/data/referti_repository.dart';
import '../data/eventi_partita_repository.dart';
import '../domain/scheda_avversario.dart';
import 'pallanuoto_providers.dart';

/// L'avversario [nome] della squadra [gruppoId] (null: le partite di
/// tutto il club). Il nome può essere come lo scriviamo noi o come lo
/// scrive il sito FIN.
typedef ChiaveAvversario = ({String clubId, String? gruppoId, String nome});

/// La scheda dalle nostre partite contro l'avversario, con i referti e
/// gli eventi dal vivo di quelle già giocate. autoDispose: riaprendola
/// si rileggono i referti salvati nel frattempo.
final schedaAvversarioProvider = FutureProvider.autoDispose
    .family<SchedaAvversario, ChiaveAvversario>((ref, chiave) async {
      final partite = await ref.watch(
        partiteListProvider(chiave.clubId).future,
      );
      final contro = partiteControAvversario(
        nome: chiave.nome,
        gruppoId: chiave.gruppoId,
        partite: partite,
      );
      final oggi = DateTime.now();
      final giocate = [
        for (final p in contro)
          if (!soloData(p.data).isAfter(soloData(oggi))) p.id,
      ];
      final referti = await ref
          .watch(refertiRepositoryProvider)
          .perPartite(giocate);
      final eventi = await ref
          .watch(eventiPartitaRepositoryProvider)
          .perPartite(giocate);
      return schedaAvversario(
        nome: chiave.nome,
        partite: contro,
        referti: referti,
        eventi: eventi,
        oggi: oggi,
      );
    });
