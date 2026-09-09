import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Il gruppo scelto dal coach per questa sessione, nella schermata
/// "scegli il gruppo" mostrata a ogni apertura dell'app.
class SelezioneGruppo {
  const SelezioneGruppo(this.gruppoId);

  /// null = "Tutti gli atleti" (nessun filtro), non "nessuna scelta".
  final String? gruppoId;
}

/// null (lo stato del notifier, non il campo sopra) = non ancora scelto in
/// questa sessione: va mostrata la schermata di scelta. Non persistito
/// apposta: si resetta a ogni riavvio dell'app.
class SelezioneGruppoNotifier extends Notifier<SelezioneGruppo?> {
  @override
  SelezioneGruppo? build() => null;

  void scegli(SelezioneGruppo? selezione) => state = selezione;
}

final selezioneGruppoProvider =
    NotifierProvider<SelezioneGruppoNotifier, SelezioneGruppo?>(
      SelezioneGruppoNotifier.new,
    );
