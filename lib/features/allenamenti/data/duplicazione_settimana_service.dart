import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/giorni.dart';
import '../domain/allenamento.dart';
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

  Future<void> _duplicaAllenamento(
    Allenamento sorgente, {
    required String clubId,
    required DateTime dataInizioSorgente,
    required DateTime nuovaDataInizio,
  }) async {
    // Stesso spostamento in giorni di calendario per ogni seduta, tenendo
    // l'orario: con "+N x 24 ore" la settimana del cambio dell'ora finiva
    // su un giorno sbagliato e l'ora della seduta si perdeva.
    final spostamento = giorniTra(dataInizioSorgente, nuovaDataInizio);
    final nuovo = await _allenamenti.createAllenamento(
      clubId: clubId,
      data: aggiungiGiorni(sorgente.data, spostamento),
      titolo: sorgente.titolo,
      gruppoId: sorgente.gruppoId,
      note: sorgente.note,
    );

    final serie = await _serie.fetchPerAllenamento(sorgente.id);
    await Future.wait([
      for (final s in serie)
        _serie.createSerie(
          allenamentoId: nuovo.id,
          ordine: s.ordine,
          blocco: s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          durataS: s.durataS,
          stile: s.stile,
          esecuzione: s.esecuzione,
          zona: s.zona,
          passoObiettivoS: s.passoObiettivoS,
          recuperoS: s.recuperoS,
          ripartenzaS: s.ripartenzaS,
          attrezzatura: s.attrezzatura,
          note: s.note,
        ),
    ]);
  }

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

    // Un allenamento indipendente dall'altro: si duplicano tutti insieme
    // invece che uno alla volta, per non far aspettare il coach un
    // giro di rete per ogni singolo allenamento della settimana.
    await Future.wait([
      for (final a in sorgenti)
        _duplicaAllenamento(
          a,
          clubId: clubId,
          dataInizioSorgente: dataInizioSorgente,
          nuovaDataInizio: nuovaDataInizio,
        ),
    ]);

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
