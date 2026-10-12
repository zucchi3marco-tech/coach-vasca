import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/giorni.dart';
import '../domain/allenamento.dart';
import '../domain/serie.dart';
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

  /// Copia un allenamento con tutte le sue serie in [data], per
  /// [gruppoId] — anche un'altra squadra ("Duplica" nel dettaglio,
  /// richiesta del coach 2026-10-08). Le piramidi e i "2x" restano
  /// gruppi, con un `piramideId` nuovo; l'esito (fatta/saltata) no.
  /// Per un'altra squadra le serie restano dei portieri o del movimento,
  /// ma non di alcuni atleti: quelle solo per loro non si copiano, e chi
  /// era escluso da una serie qui la fa.
  Future<Allenamento> copiaAllenamento(
    Allenamento sorgente, {
    required DateTime data,
    required String? gruppoId,
  }) async {
    final nuovo = await _allenamenti.createAllenamento(
      clubId: sorgente.clubId,
      data: data,
      titolo: sorgente.titolo,
      gruppoId: gruppoId,
      note: sorgente.note,
    );

    final stessaSquadra = gruppoId == sorgente.gruppoId;
    final serie = [
      for (final s in await _serie.fetchPerAllenamento(sorgente.id))
        if (stessaSquadra || s.destinatari.soloAtleti.isEmpty) s,
    ];
    final gruppi = <String, String>{};
    await Future.wait([
      for (final (i, s) in serie.indexed)
        _serie.createSerie(
          allenamentoId: nuovo.id,
          ordine: i + 1,
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
          piramideId: s.piramideId == null
              ? null
              : gruppi.putIfAbsent(s.piramideId!, () => const Uuid().v4()),
          recuperoDopoS: s.recuperoDopoS,
          destinatari: stessaSquadra
              ? s.destinatari
              : Destinatari(ruolo: s.destinatari.ruolo),
        ),
    ]);
    return nuovo;
  }

  Future<void> _duplicaAllenamento(
    Allenamento sorgente, {
    required DateTime dataInizioSorgente,
    required DateTime nuovaDataInizio,
  }) async {
    // Stesso spostamento in giorni di calendario per ogni seduta, tenendo
    // l'orario: con "+N x 24 ore" la settimana del cambio dell'ora finiva
    // su un giorno sbagliato e l'ora della seduta si perdeva.
    final spostamento = giorniTra(dataInizioSorgente, nuovaDataInizio);
    await copiaAllenamento(
      sorgente,
      data: aggiungiGiorni(sorgente.data, spostamento),
      gruppoId: sorgente.gruppoId,
    );
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
