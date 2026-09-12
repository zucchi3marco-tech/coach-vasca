import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'allenamenti_repository.dart';
import 'serie_repository.dart';

/// Duplica tutti gli allenamenti (e le relative serie) di un intervallo
/// di date su un nuovo intervallo spostato in avanti — analisi video,
/// sezione 5: "duplicare la settimana precedente e modificarla" è più
/// utile di una generazione da zero. Ogni scrittura passa dai repository
/// esistenti, quindi eredita lo stesso comportamento resiliente
/// (online-first, coda locale se offline) di ogni altra creazione
/// nell'app.
class DuplicazioneSettimanaService {
  DuplicazioneSettimanaService(this._allenamenti, this._serie);

  final AllenamentiRepository _allenamenti;
  final SerieRepository _serie;

  /// Torna il numero di allenamenti duplicati.
  Future<int> duplica({
    required String clubId,
    required DateTime dataInizioSorgente,
    required DateTime dataFineSorgente,
    required DateTime nuovaDataInizio,
  }) async {
    final sorgenti = await _allenamenti.fetchPerClubEPeriodo(
      clubId: clubId,
      dataInizio: dataInizioSorgente,
      dataFine: dataFineSorgente,
    );

    for (final a in sorgenti) {
      final offsetGiorni = a.data.difference(dataInizioSorgente).inDays;
      final nuovo = await _allenamenti.createAllenamento(
        clubId: clubId,
        data: nuovaDataInizio.add(Duration(days: offsetGiorni)),
        titolo: a.titolo,
        gruppoId: a.gruppoId,
        note: a.note,
      );

      final serie = await _serie.fetchPerAllenamento(a.id);
      for (final s in serie) {
        await _serie.createSerie(
          allenamentoId: nuovo.id,
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

    return sorgenti.length;
  }
}

final duplicazioneSettimanaServiceProvider =
    Provider<DuplicazioneSettimanaService>((ref) {
      return DuplicazioneSettimanaService(
        ref.watch(allenamentiRepositoryProvider),
        ref.watch(serieRepositoryProvider),
      );
    });
