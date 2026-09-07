import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chiave = 'tema_bordo_vasca_scuro';

/// Scelta chiaro/scuro per le tre schermate da bordo vasca (DESIGN.md
/// sezione 9) — solo un gusto visivo di chi tocca quel tablet, salvato
/// sul device e non sincronizzato su Supabase.
class TemaBordoVascaNotifier extends Notifier<bool> {
  @override
  bool build() {
    _carica();
    return false;
  }

  Future<void> _carica() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_chiave) ?? false;
  }

  Future<void> commuta() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chiave, state);
  }
}

final temaBordoVascaScuroProvider =
    NotifierProvider<TemaBordoVascaNotifier, bool>(TemaBordoVascaNotifier.new);
