import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chiaveTemaApp = 'tema_app';
const _chiaveTemaBordoVasca = 'tema_bordo_vasca';

/// Override del tema per le tre schermate da bordo vasca (DESIGN.md
/// sezione 15): "segui l'app" (predefinito), oppure forza chiaro o
/// scuro indipendentemente dall'impostazione generale — la scelta lì
/// dipende dall'impianto (luce, riflessi), non dal gusto, e può cambiare
/// da un giorno all'altro.
enum TemaBordoVasca {
  seguiApp,
  chiaro,
  scuro;

  String get _chiave => switch (this) {
    TemaBordoVasca.seguiApp => 'segui_app',
    TemaBordoVasca.chiaro => 'chiaro',
    TemaBordoVasca.scuro => 'scuro',
  };

  static TemaBordoVasca _daChiave(String? chiave) => switch (chiave) {
    'chiaro' => TemaBordoVasca.chiaro,
    'scuro' => TemaBordoVasca.scuro,
    _ => TemaBordoVasca.seguiApp,
  };
}

/// `ThemeMode` per l'app intera — DESIGN.md sezione 15: Sistema (di
/// default) · Chiaro · Scuro, persistito con `shared_preferences` sul
/// device (non su Supabase: è un gusto del device, non un dato del
/// club).
class TemaAppNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _carica();
    return ThemeMode.system;
  }

  Future<void> _carica() async {
    final prefs = await SharedPreferences.getInstance();
    final valore = prefs.getString(_chiaveTemaApp);
    state = switch (valore) {
      'chiaro' => ThemeMode.light,
      'scuro' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> imposta(ThemeMode modo) async {
    state = modo;
    final prefs = await SharedPreferences.getInstance();
    final valore = switch (modo) {
      ThemeMode.light => 'chiaro',
      ThemeMode.dark => 'scuro',
      ThemeMode.system => 'sistema',
    };
    await prefs.setString(_chiaveTemaApp, valore);
  }
}

final temaAppProvider = NotifierProvider<TemaAppNotifier, ThemeMode>(
  TemaAppNotifier.new,
);

/// Override bordo vasca — non ancora consumato da nessuna schermata in
/// questa fase (arriverà con `ThemeToggle` e le tre schermate vasca,
/// DESIGN.md sezione 20 "Ordine di lavoro" punto 4).
///
/// Nome distinto da `TemaBordoVascaNotifier` (in
/// `tema_bordo_vasca_provider.dart`, ancora in uso da
/// `partita_live_screen.dart`): due sistemi che coesistono finché le
/// schermate vasca non migrano a questo, a tre stati invece che un solo
/// booleano scuro/chiaro.
class TemaBordoVascaOverrideNotifier extends Notifier<TemaBordoVasca> {
  @override
  TemaBordoVasca build() {
    _carica();
    return TemaBordoVasca.seguiApp;
  }

  Future<void> _carica() async {
    final prefs = await SharedPreferences.getInstance();
    state = TemaBordoVasca._daChiave(prefs.getString(_chiaveTemaBordoVasca));
  }

  Future<void> imposta(TemaBordoVasca tema) async {
    state = tema;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chiaveTemaBordoVasca, tema._chiave);
  }
}

final temaBordoVascaOverrideProvider =
    NotifierProvider<TemaBordoVascaOverrideNotifier, TemaBordoVasca>(
      TemaBordoVascaOverrideNotifier.new,
    );
