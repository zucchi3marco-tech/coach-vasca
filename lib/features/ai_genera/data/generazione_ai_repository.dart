import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/modulo_compilato.dart';
import '../domain/modulo_settimana_compilato.dart';
import '../domain/parametri_generazione.dart';
import '../domain/scheda_generata.dart';
import '../domain/settimana_generata.dart';

/// Oltre questo tempo una chiamata alla generazione AI viene considerata
/// bloccata: senza un limite esplicito, un provider AI che non risponde
/// resta indistinguibile da un tocco su "Genera" che non ha fatto nulla
/// (il problema segnalato in analisi, FASE 11 punto 4/analisi video 2.7).
const _timeoutGenerazione = Duration(seconds: 60);

/// Chiama la Edge Function `genera-allenamento`, che tiene la chiave del
/// provider AI lato server e la inoltra a Gemini. Così il provider si può
/// cambiare in futuro riscrivendo solo la Edge Function, senza toccare
/// l'app. La Edge Function valida già la scheda contro i valori noti
/// (blocco/stile/esecuzione/zona): qui ci si fida della forma dei dati.
class GenerazioneAiRepository {
  GenerazioneAiRepository(this._client);

  final SupabaseClient _client;

  Future<SchedaGenerata> generaAllenamento(
    ParametriGenerazione parametri,
  ) async {
    try {
      final risposta = await _client.functions
          .invoke('genera-allenamento', body: parametri.toMap())
          .timeout(_timeoutGenerazione);
      final dati = risposta.data;
      if (dati is Map && dati['scheda'] is Map) {
        return SchedaGenerata.fromMap(dati['scheda'] as Map<String, dynamic>);
      }
      throw Exception('Risposta inattesa dalla generazione AI: $dati');
    } on FunctionException catch (e) {
      final dettagli = e.details;
      if (dettagli is Map && dettagli['error'] is String) {
        throw Exception(dettagli['error'] as String);
      }
      rethrow;
    }
  }

  /// Chiama la Edge Function `detta-allenamento`: a differenza di
  /// [generaAllenamento] (che *inventa* una scheda da parametri), qui
  /// Gemini deve solo *trascrivere fedelmente* in JSON strutturato quello
  /// che il coach ha dettato — stessa forma di output ([SchedaGenerata]),
  /// stessa Edge Function del "genera con AI" nel senso di isolare la
  /// chiave del provider lato server, ma un prompt diverso.
  Future<SchedaGenerata> generaDaDettatura({
    required String testo,
    required String clubId,
    String? gruppo,
  }) async {
    try {
      final risposta = await _client.functions
          .invoke(
            'detta-allenamento',
            body: {'testo': testo, 'gruppo': gruppo, 'clubId': clubId},
          )
          .timeout(_timeoutGenerazione);
      final dati = risposta.data;
      if (dati is Map && dati['scheda'] is Map) {
        return SchedaGenerata.fromMap(dati['scheda'] as Map<String, dynamic>);
      }
      throw Exception('Risposta inattesa dalla dettatura: $dati');
    } on FunctionException catch (e) {
      final dettagli = e.details;
      if (dettagli is Map && dettagli['error'] is String) {
        throw Exception(dettagli['error'] as String);
      }
      rethrow;
    }
  }

  /// Chiama `compila-modulo`: dal testo libero del coach ricava i valori
  /// dei campi del form "Genera con AI" (vasca, volumi, tipi di lavoro,
  /// focus, attrezzi...). Non genera nessuna scheda: il coach rivede il
  /// modulo compilato e poi preme Genera.
  Future<ModuloCompilato> compilaModulo(String testo) async {
    try {
      final risposta = await _client.functions
          .invoke('compila-modulo', body: {'testo': testo})
          .timeout(_timeoutGenerazione);
      final dati = risposta.data;
      if (dati is Map && dati['modulo'] is Map) {
        return ModuloCompilato.fromMap(
          Map<String, dynamic>.from(dati['modulo'] as Map),
        );
      }
      throw Exception('Risposta inattesa dall\'AI: $dati');
    } on FunctionException catch (e) {
      final dettagli = e.details;
      if (dettagli is Map && dettagli['error'] is String) {
        throw Exception(dettagli['error'] as String);
      }
      rethrow;
    }
  }

  /// Chiama `compila-settimana`: come [compilaModulo], ma per il form
  /// della settimana (giorni, volume settimanale, focus per giorno...).
  Future<ModuloSettimanaCompilato> compilaSettimana(String testo) async {
    try {
      final risposta = await _client.functions
          .invoke('compila-settimana', body: {'testo': testo})
          .timeout(_timeoutGenerazione);
      final dati = risposta.data;
      if (dati is Map && dati['modulo'] is Map) {
        return ModuloSettimanaCompilato.fromMap(
          Map<String, dynamic>.from(dati['modulo'] as Map),
        );
      }
      throw Exception('Risposta inattesa dall\'AI: $dati');
    } on FunctionException catch (e) {
      final dettagli = e.details;
      if (dettagli is Map && dettagli['error'] is String) {
        throw Exception(dettagli['error'] as String);
      }
      rethrow;
    }
  }

  /// Chiama `genera-settimana`: solo lo scheletro di una settimana
  /// (numero di sedute, codice, volume) — FASE 10, punto 5. Il dettaglio
  /// delle serie di ogni seduta si genera poi con [generaAllenamento].
  Future<SettimanaGenerata> generaSettimana(
    ParametriSettimana parametri,
  ) async {
    try {
      final risposta = await _client.functions
          .invoke('genera-settimana', body: parametri.toMap())
          .timeout(_timeoutGenerazione);
      final dati = risposta.data;
      if (dati is Map && dati['settimana'] is Map) {
        return SettimanaGenerata.fromMap(
          dati['settimana'] as Map<String, dynamic>,
        );
      }
      throw Exception('Risposta inattesa dalla generazione AI: $dati');
    } on FunctionException catch (e) {
      final dettagli = e.details;
      if (dettagli is Map && dettagli['error'] is String) {
        throw Exception(dettagli['error'] as String);
      }
      rethrow;
    }
  }
}

final generazioneAiRepositoryProvider = Provider<GenerazioneAiRepository>((
  ref,
) {
  return GenerazioneAiRepository(ref.watch(supabaseClientProvider));
});
