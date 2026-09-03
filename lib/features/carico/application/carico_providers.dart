import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/carico_repository.dart';
import '../domain/banister.dart';

typedef _ChiaveCarico = ({String atletaId, String clubId});

final andamentoCaricoProvider =
    FutureProvider.family<List<PuntoBanister>, _ChiaveCarico>((
      ref,
      chiave,
    ) async {
      final repository = ref.watch(caricoRepositoryProvider);
      final caricoPerGiorno = await repository.caricoGiornalieroPerAtleta(
        atletaId: chiave.atletaId,
        clubId: chiave.clubId,
      );
      return calcolaBanister(caricoPerGiorno);
    });
