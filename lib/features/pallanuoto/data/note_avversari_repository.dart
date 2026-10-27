import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../domain/nota_avversario.dart';

/// Le note dello staff sugli avversari (tabella `note_avversari`). Si
/// scrivono di rado, da una persona alla volta: solo con la rete. Le
/// ultime lette restano sul telefono, così si leggono anche in una
/// piscina senza rete. Chi le vede lo decide il database: lo staff e
/// gli atleti della squadra.
class NoteAvversariRepository {
  NoteAvversariRepository(this._client);

  final SupabaseClient _client;

  static String _chiaveCopia(String clubId, String? gruppoId) =>
      'note_avversari_${clubId}_${gruppoId ?? 'club'}';

  Future<List<NotaAvversario>> _copia(String clubId, String? gruppoId) async {
    final prefs = await SharedPreferences.getInstance();
    final testo = prefs.getString(_chiaveCopia(clubId, gruppoId));
    if (testo == null) return [];
    return [
      for (final m in jsonDecode(testo) as List)
        NotaAvversario.fromMap(Map<String, dynamic>.from(m as Map)),
    ];
  }

  Future<void> _salvaCopia(
    String clubId,
    String? gruppoId,
    List<NotaAvversario> note,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chiaveCopia(clubId, gruppoId),
      jsonEncode([
        for (final n in note)
          {
            ...n.toMap(),
            'id': n.id,
            'updated_at': n.aggiornataIl?.toUtc().toIso8601String(),
          },
      ]),
    );
  }

  /// Le note sugli avversari della squadra [gruppoId] (null: quelle
  /// delle partite di tutto il club). Senza rete l'ultima copia.
  Future<List<NotaAvversario>> perSquadra(
    String clubId,
    String? gruppoId,
  ) async {
    try {
      var query = _client.from('note_avversari').select().eq('club_id', clubId);
      query = gruppoId == null
          ? query.isFilter('gruppo_id', null)
          : query.eq('gruppo_id', gruppoId);
      final righe = await query;
      final note = [for (final r in righe) NotaAvversario.fromMap(r)];
      await _salvaCopia(clubId, gruppoId, note);
      return note;
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      return _copia(clubId, gruppoId);
    }
  }

  /// Salva la nota (la crea se è nuova). Una nota senza niente dentro,
  /// nemmeno il nome FIN, si toglie.
  Future<NotaAvversario?> salva(NotaAvversario nota) async {
    if (nota.senzaNote && nota.nomeFin == null) {
      if (nota.id != null) await elimina(nota);
      return null;
    }
    try {
      final riga = nota.id == null
          ? await _client
                .from('note_avversari')
                .upsert(nota.toMap(), onConflict: 'club_id,gruppo_id,chiave')
                .select()
                .single()
          : await _client
                .from('note_avversari')
                .update(nota.toMap())
                .eq('id', nota.id!)
                .select()
                .single();
      final salvata = NotaAvversario.fromMap(riga);
      await _sostituisciInCopia(salvata);
      return salvata;
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // La demo non ha un server: la nota resta sul telefono.
      if (modalitaDemo) {
        final salvata = NotaAvversario.fromMap({
          ...nota.toMap(),
          'id': nota.id ?? const Uuid().v4(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        await _sostituisciInCopia(salvata);
        return salvata;
      }
      throw Exception(
        'Serve la rete per salvare le note: riprova quando torna.',
      );
    }
  }

  Future<void> elimina(NotaAvversario nota) async {
    final id = nota.id;
    if (id == null) return;
    try {
      await _client.from('note_avversari').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      if (!modalitaDemo) {
        throw Exception(
          'Serve la rete per togliere le note: riprova quando torna.',
        );
      }
    }
    final note = await _copia(nota.clubId, nota.gruppoId);
    await _salvaCopia(nota.clubId, nota.gruppoId, [
      for (final n in note)
        if (n.id != id) n,
    ]);
  }

  Future<void> _sostituisciInCopia(NotaAvversario salvata) async {
    final note = await _copia(salvata.clubId, salvata.gruppoId);
    await _salvaCopia(salvata.clubId, salvata.gruppoId, [
      for (final n in note)
        if (n.id != salvata.id && n.chiave != salvata.chiave) n,
      salvata,
    ]);
  }
}

final noteAvversariRepositoryProvider = Provider<NoteAvversariRepository>(
  (ref) => NoteAvversariRepository(ref.watch(supabaseClientProvider)),
);

/// Le note sugli avversari di una squadra. autoDispose: riaprendo la
/// scheda si rileggono quelle scritte da un collega.
final noteAvversariProvider = FutureProvider.autoDispose
    .family<List<NotaAvversario>, ({String clubId, String? gruppoId})>(
      (ref, k) => ref
          .watch(noteAvversariRepositoryProvider)
          .perSquadra(k.clubId, k.gruppoId),
    );
