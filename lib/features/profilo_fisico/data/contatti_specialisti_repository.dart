import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/cache_utente_guard.dart';
import '../../../core/demo/modalita_demo.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../../atleti/domain/atleta.dart';
import '../domain/chi_mi_puo_aiutare.dart';
import '../domain/specialista.dart';

/// Il codice dell'atleta per gli specialisti e la traccia dei contatti
/// (profilo fisico, passo D). Si scrive solo con le funzioni del
/// database (`mio_codice_specialisti`, `registra_contatto_specialista`);
/// l'elenco lo legge solo il responsabile. Il codice e l'ultimo elenco
/// restano sul telefono, e si cancellano cambiando utente.
class ContattiSpecialistiRepository {
  ContattiSpecialistiRepository(this._client);

  final SupabaseClient _client;

  static String _chiaveCodice(String atletaId) =>
      '${prefissiCopieContatti.$1}$atletaId';

  static String _chiaveContatti(String clubId) =>
      '${prefissiCopieContatti.$2}$clubId';

  /// Il codice dell'atleta collegato: il database lo crea la prima volta.
  /// Senza rete quello sul telefono, se c'è.
  Future<String?> mioCodice(String atletaId) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final codice = await _client.rpc('mio_codice_specialisti') as String;
      await prefs.setString(_chiaveCodice(atletaId), codice);
      return codice;
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final copia = prefs.getString(_chiaveCodice(atletaId));
      if (copia != null || !modalitaDemo) return copia;
      // La demo non ha un server: il codice nasce sul telefono.
      final demo = codiceCasuale(Random().nextInt);
      await prefs.setString(_chiaveCodice(atletaId), demo);
      return demo;
    }
  }

  /// Segna il contatto. Non fa mai fallire il contatto: senza rete (o
  /// con un errore) non si segna, e torna false.
  Future<bool> registra({
    required Atleta atleta,
    required Specialista specialista,
    required ProblemaFisico problema,
    required CanaleContatto canale,
    required String? codice,
  }) async {
    try {
      await _client.rpc(
        'registra_contatto_specialista',
        params: {
          'p_specialista_id': specialista.id,
          'p_problema': problema.codice,
          'p_canale': canale.name,
        },
      );
      return true;
    } catch (e) {
      if (!isNetworkFailure(e) || !modalitaDemo || codice == null) {
        return false;
      }
      // In demo il contatto resta sul telefono, per vederlo da
      // responsabile.
      final oggi = DateTime.now();
      final copia = await _copia(atleta.clubId);
      final giaOggi = copia.any(
        (c) =>
            c.atletaId == atleta.id &&
            c.specialistaId == specialista.id &&
            c.giorno.year == oggi.year &&
            c.giorno.month == oggi.month &&
            c.giorno.day == oggi.day,
      );
      if (!giaOggi) {
        await _salvaCopia(atleta.clubId, [
          ...copia,
          ContattoSpecialista(
            id: const Uuid().v4(),
            clubId: atleta.clubId,
            atletaId: atleta.id,
            nomeAtleta: '${atleta.nome} ${atleta.cognome}',
            specialistaId: specialista.id,
            specialistaNome: specialista.nome,
            tipo: specialista.tipo,
            problema: problema,
            canale: canale,
            codice: codice,
            giorno: DateTime(oggi.year, oggi.month, oggi.day),
          ),
        ]);
      }
      return true;
    }
  }

  Future<List<ContattoSpecialista>> _copia(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    final testo = prefs.getString(_chiaveContatti(clubId));
    if (testo == null) return [];
    return [
      for (final m in jsonDecode(testo) as List)
        ?ContattoSpecialista.fromMap(Map<String, dynamic>.from(m as Map)),
    ];
  }

  Future<void> _salvaCopia(
    String clubId,
    List<ContattoSpecialista> elenco,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chiaveContatti(clubId),
      jsonEncode([for (final c in elenco) c.toMap()]),
    );
  }

  /// I contatti del club, per il responsabile. Senza rete l'ultima copia.
  Future<List<ContattoSpecialista>> elenco(String clubId) async {
    try {
      final righe = await _client
          .from('contatti_specialisti')
          .select('*, atleti(nome, cognome)')
          .eq('club_id', clubId)
          .order('giorno', ascending: false);
      final elenco = [for (final r in righe) ?ContattoSpecialista.fromMap(r)];
      await _salvaCopia(clubId, elenco);
      return elenco;
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      return _copia(clubId);
    }
  }

  /// Spunta (o toglie) «visita confermata».
  Future<ContattoSpecialista> confermaVisita(
    ContattoSpecialista contatto, {
    required bool confermata,
  }) async {
    final oggi = DateTime.now();
    final il = confermata ? DateTime(oggi.year, oggi.month, oggi.day) : null;
    final aggiornato = contatto.conConferma(il);
    try {
      await _client
          .from('contatti_specialisti')
          .update({
            'visita_confermata_il': aggiornato.toMap()['visita_confermata_il'],
          })
          .eq('id', contatto.id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      if (!modalitaDemo) {
        throw Exception('Serve la rete per segnare la visita: riprova.');
      }
    }
    final copia = await _copia(contatto.clubId);
    await _salvaCopia(contatto.clubId, [
      for (final c in copia) c.id == contatto.id ? aggiornato : c,
    ]);
    return aggiornato;
  }
}

final contattiSpecialistiRepositoryProvider =
    Provider<ContattiSpecialistiRepository>(
      (ref) => ContattiSpecialistiRepository(ref.watch(supabaseClientProvider)),
    );

/// Il codice dell'atleta per gli specialisti (null senza rete la prima
/// volta, o se non si legge).
final codiceSpecialistiProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, atletaId) async {
      try {
        return await ref
            .watch(contattiSpecialistiRepositoryProvider)
            .mioCodice(atletaId);
      } catch (_) {
        return null;
      }
    });

/// I contatti del club, per il responsabile.
final contattiSpecialistiProvider = FutureProvider.autoDispose
    .family<List<ContattoSpecialista>, String>(
      (ref, clubId) =>
          ref.watch(contattiSpecialistiRepositoryProvider).elenco(clubId),
    );
