import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Quello che la configurazione guidata legge sul server oltre a squadre,
/// atleti e membri: se sono già stati fatti dei codici. Online-only, come
/// gli inviti.
class ConfigurazioneRepository {
  ConfigurazioneRepository(this._client);

  final SupabaseClient _client;

  /// È stato creato almeno un codice per un allenatore o un assistente,
  /// usato o no. Li vede solo il responsabile.
  Future<bool> ciSonoInvitiAllenatori(String clubId) =>
      _ceNe('inviti_staff', clubId);

  /// È stato creato almeno un codice personale per un atleta.
  Future<bool> ciSonoCodiciAtleti(String clubId) =>
      _ceNe('inviti_atleta', clubId);

  Future<bool> _ceNe(String tabella, String clubId) async {
    final righe = await _client
        .from(tabella)
        .select('id')
        .eq('club_id', clubId)
        .limit(1);
    return righe.isNotEmpty;
  }
}

final configurazioneRepositoryProvider = Provider<ConfigurazioneRepository>(
  (ref) => ConfigurazioneRepository(ref.watch(supabaseClientProvider)),
);

/// Le scelte della configurazione che restano su questo telefono o
/// computer (`shared_preferences`, come il tour della home): non sono dati
/// del club, e su un altro dispositivo la scheda si nasconde di nuovo con
/// un tocco.
class PreferenzeConfigurazione {
  const PreferenzeConfigurazione();

  static String _chiaveNascosta(String clubId) =>
      'configurazione_nascosta_$clubId';

  static String _chiaveDaSolo(String clubId) => 'alleno_da_solo_$clubId';

  /// La scheda "Per cominciare" è stata nascosta.
  Future<bool> nascosta(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chiaveNascosta(clubId)) ?? false;
  }

  Future<void> nascondi(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chiaveNascosta(clubId), true);
  }

  /// Il responsabile ha toccato "Alleno da solo".
  Future<bool> allenaDaSolo(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chiaveDaSolo(clubId)) ?? false;
  }

  Future<void> segnaAllenaDaSolo(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chiaveDaSolo(clubId), true);
  }
}

final preferenzeConfigurazioneProvider = Provider<PreferenzeConfigurazione>(
  (ref) => const PreferenzeConfigurazione(),
);
