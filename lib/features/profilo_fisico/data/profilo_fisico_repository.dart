import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../../../core/utils/date_format.dart';
import '../domain/misura_fisica.dart';

/// Altezza e peso dell'atleta (`misure_fisiche`) e il consenso del
/// genitore per i minorenni (`consensi_profilo_fisico`). Si scrivono di
/// rado: solo con la rete. L'ultima copia letta resta sul telefono, per
/// leggerla senza rete. Chi legge e chi scrive lo decide il database:
/// l'atleta le sue, lo staff legge e segna il consenso.
class ProfiloFisicoRepository {
  ProfiloFisicoRepository(this._client);

  final SupabaseClient _client;

  static String _chiaveMisure(String atletaId) => 'misure_fisiche_$atletaId';
  static String _chiaveConsenso(String atletaId) =>
      'consenso_profilo_fisico_$atletaId';

  static const _senzaRete = 'Serve la rete per salvare: riprova quando torna.';

  Future<List<MisuraFisica>> _copiaMisure(String atletaId) async {
    final prefs = await SharedPreferences.getInstance();
    final testo = prefs.getString(_chiaveMisure(atletaId));
    if (testo == null) return [];
    return _ordinate([
      for (final m in jsonDecode(testo) as List)
        MisuraFisica.fromMap(Map<String, dynamic>.from(m as Map)),
    ]);
  }

  Future<void> _salvaCopiaMisure(
    String atletaId,
    List<MisuraFisica> misure,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chiaveMisure(atletaId),
      jsonEncode([for (final m in misure) m.toMap()]),
    );
  }

  static List<MisuraFisica> _ordinate(List<MisuraFisica> misure) =>
      misure..sort((a, b) => b.data.compareTo(a.data));

  /// Le misure dell'atleta, dalla più recente. Senza rete l'ultima copia.
  Future<List<MisuraFisica>> misure(String atletaId) async {
    try {
      final righe = await _client
          .from('misure_fisiche')
          .select()
          .eq('atleta_id', atletaId);
      final misure = _ordinate([
        for (final r in righe) MisuraFisica.fromMap(r),
      ]);
      await _salvaCopiaMisure(atletaId, misure);
      return misure;
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      return _copiaMisure(atletaId);
    }
  }

  /// Il giorno in cui lo staff ha segnato il consenso del genitore, se
  /// c'è. Senza rete l'ultima copia.
  Future<DateTime?> consenso(String atletaId) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final riga = await _client
          .from('consensi_profilo_fisico')
          .select('ricevuto_il')
          .eq('atleta_id', atletaId)
          .maybeSingle();
      final il = riga?['ricevuto_il'] as String?;
      if (il == null) {
        await prefs.remove(_chiaveConsenso(atletaId));
      } else {
        await prefs.setString(_chiaveConsenso(atletaId), il);
      }
      return il == null ? null : DateTime.parse(il);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final il = prefs.getString(_chiaveConsenso(atletaId));
      return il == null ? null : DateTime.parse(il);
    }
  }

  /// Salva la misura del giorno (una sola per giorno: la riscrive).
  Future<MisuraFisica> salva(MisuraFisica misura) async {
    MisuraFisica salvata;
    try {
      final payload = misura.toMap()..remove('id');
      final riga = await _client
          .from('misure_fisiche')
          .upsert(payload, onConflict: 'atleta_id,data')
          .select()
          .single();
      salvata = MisuraFisica.fromMap(riga);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // La demo non ha un server: la misura resta sul telefono.
      if (!modalitaDemo) throw Exception(_senzaRete);
      salvata = MisuraFisica.fromMap({
        ...misura.toMap(),
        'id': misura.id ?? const Uuid().v4(),
      });
    }
    final giorno = formatDateOnly(salvata.data);
    final copia = await _copiaMisure(salvata.atletaId);
    await _salvaCopiaMisure(
      salvata.atletaId,
      _ordinate([
        for (final m in copia)
          if (formatDateOnly(m.data) != giorno) m,
        salvata,
      ]),
    );
    return salvata;
  }

  Future<void> elimina(MisuraFisica misura) async {
    try {
      await _client
          .from('misure_fisiche')
          .delete()
          .eq('atleta_id', misura.atletaId)
          .eq('data', formatDateOnly(misura.data));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      if (!modalitaDemo) {
        throw Exception('Serve la rete per togliere: riprova quando torna.');
      }
    }
    final giorno = formatDateOnly(misura.data);
    final copia = await _copiaMisure(misura.atletaId);
    await _salvaCopiaMisure(misura.atletaId, [
      for (final m in copia)
        if (formatDateOnly(m.data) != giorno) m,
    ]);
  }

  /// Lo staff segna il consenso del genitore ricevuto (oggi).
  Future<DateTime> segnaConsenso({
    required String atletaId,
    required String clubId,
  }) async {
    var il = DateTime.now();
    try {
      // Solo insert (il consenso non si modifica): se un collega l'ha
      // già segnato, si legge il suo.
      try {
        await _client.from('consensi_profilo_fisico').insert({
          'atleta_id': atletaId,
          'club_id': clubId,
        });
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
      }
      final riga = await _client
          .from('consensi_profilo_fisico')
          .select('ricevuto_il')
          .eq('atleta_id', atletaId)
          .single();
      il = DateTime.parse(riga['ricevuto_il'] as String);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      if (!modalitaDemo) throw Exception(_senzaRete);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chiaveConsenso(atletaId), formatDateOnly(il));
    return il;
  }

  /// Lo staff toglie il consenso: il database cancella anche le misure
  /// dell'atleta minorenne ([minorenne] le toglie dalla copia).
  Future<void> togliConsenso({
    required String atletaId,
    required bool minorenne,
  }) async {
    try {
      await _client
          .from('consensi_profilo_fisico')
          .delete()
          .eq('atleta_id', atletaId);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      if (!modalitaDemo) {
        throw Exception('Serve la rete per togliere: riprova quando torna.');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chiaveConsenso(atletaId));
    if (minorenne) await prefs.remove(_chiaveMisure(atletaId));
  }
}

final profiloFisicoRepositoryProvider = Provider<ProfiloFisicoRepository>(
  (ref) => ProfiloFisicoRepository(ref.watch(supabaseClientProvider)),
);

/// Le misure di un atleta. autoDispose: riaprendo la pagina si rileggono.
final misureFisicheProvider = FutureProvider.autoDispose
    .family<List<MisuraFisica>, String>(
      (ref, atletaId) =>
          ref.watch(profiloFisicoRepositoryProvider).misure(atletaId),
    );

/// Il giorno del consenso del genitore, se c'è.
final consensoProfiloFisicoProvider = FutureProvider.autoDispose
    .family<DateTime?, String>(
      (ref, atletaId) =>
          ref.watch(profiloFisicoRepositoryProvider).consenso(atletaId),
    );
