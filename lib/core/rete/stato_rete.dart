import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La rete come la vedono le chiamate al server: «senza rete» dal momento
/// in cui una chiamata non arriva (rete assente o server che non risponde
/// entro il tempo massimo), di nuovo in rete alla prima risposta, qualunque
/// sia. Lo aggiorna [ClientConTempoMassimo]; lo mostra la spia nella barra.
class StatoRete extends ValueNotifier<DateTime?> {
  StatoRete() : super(null);

  /// Da quando manca la rete; null = in rete.
  DateTime? get senzaReteDa => value;

  bool get inRete => value == null;

  void chiamataFallita([DateTime? quando]) {
    value ??= quando ?? DateTime.now();
  }

  void rispostaArrivata() {
    value = null;
  }
}

/// Uno solo per tutta l'app: il client HTTP di Supabase nasce in `main()`,
/// prima di Riverpod.
final statoRete = StatoRete();

/// Da quando manca la rete (null = in rete), per la UI.
final senzaReteDaProvider = NotifierProvider<SenzaReteDa, DateTime?>(
  SenzaReteDa.new,
);

class SenzaReteDa extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    void aggiorna() => state = statoRete.value;
    statoRete.addListener(aggiorna);
    ref.onDispose(() => statoRete.removeListener(aggiorna));
    return statoRete.value;
  }
}
