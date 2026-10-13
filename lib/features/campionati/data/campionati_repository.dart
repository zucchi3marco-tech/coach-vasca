import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../domain/campionato_fin.dart';
import '../domain/lettore_fin.dart';
import 'pagine_fin_demo.dart';

const _uuid = Uuid();

/// Un girone letto dal sito FIN, con l'ora della lettura. [daCopia]: il
/// sito (o la rete) non ha risposto e si mostra l'ultima copia salvata
/// sul telefono.
class LetturaGirone {
  const LetturaGirone({
    required this.girone,
    required this.lettoIl,
    this.daCopia = false,
  });

  final GironeFin girone;
  final DateTime lettoIl;
  final bool daCopia;
}

/// I campionati FIN Lombardia: le pagine del sito arrivano dalla funzione
/// `campionati-fin` (l'app web non può leggerle direttamente) e si leggono
/// qui con `lettore_fin.dart`. L'ultima pagina di ogni girone resta sul
/// telefono, per vederla anche senza rete.
///
/// I collegamenti fra le squadre del club e i gironi stanno nella tabella
/// `gironi_fin`: si cambiano solo con la rete (per collegare un girone
/// serve comunque il sito FIN), si leggono anche senza dall'ultima copia.
class CampionatiRepository {
  CampionatiRepository(this._client);

  final SupabaseClient _client;

  static String _chiaveGirone(int cmpId) => 'fin_girone_$cmpId';
  static String _chiaveCollegati(String clubId) => 'fin_collegati_$clubId';

  Future<({String html, DateTime lettoIl})> _pagina(
    Map<String, Object?> corpo,
  ) async {
    try {
      final risposta = await _client.functions.invoke(
        'campionati-fin',
        body: corpo,
      );
      final dati = risposta.data;
      if (dati is Map && dati['html'] is String) {
        return (
          html: dati['html'] as String,
          lettoIl:
              DateTime.tryParse('${dati['letto_il']}')?.toLocal() ??
              DateTime.now(),
        );
      }
      throw Exception('Risposta inattesa dal servizio dei campionati.');
    } on FunctionException catch (e) {
      final dettagli = e.details;
      final errore = dettagli is Map ? dettagli['error'] as String? : null;
      throw Exception(
        errore ?? 'Il sito della FIN non ha risposto. Riprova più tardi.',
      );
    }
  }

  /// L'elenco dei gironi di [stagione] (null = quella che il sito mostra
  /// per prima, la più recente).
  Future<ElencoFin> elenco({String? stagione}) async {
    if (modalitaDemo) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return leggiElencoFin(paginaElencoDemoFin());
    }
    final pagina = await _pagina({
      'pagina': 'elenco',
      'stagione': ?stagione,
    });
    return leggiElencoFin(pagina.html);
  }

  /// Classifica e calendario di un girone. Senza rete, o se il sito non
  /// risponde, l'ultima copia salvata; senza copia l'errore.
  Future<LetturaGirone> girone(int cmpId) async {
    if (modalitaDemo) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return LetturaGirone(
        girone: leggiGironeFin(paginaGironeDemoFin(cmpId), cmpId: cmpId),
        lettoIl: DateTime.now(),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    try {
      final pagina = await _pagina({'pagina': 'girone', 'cmp_id': cmpId});
      final girone = leggiGironeFin(pagina.html, cmpId: cmpId);
      await prefs.setString(
        _chiaveGirone(cmpId),
        jsonEncode({
          'html': pagina.html,
          'letto_il': pagina.lettoIl.toIso8601String(),
        }),
      );
      return LetturaGirone(girone: girone, lettoIl: pagina.lettoIl);
    } catch (_) {
      final copia = prefs.getString(_chiaveGirone(cmpId));
      if (copia == null) rethrow;
      final m = jsonDecode(copia) as Map<String, dynamic>;
      return LetturaGirone(
        girone: leggiGironeFin(m['html'] as String, cmpId: cmpId),
        lettoIl: DateTime.parse(m['letto_il'] as String),
        daCopia: true,
      );
    }
  }

  // -------------------------------------------------------------------------
  // I gironi collegati alle squadre del club

  Future<List<GironeCollegato>> _copiaCollegati(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    final copia = prefs.getString(_chiaveCollegati(clubId));
    if (copia == null) return [];
    return [
      for (final m in jsonDecode(copia) as List)
        GironeCollegato.daMap((m as Map).cast<String, dynamic>()),
    ];
  }

  Future<void> _salvaCopiaCollegati(
    String clubId,
    List<GironeCollegato> collegati,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chiaveCollegati(clubId),
      jsonEncode([for (final g in collegati) g.toMap()]),
    );
  }

  /// I gironi collegati del club, dal più recente.
  Future<List<GironeCollegato>> collegati(String clubId) async {
    if (modalitaDemo) return _copiaCollegati(clubId);
    try {
      final righe = await _client
          .from('gironi_fin')
          .select()
          .eq('club_id', clubId)
          .order('created_at', ascending: false);
      final collegati = [
        for (final r in (righe as List).cast<Map<String, dynamic>>())
          GironeCollegato.daMap(r),
      ];
      await _salvaCopiaCollegati(clubId, collegati);
      return collegati;
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      return _copiaCollegati(clubId);
    }
  }

  Future<GironeCollegato> collega({
    required String clubId,
    required String? gruppoId,
    required VoceElencoFin voce,
    required String stagione,
    required String squadra,
  }) async {
    final nuovo = GironeCollegato(
      id: _uuid.v4(),
      clubId: clubId,
      gruppoId: gruppoId,
      cmpId: voce.cmpId,
      stagione: stagione,
      campionato: voce.campionato,
      fase: voce.fase.isEmpty ? null : voce.fase,
      girone: voce.girone.isEmpty ? null : voce.girone,
      squadra: squadra,
      creatoIl: DateTime.now(),
    );
    if (modalitaDemo) {
      final collegati = await _copiaCollegati(clubId);
      collegati.removeWhere(
        (g) => g.gruppoId == gruppoId && g.cmpId == voce.cmpId,
      );
      await _salvaCopiaCollegati(clubId, [nuovo, ...collegati]);
      return nuovo;
    }
    final mappa = nuovo.toMap()..remove('created_at');
    try {
      final riga = await _client
          .from('gironi_fin')
          .insert(mappa)
          .select()
          .single();
      return GironeCollegato.daMap(riga);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          'Questo girone è già collegato alla squadra: per cambiare la '
          'squadra scelta, toglilo e collegalo di nuovo.',
        );
      }
      rethrow;
    } catch (e) {
      if (isNetworkFailure(e)) {
        throw Exception('Per collegare un girone serve la rete.');
      }
      rethrow;
    }
  }

  Future<void> scollega(GironeCollegato girone) async {
    if (modalitaDemo) {
      final collegati = await _copiaCollegati(girone.clubId);
      collegati.removeWhere((g) => g.id == girone.id);
      await _salvaCopiaCollegati(girone.clubId, collegati);
      return;
    }
    try {
      await _client.from('gironi_fin').delete().eq('id', girone.id);
    } catch (e) {
      if (isNetworkFailure(e)) {
        throw Exception('Per togliere un girone serve la rete.');
      }
      rethrow;
    }
  }
}

final campionatiRepositoryProvider = Provider<CampionatiRepository>(
  (ref) => CampionatiRepository(ref.watch(supabaseClientProvider)),
);
