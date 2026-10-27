import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/segnalazioni/dispositivo.dart';
import '../../../core/versione/versione_app.dart';
import '../../segnalazioni/data/segnalazioni_repository.dart';
import '../../segnalazioni/domain/segnalazione.dart';
import 'campionati_providers.dart';

/// Manda una segnalazione di «Scrivimi».
typedef InviaSegnalazione = Future<void> Function({
  required String clubId,
  required String testo,
  required ContestoSegnalazione contesto,
});

/// Quando il lettore non capisce più il sito della FIN (`nonTuttoLetto`)
/// parte da sola una segnalazione fra quelle di «Scrivimi», così si
/// sistema il lettore prima che se ne accorga un club. Al massimo una al
/// giorno per telefono; se non parte (senza rete, o è un atleta, che non
/// scrive segnalazioni) non succede niente e si riprova la volta dopo.
class SegnalatoreSitoFin {
  SegnalatoreSitoFin(this._invia, {DateTime Function()? adesso})
    : _adesso = adesso ?? DateTime.now;

  final InviaSegnalazione _invia;
  final DateTime Function() _adesso;
  bool _inCorso = false;

  static const chiave = 'fin_sito_cambiato_segnalato_il';

  static String testo(String cosa) =>
      'Segnalazione automatica: il sito della FIN Lombardia è cambiato e '
      "l'app non riesce più a leggere tutta la pagina ($cosa). Va "
      'sistemato il lettore dei campionati.';

  Future<void> segnala({required String clubId, required String cosa}) async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final oggi = _adesso();
      final giorno =
          '${oggi.year}-${oggi.month.toString().padLeft(2, '0')}-'
          '${oggi.day.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(chiave) == giorno) return;
      await _invia(
        clubId: clubId,
        testo: testo(cosa),
        contesto: ContestoSegnalazione(
          versione: VersioneApp.corrente.compatta,
          pagina: 'Campionati FIN, $cosa',
          dispositivo: descrizioneDispositivo(),
        ),
      );
      await prefs.setString(chiave, giorno);
    } catch (_) {
      // Una segnalazione che non parte non deve disturbare chi guarda la
      // classifica: il messaggio nella pagina c'è comunque.
    } finally {
      _inCorso = false;
    }
  }
}

final segnalatoreSitoFinProvider = Provider<SegnalatoreSitoFin>((ref) {
  if (dotenv.isInitialized && modalitaDemo) {
    return SegnalatoreSitoFin(
      ({required clubId, required testo, required contesto}) async {},
    );
  }
  return SegnalatoreSitoFin(ref.watch(segnalazioniRepositoryProvider).invia);
});

/// Quello che vede chi guarda la pagina quando il sito non si legge tutto.
const testoSitoFinCambiato =
    "Il sito della FIN è cambiato e l'app non riesce più a leggerlo tutto: "
    'qui può mancare qualcosa. Guarda la pagina sul sito della FIN.';

/// Dentro `build`: quando dal sito (non dalla copia sul telefono) arriva un
/// girone che non si è capito tutto, parte la segnalazione.
void segnalaSeGironeNonLetto(
  WidgetRef ref, {
  required int cmpId,
  required String clubId,
  required String nome,
}) {
  ref.listen(gironeFinProvider(cmpId), (_, next) {
    final lettura = next.value;
    if (lettura == null || lettura.daCopia) return;
    if (!lettura.girone.nonTuttoLetto) return;
    ref
        .read(segnalatoreSitoFinProvider)
        .segnala(clubId: clubId, cosa: 'girone $nome, CMPid $cmpId');
  });
}

/// Dentro `build`: lo stesso per l'elenco dei campionati di [stagione].
void segnalaSeElencoNonLetto(
  WidgetRef ref, {
  required String? stagione,
  required String clubId,
}) {
  ref.listen(elencoFinProvider(stagione), (_, next) {
    final elenco = next.value;
    if (elenco == null || !elenco.nonTuttoLetto) return;
    final quale = elenco.stagione.isEmpty ? '' : ' ${elenco.stagione}';
    ref
        .read(segnalatoreSitoFinProvider)
        .segnala(clubId: clubId, cosa: 'elenco dei campionati$quale');
  });
}
