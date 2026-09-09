import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../domain/microciclo.dart';
import 'microcicli_repository.dart';

/// Duplica una settimana (microciclo) creandone una nuova, subito
/// successiva, con la stessa durata e una copia di tutti gli allenamenti
/// e le relative serie. Ogni scrittura passa dai repository esistenti,
/// quindi eredita lo stesso comportamento resiliente (online-first, coda
/// locale se offline) di ogni altra creazione nell'app.
class DuplicazioneSettimanaService {
  DuplicazioneSettimanaService(this._microcicli, this._allenamenti, this._serie);

  final MicrocicliRepository _microcicli;
  final AllenamentiRepository _allenamenti;
  final SerieRepository _serie;

  Future<Microciclo> duplica(Microciclo sorgente) async {
    final durata = sorgente.dataFine.difference(sorgente.dataInizio);
    final nuovaDataInizio = sorgente.dataFine.add(const Duration(days: 1));
    final nuovaDataFine = nuovaDataInizio.add(durata);

    final nuovoMicrociclo = await _microcicli.createMicrociclo(
      mesocicloId: sorgente.mesocicloId,
      nome: sorgente.nome,
      numeroSettimana: sorgente.numeroSettimana != null
          ? sorgente.numeroSettimana! + 1
          : null,
      ordine: sorgente.ordine + 1,
      dataInizio: nuovaDataInizio,
      dataFine: nuovaDataFine,
      tipo: sorgente.tipo,
    );

    final allenamenti = await _allenamenti.fetchPerMicrociclo(sorgente.id);
    for (final a in allenamenti) {
      final offsetGiorni = a.data.difference(sorgente.dataInizio).inDays;
      final nuovoAllenamento = await _allenamenti.createAllenamento(
        clubId: a.clubId,
        data: nuovoMicrociclo.dataInizio.add(Duration(days: offsetGiorni)),
        microcicloId: nuovoMicrociclo.id,
        titolo: a.titolo,
        gruppoId: a.gruppoId,
        note: a.note,
      );

      final serie = await _serie.fetchPerAllenamento(a.id);
      for (final s in serie) {
        await _serie.createSerie(
          allenamentoId: nuovoAllenamento.id,
          ordine: s.ordine,
          blocco: s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          stile: s.stile,
          esecuzione: s.esecuzione,
          zona: s.zona,
          passoObiettivoS: s.passoObiettivoS,
          recuperoS: s.recuperoS,
          ripartenzaS: s.ripartenzaS,
          attrezzatura: s.attrezzatura,
          note: s.note,
        );
      }
    }

    return nuovoMicrociclo;
  }
}

final duplicazioneSettimanaServiceProvider =
    Provider<DuplicazioneSettimanaService>((ref) {
      return DuplicazioneSettimanaService(
        ref.watch(microcicliRepositoryProvider),
        ref.watch(allenamentiRepositoryProvider),
        ref.watch(serieRepositoryProvider),
      );
    });
