import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../domain/specialista.dart';

/// Gli specialisti convenzionati del club (tabella `specialisti`). Li
/// scrive il responsabile, di rado: solo con la rete. L'ultimo elenco
/// letto resta sul telefono, per leggerlo senza rete.
class SpecialistiRepository {
  SpecialistiRepository(this._client);

  final SupabaseClient _client;

  static String _chiave(String clubId) => 'specialisti_$clubId';

  Future<List<Specialista>> _copia(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    final testo = prefs.getString(_chiave(clubId));
    if (testo == null) return [];
    return ordinaSpecialisti([
      for (final m in jsonDecode(testo) as List)
        ?Specialista.fromMap(Map<String, dynamic>.from(m as Map)),
    ]);
  }

  Future<void> _salvaCopia(String clubId, List<Specialista> elenco) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chiave(clubId),
      jsonEncode([for (final s in elenco) s.toMap()]),
    );
  }

  /// Gli specialisti del club, per tipo e nome. Senza rete l'ultima copia.
  Future<List<Specialista>> elenco(String clubId) async {
    try {
      final righe = await _client
          .from('specialisti')
          .select()
          .eq('club_id', clubId);
      final elenco = ordinaSpecialisti([
        for (final r in righe) ?Specialista.fromMap(r),
      ]);
      await _salvaCopia(clubId, elenco);
      return elenco;
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      return _copia(clubId);
    }
  }

  /// Crea lo specialista o lo aggiorna (con l'id).
  Future<Specialista> salva(Specialista specialista) async {
    Specialista salvato;
    try {
      final payload = specialista.toMap()..remove('id');
      final riga = specialista.id == null
          ? await _client.from('specialisti').insert(payload).select().single()
          : await _client
                .from('specialisti')
                .update(payload)
                .eq('id', specialista.id!)
                .select()
                .single();
      salvato = Specialista.fromMap(riga)!;
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // La demo non ha un server: lo specialista resta sul telefono.
      if (!modalitaDemo) {
        throw Exception('Serve la rete per salvare: riprova quando torna.');
      }
      salvato = Specialista.fromMap({
        ...specialista.toMap(),
        'id': specialista.id ?? const Uuid().v4(),
      })!;
    }
    final copia = await _copia(salvato.clubId);
    await _salvaCopia(
      salvato.clubId,
      ordinaSpecialisti([
        for (final s in copia)
          if (s.id != salvato.id) s,
        salvato,
      ]),
    );
    return salvato;
  }

  Future<void> elimina(Specialista specialista) async {
    final id = specialista.id;
    if (id == null) return;
    try {
      await _client.from('specialisti').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      if (!modalitaDemo) {
        throw Exception('Serve la rete per togliere: riprova quando torna.');
      }
    }
    final copia = await _copia(specialista.clubId);
    await _salvaCopia(specialista.clubId, [
      for (final s in copia)
        if (s.id != id) s,
    ]);
  }
}

final specialistiRepositoryProvider = Provider<SpecialistiRepository>(
  (ref) => SpecialistiRepository(ref.watch(supabaseClientProvider)),
);

/// Gli specialisti del club. autoDispose: riaprendo la pagina si
/// rileggono quelli scritti nel frattempo.
final specialistiProvider = FutureProvider.autoDispose
    .family<List<Specialista>, String>(
      (ref, clubId) => ref.watch(specialistiRepositoryProvider).elenco(clubId),
    );
