import 'package:shared_preferences/shared_preferences.dart';

import '../domain/novita.dart';

const _chiaveUltimaNovitaVista = 'novita_ultima_vista';

/// L'`id` dell'ultima novità già mostrata su questo device, o null se non
/// ne è mai stata segnata una — persistito con `shared_preferences` (stato
/// del device, non un dato del club, come `onboarding_coach.dart`).
Future<String?> leggiUltimaNovitaVista() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_chiaveUltimaNovitaVista);
}

/// Segna come viste tutte le novità del [registro] (di norma
/// [registroNovita]): si ricorda la più recente. Con il registro vuoto non
/// fa niente.
Future<void> segnaNovitaViste([List<Novita>? registro]) async {
  final elenco = registro ?? registroNovita;
  if (elenco.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_chiaveUltimaNovitaVista, elenco.first.id);
}
