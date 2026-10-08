import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_genera/application/corsie_service.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/application/personal_best_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/personal_best.dart';
import '../domain/durata_serie.dart';

/// Il passo di riferimento degli atleti attivi del gruppo [gruppoId]
/// (null = tutto il club): le corsie come le fa il generatore
/// ([assegnaCorsie], dai primati sui 100 e 200 stile libero) e di queste
/// la più lenta. `null` se nessuno ha il primato sui 100 sl: la durata si
/// stima allora sul passo medio.
PassoRiferimento? passoRiferimentoDelGruppo({
  required List<Atleta> atleti,
  required List<PersonalBest> primati,
  required String? gruppoId,
}) {
  final delGruppo = [
    for (final a in atleti)
      if (a.attivo && (gruppoId == null || a.gruppoId == gruppoId)) a,
  ];
  final primatiPerAtleta = <String, List<PersonalBest>>{};
  for (final p in primati) {
    (primatiPerAtleta[p.atletaId] ??= []).add(p);
  }
  final corsie = assegnaCorsie(delGruppo, primatiPerAtleta).corsie;
  if (corsie.isEmpty) return null;
  final piuLenta = corsie.reduce((a, b) => b.passo100S > a.passo100S ? b : a);
  return (
    passo100S: piuLenta.passo100S,
    differenzialeS: piuLenta.differenzialeS,
  );
}

typedef ChiaveGruppo = ({String clubId, String? gruppoId});

/// [passoRiferimentoDelGruppo] per un allenamento: i primati di tutto il
/// club arrivano con una richiesta sola. Finché atleti e primati non sono
/// caricati vale `null` (passo medio), poi la stima si aggiorna da sola.
final passoRiferimentoProvider =
    Provider.family<PassoRiferimento?, ChiaveGruppo>((ref, chiave) {
      final atleti = ref
          .watch(
            atletiListProvider((clubId: chiave.clubId, includeInactive: false)),
          )
          .value;
      final primati = ref.watch(personalBestClubProvider(chiave.clubId)).value;
      if (atleti == null || primati == null) return null;
      return passoRiferimentoDelGruppo(
        atleti: atleti,
        primati: primati,
        gruppoId: chiave.gruppoId,
      );
    });
