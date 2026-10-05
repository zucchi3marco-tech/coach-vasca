import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/prossimo_allenamento.dart';
import '../../atleti/domain/atleta.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../presenze/application/presenze_providers.dart';

/// La calottina dell'ultima convocazione dell'atleta: numero, portiere
/// (calottina rossa) e colore della squadra in quella partita. null se
/// non e' mai stato convocato.
typedef CalottinaAtleta = ({int numero, bool portiere, String? colore});

final calottinaAtletaProvider = FutureProvider.autoDispose
    .family<CalottinaAtleta?, String>((ref, atletaId) async {
      final db = ref.watch(appDatabaseProvider);
      final d = db.distintaGiocatoriTable;
      final p = db.partiteTable;
      final riga =
          await (db.select(d).join([innerJoin(p, p.id.equalsExp(d.partitaId))])
                ..where(d.atletaId.equals(atletaId))
                ..orderBy([OrderingTerm.desc(p.data)])
                ..limit(1))
              .getSingleOrNull();
      if (riga == null) return null;
      final convocazione = riga.readTable(d);
      final partita = riga.readTable(p);
      return (
        numero: convocazione.numeroCalottina,
        portiere: convocazione.portiere,
        colore: partita.coloreCalottina,
      );
    });

/// Prossima partita in calendario per il gruppo dell'atleta (o di tutto
/// il club), da oggi in avanti.
final prossimaPartitaAtletaProvider = Provider.autoDispose
    .family<Partita?, Atleta>((ref, atleta) {
      final partite = ref.watch(partiteListProvider(atleta.clubId)).value;
      if (partite == null) return null;
      final oggi = DateTime.now();
      final inizio = DateTime(oggi.year, oggi.month, oggi.day);
      final future =
          partite
              .where(
                (p) =>
                    !p.data.isBefore(inizio) &&
                    visibileNelGruppo(
                      gruppoDelRecord: p.gruppoId,
                      gruppoSelezionato: atleta.gruppoId,
                    ),
              )
              .toList()
            ..sort((a, b) => a.data.compareTo(b.data));
      return future.isEmpty ? null : future.first;
    });

/// Allenamenti del gruppo dell'atleta e % di presenze su quelli gia'
/// passati.
typedef RiepilogoAllenamenti = ({
  Allenamento? prossimo,
  int? percentualePresenze,
  int fatti,
  int presente,
});

final riepilogoAllenamentiAtletaProvider = Provider.autoDispose
    .family<RiepilogoAllenamenti?, Atleta>((ref, atleta) {
      final allenamenti = ref
          .watch(allenamentiAtletaProvider(atleta.clubId))
          .value;
      final presenze = ref.watch(presenzePerAtletaProvider(atleta.id)).value;
      if (allenamenti == null) return null;
      final rilevanti = allenamenti
          .where(
            (a) => visibileNelGruppo(
              gruppoDelRecord: a.gruppoId,
              gruppoSelezionato: atleta.gruppoId,
            ),
          )
          .toList();
      final adesso = DateTime.now();
      final passati = rilevanti.where((a) => a.data.isBefore(adesso)).toList();
      final idPassati = passati.map((a) => a.id).toSet();
      final presente = presenze == null
          ? 0
          : presenze
                .where(
                  (p) =>
                      p.stato == 'presente' &&
                      idPassati.contains(p.allenamentoId),
                )
                .length;
      return (
        prossimo: prossimoAllenamento(rilevanti, atleta.gruppoId),
        percentualePresenze: passati.isEmpty || presenze == null
            ? null
            : (presente / passati.length * 100).round(),
        fatti: passati.length,
        presente: presente,
      );
    });

/// Gol e tiri dell'atleta nelle partite tracciate dal vivo.
typedef TiriAtleta = ({int gol, int tiri});

final golTiriAtletaProvider = Provider.autoDispose.family<TiriAtleta?, String>((
  ref,
  atletaId,
) {
  final eventi = ref.watch(tiriAtletaProvider(atletaId)).value;
  if (eventi == null) return null;
  final tiri = eventi.where((e) => e.tipo == 'tiro').toList();
  return (gol: tiri.where((e) => e.esito == 'gol').length, tiri: tiri.length);
});
