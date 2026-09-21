import 'package:shared_preferences/shared_preferences.dart';

// `_v2`: il tour è stato riscritto (barra in alto, Schemi tattici, Gare,
// partite dal calendario): chi l'aveva già visto lo rivede una volta.
const _chiaveOnboardingCoachVisto = 'onboarding_coach_tab_visto_v2';

/// Se il tour della home (barra in alto e tab) è già
/// stato mostrato su questo device a un account allenatore — persistito
/// con `shared_preferences` (gusto/stato del device, non un dato del
/// club, stesso schema di `tema_provider.dart`).
Future<bool> onboardingCoachGiaVisto() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_chiaveOnboardingCoachVisto) ?? false;
}

Future<void> segnaOnboardingCoachVisto() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_chiaveOnboardingCoachVisto, true);
}
