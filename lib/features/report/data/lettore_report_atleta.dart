import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/giorni.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../atleti/domain/atleta.dart';
import '../../benessere/data/schede_benessere_repository.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../carico/data/rpe_repository.dart';
import '../../obiettivi/data/obiettivi_repository.dart';
import '../../pallanuoto/data/distinta_repository.dart';
import '../../pallanuoto/data/eventi_partita_repository.dart';
import '../../pallanuoto/data/partite_repository.dart';
import '../../pallanuoto/domain/numeri_portiere.dart';
import '../../presenze/data/presenze_repository.dart';
import '../../referti/data/referti_repository.dart';
import '../../test/data/test_club_repository.dart';
import '../domain/report_atleta.dart';

/// Legge tutto quello che serve al report di un atleta. Senza rete usa
/// le copie sul telefono dove ci sono; le schede degli obiettivi stanno
/// solo sul server, e senza rete il report lo dice.
class LettoreReportAtleta {
  const LettoreReportAtleta(this._ref);

  final Ref _ref;

  /// Prova [fai]; se fallisce (di solito la rete) va avanti con [altrimenti].
  static Future<T> _oppure<T>(Future<T> Function() fai, T altrimenti) async {
    try {
      return await fai();
    } catch (_) {
      return altrimenti;
    }
  }

  Future<DatiReportAtleta> leggi(
    Atleta atleta,
    PeriodoReport periodo, {
    bool conBenessere = false,
  }) async {
    // Il giorno dopo la fine: allenamenti e partite con l'ora entrano
    // tutti; quelli in più li toglie il report.
    final finoA = aggiungiGiorni(periodo.al, 1);
    final allenamenti = await _ref
        .read(allenamentiRepositoryProvider)
        .fetchPerClubEPeriodo(
          clubId: atleta.clubId,
          dataInizio: periodo.dal,
          dataFine: finoA,
        );

    final presenzeRepo = _ref.read(presenzeRepositoryProvider);
    await _oppure(
      () => presenzeRepo.refreshFromRemotePerAtleta(atleta.id),
      null,
    );
    final presenze = await presenzeRepo.watchPerAtleta(atleta.id).first;

    final pallanuoto = atleta.sport == 'pallanuoto';
    final partite = pallanuoto
        ? await _ref
              .read(partiteRepositoryProvider)
              .perClubEPeriodo(
                clubId: atleta.clubId,
                dataInizio: periodo.dal,
                dataFine: finoA,
              )
        : const <Never>[];
    final idPartite = [for (final p in partite) p.id];
    final distinta = _ref.read(distintaRepositoryProvider);
    final convocato = idPartite.isEmpty
        ? <String>{}
        : await _oppure(
            () => distinta.partiteDellAtleta(atleta.id),
            <String>{},
          );
    final referti = idPartite.isEmpty
        ? const <Never>[]
        : await _ref.read(refertiRepositoryProvider).perPartite(idPartite);
    final eventi = idPartite.isEmpty
        ? const <Never>[]
        : await _ref
              .read(eventiPartitaRepositoryProvider)
              .perPartite(idPartite);

    NumeriPortiere? portiere;
    if (pallanuoto && atleta.portiere && idPartite.isNotEmpty) {
      final tempi = await _oppure(
        () => distinta.tempiInPortaDellAtleta(atleta.id),
        <String, List<int>>{},
      );
      final giocate = [
        for (final p in partite)
          if (periodo.contiene(p.data)) p,
      ];
      portiere = numeriPortiere(
        atletaId: atleta.id,
        partite: giocate,
        tempiInPorta: tempi,
        eventi: eventi,
        referti: {for (final r in referti) r.partitaId: r},
      );
    }

    final testRepo = _ref.read(testClubRepositoryProvider);
    await _oppure(() => testRepo.refreshTest(atleta.clubId), null);
    await _oppure(() => testRepo.refreshRisultati(atleta.clubId), null);
    final test = await testRepo.watchTest(atleta.clubId).first;
    final risultati = await testRepo.watchRisultati(atleta.clubId).first;

    final obiettiviRepo = _ref.read(obiettiviRepositoryProvider);
    var obiettiviLetti = true;
    final schede = await _oppure(
      () => obiettiviRepo.schede(atleta.clubId),
      null,
    );
    final risposte = await _oppure(
      () => obiettiviRepo.risposteDellAtleta(atleta.id),
      null,
    );
    if (schede == null || risposte == null) obiettiviLetti = false;

    List<SchedaBenessere>? benessere;
    if (conBenessere) {
      final repo = _ref.read(schedeBenessereRepositoryProvider);
      await _oppure(() => repo.refreshFromRemote(atleta.id), null);
      benessere = await repo.watchPerAtleta(atleta.id).first;
    }
    final rpe = conBenessere
        ? await _oppure(
            () => _ref.read(rpeRepositoryProvider).perAtleta(atleta.id),
            null,
          )
        : null;

    return DatiReportAtleta(
      allenamenti: allenamenti,
      presenze: presenze,
      partite: partite,
      convocato: convocato,
      referti: referti,
      eventi: eventi,
      portiere: portiere,
      test: test,
      risultatiTest: [
        for (final r in risultati)
          if (r.atletaId == atleta.id) r,
      ],
      schedeObiettivi: schede ?? const [],
      risposteObiettivi: risposte ?? const [],
      obiettiviLetti: obiettiviLetti,
      benessere: benessere ?? const [],
      rpe: rpe ?? const [],
    );
  }
}

final lettoreReportAtletaProvider = Provider<LettoreReportAtleta>(
  (ref) => LettoreReportAtleta(ref),
);
