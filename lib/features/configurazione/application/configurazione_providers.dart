import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../club/application/membri_club_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../data/configurazione_repository.dart';
import '../domain/stato_configurazione.dart';

/// La configurazione guidata a tutto schermo nella home, subito dopo "Crea
/// club": l'id del club, null quando non c'è. Non si ricorda fra un avvio e
/// l'altro: riaprendo l'app si riparte dalla home (o dalle squadre, se non
/// ce n'è ancora una), e il resto lo propone la scheda "Per cominciare".
class ConfigurazioneInCorsoNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void inizia(String clubId) => state = clubId;

  void finisci() => state = null;
}

final configurazioneInCorsoProvider =
    NotifierProvider<ConfigurazioneInCorsoNotifier, String?>(
      ConfigurazioneInCorsoNotifier.new,
    );

/// A che punto è la configurazione del club. Squadre e atleti dai dati sul
/// telefono; allenatori e codici dal server, quindi senza rete è un errore
/// (e la scheda "Per cominciare" semplicemente non c'è). Nella demo il club
/// è solo mio e i codici non si fanno: non si chiede niente al server.
///
/// Dopo "Alleno da solo", un invito o il foglio dei codici va invalidato:
/// squadre e atleti invece si aggiornano da soli.
final statoConfigurazioneProvider = FutureProvider.autoDispose
    .family<StatoConfigurazione, String>((ref, clubId) async {
      final gruppi = await ref.watch(gruppiListProvider(clubId).future);
      final atleti = await ref.watch(
        atletiListProvider((clubId: clubId, includeInactive: false)).future,
      );
      final daSolo = await ref
          .watch(preferenzeConfigurazioneProvider)
          .allenaDaSolo(clubId);

      var altriAllenatori = 0;
      var invitiAllenatori = false;
      var codiciAtleti = false;
      if (!(dotenv.isInitialized && modalitaDemo)) {
        final repository = ref.watch(configurazioneRepositoryProvider);
        final membri = await ref.watch(membriClubProvider(clubId).future);
        altriAllenatori = membri.where((m) => !m.sonoIo).length;
        (invitiAllenatori, codiciAtleti) = await (
          repository.ciSonoInvitiAllenatori(clubId),
          repository.ciSonoCodiciAtleti(clubId),
        ).wait;
      }

      return StatoConfigurazione(
        squadre: gruppi.length,
        altriAllenatori: altriAllenatori,
        invitiAllenatori: invitiAllenatori,
        allenaDaSolo: daSolo,
        atleti: atleti.length,
        atletiConAccount: atleti.where((a) => a.haAccountCollegato).length,
        codiciAtleti: codiciAtleti,
      );
    }, retry: (_, _) => null);

/// La scheda "Per cominciare" è stata nascosta su questo dispositivo.
final configurazioneNascostaProvider = FutureProvider.autoDispose
    .family<bool, String>(
      (ref, clubId) =>
          ref.watch(preferenzeConfigurazioneProvider).nascosta(clubId),
    );
