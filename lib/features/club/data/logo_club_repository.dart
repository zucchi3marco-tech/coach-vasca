import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';

/// Il logo più grande che si carica: lo stesso limite dello spazio sul
/// server.
const logoClubMassimoByte = 1024 * 1024;

/// Che immagine è [bytes], dai primi byte: 'image/png', 'image/jpeg' o
/// null (un altro formato, o un file rovinato). I PDF sanno disegnare
/// solo questi due.
String? tipoLogo(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  return null;
}

/// Il logo del club: un file nello spazio `loghi_club`, sempre in
/// `club_id/logo`. L'ultimo letto resta sul telefono, così i PDF
/// hanno il logo anche senza rete. Lo cambia solo il responsabile del
/// club: lo decide il database.
class LogoClubRepository {
  LogoClubRepository(this._client);

  final SupabaseClient _client;

  static const _spazio = 'loghi_club';

  static String _percorso(String clubId) => '$clubId/logo';

  static String _chiaveCopia(String clubId) => 'logo_club_$clubId';

  /// La copia sul telefono: null se non c'è, un elenco vuoto se l'ultima
  /// volta il club non aveva un logo.
  Future<Uint8List?> _copia(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    final testo = prefs.getString(_chiaveCopia(clubId));
    if (testo == null) return null;
    return base64Decode(testo);
  }

  Future<void> _salvaCopia(String clubId, Uint8List? logo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chiaveCopia(clubId), base64Encode(logo ?? []));
  }

  static bool _nonCe(Object e) =>
      e is StorageException &&
      (e.statusCode == '400' ||
          e.statusCode == '404' ||
          e.message.toLowerCase().contains('not found'));

  /// Il logo del club, o null se non ce l'ha. Senza rete (o se il server
  /// non risponde entro [attesa]) l'ultima copia.
  Future<Uint8List?> logo(String clubId, {Duration? attesa}) async {
    try {
      final scarica = _client.storage.from(_spazio).download(_percorso(clubId));
      final bytes = attesa == null
          ? await scarica
          : await scarica.timeout(attesa);
      final valido = tipoLogo(bytes) == null ? null : bytes;
      await _salvaCopia(clubId, valido);
      return valido;
    } catch (e) {
      if (_nonCe(e)) {
        await _salvaCopia(clubId, null);
        return null;
      }
      if (!isNetworkFailure(e) && e is! TimeoutException) rethrow;
      final copia = await _copia(clubId);
      return (copia == null || copia.isEmpty) ? null : copia;
    }
  }

  /// Mette [bytes] come logo del club, al posto di quello che c'era.
  Future<void> carica(String clubId, Uint8List bytes) async {
    final tipo = tipoLogo(bytes);
    if (tipo == null) {
      throw Exception("Il logo dev'essere un'immagine PNG o JPG.");
    }
    if (bytes.length > logoClubMassimoByte) {
      throw Exception(
        'Il logo è troppo grande (${_megabyte(bytes.length)}): al massimo '
        '1 MB. Prova con un\'immagine più piccola.',
      );
    }
    try {
      await _client.storage
          .from(_spazio)
          .uploadBinary(
            _percorso(clubId),
            bytes,
            fileOptions: FileOptions(
              contentType: tipo,
              upsert: true,
              // Chi lo rilegge chiede sempre al server: un logo appena
              // cambiato non resta vecchio per un'ora.
              cacheControl: '0',
            ),
          );
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // La demo non ha un server: il logo resta sul telefono.
      if (!modalitaDemo) {
        throw Exception(
          'Serve la rete per caricare il logo: riprova quando torna.',
        );
      }
    }
    await _salvaCopia(clubId, bytes);
  }

  /// Toglie il logo del club.
  Future<void> togli(String clubId) async {
    try {
      await _client.storage.from(_spazio).remove([_percorso(clubId)]);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      if (!modalitaDemo) {
        throw Exception(
          'Serve la rete per togliere il logo: riprova quando torna.',
        );
      }
    }
    await _salvaCopia(clubId, null);
  }
}

/// "2,3 MB", "640 KB".
String _megabyte(int byte) {
  if (byte < 1024 * 1024) return '${(byte / 1024).round()} KB';
  final mb = (byte / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');
  return '$mb MB';
}

final logoClubRepositoryProvider = Provider<LogoClubRepository>(
  (ref) => LogoClubRepository(ref.watch(supabaseClientProvider)),
);

/// Il logo del club. autoDispose: riaprendo «Il mio club» si rilegge
/// quello messo da un altro telefono.
final logoClubProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, clubId) => ref.watch(logoClubRepositoryProvider).logo(clubId),
);
